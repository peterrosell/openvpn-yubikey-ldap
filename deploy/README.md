# Deploy to Kubernetes

These instructions are for creating a example setup of OpenVPN on Kubernetes. The default config uses
client cert and OTP via Yubikey as two factor authentication. The Yubikey IDs are stored in a file
that is deployed together with the app. This setup works for a small number of users, but for a larger
organisation you should concider using an LDAP server as backend. Then you can use a combination of
password and OTP via Yubikey and get rid of the distribution of client certificates.

## Create OpenVPN config

First we need to create configurations for OpenVPN. That's done by using the `initopenvpn` command with
the flags that are suitable for the setup we want.
By running the make command we get the config files generated to the correct folder.

```shell
make initopenvpn
```

## Create PKI

Second step is to create the private keys, certs, dh params etc. You do that with `initpki`.
You will get promted a number of times to fill in passwords for the CA, TLS cert etc.

```shell
make initpki
```

## Add the user alice

When we created the OpenVPN config we got an example file, `yubikey_mappings.example`. It shows an example
of how the Yubikey IDs should be stored. Rename the file to `yubikey_mappings` and replace the Yubikey ID
`cccccccccc` with the ID from your yubikey. The first 12 characters from the OTP code that you get from
your Yubikey when you touch it is the ID.

### Generate a config with certifiate

To create a config file for the user you must first run the `easyrsa build-client-full` command and then
fetch the config file. Here we use a make target again. It will store a config file `client-config_alice.ovpn`
that shall be loaded into the user's OpenVPN client.

```shell
make create-client-cert CLIENT=alice
```

## Deploy OpenVPN server to Kubernetes

After the OpenVPN config and PKI have been created you can deploy the manifests to Kubernetes. The config files
and secrets are referred to in the `kustomization.yaml` file.
A load balancer will be created to handle the incoming traffic. If you want to fixed IP of the service remember
to specify that in the `service.yaml` file. This is a good idea if you have a port-forwarding in your firewall/router.

Note! This config is an example setup. In a production setup you should keep the secrets stored in a secure place
such as a Secret Management System, like [Google Secret Manager](https://cloud.google.com/secret-manager) or
[Vault](https://www.vaultproject.io/). You can for example use [External Secret](https://external-secrets.io/)
to fetch the secret into the cluster.
