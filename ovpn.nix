{ config, lib, ... }:

with lib;

{
  options = {
    ovpn.client = mkOption {
      type = types.lines;
      description = "Template function for client certs.";
    };
  };
}
