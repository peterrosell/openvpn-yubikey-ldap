# OpenVPN for Docker

Setup a secure OpenVPN server without effort using Docker.

## Quick Start

1. Create the `$OVPN_DATA` volume container, i.e. `export OVPN_DATA=openvpn_data`

        docker run --name $OVPN_DATA -v /etc/openvpn busybox

2. Initialize the `$OVPN_DATA` container that will hold the configuration files and certificates

        docker run --volumes-from $OVPN_DATA --rm martin/openvpn ovpn_genconfig -u udp://VPN.SERVERNAME.COM
        docker run --volumes-from $OVPN_DATA --rm -it martin/openvpn ovpn_initpki

3. Start OpenVPN server process

        docker run --volumes-from $OVPN_DATA -v /etc/localtime:/etc/localtime:ro -d -p 1194:1194/udp --cap-add=NET_ADMIN martin/openvpn

4. Generate a client certificate

        docker run --volumes-from $OVPN_DATA --rm -it martin/openvpn easyrsa build-client-full CLIENTNAME

    - Or without a passphrase (only do this for testing purposes)

            docker run --volumes-from $OVPN_DATA --rm -it martin/openvpn easyrsa build-client-full CLIENTNAME nopass

5. Retrieve the client configuration with embedded certificates

        docker run --volumes-from $OVPN_DATA --rm martin/openvpn ovpn_getclient CLIENTNAME > CLIENTNAME.ovpn

    - Or retrieve the client configuration with mssfix set to a lower value (yay Ziggo WifiSpots)

            docker run --volumes-from $OVPN_DATA --rm martin/openvpn ovpn_getclient -M 1312 CLIENTNAME > CLIENTNAME.ovpn
		
* If you need to remove access for a client then you can revoke the client certificate by running

        docker run --volumes-from $OVPN_DATA --rm -it martin/openvpn ovpn_revokeclient CLIENTNAME


## Settings and featurs
* OpenVPN 2.3.6
* Easy-RSA v3.0.0-rc2 with utf-8 patch
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
* Certificates are generated in `/etc/openvpn/pki`.


## Tested On

* Clients
  * Android App OpenVPN Connect 1.1.14 (built 56)
  * Windows 8.1 64 bit using openvpn-2.3.6


Based on [kylemanna/docker-openvpn](https://github.com/kylemanna/docker-openvpn).
