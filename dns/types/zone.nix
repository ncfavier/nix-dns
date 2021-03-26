#
# © 2019 Kirill Elagin <kirelagin@gmail.com>
#
# SPDX-License-Identifier: MIT
#

{ pkgs }:

let
  inherit (builtins) attrValues filter map removeAttrs;
  inherit (pkgs.lib) concatMapStringsSep concatStringsSep mapAttrs
                     mapAttrsToList optionalString;
  inherit (pkgs.lib) mkOption types;

  inherit (import ./record.nix { inherit pkgs; }) recordType writeRecord;

  rsubtypes = import ./records { inherit pkgs; };
  rsubtypes' = removeAttrs rsubtypes ["SOA"];

  subzoneOptions = config: {
    defaults = {
      class = mkOption {
        type = types.enum [ "IN" ];
        default = "IN";
        example = "IN";
        description = "Resource record class. Only IN is supported";
      };
      ttl = mkOption {
        type = types.ints.unsigned; # TODO: u32
        default = 24 * 60 * 60;
        example = 300;
        description = "Default record caching duration (in seconds)";
      };
    };
    subdomains = mkOption {
      type = types.attrsOf subzone;
      default = {};
      example = {
        www = {
          A = [ { address = "1.1.1.1"; } ];
        };
        staging = {
          A = [ { address = "1.0.0.1"; } ];
        };
      };
      description = "Records for subdomains of the domain";
    };
  } //
    mapAttrs (n: t: mkOption rec {
      type = types.listOf (recordType config t);
      default = [];
      example = [ t.example ];
      description = "List of ${t} records for this zone/subzone";
    }) rsubtypes';

  subzone = types.submodule ({ config, ... }: {
    options = subzoneOptions config;
  });

  writeSubzone = name: zone:
    let
      groupToString = pseudo: subt:
        concatMapStringsSep "\n" (writeRecord name zone subt) (zone."${pseudo}");
      groups = mapAttrsToList groupToString rsubtypes';
      groups' = filter (s: s != "") groups;

      writeSubzone' = subname: writeSubzone "${subname}.${name}";
      sub = concatStringsSep "\n\n" (mapAttrsToList writeSubzone' zone.subdomains);
    in
      concatStringsSep "\n\n" groups'
      + optionalString (sub != "") ("\n\n" + sub);

  zone = types.submodule ({ name, config, ... }: {
    options = {
      SOA = mkOption rec {
        type = recordType config rsubtypes.SOA;
        example = {
          ttl = 24 * 60 * 60;
        } // type.example;
        description = "SOA record";
      };
      __toString = mkOption {
        readOnly = true;
        visible = false;
      };
    } // subzoneOptions config;

    config = {
      __toString = zone@{ SOA, ... }:
        ''
          ${writeRecord name zone rsubtypes.SOA SOA}

          ${writeSubzone name zone}
        '';
    };
  });

in

{
  inherit zone;
  inherit subzone;
}
