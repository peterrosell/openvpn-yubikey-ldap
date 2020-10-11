FROM ubuntu:18.04

LABEL maintainer "Peter Rosell <peter.rosell@gmail.com>"

##### install yubico pam module + other tools
RUN . /etc/lsb-release && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        gnupg && \
    . /etc/lsb-release && echo "deb http://ppa.launchpad.net/yubico/stable/ubuntu $DISTRIB_CODENAME main" >> /etc/apt/sources.list && \
    echo "deb-src http://ppa.launchpad.net/yubico/stable/ubuntu $DISTRIB_CODENAME main " >> /etc/apt/sources.list && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 32CBA1A9 && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        curl \
        libcurl4 && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        inetutils-syslogd \
        libpam-ldap && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        libpam-radius-auth \
        libpam-yubico \
    && \
    apt-get clean autoclean && apt-get autoremove -y && rm -rf /var/lib/{apt,dpkg,cache,log}/


##### install openvpn and yubico pam module

# Patch base image to allow installation of openvpn.
# postinst scripts in deb package don't work inside ubuntu 18 base image
RUN echo "#!/bin/sh\nexit 0" > /usr/sbin/policy-rc.d &&\
    echo "#!/bin/sh\nexit 0" > /usr/sbin/invoke-rc.d &&\
    echo "#!/bin/sh\nexit 0" > /usr/sbin/update-rc.d &&\
    echo "#!/bin/sh\nexit 0" > /usr/sbin/systemctl &&\
    chmod +x /usr/sbin/systemctl &&\
    ln -s /systemd /sbin/init

# DEBIAN_SCRIPT_DEBUG=true
RUN . /etc/lsb-release && \
    curl -s https://swupdate.openvpn.net/repos/repo-public.gpg | apt-key add && \
    echo "deb http://build.openvpn.net/debian/openvpn/stable $DISTRIB_CODENAME main" > /etc/apt/sources.list.d/openvpn-aptrepo.list && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        iptables \
        git \
        openvpn \ 
    && \
    apt-get clean autoclean && apt-get autoremove -y && rm -rf /var/lib/{apt,dpkg,cache,log}/

##### install Easy-RSA
RUN cd /tmp && \
    curl -sLOf https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.8/EasyRSA-3.0.8.tgz &&\
    tar -xvzf EasyRSA-3.0.8.tgz &&\
    mkdir /usr/local/share/easyrsa &&\
    cp -r EasyRSA-3.0.8/* /usr/local/share/easyrsa &&\
    ln -s /usr/local/share/easyrsa/easyrsa /usr/local/bin

# Needed by scripts
ENV OPENVPN=/etc/openvpn \
    EASYRSA=/usr/local/share/easyrsa \
    EASYRSA_PKI=/etc/openvpn/pki \
    EASYRSA_VARS_FILE=/etc/openvpn/vars

VOLUME ["/etc/openvpn"]

EXPOSE 1194/udp

WORKDIR /etc/openvpn
CMD ["startopenvpn"]

ADD bin /usr/local/bin
ADD package /
