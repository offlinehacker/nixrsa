{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.certs;

in {
  options.certs = {
    country = mkOption {
      type = types.str;
      description = "Issued certificate country.";
      example = "SI";
    };

    province = mkOption {
      type = types.str;
      description = "Issued certificate province.";
      example = "SI";
    };

    city = mkOption {
      type = types.str;
      description = "Issued certificate city.";
      example = "Ljubljana";
    };

    organization = mkOption {
      type = types.str;
      description = "Issues certificate organization.";
      example = "My organization.";
    };

    email = mkOption {
      type = types.str;
      description = "Issued certificate email.";
      example = "info@mycompany.com";
    };

    cname = mkOption {
      type = types.str;
      description = "Issued certificate common name.";
      example = "mycompany";
    };

    keySize = mkOption {
      type = types.int;
      description = "Issued certificate key size.";
      default = 2048;
    };

    caExpire = mkOption {
      type = types.int;
      description = "In how many days should the root CA key expire.";
      default = 3650;
    };

    keyExpire = mkOption {
      type = types.int;
      description = "In how many days should certificates expire.";
      default = 3650;
    };

    nodes = mkOption {
      type = types.attrsOf types.optionSet;
      description = "Attribute set of server certs to create.";
      options = [({ name, config, ... }: {
        options = {
          type = mkOption {
            description = "Certificate type.";
            default = "client";
            type = types.enum ["client" "server"];
          };

          cname = mkOption {
            description = "Server commonName.";
            default = name;
            type = types.str;
          };

          email = mkOption {
            description = "Server contact email.";
            default = cfg.email;
            type = types.str;
          };

          gpg = mkOption {
            description = "GPG key id to use to for encryption of files";
            default = "";
            type = types.str;
          };
        };
      })];
      default = [];
    };
  };
}
