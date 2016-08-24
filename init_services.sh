#!/bin/bash

HOME=$PWD

# 
LDAP_IP=127.0.0.1
CN=admin
IDEALX=example
ORG=com
LDAP_ADMIN_PASSWORD=coreos1234
LDAP_DOMAIN=$IDEALX.$ORG
LDAP_ORGANISATION=$IDEALX
LDAP_SRV_PW=$LDAP_ADMIN_PASSWORD
LDAP_BACKEND=HDB

SID=

MASTER_IP=$LDAP_IP
MASTER_CN=$CN
MASTER_IDEALX=$IDEALX
MASTER_ORG=$ORG
MASTER_PW=$LDAP_ADMIN_PASSWORD

SLAVE_IP=$LDAP_IP
SLAVE_CN=$CN
SLAVE_IDEALX=$IDEALX
SLAVE_ORG=$ORG
SLAVE_PW=$LDAP_ADMIN_PASSWORD

#smb.conf
SMB_LDAP_SRV_IP=$MASTER_IP
SMB_SUFFIX_IDEALX=$IDEALX
SMB_SUFFIX_ORG=$ORG
SMB_ADMIN_CN=$CN
SMB_ADMIN_IDEALX=$IDEALX
SMB_ADMIN_ORG=$ORG
SMB_SHARE_PATH=/srv/samba/share
#samba default account/pwd
SMB_DEFAULT_USER=core
SMB_DEFAULT_PW=coreos1234

apt-get install slapd ldap-utils libnss-ldapd libpam-ldapd samba smbldap-tools samba-doc -y

set -e

if [ -z $LDAP_IP ]; then
   echo "no LDAP_IP specified! (default: LDAP_IP=$LDAP_IP)"
fi

if [ -z $LDAP_ADMIN_PASSWORD ]; then
   echo "no LDAP_ADMIN_PASSWORD specified! (default: LDAP_ADMIN_PASSWORD=$LDAP_ADMIN_PASSWORD)"
fi

if [ -z $CN ]; then
   echo "no CN specified! (default: CN=$CN)"
fi

if [ -z $IDEALX ]; then
   echo "no IDEALX specified! (default: IDEALX=$IDEALX)"
fi

if [ -z $ORG ]; then
   echo "no ORG specified! (default: ORG=$ORG)"
fi

debconf-set-selections <<< 'slapd slapd/internal/generated_adminpw password '$LDAP_ADMIN_PASSWORD''
debconf-set-selections <<< 'slapd slapd/internal/adminpw password '$LDAP_ADMIN_PASSWORD''
debconf-set-selections <<< 'slapd slapd/password2 password '$LDAP_ADMIN_PASSWORD''
debconf-set-selections <<< 'slapd slapd/password1 password '$LDAP_ADMIN_PASSWORD''
debconf-set-selections <<< 'slapd slapd/dump_database_destdir string /var/backups/slapd-VERSION'
debconf-set-selections <<< 'slapd slapd/domain string '$LDAP_DOMAIN''
debconf-set-selections <<< 'slapd shared/organization string '$LDAP_ORGANISATION''
debconf-set-selections <<< 'slapd slapd/backend string '$LDAP_BACKEND''
debconf-set-selections <<< 'slapd slapd/purge_database boolean true'
debconf-set-selections <<< 'slapd slapd/move_old_database boolean true'
debconf-set-selections <<< 'slapd slapd/allow_ldap_v2 boolean false'
debconf-set-selections <<< 'slapd slapd/no_configuration boolean false'
debconf-set-selections <<< 'slapd slapd/dump_database select when needed'

dpkg-reconfigure -f noninteractive slapd

cp -f $HOME/ldap_conf/usr.sbin.slapd /etc/apparmor.d/usr.sbin.slapd
cp -f $HOME/ldap_conf/slapd  /etc/default/slapd

#restart ldap service
/etc/init.d/slapd restart

# Copy schema into LDAP schema dir
cd /etc/ldap/schema
cp -f /usr/share/doc/samba-doc/examples/LDAP/samba.schema.gz /etc/ldap/schema
gzip -f -d /etc/ldap/schema/samba.schema.gz
sudo cp $HOME/ldap_conf/schema_convert.conf  /etc/ldap/

# Create directory to work in :
cd /etc/ldap
sudo mkdir -p ldif_output

# Find Index of samba : You need to make sure it is the same as what we will be using later.
slapcat -f schema_convert.conf -F ldif_output -n 0 | grep samba,cn=schema

# Convert the schema :
slapcat -f schema_convert.conf -F ldif_output -n0 -H ldap:///cn={14}samba,cn=schema,cn=config  -l     cn=samba.ldif

# Edit the schema :
cp -f $HOME/ldap_conf/cn=samba.ldif /etc/ldap/cn=samba.ldif

# Add the new schema:
ldapadd -Q -Y EXTERNAL -H ldapi:/// -f cn\=samba.ldif

# Test the new schema
ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b cn=schema,cn=config 'cn=*samba*'

#Create indices :      
cp -f $HOME/ldap_conf/samba_indices.ldif  /etc/ldap/samba_indices.ldif

# Load the new indices:                      
ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f samba_indices.ldif

# Create config files for smbldap-populate
cd /usr/share/doc/smbldap-tools/examples/
cp -f smbldap_bind.conf /etc/smbldap-tools/
cp -f smbldap.conf.gz /etc/smbldap-tools/
gzip -f -d /etc/smbldap-tools/smbldap.conf.gz

SID=$(net getlocalsid | grep -Eo S-1-5-21-[0-9]*-[0-9]*-[0-9]*)
cp -f $HOME/ldap_conf/smbldap.conf /etc/smbldap-tools/smbldap.conf
cp -f $HOME/ldap_conf/smbldap_bind.conf /etc/smbldap-tools/smbldap_bind.conf
sed -Ei s/__SID__/$SID/g /etc/smbldap-tools/smbldap.conf
sed -Ei s/__LDAP_TLS__/0/g /etc/smbldap-tools/smbldap.conf
sed -Ei s/__SLAVE_LDAP_IP__/$SLAVE_IP/g /etc/smbldap-tools/smbldap.conf
sed -Ei s/__MASTER_LDAP_IP__/$MASTER_IP/g /etc/smbldap-tools/smbldap.conf
sed -Ei s/__IDEALX__/$IDEALX/g /etc/smbldap-tools/smbldap.conf
sed -Ei s/__ORG__/$ORG/g /etc/smbldap-tools/smbldap.conf
sed -Ei s/__MAIL_IDEALX__/$IDEALX/g /etc/smbldap-tools/smbldap.conf
sed -Ei s/__MAIL_ORG__/$ORG/g /etc/smbldap-tools/smbldap.conf
sed -Ei s/__SLAVE_CN__/$SLAVE_CN/g /etc/smbldap-tools/smbldap_bind.conf
sed -Ei s/__SLAVE_IDEALX__/$SLAVE_IDEALX/g /etc/smbldap-tools/smbldap_bind.conf
sed -Ei s/__SLAVE_ORG__/$SLAVE_ORG/g /etc/smbldap-tools/smbldap_bind.conf
sed -Ei s/__SLAVE_PW__/$SLAVE_PW/g /etc/smbldap-tools/smbldap_bind.conf
sed -Ei s/__MASTER_CN__/$MASTER_CN/g /etc/smbldap-tools/smbldap_bind.conf
sed -Ei s/__MASTER_IDEALX__/$MASTER_IDEALX/g /etc/smbldap-tools/smbldap_bind.conf
sed -Ei s/__MASTER_ORG__/$MASTER_ORG/g /etc/smbldap-tools/smbldap_bind.conf
sed -Ei s/__MASTER_PW__/$MASTER_PW/g /etc/smbldap-tools/smbldap_bind.conf

#Set proper file permissions
chmod 0644 /etc/smbldap-tools/smbldap.conf
chmod 0600 /etc/smbldap-tools/smbldap_bind.conf

#populate server
(echo $LDAP_SRV_PW; echo $LDAP_SRV_PW) | smbldap-populate

#establish samba share space
mkdir -p $SMB_SHARE_PATH
chmod 755 $SMB_SHARE_PATH 
chown nobody:nogroup $SMB_SHARE_PATH

cp -f $HOME/ldap_conf/smb.conf  /etc/samba/smb.conf
sed -Ei s/__LDAP_SERVER_IP__/$SMB_LDAP_SRV_IP/g /etc/samba/smb.conf    
sed -Ei s/__SMB_SUFFIX_IDEALX__/$SMB_SUFFIX_IDEALX/g /etc/samba/smb.conf    
sed -Ei s/__SMB_SUFFIX_ORG__/$SMB_SUFFIX_ORG/g /etc/samba/smb.conf    
sed -Ei s/__ADMIN_CN__/$SMB_ADMIN_CN/g /etc/samba/smb.conf    
sed -Ei s/__ADMIN_IDEALX__/$SMB_ADMIN_IDEALX/g /etc/samba/smb.conf    
sed -Ei s/__ADMIN_ORG__/$SMB_ADMIN_ORG/g /etc/samba/smb.conf    

/etc/init.d/slapd restart
/etc/init.d/samba restart

smbpasswd -w $LDAP_SRV_PW
#create a new Samba user
(echo $SMB_DEFAULT_PW; echo $SMB_DEFAULT_PW) | smbldap-useradd -a -P $SMB_DEFAULT_USER
useradd $SMB_DEFAULT_USER
(echo $SMB_DEFAULT_PW; echo $SMB_DEFAULT_PW) | smbpasswd -a $SMB_DEFAULT_USER

ldapsearch -x -LLL -H ldap:/// -b dc=$IDEALX,dc=$ORG dn | grep $SMB_DEFAULT_USER

# wait indefinetely
while true
do
   tail -f /dev/null & wait ${!}
done
