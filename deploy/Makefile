CONTAINER_CLI=podman
PUBLIC_HOSTNAME?=example.net
OPENVPN_ARGS?=-yN

CONFIG_DIR=$(PWD)/config
PKI_DIR=$(PWD)/easy-rsa

OPENVPN_CLI=$(CONTAINER_CLI) run -it --rm \
		-v $(CONFIG_DIR):/etc/openvpn \
		-v $(PKI_DIR):/etc/easy-rsa \
		quay.io/peter_rosell/openvpn-yubikey-ldap:latest

.PHONY: mkdir
mkdir:
	mkdir -p $(CONFIG_DIR) $(PKI_DIR)

.PHONY: initopenvpn
initopenvpn: mkdir
	$(OPENVPN_CLI) initopenvpn -u $(PUBLIC_HOSTNAME) $(OPENVPN_ARGS)

.PHONY: initpki
initpki: mkdir
	$(OPENVPN_CLI) initpki

.PHONY: create-client-cert
create-client-cert:
	@[ "$(CLIENT)" = "" ] && echo "Missing CLIENT value" && exit 4 || true
	$(OPENVPN_CLI) easyrsa build-client-full $(CLIENT)
	$(OPENVPN_CLI) getclient $(CLIENT) > client_$(CLIENT).ovpn
	echo "Client config written to client_$(CLIENT).ovpn"

.PHONY: get-client-config-no-cert
get-client-config-no-cert:
	$(OPENVPN_CLI) getclient -X > client-config-no-cert.ovpn

.PHONY: deploy
deploy:
	kustomize build | kubectl apply -f -
