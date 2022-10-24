# OpenVPN for Docker

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/peterrosell/openvpn-yubikey-ldap/master/LICENSE)

Setup a full featured and secure OpenVPN server that support Yubikey OTP, LDAP and Radius without effort using Docker.

Several different configuration can be used when configuring OpenVPN with
this docker container.

* Yubikey with the yubikey IDs specified in a local file
* Yubikey with the yubikey IDs specified in the user's account info in a LDAP server.
* Password stored in a LDAP server.
* A combination of Yubikey ID and Password stored in a LDAP server.
* Authentication handled by a Radius server. (Tested with FreeRadius)

All the above configurations can be used with or without client certificates. Make sure you always have 2 factor authentication!

## Configuration of OpenVPN

When you setup OpenVPN you first have to initialize its configuration. That
is done with the `initopenvpn` command. `initopenvpn` has a number of configuration flags that can be used.

To show the flags for `initopenvpn` command you can run:

        docker run --rm quay.io/peter_rosell/openvpn-yubikey-ldap initopenvpn -h

It will show the usage of the command:

```bash
usage: /usr/local/bin/initopenvpn [-d]
                -u SERVER_PUBLIC_URL
                [-s SERVER_SUBNET]
                [-r ROUTE ...]
                [-p PUSH ...]

optional arguments:
-h    Show this help
-d    Disable NAT routing and default route
-c    Enable client-to-client option
-D    Disable built in external dns (google dns)
-N    Configure NAT to access external server network
-m    Set tun-mtu
-y    Authentication with Yubikey OTP. IDs stored in local file
-Y    Authentication with Yubikey OTP. IDs stored in LDAP
-L    Authentication with Password stored in LDAP. Can be combined with Yubikey with LDAP backend
-R    Authentication via Radius server
-X    Make client certificate optional. Only use if 2FA already is configure, such as Yubikey and password
```

When specifying any of the flags -y, -Y, -L, -R example files will be generated in the openvpn data directory. You will need to create correctly
configured file before starting the OpenVPN server. The expected files
should be named like the example files, except for the example* part.
I.e. openvpn_external.example-yubikey-and-ldap should be renamed to
openvpn_external.

### Required files

* -y    -- yubikey_mappings
* -L    -- ldap.conf
* -Y    -- openvpn_external (based on openvpn_external.example-yubikey)
* -L -Y -- ldap.cpnf and openvpn_external (based on openvpn_external.example-yubikey-and-ldap)
* -R    -- pam_radius_auth.conf

## Quick Start

1. Create the `$OVPN_DATA` volume container

        export OVPN_DATA=/path/to/my/openvpn/data
        export EASYRSA_CONFIG_DIR=/path/to/my/easy-rsa

2a. Initialize the `$OVPN_DATA` data store that will hold the configuration files and certificates. This example shows how to setup without default routing and using LDAP for both user/password and yubikey id. Client certificate is optional. 

        docker run -v $OVPN_DATA:/etc/openvpn --rm quay.io/peter_rosell/openvpn-yubikey-ldap initopenvpn -u udp://VPN.SERVERNAME.COM -dLYX
        docker run -v $OVPN_DATA:/etc/openvpn -v $EASYRSA_CONFIG_DIR=/etc/easy-rsa --rm -it quay.io/peter_rosell/openvpn-yubikey-ldap initpki

2b. Rename the generated example file for yubikey's PAM configuration from `openvpn_external.example-yubikey-and-ldap` to `openvpn_external`. Edit the parameters for the yubikey PAM module to match your LDAP server's settings. If you want debug output you can add `debug` at the end of the file.

2c. Rename the generated example file for LDAP config from `ldap.conf.example` to `ldap.conf`. Edit the values for `base`, `uri`, `binddn` and `bindpw`.

3. Start OpenVPN server process

        docker run --name openvpn -v $OVPN_DATA:/etc/openvpn -v $EASYRSA_CONFIG_DIR=/etc/easy-rsa -d -p 1194:1194/udp --cap-add=NET_ADMIN quay.io/peter_rosell/openvpn-yubikey-ldap

4. Generate a client certificate (only if client certificates are used)

        docker run -v $OVPN_DATA:/etc/openvpn -v $EASYRSA_CONFIG_DIR=/etc/easy-rsa --rm -it quay.io/peter_rosell/openvpn-yubikey-ldap easyrsa build-client-full CLIENTNAME

    - Or without a passphrase (only do this for testing purposes)

            docker run -v $OVPN_DATA:/etc/openvpn -v $EASYRSA_CONFIG_DIR=/etc/easy-rsa --rm -it quay.io/peter_rosell/openvpn-yubikey-ldap easyrsa build-client-full CLIENTNAME nopass

5. Retrieve the client configuration with embedded certificates

        docker run -v $OVPN_DATA:/etc/openvpn -v $EASYRSA_CONFIG_DIR=/etc/easy-rsa --rm quay.io/peter_rosell/openvpn-yubikey-ldap getclient CLIENTNAME > CLIENTNAME.ovpn

    - Or retrieve the client configuration with mssfix set to a lower value (yay Ziggo WifiSpots)

            docker run -v $OVPN_DATA:/etc/openvpn -v $EASYRSA_CONFIG_DIR=/etc/easy-rsa --rm quay.io/peter_rosell/openvpn-yubikey-ldap getclient -M 1312 CLIENTNAME > CLIENTNAME.ovpn

    - Or if not client certificates are used just fetch the client configuration.

        docker run -v $OVPN_DATA:/etc/openvpn -v $EASYRSA_CONFIG_DIR=/etc/easy-rsa --rm quay.io/peter_rosell/openvpn-yubikey-ldap getclient -X > client-config.ovpn

6. Revoke a client certificate
		
    If you need to remove access for a client then you can revoke the client certificate by running

        docker run -v $OVPN_DATA:/etc/openvpn -v $EASYRSA_CONFIG_DIR=/etc/easy-rsa --rm -it quay.io/peter_rosell/openvpn-yubikey-ldap revokeclient CLIENTNAME

7. List all generated certificate names (includes the server certificate name)

        docker run -v $OVPN_DATA:/etc/openvpn -v $EASYRSA_CONFIG_DIR=/etc/easy-rsa --rm quay.io/peter_rosell/openvpn-yubikey-ldap listcerts

8. Renew the CRL

        docker run -v $OVPN_DATA:/etc/openvpn -v $EASYRSA_CONFIG_DIR=/etc/easy-rsa --rm -it quay.io/peter_rosell/openvpn-yubikey-ldap renewcrl

* To enable (bash) debug output set an environment variable with the name DEBUG and value of 1 (using "docker -e")
        for example `docker run -e DEBUG=1 --name openvpn -v $OVPN_DATA:/etc/openvpn -d -p 1194:1194/udp --cap-add=NET_ADMIN quay.io/peter_rosell/openvpn-yubikey-ldap`

* To view the log output run `docker logs openvpn`, to view it realtime run `docker logs -f openvpn`

### Troubleshooting

When troubleshooting you can do some changes in the configuration to
activate more detailed logging.

* Log level in OpenVPN

To add more loggning in OpenVPN increase the log level value.
Valid values are from 1 up to 11. Usually 9 or a bit lower will give enough info.

* pam logging

pam logs to syslog and the syslog daemon is not running inside the container
by default. To activate pam logging you will first need to add `debug` to
the pam module that you want to troubleshoot. The start the syslog daemon
inside the container and watch the logs. When having the OpenVPN container running you can use this command:

        docker exec -i -t openvpn bash -c 'if [ "$$(ps -ef | grep syslog | grep -v grep | wc -l)" == "0" ]; then syslogd ; fi ; tail -f -n 20 /var/log/debug.log'


## Settings and features
* OpenVPN 2.5.7
* OpenSSL 3.0.2
* Easy-RSA v3.1.1
* `tun` mode because it works on the widest range of devices. `tap` mode, for instance, does not work on Android, except if the device is rooted.
* The UDP server uses`192.168.255.0/24` for clients.
* TLS 1.2 minimum
* TLS auth key for HMAC security
* Diffie-Hellman parameters for perfect forward secrecy
* Verification of the server certificate subject
* Extended Key usage check of both client and server certificates
* 2048 bits key size
* Client certificate revocation functionality
* SHA256 signature hash
* AES-256-CBC cipher
* TLS cipher limited to TLS-ECDHE-RSA-WITH-AES-128-GCM-SHA256, TLS-ECDHE-ECDSA-WITH-AES-128-GCM-SHA256, TLS-DHE-RSA-WITH-AES-256-GCM-SHA384 or TLS-DHE-RSA-WITH-AES-256-CBC-SHA256
* Compression enabled and set to adaptive
* Floating client ip's enabled
* Tweaks for Windows clients
* `net30` topology because it works on the widest range of OS's. `p2p`, for instance, does not work on Windows.
* Google DNS (8.8.4.4 and 8.8.8.8)

* The configuration is located in `/etc/openvpn`
* Certificates are generated in `/etc/easy-rsa/pki`.

## Tested On

* Clients
  * Ubuntu OpenVPN Client (Network Manager)
  * Windows
  * OpenVPN for Android

Based on [chadoe/docker-openvpn](https://github.com/chadoe/docker-openvpn) [kylemanna/docker-openvpn](https://github.com/kylemanna/docker-openvpn).
