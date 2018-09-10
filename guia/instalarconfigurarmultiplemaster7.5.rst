Instalar y configurar OpenLDAP Multiple-Master  Centos 7.5
============================================================


En la replicación Multi-Master, dos o más servidores actúan como maestros y todos estos son autorizados para cualquier cambio en el directorio LDAP. Las consultas de los clientes se distribuyen en los servidores múltiples con la ayuda de la replicación.

Ambiente
++++++++

Se utilizaran dos servidores en CentOS 7.5 y cada uno como Master OpenLdap.Agregamos las siguientes lineas en el /etc/hosts::
	
	# vi /etc/hosts
	192.168.0.210	ldapsrv01.dominio.local ldapsrv01
	192.168.0.220	ldapsrv02.dominio.local ldapsrv02


Instalar LDAP
+++++++++++++

Instale paquetes LDAP en todos sus servidores.::

	# yum install openldap-servers openldap-clients


Inicie el servicio LDAP y habilítelo para el inicio automático en el arranque del sistema.::

	systemctl start slapd.service
	systemctl enable slapd.service
	systemctl status slapd.service


Configurar los LOGs LDAP
++++++++++++++++++++++++++

Configure syslog para habilitar el registro de LDAP.::

	cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
	chown ldap:ldap /var/lib/ldap/*


Configurar la replicación OpenLDAP Multi-Master
++++++++++++++++++++++++++++++++++++++++++++++++


Copie el archivo de configuración de la base de datos de muestra en el directorio /var/lib/ldap y actualice los permisos del archivo.::

	cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
	chown ldap:ldap /var/lib/ldap/*


Habilitaremos el módulo syncprov.::

	vi syncprov_mod.ldif
	dn: cn=module,cn=config
	objectClass: olcModuleList
	cn: module
	olcModulePath: /usr/lib64/openldap
	olcModuleLoad: syncprov.la

::

	ldapadd -Y EXTERNAL -H ldapi:/// -f syncprov_mod.ldif
	SASL/EXTERNAL authentication started
	SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
	SASL SSF: 0
	adding new entry "cn=module,cn=config"


Habilitar la configuración replicación
++++++++++++++++++++++++++++++++++++++

Cambie olcServerID en todos los servidores. Por ejemplo, para ldpsrv1, establezca olcServerID en 1, para ldpsrv2, establezca olcServerID en 2.::

	vi olcserverid.ldif
	dn: cn=config
	changetype: modify
	add: olcServerID
	olcServerID: 1

Actualizamos la configuración de LDAP.::

	ldapmodify -Y EXTERNAL -H ldapi:/// -f olcserverid.ldif
	SASL/EXTERNAL authentication started
	SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
	SASL SSF: 0
	modifying entry "cn=config"

Necesitamos generar una contraseña para la replicación de la configuración de LDAP.::

	slappasswd -h {SSHA} -s America21
	{SSHA}0TW9BL3cHyp8iEkj8hP19jIrANO5w8H4


Debe generar una contraseña en cada servidor ejecutando el comando slappasswd.

Establecer una contraseña para la base de datos de configuración.::

Debe generar una contraseña en cada servidor ejecutando el comando slappasswd. Debe ingresar la contraseña que generó en el paso anterior de este archivo.::

	vi olcdatabase.ldif
	dn: olcDatabase={0}config,cn=config
	add: olcRootPW
	olcRootPW: {SSHA}0TW9BL3cHyp8iEkj8hP19jIrANO5w8H4


Actualizamos la configuración de LDAP.::

	ldapmodify -Y EXTERNAL -H ldapi:/// -f olcdatabase.ldif
	SASL/EXTERNAL authentication started
	SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
	SASL SSF: 0
	modifying entry "olcDatabase={0}config,cn=config"


Ahora configuraremos la replicación de la configuración en todos los servidores.::

	vi configrep.ldif

	### Update Server ID with LDAP URL ###

	dn: cn=config
	changetype: modify
	replace: olcServerID
	olcServerID: 1 ldap://ldpsrv1.itzgeek.local
	olcServerID: 2 ldap://ldpsrv2.itzgeek.local

	### Enable Config Replication###

	dn: olcOverlay=syncprov,olcDatabase={0}config,cn=config
	changetype: add
	objectClass: olcOverlayConfig
	objectClass: olcSyncProvConfig
	olcOverlay: syncprov

	### Adding config details for confDB replication ###

	dn: olcDatabase={0}config,cn=config
	changetype: modify
	add: olcSyncRepl
	olcSyncRepl: rid=001 provider=ldap://ldpsrv1.itzgeek.local binddn="cn=config"
	  bindmethod=simple credentials=America21 searchbase="cn=config"
	  type=refreshAndPersist retry="5 5 300 5" timeout=1
	olcSyncRepl: rid=002 provider=ldap://ldpsrv2.itzgeek.local binddn="cn=config"
	  bindmethod=simple credentials=America21 searchbase="cn=config"
	  type=refreshAndPersist retry="5 5 300 5" timeout=1
	-
	add: olcMirrorMode
	olcMirrorMode: TRUE

Actualizamos la configuración de LDAP.::

	ldapmodify -Y EXTERNAL -H ldapi:/// -f configrep.ldif
	SASL/EXTERNAL authentication started
	SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
	SASL SSF: 0
	modifying entry "cn=config"

	adding new entry "olcOverlay=syncprov,olcDatabase={0}config,cn=config"

	modifying entry "olcDatabase={0}config,cn=config"

Habilitar la replicación de bases de datos
++++++++++++++++++++++++++++++++++++++++++++


En este momento, todas sus configuraciones de LDAP se replican. Ahora, habilitaremos la replicación de los datos reales, es decir, la base de datos del usuario. Realice los pasos siguientes en cualquiera de los nodos de los que están replicando.

Tendríamos que habilitar syncprov para la base de datos hdb.::

	vi syncprov.ldif

	dn: olcOverlay=syncprov,olcDatabase={2}hdb,cn=config
	changetype: add
	objectClass: olcOverlayConfig
	objectClass: olcSyncProvConfig
	olcOverlay: syncprov


Actualizamos la configuración de LDAP.::

	ldapmodify -Y EXTERNAL -H ldapi:/// -f syncprov.ldif

	SASL/EXTERNAL authentication started
	SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
	SASL SSF: 0
	adding new entry "olcOverlay=syncprov,olcDatabase={2}hdb,cn=config"

Configuración para la replicaciónpara la base de datos hdb. Puede obtener un error para olcSuffix, olcRootDN y olcRootPW si ya tiene estos en su configuración. Elimine las entradas, si no es necesario.::

	vi olcdatabasehdb.ldif

	dn: olcDatabase={2}hdb,cn=config
	changetype: modify
	replace: olcSuffix
	olcSuffix: dc=itzgeek,dc=local
	-
	replace: olcRootDN
	olcRootDN: cn=ldapadm,dc=itzgeek,dc=local
	-
	replace: olcRootPW
	olcRootPW: {SSHA}0TW9BL3cHyp8iEkj8hP19jIrANO5w8H4
	-
	add: olcSyncRepl
	olcSyncRepl: rid=004 provider=ldap://ldpsrv1.itzgeek.local binddn="cn=ldapadm,dc=itzgeek,dc=local" bindmethod=simple
	  credentials=America21 searchbase="dc=itzgeek,dc=local" type=refreshOnly
	  interval=00:00:00:10 retry="5 5 300 5" timeout=1
	olcSyncRepl: rid=005 provider=ldap://ldpsrv2.itzgeek.local binddn="cn=ldapadm,dc=itzgeek,dc=local" bindmethod=simple
	  credentials=America21 searchbase="dc=itzgeek,dc=local" type=refreshOnly
	  interval=00:00:00:10 retry="5 5 300 5" timeout=1
	-
	add: olcDbIndex
	olcDbIndex: entryUUID  eq
	-
	add: olcDbIndex
	olcDbIndex: entryCSN  eq
	-
	add: olcMirrorMode
	olcMirrorMode: TRUE



Una vez que haya actualizado el archivo, envíe la configuración al servidor LDAP.::

	ldapmodify -Y EXTERNAL  -H ldapi:/// -f olcdatabasehdb.ldif

	SASL/EXTERNAL authentication started
	SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
	SASL SSF: 0
	modifying entry "olcDatabase={2}hdb,cn=config"


Realice cambios en el archivo olcDatabase={1} monitor.ldif para restringir el acceso del monitor solo al usuario raíz LDAP (ldapadm), no a otros.::

	# vi monitor.ldif

	dn: olcDatabase={1}monitor,cn=config
	changetype: modify
	replace: olcAccess
	olcAccess: {0}to * by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external, cn=auth" read by dn.base="cn=ldapadm,dc=itzgeek,dc=local" read by * none


Una vez que haya actualizado el archivo, envíe la configuración al servidor LDAP.::

	ldapmodify -Y EXTERNAL  -H ldapi:/// -f monitor.ldif


Agregamos los siguientes schemas LDAP.::

	ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif
	ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif 
	ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif


Genera el archivo base.ldif para tu dominio.::

	# vi base.ldif

	dn: dc=itzgeek,dc=local
	dc: itzgeek
	objectClass: top
	objectClass: domain

	dn: cn=ldapadm ,dc=itzgeek,dc=local
	objectClass: organizationalRole
	cn: ldapadm
	description: LDAP Manager

	dn: ou=People,dc=itzgeek,dc=local
	objectClass: organizationalUnit
	ou: People

	dn: ou=Group,dc=itzgeek,dc=local
	objectClass: organizationalUnit
	ou: Group


Generamos la estructura del directorio.::

	ldapadd -x -W -D "cn=ldapadm,dc=itzgeek,dc=local" -f base.ldif

	Enter LDAP Password:
	adding new entry "dc=itzgeek,dc=local"

	adding new entry "cn=ldapadm ,dc=itzgeek,dc=local"

	adding new entry "ou=People,dc=itzgeek,dc=local"

	adding new entry "ou=Group,dc=itzgeek,dc=local"


Pruebe de replicación en el LDAP
++++++++++++++++++++++++++++++++


Creemos un usuario LDAP llamado "ldaptest" en cualquiera de sus servidores maestros, para hacer eso, cree un archivo .ldif en ldpsrv1.itzgeek.local (en mi caso).::

	vi ldaptest.ldif

	dn: uid=ldaptest,ou=People,dc=itzgeek,dc=local
	objectClass: top
	objectClass: account
	objectClass: posixAccount
	objectClass: shadowAccount
	cn: ldaptest
	uid: ldaptest
	uidNumber: 9988
	gidNumber: 100
	homeDirectory: /home/ldaptest
	loginShell: /bin/bash
	gecos: LDAP Replication Test User
	userPassword: {crypt}x
	shadowLastChange: 17058
	shadowMin: 0
	shadowMax: 99999
	shadowWarning: 7


Agregue un usuario al servidor LDAP usando el comando ldapadd.::

	ldapadd -x -W -D "cn=ldapadm,dc=itzgeek,dc=local" -f ldaptest.ldif
	Enter LDAP Password:
	adding new entry "uid=ldaptest,ou=People,dc=itzgeek,dc=local"



Busque "ldaptest" en otro servidor maestro (ldpsrv2.itzgeek.local).::

	ldapsearch -x cn=ldaptest -b dc=itzgeek,dc=local

	# extended LDIF
	#
	# LDAPv3
	# base <dc=itzgeek,dc=local> with scope subtree
	# filter: cn=ldaptest
	# requesting: ALL
	#

	# ldaptest, People, itzgeek.local
	dn: uid=ldaptest,ou=People,dc=itzgeek,dc=local
	objectClass: top
	objectClass: account
	objectClass: posixAccount
	objectClass: shadowAccount
	cn: ldaptest
	uid: ldaptest
	uidNumber: 9988
	gidNumber: 100
	homeDirectory: /home/ldaptest
	loginShell: /bin/bash
	gecos: LDAP Replication Test User
	userPassword:: e2NyeXB0fXg=
	shadowLastChange: 17058
	shadowMin: 0
	shadowMax: 99999
	shadowWarning: 7

	# search result
	search: 2
	result: 0 Success

	# numResponses: 2
	# numEntries: 1

Ahora, establezca una contraseña para el usuario creado en ldpsrv1.itzgeek.local yendo a ldpsrv2.itzgeek.local. Si puede establecer la contraseña, eso significa que la replicación está funcionando como se esperaba.::

	ldappasswd -s password123 -W -D "cn=ldapadm,dc=itzgeek,dc=local" -x "uid=ldaptest,ou=People,dc=itzgeek,dc=local"


Where,

-s specify the password for the username

-x username for which the password is changed

-D Distinguished name to authenticate to the LDAP server.














