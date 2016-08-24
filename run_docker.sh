docker run -e LDAP_IP=127.0.0.1 \
           -e LDAP_ADMIN_PASSWORD=coreos43210 \
           -e CN=super \
           -e IDEALX=my_ex \
           -e ORG=org \
           -e SMB_USER=demo1 \
           -e SMB_PW=coreos4321  -it -d  smb-ldap:2.36
