FROM alpine:3.7 as pam_radius

RUN apk add --no-cache build-base git linux-pam-dev

RUN git clone https://github.com/FreeRADIUS/pam_radius && \
        cd /pam_radius && \
        ./configure && \
        make


FROM alpine:3.7

LABEL maintainer "Peter Rosell <peter.rosell@gmail.com>"

ADD bin /usr/local/bin

COPY --from=pam_radius /pam_radius/pam_radius_auth.so /lib/security/

RUN apk add --no-cache bash openvpn git openssl openvpn-auth-pam freeradius-pam && \
# Get easy-rsa
    git clone https://github.com/OpenVPN/easy-rsa.git /tmp/easy-rsa && \
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

ADD package /
