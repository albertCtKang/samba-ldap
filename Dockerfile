FROM ubuntu:14.04
MAINTAINER Albert Kang <albert.kang@qnap.com>

##################
##   BUILDING   ##
##################

# Prerequisites
RUN apt-get --quiet --yes update
ENV DEBIAN_FRONTEND noninteractive
RUN ln -s -f /bin/true /usr/bin/chfn

# Versions to use
ENV slapd_version XXX
ENV samba_version XXX

# Install prerequisites:
RUN apt-get --quiet --yes install slapd ldap-utils libnss-ldapd libpam-ldapd samba smbldap-tools samba-doc debconf-utils

ADD config_services.sh /config_services.sh

RUN update-rc.d slapd defaults
RUN update-rc.d samba defaults

#EXPOSE 548 636

CMD [ "/bin/bash", "/init_services.sh" ]
