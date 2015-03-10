{ pkgs ? import <nixpkgs> {}, configuration, name ? "" }:

with pkgs.lib;

let
  config = (evalModules {
    modules = [./certs.nix ./ovpn.nix configuration];
    args = { inherit pkgs; };
  }).config;

  certs =
    if hasAttr "certs.json" (builtins.readDir ./build) then
      builtins.fromJSON (builtins.readFile ./build/certs.json)
    else { nodes = {}; };

  revoke = filterAttrs (n: v: !(hasAttr n config.certs.nodes) ) certs.nodes;

in {
  certs = pkgs.stdenv.mkDerivation {
    name = "nixrsa-keys-${toString builtins.currentTime}";
    buildInputs = [ pkgs.easyrsa ];
    phases = [ "installPhase" ];

    src = { outPath = ./build; name = "nixrsa-cert"; };

    installPhase = ''
      mkdir -p $out
      cp -R "$src/"* "$out/" || true

      # This variable should point to
      # the requested executables
      #
      export PKCS11TOOL="pkcs11-tool"

      # This variable should point to
      # the openssl.cnf file included
      # with easy-rsa.
      export EASY_RSA="${pkgs.easyrsa}/share/easy-rsa"

      # Edit this variable to point to
      # your soon-to-be-created key
      # directory.
      export KEY_DIR="$out"

      # Increase this to 2048 if you
      # are paranoid.  This will slow
      # down TLS negotiation performance
      # as well as the one-time DH parms
      # generation process.
      export KEY_SIZE=${toString config.certs.keySize}

      # In how many days should the root CA key expire?
      export CA_EXPIRE=${toString config.certs.caExpire}

      # In how many days should certificates expire?
      export KEY_EXPIRE=${toString config.certs.keyExpire}

      # certificate fields
      export KEY_COUNTRY="${config.certs.country}"
      export KEY_PROVINCE="${config.certs.province}"
      export KEY_CITY="${config.certs.city}"
      export KEY_ORG="${config.certs.organization}"
      export KEY_EMAIL="${config.certs.email}"
      export KEY_CNAME="${config.certs.cname}"

      # needed for openssl random file
      export HOME=$out

      export SSLCNF=$($EASY_RSA/whichopensslcnf $EASY_RSA)
      head -n -5 $SSLCNF > openssl.cnf
      chmod 744 openssl.cnf
      echo "commonName_default        = $ENV::KEY_CNAME" >> openssl.cnf
      export KEY_CONFIG=`pwd`/openssl.cnf

      if [ ! -f $out/index.txt ]; then
        echo "Creating CA"
        clean-all
      fi

      if [ ! -f $out/ca.crt ] || [ ! -f $out/ca.key ]; then
        echo "Generating CA"
        build-ca --batch
      fi

      if [ ! -f $out/dh${toString config.certs.keySize}.pem ]; then
        echo "Generating DH key"
        build-dh --batch
      fi

      ${concatMapStrings (s: ''
        if [ ! -f $out/${s.cname}.key ]; then
          export KEY_EMAIL="${s.email}"
          echo "Generating server key for ${s.cname}"
          build-key${optionalString (s.type == "server") "-server"} --batch ${s.cname}
        fi
      '') (attrValues config.certs.nodes)}

      ${concatMapStrings (r: ''
        echo "Revoking key ${r.cname}"
        chmod +w $out/crl.pem || true
        revoke-full ${r.cname} || true
        rm -f $out/${r.cname}*
        echo ${r.cname}
      '') (attrValues revoke)}

      rm -f $out/certs.json || true
      cp ${pkgs.writeText "active-certs" (builtins.toJSON config.certs)} $out/certs.json
    '';
  };

  ovpn = let
    cfg = config.certs.nodes.${name};
  in pkgs.stdenv.mkDerivation {
    name = "nixrsa-ovpn-${name}-${toString builtins.currentTime}";
    buildInputs = [ pkgs.easyrsa ];
    phases = [ "installPhase" ];

    src = { outPath = ./build; name = "nixrsa-cert"; };

    installPhase = ''
      cp ${pkgs.writeText "nixrsa-ovpn" config.ovpn.client} $out
      substituteInPlace $out --replace INSERT_CA_CERT "$(< $src/ca.crt)"
      substituteInPlace $out --replace INSERT_CLIENT_CERT "$(< $src/${cfg.cname}.crt)"
      substituteInPlace $out --replace INSERT_CLIENT_KEY "$(< $src/${cfg.cname}.key)"
    '';
  };

  inherit config;
}
