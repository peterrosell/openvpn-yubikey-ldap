FROM alpine:3.1

MAINTAINER Martin van Beurden <chadoe@gmail.com>

ADD ./bin /usr/local/bin

RUN apk add --update-cache bash openvpn git && \
    rm -rf /var/cache/apk/* /tmp/* && \
# Get easy-rsa
    git clone --branch v3.0.0-rc2 https://github.com/OpenVPN/easy-rsa.git /tmp/easy-rsa && \
# Merge utf-8 patch
    cd /tmp/easy-rsa && \
    git checkout -b roubert-utf-8 v3.0.0-rc2 && \
    git -c user.email='dummy@email.none' pull https://github.com/roubert/easy-rsa.git && \
    git checkout v3.0.0-rc2 && \
    git -c user.email='dummy@email.none' merge --no-ff roubert-utf-8 && \
# Cleanup
    apk del git && \
    rm -rf /tmp/easy-rsa/.git && cp -a /tmp/easy-rsa /usr/local/share/ && \
    rm -rf /tmp/easy-rsa/ && \
    ln -s /usr/local/share/easy-rsa/easyrsa3/easyrsa /usr/local/bin && \
    chmod 774 /usr/local/bin/*

# Needed by scripts
ENV OPENVPN=/etc/openvpn \
    EASYRSA=/usr/local/share/easy-rsa/easyrsa3 \
    EASYRSA_PKI=$OPENVPN/pki \
    EASYRSA_VARS_FILE=$OPENVPN/vars

VOLUME ["/etc/openvpn"]

EXPOSE 1194/udp

WORKDIR /etc/openvpn
CMD ["start_openvpn"]

