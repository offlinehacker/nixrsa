NIXRSA - Cert managment sucks!!!
================================

Let's try to make cert management a little bit more deterministic

Install:
--------

TODO

Usage:
------

```bash
nix-cert -h                                               Display this help message.
nix-cert cert -c <configuration> [-o <certs>]             Generate certs.
nix-cert ovpn -c <configuration> -n <name> [-o <certs>]   Generate ovpn files.
```

Tutorial:
---------

- Create cert configuration file with custom name eg. `nixrsa.nix`

    ```nix
    {config, ... }: {
    certs = {
        country = "SI";
        province = "SI";
        city = "Ljubljana";
        organization = "Nixrsa Limited";
        email = "info@nixrsa.net";
        cname = "nixrsa.net";
        nodes = {
            openvpn.cname = "openvpn.nixrsa.net";
            openvpn.type = "server";
            jaka.cname = "jaka.nixrsa.net";
        };
    };

    ovpn.client = ''
        client
        comp-lzo
        dev tun
        nobind
        persist-key
        persist-tun
        remote 54.91.34.25 1194
        resolv-retry infinite
        remote-cert-tls server
        verb 3
        proto udp
        <ca>
        INSERT_CA_CERT
        </ca>
        <cert>
        INSERT_CLIENT_CERT
        </cert>
        <key>
        INSERT_CLIENT_KEY
        </key>
    '';
    }
    ```

- Build certs:

    ```bash
    ./nixrsa.sh cert -c nixrsa.nix -o nixrsa
    ```

- Update certs:

    Nixrsa will track changes and create/revoke certs

    ```bash
    ./nixrsa.sh cert -c nixrsa.nix -o nixrsa
    ```

- Generate openvpn config files:

    ```
    ./nixrsa.sh ovpn -c gatehub.nix -o gatehub -n jaka
    ```

Todo:
-----

- Better garbage collection to remove all private files from store
- Support for import/export

License:
--------

MIT
