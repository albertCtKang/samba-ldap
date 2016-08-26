# Integration of SAMBA Authentication with LDAP
A docker container to running the specific version of SAMBA&LDAP in order to run Samba file server and user authentication with LDAP. For details installation guide please refer to below:

Integration of Samba with LDAP
https://vsdx.hackpad.com/Integration-of-Samba-with-LDAP-4AUylZWqGBd 

## Installation

To download the docker container and execute it, simply run:

`docker run -e LDAP_IP=127.0.0.1 \
            -e LDAP_ADMIN_PASSWORD=coreos1234 \
            -e CN=admin \
            -e IDEALX=example \
            -e ORG=com \
            -e SMB_USER=core \
            -e SMB_PW=coreos1234  \
            -it -d --net=host vos/samba-ldap:0.2`

As you can see, after creating a container by running the docker-cmd, you have created a SAMBA user named 'core' with password 'coreos1234'. Besides, for each samba server, you can specify the LDAP server with specifying the LDAP server IP of 'LDAP_IP'.
