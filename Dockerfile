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
WORKDIR /usr/local/src

RUN mkdir -p /usr/loca/src/ldap_conf
ADD ldap_conf/cn=samba.ldif /usr/local/src/ldap_conf/
ADD ldap_conf/samba_indices.ldif /usr/local/src/ldap_conf/
ADD ldap_conf/schema_convert.conf /usr/local/src/ldap_conf/
ADD ldap_conf/slapd /usr/local/src/ldap_conf/
ADD ldap_conf/smb.conf /usr/local/src/ldap_conf/
ADD ldap_conf/smbldap.conf /usr/local/src/ldap_conf/
ADD ldap_conf/smbldap_bind.conf /usr/local/src/ldap_conf/
ADD ldap_conf/usr.sbin.slapd /usr/local/src/ldap_conf/
ADD init_services.sh /usr/local/src/

RUN update-rc.d slapd defaults
RUN update-rc.d samba defaults

CMD [ "/bin/bash", "/usr/local/src/init_services.sh" ]
