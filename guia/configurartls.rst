Configuración de OpenLDAP sobre TLS
===================================

Creamos la llave primaria y un certificado autofirmad.::

	# cd /tmp
	# openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -keyout privateKey.key -out certificate.crt
	Generating a 2048 bit RSA private key
	...............................+++
	..................+++
	writing new private key to 'privateKey.key'
	-----
	You are about to be asked to enter information that will be incorporated
	into your certificate request.
	What you are about to enter is what is called a Distinguished Name or a DN.
	There are quite a few fields but you can leave some blank
	For some fields there will be a default value,
	If you enter '.', the field will be left blank.
	-----
	Country Name (2 letter code) [XX]:VE
	State or Province Name (full name) []:DC
	Locality Name (eg, city) [Default City]:Caracas
	Organization Name (eg, company) [Default Company Ltd]:Personal Company Ltd
	Organizational Unit Name (eg, section) []:Tecnologia de la Informacion
	Common Name (eg, your name or your server's hostname) []:
	Email Address []:

::

	# cd /etc/openldap/
	# mkdir certificado
	# cp /tmp/certificate.crt /tmp/privateKey.key /etc/openldap/certificado/
	# cp /etc/pki/tls/certs/ca-bundle.crt /etc/openldap/certificado/
	# chown -R ldap: /etc/openldap/certificado

::

	# vi mod_ssl.ldif
	# create new
	dn: cn=config
	changetype: modify
	add: olcTLSCACertificateFile
	# replace: olcTLSCACertificateFile
	olcTLSCACertificateFile: /etc/openldap/certificado/ca-bundle.crt
	-
	replace: olcTLSCertificateFile
	olcTLSCertificateFile: /etc/openldap/certificado/certificate.crt
	-
	replace: olcTLSCertificateKeyFile
	olcTLSCertificateKeyFile: /etc/openldap/certificado/privateKey.key

::

	# ldapmodify -Y EXTERNAL -H ldapi:/// -f mod_ssl.ldif 
	SASL/EXTERNAL authentication started
	SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
	SASL SSF: 0
	modifying entry "cn=config"

::

	# vi /etc/sysconfig/ldap
	# line 16: change
	SLAPD_LDAPS=yes

::

	#  vi /etc/openldap/ldap.conf
	#
	# LDAP Defaults
	#

	# See ldap.conf(5) for details
	# This file should be world readable but not world writable.

	#BASE   dc=example,dc=com
	#URI    ldap://ldap.example.com ldap://ldap-master.example.com:666

	#SIZELIMIT      12
	#TIMELIMIT      15
	#DEREF          never

	# Esta linea es la que indica cual es el default de los certificados
	# TLS_CACERTDIR /etc/openldap/certs
	TLS_CACERTDIR   /etc/openldap/cacerts

	# Esta linea en realidad es para el openldap-client sin ella nos daria error al momento de hacer un ldapsearch
	TLS_REQCERT allow

::

	# /etc/init.d/slapd restart

Realizamos pruebas, si no hubieramos colocado el "TLS_REQCERT allow" en /etc/openldap/ldap.conf los ldapsearch que vayan hacia el puerto 636 y que consulta los certificados, nos darian errores.::

	# ldapsearch -x  -b "dc=acme,dc=com"
	# ldapsearch -x  -b "dc=acme,dc=com" –ZZ
	 
	# ldapsearch -x -LLL -H ldaps://localhost:636 -D cn=Manager,dc=acme,dc=com -b dc=acme,dc=com -w Venezuela21
	# ldapsearch -x -LLL -H ldap://localhost:389 -D cn=Manager,dc=acme,dc=com -b dc=acme,dc=com -w Venezuela21
	 
	# ldapsearch -x -LLL -H ldaps://localhost:636 -D cn=Manager,dc=acme,dc=com -b dc=acme,dc=com -w Venezuela21 -d -1
	# ldapsearch -x -LLL -H ldap://localhost:389 -D cn=Manager,dc=acme,dc=com -b dc=acme,dc=com -w Venezuela21 -d -1
 



