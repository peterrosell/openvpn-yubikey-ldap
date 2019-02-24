OVPN_DATA ?= $(PWD)/.tmp/openvpn_data
OPENVPN_IP ?= my-openvpn-server
DOCKER_REGISTRY ?= peterrosell/
DOCKER_IMAGE_VERSION=latest
DOCKER_IMAGE_NAME=$(DOCKER_REGISTRY)openvpn-yubikey-ldap
DOCKER_IMAGE=$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_VERSION)
DOCKER_VOLUME_MOUNT=-v $(OVPN_DATA):/etc/openvpn
DOCKER_RUN_FLAGS=$(DOCKER_VOLUME_MOUNT) -p 1194:1194/udp -v /dev/urandom:/dev/random -e LOGMON_ACTIVE_MODE=true --net=host --cap-add=NET_ADMIN

show-config:
	@echo "OVPN_DATA=$(OVPN_DATA)"
	@echo "OPENVPN_IP=$(OPENVPN_IP)"
	@echo "DOCKER_IMAGE=$(DOCKER_IMAGE)"

build:
	docker build -t $(DOCKER_IMAGE) .

build-compile-yubikey:
	cat Dockerfile.pam_yubikey Dockerfile | docker build -f - -t $(DOCKER_IMAGE) .

build-ubuntu16:
	docker build -f Dockerfile_16.04 -t $(DOCKER_IMAGE)-ubuntu16 .

build-alpine:
	docker build -f Dockerfile.alpine -t $(DOCKER_IMAGE)-alpine .

push:
	docker push $(DOCKER_IMAGE)

push-ubuntu16:
	docker push $(DOCKER_IMAGE)-ubuntu16

push-alpine:
	docker push $(DOCKER_IMAGE)-alpine

run:
	docker run -it --rm --name openvpn $(DOCKER_RUN_FLAGS) $(DOCKER_IMAGE)

run-debug:
	docker run -it --rm --name openvpn $(DOCKER_RUN_FLAGS) -e DEBUG=true $(DOCKER_IMAGE)

run-alpine-debug:
	docker run -it --rm --name openvpn-alpine $(DOCKER_RUN_FLAGS) -e DEBUG=true $(DOCKER_IMAGE):alpine

bash:
	docker run -it --rm --name openvpn-bash $(DOCKER_RUN_FLAGS) $(DOCKER_IMAGE) bash

show-versions:
	docker run -it --rm --name openvpn $(DOCKER_RUN_FLAGS) $(DOCKER_IMAGE) versions

logs-run:
	docker logs --tail=200 -f openvpn

logs-bash:
	docker logs --tail=200 -f openvpn-bash

stop:
	docker stop openvpn

pam-logs:
	docker exec -i -t openvpn bash -c 'if [ "$$(ps -ef | grep syslog | grep -v grep | wc -l)" == "0" ]; then syslogd ; fi ; tail -f -n 20 /var/log/debug.log'

watch-ps:
	docker exec -i -t openvpn watch -n .5 ps -ef

init: mkdirs
	docker run --rm $(DOCKER_VOLUME_MOUNT) $(DOCKER_IMAGE) initopenvpn -u udp://$(OPENVPN_IP) $(ARGS) && \
	docker run --rm -it $(DOCKER_VOLUME_MOUNT) $(DOCKER_IMAGE) initpki

gen-client:
	docker run --rm -it $(DOCKER_VOLUME_MOUNT) $(DOCKER_IMAGE) easyrsa build-client-full $(USER) nopass

get-certs:
	docker run --rm $(DOCKER_VOLUME_MOUNT) $(DOCKER_IMAGE) getclient $(USER) > $(USER).ovpn

get-client-config:
	docker run --rm $(DOCKER_VOLUME_MOUNT) $(DOCKER_IMAGE) getclient -X > $(OPENVPN_IP).ovpn

mkdirs:
	mkdir -p $(OVPN_DATA)
