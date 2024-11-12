Cambiar password de admin
===========================

Consultamos las BD del OpenLdap::

  slapcat -n 0 -a '(objectClass=olcDatabaseConfig)' | grep -E '^dn:|RootDN|RootPW|olcSuffix'
  
  dn: olcDatabase={-1}frontend,cn=config
  dn: olcDatabase={0}config,cn=config
  dn: olcDatabase={1}monitor,cn=config
  dn: olcDatabase={2}hdb,cn=config
  olcSuffix: dc=credicard,dc=com,dc=ve
  olcRootDN: cn=admin,dc=credicard,dc=com,dc=ve
  olcRootPW:: e1NTSEF9Q3d4RkZ1cnlsZFJWelFLaStaZSs0aW00TGZjWDlxRTM=

Crear los archivos ldif::

  # vi changepass.ldif
  dn: olcDatabase={2}hdb,cn=config
  changetype: modify
  replace: olcRootPW
  olcRootPW: {SSHA}twxXvCF7BcL6CSZERNmWqD/2E6loIN9D
  
  # vi changepass1.ldif
  dn: olcDatabase={0}config,cn=config
  changetype: modify
  replace: olcRootPW
  olcRootPW: {SSHA}twxXvCF7BcL6CSZERNmWqD/2E6loIN9D
  

Aplicamos los cambios::
  
  sudo ldapmodify -H ldapi:/// -Y EXTERNAL -D 'cn=config' -f ./changepass.ldif
  

Realizamos la consulta::

  ldapsearch -x -LLL -H ldaps://localhost:636 -D cn=admin,dc=credicard,dc=com,dc=ve -b dc=credicard,dc=com,dc=ve -w S3guridadccr2025.
