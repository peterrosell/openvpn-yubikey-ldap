# OpenVPN for Docker

OpenVPN server in a Docker container complete with an EasyRSA PKI CA.

Based on [kylemanna/docker-openvpn](https://github.com/kylemanna/docker-openvpn) but with certificate revocation functionality.

## Quick Start

* Create the `$OVPN_DATA` volume container, i.e. `OVPN_DATA="openvpn_data"`

        docker run --name $OVPN_DATA -v /etc/openvpn busybox

* Initialize the `$OVPN_DATA` container that will hold the configuration files and certificates

        docker run --volumes-from $OVPN_DATA --rm martin/openvpn ovpn_genconfig -u udp://VPN.SERVERNAME.COM
        docker run --volumes-from $OVPN_DATA --rm -it martin/openvpn ovpn_initpki

* Start OpenVPN server process

        docker run --volumes-from $OVPN_DATA -d -p 1194:1194/udp --cap-add=NET_ADMIN martin/openvpn

* Generate a client certificate without a passphrase

        docker run --volumes-from $OVPN_DATA --rm -it martin/openvpn easyrsa build-client-full CLIENTNAME

    - Or without a passphrase (only do this for testing purposes)

            docker run --volumes-from $OVPN_DATA --rm -it martin/openvpn easyrsa build-client-full CLIENTNAME nopass

* Retrieve the client configuration with embedded certificates

        docker run --volumes-from $OVPN_DATA --rm martin/openvpn ovpn_getclient CLIENTNAME > CLIENTNAME.ovpn

* If you need to remove access for a client then you can revoke the client certificate by running

        docker run --volumes-from $OVPN_DATA --rm -it martin/openvpn ovpn_revokeclient CLIENTNAME


## How Does It Work?

Initialize the volume container using the `martin/openvpn` image with the
included scripts to automatically generate:

- Diffie-Hellman parameters
- a private key
- a self-certificate matching the private key for the OpenVPN server
- an EasyRSA CA key and certificate
- a TLS auth key from HMAC security

The OpenVPN server is started with the default run cmd of `ovpn_run`

The configuration is located in `/etc/openvpn`, and the Dockerfile
declares that directory as a volume. It means that you can start another
container with the `--volumes-from` flag, and access the configuration.
The volume also holds the PKI keys and certs so that it could be backed up.

To generate a client certificate, `martin/openvpn` uses EasyRSA via the
`easyrsa` command in the container's path.  The `EASYRSA_*` environmental
variables place the PKI CA under `/etc/openvpn/pki`.

Conveniently, `martin/openvpn` comes with a script called `ovpn_getclient`,
which dumps an inline OpenVPN client configuration file.  This single file can
then be given to a client for access to the VPN.


## OpenVPN Details

We use `tun` mode, because it works on the widest range of devices.
`tap` mode, for instance, does not work on Android, except if the device
is rooted.

The topology used is `net30`, because it works on the widest range of OS.
`p2p`, for instance, does not work on Windows.

The UDP server uses`192.168.255.0/24` for dynamic clients by default.

The client profile specifies `redirect-gateway def1`, meaning that after
establishing the VPN connection, all traffic will go through the VPN.
This might cause problems if you use local DNS recursors which are not
directly reachable, since you will try to reach them through the VPN
and they might not answer to you. If that happens, use public DNS
resolvers like those of Google (8.8.4.4 and 8.8.8.8) or OpenDNS
(208.67.222.222 and 208.67.220.220).


## Security Discussion

The Docker container runs its own EasyRSA PKI Certificate Authority.  This was
chosen as a good way to compromise on security and convenience.  The container
runs under the assumption that the OpenVPN container is running on a secure
host, that is to say that an adversary does not have access to the PKI files
under `/etc/openvpn/pki`.  This is a fairly reasonable compromise because if an
adversary had access to these files, the adversary could manipulate the
function of the OpenVPN server itself (sniff packets, create a new PKI CA, MITM
packets, etc).

* The certificate authority key is kept in the container by default for
  simplicity.  It's highly recommended to secure the CA key with some
  passphrase to protect against a filesystem compromise.  A more secure system
  would put the EasyRSA PKI CA on an offline system (can use the same Docker
  image to accomplish this).
* It would be impossible for an adversary to sign bad or forged certificates
  without first cracking the key's passphase should the adversary have root
  access to the filesystem.
* The EasyRSA `build-client-full` command will generate and leave keys on the
  server, again possible to compromise and steal the keys.  The keys generated
  need to signed by the CA which the user hopefully configured with a passphrase
  as described above.
* Assuming the rest of the Docker container's filesystem is secure, TLS + PKI
  security should prevent any malicious host from using the VPN.


## Differences from kylemanna/openvpn

* Revocation list enabled to allow certificates to be revoked.
* Tweaks for Windows clients
* Compression enabled and set to adaptive
* Floating client ip's enabled

## Differences from jpetazzo/dockvpn

* No longer uses serveconfig to distribute the configuration via https
* Proper PKI support integrated into image
* OpenVPN config files, PKI keys and certs are stored on a storage
  volume for re-use across containers
* Addition of tls-auth for HMAC security

## Tested On

* Clients
  * Android App OpenVPN Connect 1.1.14 (built 56)
  * Windows 8.1 64 bit using openvpn-2.3.6
