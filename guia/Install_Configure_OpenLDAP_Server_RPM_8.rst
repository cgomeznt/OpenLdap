Instalar y configurar OpenLDAP Server en RHEL 8
===============================================

Los Directory services, también conocidos como name services, funcionan como authoritative identity provider (IdP) para varias empresas en todo el mundo. 
Asignan los nombres de los recursos de red a las respectivas direcciones de red. Actúa como una infraestructura de información compartida para localizar, 
gestionar, administrar y organizar recursos cotidianos como volúmenes, carpetas, archivos, impresoras, usuarios, grupos, dispositivos, números de teléfono, etc. 
Es tan esencial elegir el servidor de directorio correcto para su organización, ya que se convierte en la fuente de verdad para la autenticación y 
autorización en su espacio de trabajo digital.

**LDAP** es un acrónimo de Protocolo ligero de acceso a directorios (Lightweight directory access protocol). 
Este es un protocolo utilizado para acceder y modificar el servicio de directorio basado en X.500 que se ejecuta sobre TCP/IP. 
Se utiliza para abordar la autenticación y compartir información sobre usuarios, sistemas, servicios, redes y aplicaciones desde un servicio de directorio a 
otros servicios/aplicaciones. No solo puede leer Active Directory, sino que también puede integrarse con otros programas de Linux.

**OpenLDAP** es la implementación gratuita y de código abierto de LDAP desarrollada por OpenLDAP Project y lanzada bajo la licencia única de estilo BSD llamada OpenLDAP Public License. 
Proporciona una utilidad de línea de comandos que se puede usar para crear y administrar el directorio LDAP. 
**Para usar esta herramienta, debe tener un conocimiento profundo del protocolo y la estructura LDAP.**
Para eliminar la disputa, puede usar herramientas de terceros como phpLDAPadmin para administrar el servicio.

**OpenLDAP** ofrece las siguientes características geniales:

**Costos bajos**: es gratis, por lo que es una opción común para las nuevas empresas.

**Flexibilidad**: Esto le da una amplia aplicabilidad.

**Soporte LDAPv3**: Ofrece soporte para autenticación simple y capa de seguridad y seguridad de la capa de transporte.

**Compatibilidad con IPv6**: OpenLDAP admite la versión 6 del Protocolo de Internet de próxima generación.

**OS-agnosticismo**: es totalmente compatible con los sistemas Mac, Windows y Linux.

**API C actualizada**: esto mejora la forma en que los programadores pueden conectarse y usar servidores de directorio LDAP.

**Servidor LDAP autónomo mejorado**

**Compatibilidad con DIFv1**: proporciona compatibilidad total con el formato de intercambio de datos LDAP (LDIF) versión 1.


Preparando el Server
----------------------
Antes de iniciar debemos estar seguros que el servidor este actualizado::


	dnf update -y
	
Una vez completado, verificamos si es necesario reiniciar::

	[ -f /var/run/reboot-required ] &&  reboot -f
	
Set el nobre correcto del  hostname ::

	 hostnamectl set-hostname ldapmaster.dominio.local
	
Actualizar el  /etc/hosts con el nombre del hostnames y la IPs::

	$  vi /etc/hosts
	192.168.0.21 ldapmaster.dominio.local
	192.168.0.200 ldapclient.dominio.local
	
Step 1 – Instalar paquetes de OpenLDAP
-------------------------------------

Una vez todas las actividades anteriores esten ejecutadas, habilitamos el repositorio de **symas**, que provee de los paquetes de OpenLDAP::

	 wget -q https://repo.symas.com/configs/SOFL/rhel8/sofl.repo -O /etc/yum.repos.d/sofl-symas.repo
	
Una vez el repositorio este habilitado, instalamos los paquetes requeridos::

	 dnf install symas-openldap-clients symas-openldap-servers sssd-ldap.x86_64

El arbol de dependecias puede ser aun más que esto::

	Dependencies resolved.
	================================================================================
	 Package                      Architecture Version             Repository  Size
	================================================================================
	Installing:
	 symas-openldap-clients       x86_64       2.4.59-1.el8        sofl       203 k
	 symas-openldap-servers       x86_64       2.4.59-1.el8        sofl       2.2 M
	Installing dependencies:
	 symas-openldap               x86_64       2.4.59-1.el8        sofl       345 k

	Transaction Summary
	================================================================================
	Install  3 Packages

	Total download size: 2.8 M
	Installed size: 6.8 M
	Is this ok [y/N]: y
	
Completada la instalación, verificamos::


	$ rpm -qa | grep ldap
	symas-openldap-2.4.59-1.el8.x86_64
	openldap-2.4.46-18.el8.x86_64
	symas-openldap-servers-2.4.59-1.el8.x86_64
	sssd-ldap-2.6.2-3.el8.x86_64
	symas-openldap-clients-2.4.59-1.el8.x86_64
	
Step 2 – Configurar OpenLDAP Server
---------------------------------

Ya completa la instalación, podemos aplicar los ajustes de severidad en el OpenLDAP Server. Alguno de los requerimientos de configuración son::

1. Configurar SLAPD database

Ahora preparamos el template de database DB_CONFIG::

	 cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG 
	
Colocamos los permisos correctos para los archivos::

	 chown ldap. /var/lib/ldap/DB_CONFIG 
	
Ahora iniciamos y habilitamos el slapd service::

	 systemctl enable --now slapd
	
Verificamos si el servicio esta running y sin errores ::

	$ systemctl status slapd
	● slapd.service - OpenLDAP Server Daemon
	   Loaded: loaded (/usr/lib/systemd/system/slapd.service; enabled; vendor preset: disabled)
	   Active: active (running) since Sat 2022-09-24 04:37:08 EDT; 13s ago
		 Docs: man:slapd
			   man:slapd-config
			   man:slapd-hdb
			   man:slapd-mdb
			   file:///usr/share/doc/openldap-servers/guide.html
	  Process: 3917 ExecStart=/usr/sbin/slapd -u ldap -h ldap:/// ldaps:/// ldapi:/// (code=exited, status=0/SUCCESS)
	  Process: 3904 ExecStartPre=/usr/libexec/openldap/check-config.sh (code=exited, status=0/SUCCESS)
	 Main PID: 3919 (slapd)
		Tasks: 2 (limit: 23198)
	   Memory: 3.1M
	   CGroup: /system.slice/slapd.service
			   └─3919 /usr/sbin/slapd -u ldap -h ldap:/// ldaps:/// ldapi:///
			   
Permitimos en el Firewall el servicio del LDAP::

	 firewall-cmd --add-service={ldap,ldaps} --permanent
	 firewall-cmd --reload
	
Hay varios atributos involucrados al configurar el servidor OpenLDAP. Estos son::

	CN – Common Name

	O – Organizational

	OU – Organizational Unit

	SN – Last Name

	DC – Domain Component(DC often comes with two entries dc=example,dc=com)

	DN – Distinguished Name

2. Creamos el password de the admin
--------------------------------

Primero, generamos el password de admin usando la utilidad slappasswd::

	$ slappasswd
	New password:  Venezuela21
	Re-enter new password: Venezuela21
	{SSHA}dpyO1slseAzSUbJ8AR7JC4xNW81koPry
	
El password hash inicia con {SSHA} es un formato para encriptación de password. Ahora, creamos el .ldif con le siguiente contenido::

	$ vi changerootpw.ldif
	dn: olcDatabase={0}config,cn=config
	changetype: modify
	add: olcRootPW
	olcRootPW: {SSHA}dpyO1slseAzSUbJ8AR7JC4xNW81koPry

Para modificar el root password utilizamos el archivo LDIF creado::

	$  ldapadd -Y EXTERNAL -H ldapi:/// -f changerootpw.ldif
	ASL/EXTERNAL authentication started
	SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
	SASL SSF: 0
	modifying entry "olcDatabase={0}config,cn=config"
	
3. Importar los basic Schemas
---------------------------

Hay varios schemas required by OpenLDAP. Estos incluyen Attribute Types, Attribute Syntaxes, Matching Rules, y tipos de objetos  que un directorio puede tener. Por detecto, el schema estan almacenados en /etc/openldap/schema/. Por ahora, solo necesitamos el cosine, nis y inetorgperson LDAP schemas

Para importar los schemas, usamos el siguiente comando::

	 ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif
	 ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif 
	 ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif
	
Cremaos el schema sudo para OpenLDAP::

	 cp /usr/share/doc/sudo/schema.OpenLDAP  /etc/openldap/schema/sudo.schema
	
Creamos el archivo sudo LDIF para el schema::

	tee  /etc/openldap/schema/sudo.ldif<<EOF
	dn: cn=sudo,cn=schema,cn=config
	objectClass: olcSchemaConfig
	cn: sudo
	olcAttributeTypes: ( 1.3.6.1.4.1.15953.9.1.1 NAME 'sudoUser' DESC 'User(s) who may  run sudo' EQUALITY caseExactIA5Match SUBSTR caseExactIA5SubstringsMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.26 )
	olcAttributeTypes: ( 1.3.6.1.4.1.15953.9.1.2 NAME 'sudoHost' DESC 'Host(s) who may run sudo' EQUALITY caseExactIA5Match SUBSTR caseExactIA5SubstringsMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.26 )
	olcAttributeTypes: ( 1.3.6.1.4.1.15953.9.1.3 NAME 'sudoCommand' DESC 'Command(s) to be executed by sudo' EQUALITY caseExactIA5Match SYNTAX 1.3.6.1.4.1.1466.115.121.1.26 )
	olcAttributeTypes: ( 1.3.6.1.4.1.15953.9.1.4 NAME 'sudoRunAs' DESC 'User(s) impersonated by sudo (deprecated)' EQUALITY caseExactIA5Match SYNTAX 1.3.6.1.4.1.1466.115.121.1.26 )
	olcAttributeTypes: ( 1.3.6.1.4.1.15953.9.1.5 NAME 'sudoOption' DESC 'Options(s) followed by sudo' EQUALITY caseExactIA5Match SYNTAX 1.3.6.1.4.1.1466.115.121.1.26 )
	olcAttributeTypes: ( 1.3.6.1.4.1.15953.9.1.6 NAME 'sudoRunAsUser' DESC 'User(s) impersonated by sudo' EQUALITY caseExactIA5Match SYNTAX 1.3.6.1.4.1.1466.115.121.1.26 )
	olcAttributeTypes: ( 1.3.6.1.4.1.15953.9.1.7 NAME 'sudoRunAsGroup' DESC 'Group(s) impersonated by sudo' EQUALITY caseExactIA5Match SYNTAX 1.3.6.1.4.1.1466.115.121.1.26 )
	olcObjectClasses: ( 1.3.6.1.4.1.15953.9.2.1 NAME 'sudoRole' SUP top STRUCTURAL DESC 'Sudoer Entries' MUST ( cn ) MAY ( sudoUser $ sudoHost $ sudoCommand $ sudoRunAs $ sudoRunAsUser $ sudoRunAsGroup $ sudoOption $ description ) )
	EOF
	
Aplicamos la configuración::

	 ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/sudo.ldif
	
4. Actualizamos el Nombre del Domain Name en la Base de Datos del LDAP
----------------------------------------------------

Podemos crear otro archivo LDIF con nuestro nombre de dominio, admin user (Manager), y el password encriptado::

	$ vi setdomainname.ldif
	dn: olcDatabase={2}mdb,cn=config
	changetype: modify
	replace: olcSuffix
	olcSuffix: dc=dominio,dc=local

	dn: olcDatabase={2}mdb,cn=config
	changetype: modify
	replace: olcRootDN
	olcRootDN: cn=Manager,dc=dominio,dc=local

	dn: olcDatabase={2}mdb,cn=config
	changetype: modify
	replace: olcRootPW
	olcRootPW: {SSHA}dpyO1slseAzSUbJ8AR7JC4xNW81koPry

	dn: olcDatabase={1}monitor,cn=config
	changetype: modify
	replace: olcAccess
	olcAccess: {0}to * by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth"
	  read by dn.base="cn=Manager,dc=dominio,dc=local" read by * none

Para aplicar los cambios, ejecutamos::

	 ldapmodify -Y EXTERNAL -H ldapi:/// -f setdomainname.ldif
	
Step 3 – Creamos la Organizational Unit en el OpenLDAP
----------------------------------------------------

Para crear una organizational unit (OU). Requiere crear el archivo LDID con las siguientes entradas::

	$ vi adddomain.ldif
	dn: dc=dominio,dc=local
	objectClass: top
	objectClass: dcObject
	objectclass: organization
	o: My example Organisation
	dc: dominio

	dn: cn=Manager,dc=dominio,dc=local
	objectClass: organizationalRole
	cn: Manager
	description: OpenLDAP Manager

	dn: ou=People,dc=dominio,dc=local
	objectClass: organizationalUnit
	ou: People

	dn: ou=Group,dc=dominio,dc=local
	objectClass: organizationalUnit
	ou: Group
	
Para aplicar los cambios, ejecutamos::

	$  ldapadd -x -D cn=Manager,dc=dominio,dc=local -W -f adddomain.ldif
	Enter LDAP Password: Enter_set_password_here
	adding new entry "dc=dominio,dc=local"

	adding new entry "cn=Manager,dc=dominio,dc=local"

	adding new entry "ou=People,dc=dominio,dc=local"

	adding new entry "ou=Group,dc=dominio,dc=local"
	
Step 4 – Administrar usuarios en el OpenLDAP Server
-------------------------------------------------

Para agregar una cuenta de usuario en el OpenLDAP, creamos el archivo LDIF:: 

	vi addtestuser.ldif

En el archivo, agregamos las siguientes lines y modificamos las lineas donde se requieran::

	dn: uid=testuser,ou=People,dc=dominio,dc=local
	objectClass: inetOrgPerson
	objectClass: posixAccount
	objectClass: shadowAccount
	cn: testuser
	sn: temp
	userPassword: {SSHA}XXXXXXXXXXXXXXXXXXXX
	loginShell: /bin/bash
	uidNumber: 2000
	gidNumber: 2000
	homeDirectory: /home/testuser
	shadowLastChange: 0
	shadowMax: 0
	shadowWarning: 0

	dn: cn=testuser,ou=Group,dc=dominio,dc=local
	objectClass: posixGroup
	cn: testuser
	gidNumber: 2000
	memberUid: testuser

Podemos crear el user password con la utilidad slappasswd y remplazar {SSHA}XXXXXXXXXXXXXXXXXXXX

Aplicamos los cambios::

	$  ldapadd -x -D cn=Manager,dc=dominio,dc=local -W -f addtestuser.ldif 
	Enter LDAP Password: 
	adding new entry "uid=testuser,ou=People,dc=dominio,dc=local"

	adding new entry "cn=testuser,ou=Group,dc=dominio,dc=local"
	
Una vez creado, verificamos si el usuario fue creado ::

	ldapsearch -x cn=testuser -b dc=dominio,dc=local
	
Ejemplo de la salida::
	
	# extended LDIF
	#
	# LDAPv3
	# base <dc=dominio,dc=local> with scope subtree
	# filter: cn=testuser
	# requesting: ALL
	#
	
	# testuser, People, dominio.local
	dn: uid=testuser,ou=People,dc=dominio,dc=local
	objectClass: inetOrgPerson
	objectClass: posixAccount
	objectClass: shadowAccount
	cn: testuser
	sn: temp
	userPassword:: e1NTSEF9dSs2OTQ1amU2TGVvbmh2d1BSbHlVR2wwOWtSemFQNEU=
	loginShell: /bin/bash
	uidNumber: 2000
	gidNumber: 2000
	homeDirectory: /home/testuser
	shadowLastChange: 0
	shadowMax: 0
	shadowWarning: 0
	uid: testuser
	
	# testuser, Group, dominio.local
	dn: cn=testuser,ou=Group,dc=dominio,dc=local
	objectClass: posixGroup
	cn: testuser
	gidNumber: 2000
	memberUid: testuser
	
	# search result
	search: 2
	result: 0 Success
	
	# numResponses: 3
	# numEntries: 2


Eliminar usuarios de la Base de Datos del LDAP::

	 ldapdelete -x -W -D 'cn=Manager,dc=dominio,dc=local' "uid=testuser1,ou=People,dc=dominio,dc=local"
	 ldapdelete -x -W -D 'cn=Manager,dc=dominio,dc=local' "cn=testuser1,ou=Group,dc=dominio,dc=local" 
	
Step 5 – Configurar OpenLDAP SSL/TLS
--------------------------------------

Para poder configurar una comunicacion segura cliente servidor para el OpenLDAP. Necesitamos generar certificados SSL para OpenLDAP.

Creamos el directorio en donde estaran los certificados::

	mkdir /certs

	chown -R ldap. /certs

Por ejemplo, para generar un certificado auto firmado::

	 openssl req -x509 -nodes -days 365 \
	  -newkey rsa:2048 \
	  -keyout /certs/ldapserver.key \
	  -out /certs/ldapserver.crt
	  
Ona vez generado, configuramos el propietario::

	 chown ldap:ldap /certs/{ldapserver.crt,ldapserver.key}
	
Ahora, creamos el archivo de configuracion LDIF::

	$ vi add-tls.ldif
	dn: cn=config
	changetype: modify
	add: olcTLSCACertificateFile
	olcTLSCACertificateFile: /certs/ldapserver.crt
	-
	add: olcTLSCertificateKeyFile
	olcTLSCertificateKeyFile: /certs/ldapserver.key
	-
	add: olcTLSCertificateFile
	olcTLSCertificateFile: /certs/ldapserver.crt
	
Apply the changes::

	 ldapadd -Y EXTERNAL -H ldapi:/// -f add-tls.ldif
	
Finalmente, actualizamos el archivo de configuracion del OpenLDAP::

	$  vi /etc/openldap/ldap.conf
	...
	#TLS_CACERT     /etc/pki/tls/cert.pem
	TLS_CACERT     /certs/ldapserver.crt
	
Para aplicar los cambios, reiniciamos el service::

	 systemctl restart slapd
	
Por ultimo y para estar seguros consultamos el puerto 636 para garantizar que esta bien el certificado::

	# nmap --script ssl-enum-ciphers -p636 192.168.0.21
	Starting Nmap 7.70 ( https://nmap.org ) at 2023-08-17 22:13 -04
	Nmap scan report for ldapmaster.dominio.local (192.168.0.21)
	Host is up (0.00046s latency).
	
	PORT    STATE SERVICE
	636/tcp open  ldapssl
	| ssl-enum-ciphers:
	|   TLSv1.2:
	|     ciphers:
	|       TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA (secp256r1) - A
	|       TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256 (secp256r1) - A
	|       TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256 (secp256r1) - A
	|       TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA (secp256r1) - A
	|       TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384 (secp256r1) - A
	|       TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256 (secp256r1) - A
	|       TLS_RSA_WITH_AES_128_CBC_SHA (rsa 2048) - A
	|       TLS_RSA_WITH_AES_128_CBC_SHA256 (rsa 2048) - A
	|       TLS_RSA_WITH_AES_128_CCM (rsa 2048) - A
	|       TLS_RSA_WITH_AES_128_GCM_SHA256 (rsa 2048) - A
	|       TLS_RSA_WITH_AES_256_CBC_SHA (rsa 2048) - A
	|       TLS_RSA_WITH_AES_256_CBC_SHA256 (rsa 2048) - A
	|       TLS_RSA_WITH_AES_256_CCM (rsa 2048) - A
	|       TLS_RSA_WITH_AES_256_GCM_SHA384 (rsa 2048) - A
	|     compressors:
	|       NULL
	|     cipher preference: client
	|_  least strength: A
	
	Nmap done: 1 IP address (1 host up) scanned in 0.49 seconds
