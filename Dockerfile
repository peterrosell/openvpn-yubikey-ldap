# Original credit: https://github.com/jpetazzo/dockvpn, https://github.com/kylemanna/docker-openvpn

# Leaner build then Ubunutu
FROM debian:jessie

MAINTAINER Martin van Beurden <chadoe@gmail.com>

RUN apt-get update && apt-get install -y wget && \
    wget -O - https://swupdate.openvpn.net/repos/repo-public.gpg|apt-key add - && \
    echo "deb http://swupdate.openvpn.net/apt wheezy main" > /etc/apt/sources.list.d/swupdate.openvpn.net.list && \
    apt-get update && \
    apt-get install --no-install-recommends -y ca-certificates openvpn iptables git-core && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Update checkout to use tags when v3.0 is finally released
RUN git clone --branch v3.0.0-rc2 https://github.com/OpenVPN/easy-rsa.git /tmp/easy-rsa

# Merge utf-8 patch
RUN cd /tmp/easy-rsa && \
    git checkout -b roubert-utf-8 v3.0.0-rc2 && \
    git -c user.email='dummy@email.none' pull https://github.com/roubert/easy-rsa.git && \
    git checkout v3.0.0-rc2 && \
    git -c user.email='dummy@email.none' merge --no-ff roubert-utf-8

# Move easyrsa and cleanup
RUN rm -rf /tmp/easy-rsa/.git && cp -a /tmp/easy-rsa /usr/local/share/ && \
    rm -rf /tmp/easy-rsa/ && \
    ln -s /usr/local/share/easy-rsa/easyrsa3/easyrsa /usr/local/bin

# Needed by scripts
ENV OPENVPN /etc/openvpn
ENV EASYRSA /usr/local/share/easy-rsa/easyrsa3
ENV EASYRSA_PKI $OPENVPN/pki
ENV EASYRSA_VARS_FILE $OPENVPN/vars

VOLUME ["/etc/openvpn"]

# Internally uses port 1194, remap using docker
EXPOSE 1194/udp

WORKDIR /etc/openvpn
CMD ["start_openvpn"]

ADD ./bin /usr/local/bin
RUN chmod 774 /usr/local/bin/*
