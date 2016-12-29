Instalar y configurar OpenLDAP en Centos 6
=============================================

* Argregar una unidad organizacional (OU)
* Agregar un usuario
* Agregar un grupo
* Agregar un usuario a un grupo

Instalar y configurarOpenLDAP en Centos 6
+++++++++++++++++++++++++++++++++++++++++
::

	# yum -y install openldap openldap-clients openldap-servers

Generar un hash password.::

	# slappasswd
	New password : Venezuela21
	Re-enter new password : Venezuela21
	{SSHA}QljrDztiCdL5tf9obdaKLdDiTiBbL0jp


Agregamos el hash password en la configuracion del OpenLDAP en olcDatabase={2}bdb.ldif, el usuario root tendra permisos para agregar otros usuario, grupos, OU, etc.::

	# cd /etc/openldap/slapd.d/cn\=config
	# vi olcDatabase\=\{2\}bdb.ldif

	olcSuffix: dc=domino,dc=local
	...
	olcRootDN: cn=Manager,dc=domino,dc=local
	...
	olcRootPW: {SSHA}QljrDztiCdL5tf9obdaKLdDiTiBbL0jp
	...

No configure el cn del root localo "root" o "OpenLdap" (cn=root,dc=domino,dc=local), esto trae problemas. Modifique el DN del usuario roo en olcDatabase={1}monitor.ldif.::

	# vi olcDatabase\=\{1\}monitor.ldif
	olcAccess: {0}to * by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" read by dn.base="cn=Manager,dc=domino,dc=local" read by * none

Ahora el usuario root del LDAP es cn=Manager,dc=domino,dc=local.

Editar el  oclDatabase\=\{2\}bdb.ldif y agregue las siguientes dos lineas al final del archivo, la primera es para restringir los usuarios puedan ver los password hash de otros usuarios. La segunda es para que el usaurio pueda leer y escribir su propio password.:: 

	# vi olcDatabase\=\{2\}bdb.ldif
olcAccess: {0}to attrs=userPassword by self write by dn.base="cn=Manager,dc=domino,dc=local" write by anonymous auth by * none
olcAccess: {1}to * by dn.base="cn=Manager,dc=domino,dc=local" write by self write by * read

Iniciamos OpenLDAP service.::

	# chkconfig slapd on
	# service slapd start

Creamos manualmente la entrada del arbol LDAP "dc=domino,dc=local"
Now, you must manually create the  LDAP entry in your LDAP tree. Los nodos del arbol son llamados entradas y estas pueden representar usuarios, grupos, OU, domain controller o otros objetos. El atributo de cada una de estas entradas es determinada por un esquema LDAP. Estaremos utilizando InetOrgPerson schema (default OpenLDAP).
En orden de construccion del arbol LDAP lo primero es crear la entrada raiz (root), La entra de raiz es un usual tipo de organizacion llamada Domain Controller (DC). Asumimos que el dominio lo llamaremos dominio.local. El Domain controller LDAP se llamara dc=domino,dc=local.

Un LDAP distinguished name uniquely identifica una entrada en el LDAP.::

	# cd /tmp
	# vi domino.ldif
	dn: dc=domino,dc=local
	objectClass: dcObject
	objectClass: organization
	dc: domino
	o : domino

Introduciomos el contenido del archivo ldif.::

	# ldapadd -f domino.ldif -D cn=Manager,dc=domino,dc=local -w Venezuela21

Verificamos que la entrada se vea::

	# ldapsearch -x -LLL -b dc=domino,dc=local
	dn: dc=domino,dc=local 
	objectClass: dcObject
	objectClass: organization
	dc: domino
	o: domino

CentOS 6 firewall habilitar el pueto por defecto que es 389. 


Argregar una unidad organizacional (OU)
+++++++++++++++++++++++++++++++++++++++++++
::

	# cd /tmp
	# vi users.ldif
	Add these lines to users.ldif:
	dn: ou=Users,dc=domino,dc=local
	objectClass: organizationalUnit
	ou: Users

Agregamos users.ldif al LDAP.::

	# ldapadd -f users.ldif -D cn=Manager,dc=domino,dc=local -w Venezuela21
	Adding a user
	To add a user to LDAP

	# ldapsearch -x -LLL -b dc=domino,dc=local

In this example, we will add a user named "Carl Gomez" to LDAP inside the "Users" OU.

Agregar un usuario
++++++++++++++++++
::
	
	# cd /tmp
	# vi Carl.ldif
	dn: cn=Carl Gomez,ou=Users,dc=domino,dc=local
	cn: Carl Gomez
	sn: Gomez
	objectClass: inetOrgPerson
	userPassword: p@ssw0rd
	uid: bGomez

Agregamos Carl.ldif al LDAP.::

	# ldapadd -f Carl.ldif -D cn=Manager,dc=domino,dc=local -w p@ssw0rd
	Adding a group
	To add a group to LDAP

In this example, we will add a group called "Engineering" to LDAP inside the "Users" OU.

Agregar un grupo
++++++++++++++++++
::

	# cd /tmp
	# vi engineering.ldif
	dn: cn=Engineering,ou=Users,dc=domino,dc=local
	cn: Engineering
	objectClass: groupOfNames
	member: cn=Carl Gomez,ou=Users,dc=domino,dc=local


Agregamos engineering.ldif al LDAP.::

	# ldapadd -f engineering.ldif -D cn=Manager,dc=domino,dc=local -w Venezuela21
	Adding a user to a group
	To add a user to an LDAP group

Agregar un usuario a un grupo
++++++++++++++++++++++++++++++++
::

	# cd /tmp
	[root]# vi addUserToGroup.ldif
	dn: cn=Engineering,ou=Users,dc=domino,dc=local
	changetype: modify
	add: member
	member: cn=Blas Goncalves,ou=Users,dc=domino,dc=local

Agregamos addUserToGroup.ldif al LDAP.::

	# ldapadd -f addUserToGroup.ldif -D cn=Manager,dc=domino,dc=local -w Venezuela21
