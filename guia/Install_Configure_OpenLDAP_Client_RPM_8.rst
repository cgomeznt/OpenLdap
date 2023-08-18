Configurar un cliente OpenLDAP en RHEL 8
=======================================================

Una vez estemos seguro que el SO esta actualizado set el hostname::

	hostnamectl set-hostname ldapclient.dominio.local
	
Ahora actualizamos el archivo /etc/hosts::

	$ vim /etc/hosts
	##OpenLDAP server
	192.168.0.21 ldapmaster.dominio.local

	##OpenLDAP Client
	192.168.0.200 ldapclient.dominio.local
	
Par este caso el Dominio **dominio.local** esta corriendo en  ‘ldapmaster.dominio.local’, ver link https://github.com/cgomeznt/OpenLdap/blob/master/guia/Install_Configure_OpenLDAP_Server_RPM_8.rst

Verificar si el servidor LDAP esta disponible::

	$ sudo ping -c3 ldapmaster.dominio.local
	PING ldapmaster.dominio.local (192.168.0.21) 56(84) bytes of data.
	64 bytes from ldapmaster.dominio.local (192.168.0.21): icmp_seq=1 ttl=64 time=0.362 ms
	64 bytes from ldapmaster.dominio.local (192.168.0.21): icmp_seq=2 ttl=64 time=0.295 ms
	64 bytes from ldapmaster.dominio.local (192.168.0.21): icmp_seq=3 ttl=64 time=0.265 ms

	--- ldapmaster.dominio.local ping statistics ---
	3 packets transmitted, 3 received, 0% packet loss, time 2030ms
	rtt min/avg/max/mdev = 0.265/0.307/0.362/0.043 ms
	Step 1 – Install OpenLDAP Client and SSSD Packages
	
Teniendo configurado el FQDN en el archivo Hosts, podemos instalar el cliente de OpenLDAP y el SSSD Packages.
EL SSSD package(System Security Service Daemon) es usado para enrolar a los sistemas Linux en directory services tal como un Active Directory IPA Server, y el LDAP domain.

Para instalar todos los paquetes requeridos::

	dnf install openldap-clients sssd sssd-ldap oddjob-mkhomedir libsss_sudo
	
Arbol de dependencia::

	......
	Transaction Summary
	================================================================================
	Install   1 Package
	Upgrade  16 Packages

	Total download size: 4.6 M
	Is this ok [y/N]: y
	
Una vez instalado, se requiere cambiar la Autenticación del perfil SSD. Lista de perfiles disponibles::

	$ authselect list
	- minimal	 Local users only for minimal installations
	- nis    	 Enable NIS for system authentication
	- sssd   	 Enable SSSD for system authentication (also for local users only)
	- winbind	 Enable winbind for system authentication
	
Ahora cambiamos el Perfil SSSD::

	$ authselect select sssd with-mkhomedir --force
	Backup stored at /var/lib/authselect/backups/2022-09-24-18-22-35.bE7tCJ
	Profile "sssd" was selected.
	The following nsswitch maps are overwritten by the profile:
	- passwd
	- group
	- netgroup
	- automount
	- services

Esta es la salida del comando de arriba. Debemos estar seguros que el Servicio SSSD esta configurado y habilitado. Ver documentacion de SSSD para mayor información::

	Backup stored at /var/lib/authselect/backups/2023-08-18-03-00-37.4aDr5J
	Profile "sssd" was selected.
	The following nsswitch maps are overwritten by the profile:
	- passwd
	- group
	- netgroup
	- automount
	- services
	
	Make sure that SSSD service is configured and enabled. See SSSD documentation for more information.
	
	- with-mkhomedir is selected, make sure pam_oddjob_mkhomedir module
	  is present and oddjobd service is enabled and active
	  - systemctl enable --now oddjobd.service

	  
Despues de esto, iniciar y habilitar el servicio oddjobd service::

	systemctl enable --now oddjobd.service
	
Verificar que el servicio este en ejecución::

	$ systemctl status oddjobd.service
	● oddjobd.service - privileged operations for unprivileged applications
	   Loaded: loaded (/usr/lib/systemd/system/oddjobd.service; enabled; vendor preset: disabled)
	   Active: active (running) since Sat 2022-09-24 14:23:52 EDT; 6s ago
	 Main PID: 1080524 (oddjobd)
		Tasks: 1 (limit: 23198)
	   Memory: 876.0K
	   CGroup: /system.slice/oddjobd.service
			   └─1080524 /usr/sbin/oddjobd -n -p /run/oddjobd.pid -t 300
			   
Step 2 – Configurar el Cliente OpenLDAP y el servicio de SSSD
-------------------------------------------------------

Podmos configurar el cliente de OpenLDAP y el servicio de SSSD. Para iniciar la configuracion del Cliente OpenLDAP::

	vim /etc/openldap/ldap.conf
	
Dentro del archivo, definimos el Server de OpenLDAP y el Dominio a buscar en la Base de Datos::

	URI ldap://ldapmaster.dominio.local
	BASE dc=dominio,dc=local
	SUDOERS_BASE ou=sudo,dc=dominio,dc=local
	
La ultima linea es para el acceso SUDO, que luego estaremos configurando más adelante::

	vim /etc/sssd/sssd.conf
	
Agregamos las siguientes lineas al archivo y remplazamos el  ‘ldap_uri‘, ‘ldap_search_base‘ y ‘sudoers_base‘ apropiadamente::

	[domain/default]
	id_provider = ldap
	autofs_provider = ldap
	auth_provider = ldap
	chpass_provider = ldap
	ldap_uri = ldap://ldapmaster.dominio.local
	ldap_search_base = dc=dominio,dc=local
	sudoers_base ou=sudo,dc=dominio,dc=local
	sudo_provider = ldap
	ldap_id_use_start_tls = True
	ldap_tls_cacertdir = /etc/openldap/certs
	cache_credentials = True
	ldap_tls_reqcert = allow

	[sssd]
	services = nss, pam, autofs, sudo
	domains = default

	[nss]
	homedir_substring = /home

	[sudo]
	
Salvamos el archivo y otorgamos los permisos correspondientes::

	chmod 0600 /etc/sssd/sssd.conf
	
Reiniciamos el servicio::

	systemctl restart sssd
	
Verificamos que el servicio este en ejecución y sin errores::

	$ systemctl status sssd
	● sssd.service - System Security Services Daemon
	   Loaded: loaded (/usr/lib/systemd/system/sssd.service; enabled; vendor preset: enabled)
	   Active: active (running) since Sat 2022-09-24 14:26:27 EDT; 6s ago
	 Main PID: 1081322 (sssd)
		Tasks: 6 (limit: 23198)
	   Memory: 45.2M
	   CGroup: /system.slice/sssd.service
			   ├─1081322 /usr/sbin/sssd -i --logger=files
			   ├─1081327 /usr/libexec/sssd/sssd_be --domain implicit_files --uid 0 --gid 0 --logger=files
			   ├─1081328 /usr/libexec/sssd/sssd_be --domain default --uid 0 --gid 0 --logger=files
			   ├─1081329 /usr/libexec/sssd/sssd_nss --uid 0 --gid 0 --logger=files
			   ├─1081330 /usr/libexec/sssd/sssd_pam --uid 0 --gid 0 --logger=files
			   └─1081331 /usr/libexec/sssd/sssd_autofs --uid 0 --gid 0 --logger=files
			   
Step 3 – Probar la autenticación del Cliente OpenLDAP Authentication
--------------------------------------------------------------------

Una vez se haya completado las configuraciones, podremos realizar pruebas, podemos realizar pruebas con los usuarios disponibles en el Servidor de OpenLDAP.

Buscamos los usuarios disponibles en el servidor de OpenLDAP::

	ldapsearch -x -b "ou=people,dc=dominio,dc=local"
	

Es posible utilizar el SSH::

	ssh testuser@192.168.0.200
	
Ejemplo de la salida del comando anterior::

Step 4 – Agregando el sudoers de OpenLDAP
------------------------------------------

Es posible agregar a los usuarios atributos de sudo del OpenLDAP. Cuando configuramos el Server de OpenLDAP, creamos un archivo para el schema sudo en /etc/openldap/schema/sudo.ldif::

	$ cat /etc/openldap/schema/sudo.ldif
	dn: cn=sudo,cn=schema,cn=config
	objectClass: olcSchemaConfig
	cn: sudo
	olcAttributeTypes: {0}( 1.3.6.1.4.1.15953.9.1.1 NAME 'sudoUser' DESC 'User(s) who may  run sudo' EQUALITY caseExactIA5Match SUBSTR caseExactIA5SubstringsMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.26 )
	olcAttributeTypes: {1}( 1.3.6.1.4.1.15953.9.1.2 NAME 'sudoHost' DESC 'Host(s) who may run sudo' EQUALITY caseExactIA5Match SUBSTR caseExactIA5SubstringsMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.26 )
	olcAttributeTypes: {2}( 1.3.6.1.4.1.15953.9.1.3 NAME 'sudoCommand' DESC 'Command(s) to be executed by sudo' EQUALITY caseExactIA5Match SYNTAX 1.3.6.1.4.1.1466.115.121.1.26 )
	olcAttributeTypes: {3}( 1.3.6.1.4.1.15953.9.1.4 NAME 'sudoRunAs' DESC 'User(s) impersonated by sudo (deprecated)' EQUALITY caseExactIA5Match SYNTAX 1.3.6.1.4.1.1466.115.121.1.26 )
	olcAttributeTypes: {4}( 1.3.6.1.4.1.15953.9.1.5 NAME 'sudoOption' DESC 'Options(s) followed by sudo' EQUALITY caseExactIA5Match SYNTAX 1.3.6.1.4.1.1466.115.121.1.26 )
	olcAttributeTypes: {5}( 1.3.6.1.4.1.15953.9.1.6 NAME 'sudoRunAsUser' DESC 'User(s) impersonated by sudo' EQUALITY caseExactIA5Match SYNTAX 1.3.6.1.4.1.1466.115.121.1.26 )
	olcAttributeTypes: {6}( 1.3.6.1.4.1.15953.9.1.7 NAME 'sudoRunAsGroup' DESC 'Group(s) impersonated by sudo' EQUALITY caseExactIA5Match SYNTAX 1.3.6.1.4.1.1466.115.121.1.26 )
	olcAttributeTypes: {7}( 1.3.6.1.4.1.15953.9.1.8 NAME 'sudoNotBefore' DESC 'Start of time interval for which the entry is valid' EQUALITY generalizedTimeMatch ORDERING generalizedTimeOrderingMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.24 )
	olcAttributeTypes: {8}( 1.3.6.1.4.1.15953.9.1.9 NAME 'sudoNotAfter' DESC 'End of time interval for which the entry is valid' EQUALITY generalizedTimeMatch ORDERING generalizedTimeOrderingMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.24 )
	olcAttributeTypes: {9}( 1.3.6.1.4.1.15953.9.1.10 NAME 'sudoOrder' DESC 'an integer to order the sudoRole entries' EQUALITY integerMatch ORDERING integerOrderingMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.27 )
	olcObjectClasses: {0}( 1.3.6.1.4.1.15953.9.2.1 NAME 'sudoRole' DESC 'Sudoer Entries' SUP top STRUCTURAL MUST cn MAY ( sudoUser $ sudoHost $ sudoCommand $ sudoRunAs $ sudoRunAsUser $ sudoRunAsGroup $ sudoOption $ sudoOrder $ sudoNotBefore $ sudoNotAfter $ description ) )

Ahora en el Servidor de OpenLDAP, crearemos una, sudoers Organization Unit (ou)::

	vim sudoers.ldif

	dn: ou=sudo,dc=dominio,dc=local
	objectClass: organizationalUnit
	objectClass: top
	ou: sudo
	description: my-demo LDAP SUDO Entry
	
Aplicamos el archivo LDIF::

	$ ldapadd -x -D cn=Manager,dc=dominio,dc=local -W -f sudoers.ldif
	Enter LDAP Password: 
	adding new entry "ou=sudo,dc=dominio,dc=local"
	
Creamos los defaults LDIF::

	$ vim defaults.ldif
	dn: cn=defaults,ou=sudo,dc=dominio,dc=local
	objectClass: sudoRole
	objectClass: top
	cn: defaults
	sudoOption: env_reset
	sudoOption: mail_badpass
	sudoOption: secure_path=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin
	#sudoOrder: 1
	
Aplicamos los cambios::

	$ ldapadd -x -D cn=Manager,dc=dominio,dc=local -W -f defaults.ldif
	Enter LDAP Password: 
	adding new entry "cn=defaults,ou=sudo,dc=dominio,dc=local"
	
Finalmente, agregamos el role al usuario::

	$ vim sudo_user.ldif
	dn: cn=testuser,ou=sudo,dc=dominio,dc=local
	objectClass: sudoRole
	objectClass: top
	cn: testuser
	sudoCommand: ALL
	sudoHost: ALL
	sudoRunAsUser: ALL
	sudoUser: testuser
	#sudoOrder: 2

Recuerda cambiar el testuser con un usuario valido en el Servidor de OpenLDAP.
Puede tambien configurar el comando exacto de sudo que se quiere permitir para el usuario. Ejemplo::

	sudoCommand: /usr/sbin/useradd
	
Si se quiere se puede tener el NOPASSWD OpenLDAP SUDO, agregue la siguiente linea::

	sudooption: !authenticate

Ahora agregamos el LDIF al Servidor OpenLDAP::

	sudo ldapadd -x -D cn=Manager,dc=dominio,dc=local -W -f sudo_user.ldif
	
Una vez agregado, regresamos al Cliente OpenLDAP y modificamos el siguiente archivo::

	##On the LDAP client##
	vim /etc/nsswitch.conf
	
Y en el archivo, agregamos esta linea::

	sudoers: files sss
	
Una vez aplicadas las modificaciones, reiniciamos el servicio::

	systemctl restart sssd

Ahora probamos si sudo fue agregado al usuario::	

	[Carlos.Gomez.LAPF37H10J] ➤ ssh testuser@192.168.0.13
	testuser@192.168.0.13's password:
	X11 forwarding request failed on channel 0
	Last login: Fri Aug 11 23:48:05 2023 from 192.168.0.1
	[testuser@ldapclient ~]$ id
	uid=2000(testuser) gid=2000(testuser) groups=2000(testuser) context=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023
	[testuser@ldapclient ~]$ sudo bash
	[sudo] password for testuser:
	[root@ldapclient testuser]# id
	uid=0(root) gid=0(root) groups=0(root) context=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023
	[root@ldapclient testuser]#

