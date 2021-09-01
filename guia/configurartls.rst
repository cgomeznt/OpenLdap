Configuración de OpenLDAP sobre TLS
===================================


Se recomienda que pueda ver este link primero y tenga como crear una Entidad Certificadora:

https://github.com/cgomeznt/Certificados/blob/master/guia/cacentos7.rst


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


Consultar a OpenLDAP donde tiene actualmente su configuracion de TLS::

	# slapcat -b "cn=config" | egrep "olcTLS"
	olcTLSCACertificatePath: /etc/openldap/certs
	olcTLSCertificateFile: "OpenLDAP Server"
	olcTLSCertificateKeyFile: /etc/openldap/certs/password

::

	# cd /etc/openldap/
	# mkdir certificado
	# cp /tmp/certificate.crt /tmp/privateKey.key /etc/openldap/certificado/
	# cp /etc/pki/tls/certs/ca-bundle.crt /etc/openldap/certificado/
	# chown -R ldap: /etc/openldap/certificado

::

	# vi mod_ssl_cert_privatekey.ldif
	dn: cn=config
	changetype: modify
	#add: olcTLSCACertificateFile
	replace: olcTLSCertificateKeyFile
	olcTLSCertificateKeyFile: /etc/openldap/certificado/privateKey.key
	-
	replace: olcTLSCertificateFile
	olcTLSCertificateFile: /etc/openldap/certificado/certificate.crt

::

	# ldapmodify -Y EXTERNAL -H ldapi:/// -f mod_ssl_cert_privatekey.ldif 
	SASL/EXTERNAL authentication started
	SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
	SASL SSF: 0
	modifying entry "cn=config"

::

	# vi mod_ssl_ca_cert.ldif
	dn: cn=config
	changetype: modify
	add: olcTLSCACertificateFile
	olcTLSCACertificateFile: /etc/openldap/certificado/ca-bundle.crt

::

	# ldapmodify -Y EXTERNAL -H ldapi:/// -f mod_ssl_ca.ldif
	SASL/EXTERNAL authentication started
	SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
	SASL SSF: 0
	modifying entry "cn=config"

::

	# vi path_ssl.ldif
	dn: cn=config
	changetype: modify
	replace: olcTLSCACertificatePath
	olcTLSCACertificatePath: /etc/openldap/certificado

::

	# ldapmodify -Y EXTERNAL -H ldapi:/// -f path_ssl.ldif 
	SASL/EXTERNAL authentication started
	SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
	SASL SSF: 0
	modifying entry "cn=config"


Consultar a OpenLDAP para ver los cambios TLS::

	# slapcat -b "cn=config" | egrep "olcTLS"
	olcTLSCertificateKeyFile: /etc/openldap/certificado/srvutils.key
	olcTLSCertificateFile: /etc/openldap/certificado/srvutils.crt
	olcTLSCACertificateFile: /etc/openldap/certificado/CA_empresa.crt
	olcTLSCACertificatePath: /etc/openldap/certificado


Enable TLS in LDAP configuration file
Now we edit the /etc/sysconfig/slapd file to add ldaps:/// to the SLAPD_URLS parameter.::

	SLAPD_URLS="ldapi:/// ldap:/// ldaps:///"

Change the below in /etc/openldap/ldap.conf::

	TLS_CACERTDIR /etc/openldap/certs
	TLS_CACERT /etc/openldap/cacerts/ca.cert.pem
	TLS_REQCERT allow

Esta Opción no la ejecute, pero la dejo para recordarme de ella y evaluarla::

	# vi /etc/sysconfig/ldap
	# line 16: change
	SLAPD_LDAPS=yes

Restart slapd service Then we restart the service to activate our changes::

	# systemctl restart slapd



Realizamos pruebas, si no hubieramos colocado el "TLS_REQCERT allow" en /etc/openldap/ldap.conf los ldapsearch que vayan hacia el puerto 636 y que consulta los certificados, nos darian errores.::

	# netstat -natp | grep slapd
	tcp        0      0 0.0.0.0:389             0.0.0.0:*               LISTEN      57392/slapd         
	tcp        0      0 0.0.0.0:636             0.0.0.0:*               LISTEN      57392/slapd         
	tcp6       0      0 :::389                  :::*                    LISTEN      57392/slapd         
	tcp6       0      0 :::636                  :::*                    LISTEN      57392/slapd   

::

	# ldapsearch -x  -b "dc=dominio,dc=local"

	# extended LDIF
	#
	# LDAPv3
	# base <dc=dominio,dc=local> with scope subtree
	# filter: (objectclass=*)
	# requesting: ALL
	#

	# dominio.local
	dn: dc=dominio,dc=local
	dc: dominio
	objectClass: top
	objectClass: domain

	# ldapadm, dominio.local
	dn: cn=ldapadm,dc=dominio,dc=local
	objectClass: organizationalRole
	cn: ldapadm
	description: LDAP Manager

	# People, dominio.local
	dn: ou=People,dc=dominio,dc=local
	objectClass: organizationalUnit
	ou: People

	# Group, dominio.local
	dn: ou=Group,dc=dominio,dc=local
	objectClass: organizationalUnit
	ou: Group

	# cgomeznt, People, dominio.local
	dn: uid=cgomeznt,ou=People,dc=dominio,dc=local
	objectClass: top
	objectClass: account
	objectClass: posixAccount
	objectClass: shadowAccount
	cn: cgomeznt
	uid: cgomeznt
	uidNumber: 9999
	gidNumber: 100
	homeDirectory: /home/cgomeznt
	loginShell: /bin/bash
	gecos: cgomeznt [Admin (at) dominio]
	shadowLastChange: 17058
	shadowMin: 0
	shadowMax: 99999
	shadowWarning: 7
	userPassword:: e1NTSEF9bE9TbXBLSTJjOUw2bmpxQkNkRTE5U0hRZUF4SElTZWk=

	# search result
	search: 2
	result: 0 Success

	# numResponses: 6
	# numEntries: 5

::

	# ldapsearch -x  -b "dc=dominio,dc=local" –ZZ

	# extended LDIF
	#
	# LDAPv3
	# base <dc=dominio,dc=local> with scope subtree
	# filter: (objectclass=*)
	# requesting: –ZZ 
	#

	# dominio.local
	dn: dc=dominio,dc=local

	# ldapadm, dominio.local
	dn: cn=ldapadm,dc=dominio,dc=local

	# People, dominio.local
	dn: ou=People,dc=dominio,dc=local

	# Group, dominio.local
	dn: ou=Group,dc=dominio,dc=local

	# cgomeznt, People, dominio.local
	dn: uid=cgomeznt,ou=People,dc=dominio,dc=local

	# search result
	search: 2
	result: 0 Success

	# numResponses: 6
	# numEntries: 5

::
	 
	# ldapsearch -x -LLL -H ldaps://localhost:636 -D cn=ldapadm,dc=dominio,dc=local -b dc=dominio,dc=local -w America21
	dn: dc=dominio,dc=local
	dc: dominio
	objectClass: top
	objectClass: domain

	dn: cn=ldapadm,dc=dominio,dc=local
	objectClass: organizationalRole
	cn: ldapadm
	description: LDAP Manager

	dn: ou=People,dc=dominio,dc=local
	objectClass: organizationalUnit
	ou: People

	dn: ou=Group,dc=dominio,dc=local
	objectClass: organizationalUnit
	ou: Group

	dn: uid=cgomeznt,ou=People,dc=dominio,dc=local
	objectClass: top
	objectClass: account
	objectClass: posixAccount
	objectClass: shadowAccount
	cn: cgomeznt
	uid: cgomeznt
	uidNumber: 9999
	gidNumber: 100
	homeDirectory: /home/cgomeznt
	loginShell: /bin/bash
	gecos: cgomeznt [Admin (at) dominio]
	shadowLastChange: 17058
	shadowMin: 0
	shadowMax: 99999
	shadowWarning: 7
	userPassword:: e1NTSEF9bE9TbXBLSTJjOUw2bmpxQkNkRTE5U0hRZUF4SElTZWk=

	[root@appserver ~]# 

::

	# ldapsearch -x -LLL -H ldap://localhost:389 -D cn=ldapadm,dc=dominio,dc=local -b dc=dominio,dc=local -w America21
	dn: dc=dominio,dc=local
	dc: dominio
	objectClass: top
	objectClass: domain

	dn: cn=ldapadm,dc=dominio,dc=local
	objectClass: organizationalRole
	cn: ldapadm
	description: LDAP Manager

	dn: ou=People,dc=dominio,dc=local
	objectClass: organizationalUnit
	ou: People

	dn: ou=Group,dc=dominio,dc=local
	objectClass: organizationalUnit
	ou: Group

	dn: uid=cgomeznt,ou=People,dc=dominio,dc=local
	objectClass: top
	objectClass: account
	objectClass: posixAccount
	objectClass: shadowAccount
	cn: cgomeznt
	uid: cgomeznt
	uidNumber: 9999
	gidNumber: 100
	homeDirectory: /home/cgomeznt
	loginShell: /bin/bash
	gecos: cgomeznt [Admin (at) dominio]
	shadowLastChange: 17058
	shadowMin: 0
	shadowMax: 99999
	shadowWarning: 7
	userPassword:: e1NTSEF9bE9TbXBLSTJjOUw2bmpxQkNkRTE5U0hRZUF4SElTZWk=

::
	 
	# ldapsearch -x -LLL -H ldaps://localhost:636 -D cn=ldapadm,dc=dominio,dc=local -b dc=dominio,dc=local -w Venezuela21 -d -1
	# ldapsearch -x -LLL -H ldap://localhost:389 -D cn=ldapadm,dc=dominio,dc=local -b dc=dominio,dc=local -w Venezuela21 -d -1
 

::

	# journalctl -f
	-- Logs begin at mar 2021-08-31 16:07:22 EDT. --
	ago 31 18:16:16 appserver slapd[57392]: conn=1007 op=0 EXT oid=1.3.6.1.4.1.1466.20037
	ago 31 18:16:16 appserver slapd[57392]: conn=1007 op=0 STARTTLS
	ago 31 18:16:16 appserver slapd[57392]: conn=1007 op=0 RESULT oid= err=0 text=
	ago 31 18:16:16 appserver slapd[57392]: conn=1007 fd=13 TLS established tls_ssf=256 ssf=256   <<======Mira esto
	ago 31 18:16:16 appserver slapd[57392]: conn=1007 op=1 BIND dn="" method=128
	ago 31 18:16:16 appserver slapd[57392]: conn=1007 op=1 RESULT tag=97 err=0 text=
	ago 31 18:16:16 appserver slapd[57392]: conn=1007 op=2 SRCH base="" scope=2 deref=0 filter="(objectClass=*)"
	ago 31 18:16:16 appserver slapd[57392]: conn=1007 op=2 SEARCH RESULT tag=101 err=32 nentries=0 text=
	ago 31 18:16:16 appserver slapd[57392]: conn=1007 op=3 UNBIND
	ago 31 18:16:16 appserver slapd[57392]: conn=1007 fd=13 closed

::

	# openssl s_client -connect 192.168.1.20:636 -CAfile /etc/openldap/certificado/CA_empresa.crt 
	CONNECTED(00000003)
	depth=1 C = VE, ST = DC, L = CCS, O = Default Company Ltd, OU = Sop App, CN = PERSONAL, emailAddress = root@personal.local
	verify return:1
	depth=0 C = VE, ST = DC, L = Caracas, O = PERSONAL, OU = TI, CN = srvutils
	verify return:1
	---
	Certificate chain
	 0 s:/C=VE/ST=DC/L=Caracas/O=PERSONAL/OU=TI/CN=srvutils
	   i:/C=VE/ST=DC/L=CCS/O=Default Company Ltd/OU=Sop App/CN=PERSONAL/emailAddress=root@personal.local
	 1 s:/C=VE/ST=DC/L=CCS/O=Default Company Ltd/OU=Sop App/CN=PERSONAL/emailAddress=root@personal.local
	   i:/C=VE/ST=DC/L=CCS/O=Default Company Ltd/OU=Sop App/CN=PERSONAL/emailAddress=root@personal.local
	---
	Server certificate
	-----BEGIN CERTIFICATE-----
	MIIDvjCCAqagAwIBAgIJALU559uWUDLoMA0GCSqGSIb3DQEBCwUAMIGPMQswCQYD
	VQQGEwJWRTELMAkGA1UECAwCREMxDDAKBgNVBAcMA0NDUzEcMBoGA1UECgwTRGVm
	YXVsdCBDb21wYW55IEx0ZDEQMA4GA1UECwwHU29wIEFwcDERMA8GA1UEAwwIUEVS
	U09OQUwxIjAgBgkqhkiG9w0BCQEWE3Jvb3RAcGVyc29uYWwubG9jYWwwHhcNMjEw
	ODI5MTkxNDU2WhcNMjIwMzAyMTkxNDU2WjBfMQswCQYDVQQGEwJWRTELMAkGA1UE
	CAwCREMxEDAOBgNVBAcMB0NhcmFjYXMxETAPBgNVBAoMCFBFUlNPTkFMMQswCQYD
	VQQLDAJUSTERMA8GA1UEAwwIc3J2dXRpbHMwggEiMA0GCSqGSIb3DQEBAQUAA4IB
	DwAwggEKAoIBAQCjBDuC6DM2K346thvTeEU7qFph8yIgRbZRi3+ZssB61D8QxJxO
	DCIBpWsI0yMYum2xTV0YJelGUUNNjmuLu6ShQJwd8hlaVZ33yTrAAjWuS0Z4vJx2
	yMB9FT+QCnb9AehvnQQU3Zev+bNvBU4hrl6livnXUolqKLItWlTL9kYEVmaI1B8o
	20KeF5veH9pTUAPr3C5kC3LA0GdTjoEdZEaELA0xZDl89fHSBCBsjLevQi7QMxQA
	7lI/tRf+SylTpRlvrapYwYBNundLhP2gJONanjaLVlc3nuS6j21MN0tFWBL01HWG
	wJ0E8uZ8VMl4cQ3EGoGigkeZYS8H8zw8Z1yZAgMBAAGjTDBKMAkGA1UdEwQCMAAw
	CwYDVR0PBAQDAgXgMDAGA1UdEQQpMCeCDnNydnV0aWxzLmxvY2Fsgg9tb25pdG9y
	ZW8ubG9jYWyHBMCoABQwDQYJKoZIhvcNAQELBQADggEBAICWgrGftReBcCUUIG39
	mhKLwujRaD1gufJ5H5dx5YsxRqc+2VD6B6m5Xthq0qeQxuCdXJ0R3rRabV1YGNkt
	bSf0l/7UOWPBBPGiw1ZNfX2DbScMCCz8HgoZY42xI5RGln/ui2mPo4iMC6fGtP3X
	lW1CgloBs8kRUzNlrOXa8oRoBv8f5ZB/1kbYD23QPKpTb8S1pBFDxOSae8kC71dt
	yBBWXEWEwafroo5aHeLypLY/k0Vp7KJkhG3BrG+WdFPX7udCgOAb/nTT9GZkEFvh
	bXR+rQZGShaE1V8B1mssGtyDl6+4dJZrf30C0icYExFtyWZWsE1fwV873vomfhe3
	S6I=
	-----END CERTIFICATE-----
	subject=/C=VE/ST=DC/L=Caracas/O=PERSONAL/OU=TI/CN=srvutils
	issuer=/C=VE/ST=DC/L=CCS/O=Default Company Ltd/OU=Sop App/CN=PERSONAL/emailAddress=root@personal.local
	---
	No client certificate CA names sent
	---
	SSL handshake has read 2293 bytes and written 607 bytes
	---
	New, TLSv1/SSLv3, Cipher is AES256-GCM-SHA384
	Server public key is 2048 bit
	Secure Renegotiation IS supported
	Compression: NONE
	Expansion: NONE
	No ALPN negotiated
	SSL-Session:
	    Protocol  : TLSv1.2
	    Cipher    : AES256-GCM-SHA384
	    Session-ID: 2CD110C9427BD45B484D1BE5840F5D7C112D34719C95A3AF46E7BA06683BAD60
	    Session-ID-ctx: 
	    Master-Key: E466E34CECE1C22B1D42D6FA4A704E1DC2A0FC03CB04A58EE5DFA4C78C9E0A283E7AC3FEB7D62F0E248638418E3420C4
	    Key-Arg   : None
	    Krb5 Principal: None
	    PSK identity: None
	    PSK identity hint: None
	    TLS session ticket lifetime hint: 300 (seconds)
	    TLS session ticket:
	    0000 - f3 e9 43 40 06 70 f8 06-31 10 02 ed fd b6 da 2a   ..C@.p..1......*
	    0010 - 00 18 2b d2 0d cb 7c 1e-6c d9 a6 8a d9 80 a0 a5   ..+...|.l.......
	    0020 - 05 59 5a c9 48 e0 17 1c-dd bd 38 1b 10 b0 b9 88   .YZ.H.....8.....
	    0030 - 28 d7 de 6f 01 70 6b b0-d2 c9 f9 d9 3c d7 7f 0f   (..o.pk.....<...
	    0040 - b8 59 21 a2 33 4e 21 b3-eb 9a 35 e4 62 28 e3 61   .Y!.3N!...5.b(.a
	    0050 - a4 fc 2b 06 ee fa 78 94-dc d1 cc 8f bf 56 be 12   ..+...x......V..
	    0060 - ce 43 5a d0 42 64 3a 01-21 95 3b 7c c4 6a 97 55   .CZ.Bd:.!.;|.j.U
	    0070 - 4e f6 c0 fd 85 95 52 09-dc 40 c5 17 aa c2 8c f0   N.....R..@......
	    0080 - 4a c3 a7 4e 5f bc 52 ba-ff fe 35 ce 36 21 66 c8   J..N_.R...5.6!f.
	    0090 - 19 af ca 54 54 85 c2 34-03 63 cc 1a 84 c8 9d 1a   ...TT..4.c......

	    Start Time: 1630448452
	    Timeout   : 300 (sec)
	    Verify return code: 0 (ok)
	---





