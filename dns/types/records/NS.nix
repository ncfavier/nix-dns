#
# © 2019 Kirill Elagin <kirelagin@gmail.com>
#
# SPDX-License-Identifier: MIT
#

{ pkgs }:

let
  inherit (pkgs.lib) mkOption types;

in

{
  rtype = "NS";
  options = {
    nsdname = mkOption {
      type = types.str;
      example = "ns2.example.com";
      description = "A <domain-name> which specifies a host which should be authoritative for the specified class and domain";
    };
  };
  dataToString = {nsdname, ...}: "${nsdname}";
}
