Instalar y configurar OpenLDAP en Centos 7.5
=========================================



OpenLDAP es una implementación de código abierto de Protocolo ligero de acceso a directorios desarrollado por el proyecto OpenLDAP. LDAP es un protocolo de Internet que el correo electrónico y otros programas utilizan para buscar información de contacto de un servidor. Se lanza bajo la licencia pública de OpenLDAP; está disponible para todas las principales distribuciones de Linux, AIX, Android, HP-UX, OS X, Solaris, Windows yz / OS.

Funciona como una base de datos relacional de ciertas maneras y se puede usar para almacenar cualquier información. LDAP no está limitado a almacenar la información; también se usa como una base de datos back-end para "inicio de sesión único" donde una contraseña para un usuario se comparte entre muchos servicios.

Configuraremos OpenLDAP para el inicio de sesión centralizado donde los usuarios usan la cuenta única para iniciar sesión en varios servidores.

**IMPORTANTE** Tenga mucho cuidados con el formato de los archivos **ldif**, debe respetar los salto de linea, los espacio en blanco, los guiones "-", etc. Porque son muy delicados.

Instalar paquetes OpenLDAP
++++++++++++++++++++++++++++

Instale los siguientes paquetes LDAP RPM en el servidor LDAP::

	yum -y install openldap compat-openldap openldap-clients openldap-servers openldap-servers-sql openldap-devel
	yum -y install openldap.x86_64 compat-openldap.x86_64 openldap-servers.x86_64 openssh-ldap.x86_64 openldap-servers-sql.x86_64 openldap-devel.x86_64 openldap-clients.x86_64

Inicie el servicio LDAP y habilítelo para el inicio automático del servicio en el inicio del sistema.::

	systemctl start slapd
	systemctl enable slapd

Verifica el LDAP.::

	netstat -natp | grep slapd
	tcp        0      0 0.0.0.0:389             0.0.0.0:*               LISTEN      19848/slapd         
	tcp6       0      0 :::389                  :::*                    LISTEN      19848/slapd 

**Importante** bien configurado el hosts y el hostname.::

Configurar los LOGs para LDAP
Configuramos el syslog para habilitar los LOGs del ldap::


	# echo "local4.* /var/log/ldap.log" >> /etc/rsyslog.conf
	# systemctl restart rsyslog
	# systemctl restart slapd

Configurar la contraseña de administrador de LDAP

Ejecute debajo del comando para crear una contraseña de root de LDAP. Utilizaremos esta contraseña de administrador de LDAP (raíz) a lo largo de este artículo.
Reemplace ldppassword con su contraseña.::

	slappasswd -h {SSHA} -s America21

El comando anterior generará un hash cifrado de la contraseña ingresada que deberá usar en el archivo de configuración de LDAP. Así que toma nota de esto y mantenlo a un lado.::

	{SSHA}OfE8dsrLgiYAddJdDIC8CJWWo+NfycOV


Configurar el servidor OpenLDAP
++++++++++++++++++++++++++++++++

Los archivos de configuración de los servidores OpenLDAP se encuentran en /etc/openldap/slapd.d/. Para comenzar con la configuración de LDAP, necesitaríamos actualizar las variables "olcSuffix" y "olcRootDN".
olcSuffix - Sufijo de base de datos, es el nombre de dominio para el cual el servidor LDAP proporciona la información. En palabras simples, debe cambiarse a su dominio
olcRootDN: entrada del nombre distinguido de raíz (DN) para el usuario que tiene acceso sin restricciones para realizar todas las actividades de administración en LDAP, como un usuario raíz.
olcRootPW - contraseña de administrador de LDAP para el RootDN anterior.

crea un archivo .ldif::

	vi db.ldif
	dn: olcDatabase={2}hdb,cn=config
	changetype: modify
	replace: olcSuffix
	olcSuffix: dc=dominio,dc=local

	dn: olcDatabase={2}hdb,cn=config
	changetype: modify
	replace: olcRootDN
	olcRootDN: cn=ldapadm,dc=dominio,dc=local

	dn: olcDatabase={2}hdb,cn=config
	changetype: modify
	replace: olcRootPW
	olcRootPW: {SSHA}OfE8dsrLgiYAddJdDIC8CJWWo+NfycOV


Una vez que haya terminado con el archivo ldif, envíe la configuración al servidor LDAP.::

	# ldapmodify -Y EXTERNAL  -H ldapi:/// -f db.ldif
	SASL/EXTERNAL authentication started
	SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
	SASL SSF: 0
	modifying entry "olcDatabase={2}hdb,cn=config"

	modifying entry "olcDatabase={2}hdb,cn=config"

	modifying entry "olcDatabase={2}hdb,cn=config"


Realice cambios en el archivo /etc/openldap/slapd.d/cn=config/olcDatabase={1}monitor.ldif (No edite manualmente) para restringir el acceso del monitor solo al usuario ldap root (ldapadm) y no a otros.::

	vi monitor.ldif
	dn: olcDatabase={1}monitor,cn=config
	changetype: modify
	replace: olcAccess
	olcAccess: {0}to * by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external, cn=auth" read by dn.base="cn=ldapadm,dc=dominio,dc=local" read by * none

Una vez que haya actualizado el archivo, envíe la configuración al servidor LDAP.::

	# ldapmodify -Y EXTERNAL  -H ldapi:/// -f monitor.ldif
	SASL/EXTERNAL authentication started
	SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
	SASL SSF: 0
	modifying entry "olcDatabase={1}monitor,cn=config"


Configurar la base de datos LDAP
+++++++++++++++++++++++++++++++++

Copie el archivo de configuración de la base de datos de muestra en / var / lib / ldap y actualice los permisos del archivo.::

	# cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
	# chown ldap:ldap /var/lib/ldap/*

Agregue los esquemas de coseno y nis LDAP.::

	# ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif
	SASL/EXTERNAL authentication started
	SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
	SASL SSF: 0
	adding new entry "cn=cosine,cn=schema,cn=config"

	# ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif 
	SASL/EXTERNAL authentication started
	SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
	SASL SSF: 0
	adding new entry "cn=nis,cn=schema,cn=config"

	# ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif
	SASL/EXTERNAL authentication started
	SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
	SASL SSF: 0
	adding new entry "cn=inetorgperson,cn=schema,cn=config"

	ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/misc.ldif
	SASL/EXTERNAL authentication started
	SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
	SASL SSF: 0
	adding new entry "cn=misc,cn=schema,cn=config"

	# ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/core.ldif
	SASL/EXTERNAL authentication started
	SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
	SASL SSF: 0
	adding new entry "cn=core,cn=schema,cn=config"
	ldap_add: Other (e.g., implementation specific) error (80)
		additional info: olcAttributeTypes: Duplicate attributeType: "2.5.4.2"


Genera el archivo base.ldif para tu dominio.::

	vi base.ldif
	dn: dc=dominio,dc=local
	dc: dominio
	objectClass: top
	objectClass: domain

	dn: cn=ldapadm ,dc=dominio,dc=local
	objectClass: organizationalRole
	cn: ldapadm
	description: LDAP Manager

	dn: ou=People,dc=dominio,dc=local
	objectClass: organizationalUnit
	ou: People

	dn: ou=Group,dc=dominio,dc=local
	objectClass: organizationalUnit
	ou: Group


Construye la estructura del directorio.::

	# ldapadd -x -W -D "cn=ldapadm,dc=dominio,dc=local" -f base.ldif
	Enter LDAP Password: America21
	adding new entry "dc=dominio,dc=local"

	adding new entry "cn=ldapadm ,dc=dominio,dc=local"

	adding new entry "ou=People,dc=dominio,dc=local"

	adding new entry "ou=Group,dc=dominio,dc=local"



Crear usuario LDAP
++++++++++++++++++

Creamos un usuario dentro del Dominio::

	vi user.ldif
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
	userPassword: {crypt}x
	shadowLastChange: 17058
	shadowMin: 0
	shadowMax: 99999
	shadowWarning: 7


Utilice el comando ldapadd con el archivo anterior para crear un nuevo usuario llamado "cgomeznt" en el directorio OpenLDAP.::	

	# ldapadd -x -W -D "cn=ldapadm,dc=dominio,dc=local" -f user.ldif
	Enter LDAP Password: America21
	adding new entry "uid=cgomeznt,ou=People,dc=dominio,dc=local"


Asigna una contraseña al usuario.::

	# ldappasswd -s SuClave21 -W -D "cn=ldapadm,dc=dominio,dc=local" -x "uid=cgomeznt,ou=People,dc=dominio,dc=local"
	Enter LDAP Password: America21


Dónde,
-s especifica la contraseña para el nombre de usuario
-x nombre de usuario para el que se cambia la contraseña
-D Nombre distinguido para autenticarse en el servidor LDAP.

Verifique las entradas de LDAP.::

	# ldapsearch -x cn=cgomeznt -b dc=dominio,dc=local
		# extended LDIF
		#
		# LDAPv3
		# base <dc=dominio,dc=local> with scope subtree
		# filter: cn=cgomeznt
		# requesting: ALL
		#

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
		userPassword:: e1NTSEF9MmpTZWc0MVIwZE1CY0hFZzVSTG4xc0VNb1N6aURVYVM=

		# search result
		search: 2
		result: 0 Success

		# numResponses: 2
		# numEntries: 1

Para eliminar una entrada de LDAP (opcional).::

	ldapdelete -W -D "cn=ldapadm,dc=dominio,dc=local" "uid=cgomeznt,ou=People,dc=dominio,dc=local"

Para Modificar una entrada de LDAP (opcional).::

	# vi usermodify.ldiff
	Para Modificar una entrada de LDAP (opcional).::
	dn: uid=cgomeznt,ou=People,dc=dominio,dc=local
	changetype: modify
	replace: gecos
	gecos: Carlos Gomez G [Admin (at) dominio]


Ejecutamos la modificación.::

	# ldapmodify -x -W -D "cn=ldapadm,dc=dominio,dc=local" -f usermodify.ldif 
	Enter LDAP Password: America21
	modifying entry "uid=cgomeznt,ou=People,dc=dominio,dc=local"













