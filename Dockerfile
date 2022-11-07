FROM ubuntu:20.04

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
    curl -sLOf https://github.com/OpenVPN/easy-rsa/releases/download/v3.1.1/EasyRSA-3.1.1.tgz &&\
    tar -xvzf EasyRSA-3.1.1.tgz &&\
    mkdir /usr/local/share/easy-rsa &&\
    cp -r EasyRSA-3.1.1/* /usr/local/share/easy-rsa &&\
    ln -s /usr/local/share/easy-rsa/easyrsa /usr/local/bin

# Needed by scripts
ENV OPENVPN=/etc/openvpn \
    EASYRSA=/usr/local/share/easy-rsa \
    EASYRSA_PKI=/etc/easy-rsa/pki \
    EASYRSA_VARS_FILE=/etc/openvpn/vars

VOLUME ["/etc/openvpn"]

EXPOSE 1194/udp

WORKDIR /etc/openvpn
CMD ["startopenvpn"]

ADD bin /usr/local/bin
ADD package /
