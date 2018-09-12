Instalar y configurar OpenLDAP Multiple-Master  Centos 7.5
============================================================


En la replicación Multi-Master, dos o más servidores actúan como maestros y todos estos son autorizados para cualquier cambio en el directorio LDAP. Las consultas de los clientes se distribuyen en los servidores múltiples con la ayuda de la replicación. Esto también es gracias a la versión de slapd 2.4.44. Abandonamos slurpd y vamos a usar syncrelp la nueva forma de sincronizar directorios Openldap.

Lo primero que vamos a hacer es configurar los servidores como maestro. Escucha peticiones de sincronización de sus pares y de los esclavos y les envía las actualizaciones solicitadas. La funcionalidad de maestro está implementada en el “overlay” syncprov (proveedor de sincronización). Lo primero es cargar el modulo y configurarlo. En nuestro OpenLdap debemos cargarlo moduleload syncprov)

Configuramos nuevos índices que necesitamos en la nueva bbdd preparada para synrepl. **index entryCSN,entryUUID eq** 

Me gusto este link: "https://insanecrew.wordpress.com/2009/01/27/replicacion-en-openldap-23x/"

**IMPORTANTE** Tenga mucho cuidados con el formato de los archivos **ldif**, debe respetar los salto de linea, los espacio en blanco, los guiones "-", etc. Porque son muy delicados.

La configuración de un OpenLDAP consta de dos grandes partes:
* Una que es la replicación de la estructura del LDAP o Metadata, entre los nodos master
* La otra es la replicación de la Base de Datos, aunque redundante, toda la data que sera almacenada en el LDAP.


Ambiente
++++++++

Se utilizaran dos servidores en CentOS 7.5 y cada uno como Master OpenLdap.Agregamos las siguientes lineas en el /etc/hosts::
	
	# vi /etc/hosts
	192.168.1.21	ldapsrv1.dominio.local ldapsrv1
	192.168.1.22	ldapsrv2.dominio.local ldapsrv2

**Importante** bien configurado el hosts y el hostname.::

	[root@ldapsrv1 ~]# hostname
	ldapsrv1.dominio.local


	[root@ldapsrv2 ~]# hostname
	ldapsrv1.dominio.local



Instalar LDAP
+++++++++++++

Instale paquetes LDAP en todos sus servidores.::

	# yum install openldap-servers openldap-clients

**No olvides el SELINUX y el Firewalld...!!!**

Inicie el servicio LDAP y habilítelo para el inicio automático en el arranque del sistema.::

	systemctl start slapd.service
	systemctl enable slapd.service
	systemctl status slapd.service

Verificamos los puertos del slapd por no dejar.::

	# netstat -natp | grep slapd
	tcp        0      0 0.0.0.0:389             0.0.0.0:*               LISTEN      2215/slapd          
	tcp6       0      0 :::389                  :::*                    LISTEN      2215/slapd 


Configurar los LOGs LDAP
++++++++++++++++++++++++++

Configure syslog para habilitar el registro de LDAP.::

	echo "local4.* /var/log/ldap.log" >> /etc/rsyslog.conf
	systemctl restart rsyslog
	systemctl restart slapd.service

	tail -f /var/log/ldap.log


**NOTA:** No reinicie los servidores o el servicio de LDAP hasta terminar el manual....!!!

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

Resultado del comando.::

	SASL/EXTERNAL authentication started
	SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
	SASL SSF: 0
	adding new entry "cn=module,cn=config"


Habilitar la configuración replicación
++++++++++++++++++++++++++++++++++++++

Cambie olcServerID en todos los servidores. Por ejemplo, para ldapsrv1, establezca olcServerID en 1, para ldapsrv2, establezca olcServerID en 2.::

	vi olcserverid.ldif
	dn: cn=config
	changetype: modify
	add: olcServerID
	olcServerID: 1

Actualizamos la configuración de LDAP.::

	ldapmodify -Y EXTERNAL -H ldapi:/// -f olcserverid.ldif

Resultado del comando.::

	SASL/EXTERNAL authentication started
	SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
	SASL SSF: 0
	modifying entry "cn=config"

Necesitamos generar una contraseña para la replicación de la configuración de LDAP.::

	slappasswd -h {SSHA} -s America21
	{SSHA}0TW9BL3cHyp8iEkj8hP19jIrANO5w8H4


Debe ingresar la contraseña que generó en el paso anterior de este archivo. Esta contraseña la puede utilizar en todos los servidores, sin necesidad de ejecutar nuevamente el comando slappasswd.::

	vi olcdatabase.ldif
	dn: olcDatabase={0}config,cn=config
	add: olcRootPW
	olcRootPW: {SSHA}0TW9BL3cHyp8iEkj8hP19jIrANO5w8H4


Actualizamos la configuración de LDAP.::

	ldapmodify -Y EXTERNAL -H ldapi:/// -f olcdatabase.ldif

Resultado del comando.::

	SASL/EXTERNAL authentication started
	SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
	SASL SSF: 0
	modifying entry "olcDatabase={0}config,cn=config"


Ahora configuraremos la replicación de la configuración en todos los servidores, uno para cada servidor.::

	vi configrep.ldif

	### Update Server ID with LDAP URL ###

	dn: cn=config
	changetype: modify
	replace: olcServerID
	olcServerID: 1 ldap://ldapsrv1.dominio.local
	olcServerID: 2 ldap://ldapsrv2.dominio.local

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
	olcSyncRepl: rid=001 provider=ldap://ldapsrv1.dominio.local binddn="cn=config"
	  bindmethod=simple credentials=America21 searchbase="cn=config"
	  type=refreshAndPersist retry="5 5 300 5" timeout=1
	olcSyncRepl: rid=002 provider=ldap://ldapsrv2.dominio.local binddn="cn=config"
	  bindmethod=simple credentials=America21 searchbase="cn=config"
	  type=refreshAndPersist retry="5 5 300 5" timeout=1
	-
	add: olcMirrorMode
	olcMirrorMode: TRUE

Actualizamos la configuración de LDAP.::

	ldapmodify -Y EXTERNAL -H ldapi:/// -f configrep.ldif

Resultado del comando.::

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

Resultado del comando.::

	SASL/EXTERNAL authentication started
	SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
	SASL SSF: 0
	adding new entry "olcOverlay=syncprov,olcDatabase={2}hdb,cn=config"

Configuración para la replicación de la base de datos hdb. Puede obtener un error para olcSuffix, olcRootDN y olcRootPW si ya tiene estos en su configuración. Elimine las entradas, si no es necesario.::

	vi olcdatabasehdb.ldif

	dn: olcDatabase={2}hdb,cn=config
	changetype: modify
	replace: olcSuffix
	olcSuffix: dc=dominio,dc=local
	-
	replace: olcRootDN
	olcRootDN: cn=ldapadm,dc=dominio,dc=local
	-
	replace: olcRootPW
	olcRootPW: {SSHA}0TW9BL3cHyp8iEkj8hP19jIrANO5w8H4
	-
	add: olcSyncRepl
	olcSyncRepl: rid=003 provider=ldap://ldapsrv1.dominio.local binddn="cn=ldapadm,dc=dominio,dc=local" bindmethod=simple
	  credentials=America21 searchbase="dc=dominio,dc=local" type=refreshOnly
	  interval=00:00:00:10 retry="5 5 300 5" timeout=1
	olcSyncRepl: rid=004 provider=ldap://ldapsrv2.dominio.local binddn="cn=ldapadm,dc=dominio,dc=local" bindmethod=simple
	  credentials=America21 searchbase="dc=dominio,dc=local" type=refreshOnly
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

Resultado del comando.::

	SASL/EXTERNAL authentication started
	SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
	SASL SSF: 0
	modifying entry "olcDatabase={2}hdb,cn=config"


Realice cambios en el archivo olcDatabase={1} monitor.ldif para restringir el acceso del monitor solo al usuario raíz LDAP (ldapadm), no a otros.::

	# vi monitor.ldif

	dn: olcDatabase={1}monitor,cn=config
	changetype: modify
	replace: olcAccess
	olcAccess: {0}to * by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external, cn=auth" read by dn.base="cn=ldapadm,dc=dominio,dc=local" read by * none


Una vez que haya actualizado el archivo, envíe la configuración al servidor LDAP.::

	ldapmodify -Y EXTERNAL  -H ldapi:/// -f monitor.ldif

Resultado del comando.::

	SASL/EXTERNAL authentication started
	SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
	SASL SSF: 0
	modifying entry "olcDatabase={1}monitor,cn=config"



Agregamos los siguientes schemas LDAP.::

	ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif

Resultado del comando.::

	SASL/EXTERNAL authentication started
	SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
	SASL SSF: 0
	adding new entry "cn=cosine,cn=schema,cn=config"

schemas LDAP.::

	ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif 

Resultado del comando.::

	SASL/EXTERNAL authentication started
	SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
	SASL SSF: 0
	adding new entry "cn=nis,cn=schema,cn=config"

schemas LDAP.::

	ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif

Resultado del comando.::

	SASL/EXTERNAL authentication started
	SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
	SASL SSF: 0
	adding new entry "cn=inetorgperson,cn=schema,cn=config"



Genera el archivo base.ldif para tu dominio.::

	# vi base.ldif

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


Generamos la estructura del directorio.::

	ldapadd -x -W -D "cn=ldapadm,dc=dominio,dc=local" -f base.ldif

Resultado del comando.::

	Enter LDAP Password:
	adding new entry "dc=dominio,dc=local"

	adding new entry "cn=ldapadm ,dc=dominio,dc=local"

	adding new entry "ou=People,dc=dominio,dc=local"

	adding new entry "ou=Group,dc=dominio,dc=local"


Pruebe de replicación en el LDAP
++++++++++++++++++++++++++++++++


Creemos un usuario LDAP llamado "ldaptest" en cualquiera de sus servidores maestros, para hacer eso, cree un archivo .ldif en ldapsrv1.dominio.local (en mi caso).::

	vi user.ldif

	dn: uid=ldaptest,ou=People,dc=dominio,dc=local
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

	ldapadd -x -W -D "cn=ldapadm,dc=dominio,dc=local" -f user.ldif

Resultado del comando.::

	Enter LDAP Password:
	adding new entry "uid=ldaptest,ou=People,dc=dominio,dc=local"

Busque "ldaptest" en otro servidor maestro (ldapsrv2.dominio.local). Pero no deje de crear varios usuarios en un server y otro para certificar el funcionamiento::

	ldapsearch -x cn=ldaptest -b dc=dominio,dc=local

Resultado del comando.::

	# extended LDIF
	#
	# LDAPv3
	# base <dc=dominio,dc=local> with scope subtree
	# filter: cn=ldaptest
	# requesting: ALL
	#

	# ldaptest, People, dominio.local
	dn: uid=ldaptest,ou=People,dc=dominio,dc=local
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

Ahora, establezca una contraseña para el usuario creado en ldapsrv1.dominio.local yendo a ldapsrv2.dominio.local. Si puede establecer la contraseña, eso significa que la replicación está funcionando como se esperaba.::

	ldappasswd -s password123 -W -D "cn=ldapadm,dc=dominio,dc=local" -x "uid=ldaptest,ou=People,dc=dominio,dc=local"

**Si luego de hacer todo esto y reinicia el servicio y le genera erro y en los LOGS le indica que no puede obtener el ServerID, es un problema con su archivo "hosts" o con los DNS**

Si se observa cualquier comportamiento no deseado en la replica de la BD actualice los olcServerID.::

	vi olcserverid-2.ldif
	### Update Server ID with LDAP URL ###

	dn: cn=config
	changetype: modify
	replace: olcServerID
	olcServerID: 1 ldap://ldapsrv1.dominio.local
	olcServerID: 2 ldap://ldapsrv2.dominio.local

envíe la configuración al servidor LDAP.::

	ldapmodify -Y EXTERNAL -H ldapi:/// -f olcserverid-2.ldif

Resultado del comando.::

	SASL/EXTERNAL authentication started
	SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
	SASL SSF: 0
	modifying entry "cn=config"

**Luego de esto se puede reiniciar el servicio, servidor y siempre estará el Multi-Master**


Dónde,

-s specify the password for the username

-x username for which the password is changed

-D Distinguished name to authenticate to the LDAP server.




Listo...!!!
Gracias a Efrhen Isturdes

También

https://www.itzgeek.com/how-tos/linux/centos-how-tos/configure-openldap-multi-master-replication-linux.html

https://linoxide.com/linux-how-to/setup-openldap-multi-master-replication-centos-7/

https://www.server-world.info/en/note?os=CentOS_7&p=openldap&f=6

http://www.cyrill-gremaud.ch/howto-setup-n-way-multi-master-replication-with-openldap/












