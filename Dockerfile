FROM alpine:edge

MAINTAINER Martin van Beurden <chadoe@gmail.com>

ADD ./bin /usr/local/bin

RUN apk add --update-cache bash openvpn=2.3.10-r0 git openssl && \
    rm -rf /var/cache/apk/* /tmp/* && \
# Get easy-rsa
    git clone https://github.com/OpenVPN/easy-rsa.git /tmp/easy-rsa && \
# Reset to v3.0.0 + 1 additional commit "Use tmp file for gen-crl output"
    cd /tmp/easy-rsa && \
    git reset --hard 21ac0a76bc090059543486660eaef6409667737b && \
    cd && \
# Cleanup
    apk del git && \
    rm -rf /tmp/easy-rsa/.git && cp -a /tmp/easy-rsa /usr/local/share/ && \
    rm -rf /tmp/easy-rsa/ && \
    ln -s /usr/local/share/easy-rsa/easyrsa3/easyrsa /usr/local/bin && \
    chmod 774 /usr/local/bin/*

# Needed by scripts
ENV OPENVPN=/etc/openvpn \
    EASYRSA=/usr/local/share/easy-rsa/easyrsa3 \
    EASYRSA_PKI=/etc/openvpn/pki \
    EASYRSA_VARS_FILE=/etc/openvpn/vars

VOLUME ["/etc/openvpn"]

EXPOSE 1194/udp

WORKDIR /etc/openvpn
CMD ["startopenvpn"]

