Configuración de OpenLDAP para utilizarlo en un Correo
=========================================================

Instalar Debian Squeeze 6.0
que tenga dos adaptadores de red. (Una adaptador de puente y la otra red Interna)
que /var y /tmp estén en particiones distintas.
que la hora y fecha estén bien.

El OpenLDAP tendrá la siguiente forma de árbol::

		     dominio.local
		  	       |
	  _____________|___________
	 |             |		  |	
	users    	groups      mails
		                      |
		        	   _______|________
		      		  |               |
				 domio.local        test.org
	  				 |
	   			   cgome1
	  			  test1001

Cambiar el nombre del servidor::

	# vi /etc/hostname
	 openldap-02

	#/etc/init.d/hostname.sh

Editamos los adaptadores de red.::

	# vi /etc/network/interfaces
	# This file describes the network interfaces available on your system
	# and how to activate them. For more information, see interfaces(5).

	# The loopback network interface
	auto lo
	iface lo inet loopback

	# The primary network interface
	auto eth0
	allow-hotplug eth0
	iface eth0 inet static
	address 10.10.10.12
	netmask 255.255.255.1

	# The secundary network interface
	auto eth1
	allow-hotplug eth1
	iface eth1 inet dhcp

	# /etc/init.d/networking restart

Modificamos los repositorios de debian::

	# vi /etc/apt/sources.list
	deb http://ftp.debian.org/debian squeeze main contrib non-free

	# apt-get update

	Instalamos ssh para hacer mucho mas fácil la administración de la maquina virtual
	# apt-get install ssh

verificar fecha y hora.Supongamos queremos poner: 27-Mayo-2007 y la hora 17:27. Esto lo haremos como root::

	# date --set "2007-05-27 17:27"
	Sun May 27 17:27:00 CET 2007

Ahora realizaremos el mismo cambio para actualizar la fecha en la BIOS.::

	# hwclock --set --date="2007-05-27 17:27"

Para comprobarlo tecleamos::

	# hwclock
	Fri Feb 25 16:25:06 2000  -0.010586 seconds

Y ya está!

Instalamos los paquetes para el OpenLDAP::

	# apt-get install slapd ldap-utils

Pide "Contraseña del Aministrador" escribe lo que quieras
Pide " Verificacion de contraseña" confirmala

Configurar el "resolv.conf".::

	# vi /etc/resolv.conf
	search dominio.local
	nameserver 10.10.10.1

Hacemos una pequeña prueba del funcionamiento del dns::
	
	# ping -c4 dns-01
	PING dns-01.dominio.local (10.10.10.1) 56(84) bytes of data.
	64 bytes from 10.10.10.1: icmp_req=1 ttl=64 time=0.379 ms
	64 bytes from 10.10.10.1: icmp_req=2 ttl=64 time=0.640 ms
	64 bytes from 10.10.10.1: icmp_req=3 ttl=64 time=0.677 ms
	64 bytes from 10.10.10.1: icmp_req=4 ttl=64 time=0.666 ms

Comenzamos con la configuración del OpenLDAP del tipo dinámico, Hacemos un respaldo.::

	# cp -dpRv /etc/ldap/ /etc/ldap-original
	# cd /etc/ldap
	# ls slapd.d/
	# cat slapd.d/cn\=config.ldif
	dn: cn=config
	objectClass: olcGlobal
	cn: config
	olcArgsFile: /var/run/slapd/slapd.args
	olcLogLevel: none
	olcPidFile: /var/run/slapd/slapd.pid
	olcToolThreads: 1
	structuralObjectClass: olcGlobal
	entryUUID: 860d9fc6-6c47-1034-9537-533ece68a708
	creatorsName: cn=config
	createTimestamp: 20150331231511Z
	entryCSN: 20150331231511.147121Z#000000#000#000000
	modifiersName: cn=config
	modifyTimestamp: 20150331231511Z

	# ls slapd.d/cn\=config
	# cat slapd.d/cn\=config/olcDatabase\=\{1\}hdb.ldif
	dn: olcDatabase={1}hdb
	objectClass: olcDatabaseConfig
	objectClass: olcHdbConfig
	olcDatabase: {1}hdb
	olcDbDirectory: /var/lib/ldap <------ Ruta donde se guardan las BD, de ahí es donde lee el slapcat
	olcSuffix: dc=nodomain
	olcAccess: {0}to attrs=userPassword,shadowLastChange by self write by anonymou
	 s auth by dn="cn=admin,dc=nodomain" write by * none
	olcAccess: {1}to dn.base="" by * read
	olcAccess: {2}to * by self write by dn="cn=admin,dc=nodomain" write by * read
	olcLastMod: TRUE
	olcRootDN: cn=admin,dc=nodomain
	olcRootPW:: e1NTSEF9dDV3a0FJWnN4ZFVkaEozMkFySndZRnEyOEFVck9wQjA=
	olcDbCheckpoint: 512 30
	olcDbConfig: {0}set_cachesize 0 2097152 0
	olcDbConfig: {1}set_lk_max_objects 1500
	olcDbConfig: {2}set_lk_max_locks 1500
	olcDbConfig: {3}set_lk_max_lockers 1500
	olcDbIndex: objectClass eq
	structuralObjectClass: olcHdbConfig
	entryUUID: 860ef0c4-6c47-1034-9541-533ece68a708
	creatorsName: cn=admin,cn=config
	createTimestamp: 20150331231511Z
	entryCSN: 20150331231511.155793Z#000000#000#000000
	modifiersName: cn=admin,cn=config
	modifyTimestamp: 20150331231511Z

	# ls /var/lib/ldap/
	alock   __db.002  __db.004  __db.006  dn2id.bdb     log.0000000001
	__db.001  __db.003  __db.005  DB_CONFIG  id2entry.bdb  objectClass.bdb

	# slapcat

	# mkdir ldif-config

Creamos un password y lo guardamos::

	# slappasswd -s Venezuela21 > ldif-config/passwd
	# cat slapd.d/cn\=config/olcDatabase\=\{1\}hdb.ldif > ldif-config/config-inicial.ldif
	# cat ldif-config/passwd >> ldif-config/config-inicial.ldif

Lo vamos a modificar a nuestra conveniencia, vamos a convertirlo en formato ldif::

	# vi ldif-config/config-inicial.ldif
	dn: olcDatabase={1}hdb,cn=config
	changetype: modify
	replace: olcDbDirectory
	olcDbDirectory: /var/lib/ldap/dominio.local
	-
	replace: olcSuffix
	olcSuffix: dc=dominio,dc=local
	-
	replace: olcRootDN
	olcRootDN: cn=manager,dc=dominio,dc=local
	-
	replace: olcRootPW
	olcRootPW: {SSHA}+Ds5btDts5eAOUGKCrk+ovVU18GG8g+x
	-
	replace: olcAccess
	olcAccess: {0}to attrs=userPassword,shadowLastChange by self write by anonymous auth by dn="cn=manager,dc=dominio,dc=local" write by * none
	olcAccess: {1}to dn.base="" by * read
	olcAccess: {2}to * by self write by dn="cn=manager,dc=dominio,dc=local" write by * read

	# ls -l /var/lib/ldap
	# mkdir /var/lib/ldap/dominio.local
	# ls -l /var/lib/ldap <----- fijate en los propietarios
	# chown -R openldap.openldap /var/lib/ldap/dominio.local/
	# ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f ldif-config/config-inicial.ldif
	modifying entry "olcDatabase={1}hdb,cn=config"
	# rm /var/lib/ldap/* <----- las podemos borrar porque ya cambiamos la ruta en donde se guardan las BD
	# ls -l /var/lib/ldap/
	# ls -l /var/lib/ldap/dominio.local/
	# cat slapd.d/cn\=config/olcDatabase\=\{1\}hdb.ldif dn: olcDatabase={1}hdb
	objectClass: olcDatabaseConfig
	objectClass: olcHdbConfig
	olcDatabase: {1}hdb
	olcLastMod: TRUE
	olcDbCheckpoint: 512 30
	olcDbConfig: {0}set_cachesize 0 2097152 0
	olcDbConfig: {1}set_lk_max_objects 1500
	olcDbConfig: {2}set_lk_max_locks 1500
	olcDbConfig: {3}set_lk_max_lockers 1500
	olcDbIndex: objectClass eq
	structuralObjectClass: olcHdbConfig
	entryUUID: 860ef0c4-6c47-1034-9541-533ece68a708
	creatorsName: cn=admin,cn=config
	createTimestamp: 20150331231511Z
	olcDbDirectory: /var/lib/ldap/dominio.local  <--- Las modificaciones hechas
	olcSuffix: dc=dominio,dc=local  <--- Las modificaciones hechas
	olcRootDN: cn=manager,dc=dominio,dc=local  <--- Las modificaciones hechas
	olcRootPW:: e1NTSEF9K0RzNWJ0RHRzNWVBT1VHS0NyaytvdlZVMThHRzhnK3g=  <--- Las modificaciones hechas
	olcAccess: {0}to attrs=userPassword,shadowLastChange by self write by anonymou
	 s auth by dn="cn=manager,dc=dominio,dc=local" write by * none  <--- Las modificaciones hechas
	olcAccess: {1}to dn.base="" by * read  <--- Las modificaciones hechas
	olcAccess: {2}to * by self write by dn="cn=manager,dc=dominio,dc=local" write   <--- Las modificaciones hechas
	 by * read
	entryCSN: 20150331235941.065302Z#000000#000#000000
	modifiersName: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
	modifyTimestamp: 20150331235941Z

	# slapcat <--- Ya no tiene nada porque las BD son nuevas y no le hemos cargado la estructura.

Ahora vamos a crear la base del arbol del LDAP::

	# vi ldif-config/base.ldif
	dn: cn=readmail,dc=dominio,dc=local
	cn: readmail
	sn: readmail
	objectClass: top
	objectClass: person
	objectClass: simpleSecurityObject
	description: This Account is used to read info from LDAP database
	userPassword: 12345

	dn: ou=users,dc=dominio,dc=local
	objectClass: top
	objectClass: organizationalUnit
	description: Organizational Unit for users
	ou: users

	dn: ou=groups,dc=dominio,dc=local
	ou: groups
	objectClass: top
	objectClass: organizationalUnit
	description: Organizational Unit for groups

	dn: ou=mails,dc=dominio,dc=local
	objectClass: top
	objectClass: organizationalUnit
	ou: mails
	description: Logical divider for mail

	dn: ou=dominio.local,ou=mails,dc=dominio,dc=local
	objectClass: top
	objectClass: organizationalUnit
	description: Holder for dominio.local mail accounts
	ou: dominio.local
::

	# ldapadd -x -D "cn=manager,dc=dominio,dc=local" -w Venezuela21 -f ldif-config/base.ldif
	adding new entry "dc=dominio,dc=local"

	adding new entry "cn=readmail,dc=dominio,dc=local"

	adding new entry "ou=users,dc=dominio,dc=local"

	adding new entry "ou=groups,dc=dominio,dc=local"

	adding new entry "ou=mails,dc=dominio,dc=local"

	adding new entry "ou=dominio.local,ou=mails,dc=dominio,dc=local"

	# slapcat <--- ahora si vas a ver la informacion que cargastes

Si quieres limpiar lo que hicisteis puedes hacer-.::

	# /etc/init.d/slapd stop
	# rm /var/lib/ldap/dominio.local
	# /etc/init.d/slapd start
	# slapcat

Antes de poder crear el user.ldif debemos cargar los schemas authldap.schema y qmail.schema, podemos ver que no estan.
para authldap.schema podemos instalar courier-ldap y luego copiarlo de /usr/share/doc/courier-authlib-ldap/authldap.schema.gz o descargarlo de "https://github.com/toddr/courier/blob/master/courier-authlib/authldap.schema"
si instalamos el courier-ldap hariamos esto::

	# gunzip -d /usr/share/doc/courier-authlib-ldap/authldap.schema.gz -c > /etc/ldap/schema/authldap.schema
	# ls schema/
	# vi schema/authldap.schema  <--- le cargamos todo el contenido del authldap.schema que descargamos
	# vi schema/qmail.schema  <--- le cargamos todo el contenido del qmail.schema que descargamos

creamos un fichero schema.convert y copiamos el siguiente texto en su interior con los esquemas a incluir::

	include /etc/ldap/schema/core.schema
	include /etc/ldap/schema/cosine.schema
	include /etc/ldap/schema/nis.schema
	include /etc/ldap/schema/inetorgperson.schema
	include /etc/ldap/schema/qmail.schema
	include /etc/ldap/schema/authldap.schema

Convertimos los ficheros de esquema a ficheros ldif::

	# mkdir ldif_out
	# slaptest -f schema.convert -F ldif_out/
	config file testing succeeded
	# ls ldif_out/cn\=config/cn\=schema/
	cn={0}core.ldif    cn={2}nis.ldif      cn={4}qmail.ldif
	cn={1}cosine.ldif  cn={3}inetorgperson.ldif  cn={5}authldap.ldif

Esto convertirá los ficheros a formato ldif, pero tendremos que editarlo antes de poder importarlo::

	# vi ldif_out/cn\=config/cn\=schema/cn\=\{5\}authldap.ldif
	y cambiamos las primeras entradas para que coincidan con las siguientes
	dn: cn=authldap,cn=schema,cn=config
	...
	cn: authldap

	# vi ldif_out/cn\=config/cn\=schema/cn\=\{4\}qmail.ldif
	y cambiamos las primeras entradas para que coincidan con las siguientes
	dn: cn=qmail,cn=schema,cn=config
	...
	cn: qmail

y borramos las siguientes líneas del final de los fichero "cn\=\{4\}qmail.ldif y cn\=\{5\}authldap.ldif" (el contenido numérico variará dependiendo de la fecha, hora, en la que se realice la conversión.::

	structuralObjectClass: olcSchemaConfig
	entryUUID: 8344f43c-9d7c-102e-8f0e-f3f0ff664b39
	creatorsName: cn=config
	createTimestamp: 20100124213810Z
	entryCSN: 20100124213810.691146Z#000000#000#000000
	modifiersName: cn=config
	modifyTimestamp: 20100124213810Z

Finalmente cargamos los esquemas en OpenLDAP::

	# ldapadd -Q -Y EXTERNAL -H ldapi:/// -f ldif_out/cn\=config/cn\=schema/cn\=\{4\}qmail.ldif
	adding new entry "cn=qmail,cn=schema,cn=config"
	# ldapadd -Q -Y EXTERNAL -H ldapi:/// -f ldif_out/cn\=config/cn\=schema/cn\=\{5\}authldap.ldif
	adding new entry "cn=authldap,cn=schema,cn=config"

Creamos el user.ldif para agregar los usuarios::

	# vi ldif-config/users.ldif
	dn: uid=cgome1,ou=dominio.local,ou=mails,dc=dominio,dc=local
	cn: Carlos Gomez
	givenName: Carlos
	sn: Gomez
	uid: cgome1
	mail: cgome1@dominio.local
	mailAlternateAddress: carlos.gomez@dominio.local
	mailMessageStore: dominio.local/cgome1
	accountStatus: active
	userPassword: 12345
	objectClass: top
	objectClass: inetOrgPerson
	objectClass: qmailUser

	dn: uid=test1001,ou=dominio.local,ou=mails,dc=dominio,dc=local
	cn: test1001
	givenName: test
	sn: 1001
	uid: test1001
	mail: test1001@dominio.local
	mailAlternateAddress: test.1001@dominio.local
	mailMessageStore: dominio.local/test1001
	accountStatus: active
	userPassword: 12345
	objectClass: top
	objectClass: inetOrgPerson
	objectClass: qmailUser

Integramos los datos del archivo users.ldif en la BD del LDAP::

	# ldapadd -x -D "cn=manager,dc=dominio,dc=local" -w Venezuela21 -f ldif-config/users.ldif
	adding new entry "uid=cgome1,ou=dominio.local,ou=mail,dc=dominio,dc=local"
	adding new entry "uid=test1001,ou=dominio.local,ou=mails,dc=dominio,dc=local"

Realizamos unas pruebas de consulta al LDAP::

	# slapcat
	# ldapsearch -x -b "dc=dominio,dc=local" -D "cn=manager,dc=dominio,dc=local" -w Venezuela21 "(objectClass=*)"
	# ldapsearch -Q -Y EXTERNAL -H ldapi:/// -LLL -b cn=config olcDatabase=\* dn
	# ldapsearch -Q -Y EXTERNAL -H ldapi:/// -LLL -b cn=config 'olcDatabase={1}hdb'
	# ldapsearch -x -b "dc=dominio,dc=local" -D "cn=manager,dc=dominio,dc=local" -w Venezuela21 "(mail=cgome1*)"
	# ldapsearch -x -b "dc=dominio,dc=local" -D "cn=manager,dc=dominio,dc=local" -w Venezuela21 "(mail=cgome1*)" mail
	# ldapsearch -x -b "dc=dominio,dc=local" -D "cn=readmail,dc=dominio,dc=local" -w 12345 "(mail=cgome1*)"
	# ldapsearch -x -b "dc=dominio,dc=local" -D "cn=readmail,dc=dominio,dc=local" -w 12345 "(mail=cgome1*)" mail
	# ldapsearch -x -b "dc=dominio,dc=local" -D "uid=cgome1,ou=dominio.local,ou=mails,dc=dominio,dc=local" -w 12345 "(mail=cgome1*)"
	# ldapsearch -x -b "dc=dominio,dc=local" -D "uid=cgome1,ou=dominio.local,ou=mails,dc=dominio,dc=local" -w 12345 "(mail=cgome1*)" mail

con esto ya tenemos el servidor OpenLDAP listo para utilizar en un correo.

