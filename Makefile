
OVPN_DATA=$${PWD}/.tmp/openvpn_data
DOCKER_IMAGE_NAME=peterrosell/alpine-openvpn
DOCKER_VOLUME_MOUNT=-v $(OVPN_DATA):/etc/openvpn
DOCKER_RUN_FLAGS=$(DOCKER_VOLUME_MOUNT) -p 1194:1194/udp --cap-add=NET_ADMIN

build:
	docker build -t $(DOCKER_IMAGE_NAME) .

push:
	docker push $(DOCKER_IMAGE_NAME)

run:
	docker run -it --rm --name alpine-openvpn $(DOCKER_RUN_FLAGS) $(DOCKER_IMAGE_NAME)

run-debug:
	docker run -it --rm --name alpine-openvpn $(DOCKER_RUN_FLAGS) -e DEBUG=true $(DOCKER_IMAGE_NAME)

bash:
	docker run -it --rm --name openvpn-bash $(DOCKER_RUN_FLAGS) $(DOCKER_IMAGE_NAME) bash

logs-run:
	docker logs --tail=200 -f alpine-openvpn

logs-bash:
	docker logs --tail=200 -f openvpn-bash

stop:
	docker stop alpine-openvpn

init: mkdirs
	docker run --rm $(DOCKER_VOLUME_MOUNT) $(DOCKER_IMAGE_NAME) initopenvpn -u udp://192.168.11.73
	docker run --rm -it $(DOCKER_VOLUME_MOUNT) $(DOCKER_IMAGE_NAME) initpki

gen-client:
	docker run --rm -it $(DOCKER_VOLUME_MOUNT) $(DOCKER_IMAGE_NAME) easyrsa build-client-full $(USER) nopass

get-certs:
	docker run --rm $(DOCKER_VOLUME_MOUNT) $(DOCKER_IMAGE_NAME) getclient $(USER) > $(USER).ovpn

mkdirs:
	mkdir -p $(OVPN_DATA)
