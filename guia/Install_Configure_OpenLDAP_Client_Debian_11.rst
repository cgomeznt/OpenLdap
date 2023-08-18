Configurar un cliente OpenLDAP en Debian 11
=======================================================

Una vez estemos seguro que el SO esta actualizado set el hostname::

	hostnamectl set-hostname ldapclient2.dominio.local sudo
	
Ahora actualizamos el archivo /etc/hosts::

	$ vi /etc/hosts
	##OpenLDAP server
	192.168.0.21 ldapmaster.dominio.local

	##OpenLDAP Client RHEL 8
	192.168.0.200 ldapclient.dominio.local
	
	##OpenLDAP Client Debian 11
	192.168.0.201 ldapclient2.dominio.local
	
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

	apt install sssd libpam-sss libnss-sss sssd-tools libsss-sudo

			   
Step 2 – Configurar el Cliente OpenLDAP y el servicio de SSSD
-------------------------------------------------------

Podmos configurar el cliente de OpenLDAP y el servicio de SSSD. Para iniciar la configuracion del Cliente OpenLDAP::

	vi /etc/ldap/ldap.conf
	
Dentro del archivo, definimos el Server de OpenLDAP y el Dominio a buscar en la Base de Datos::

	URI ldap://ldapmaster.dominio.local
	BASE dc=dominio,dc=local
	SUDOERS_BASE ou=sudo,dc=dominio,dc=local
	
La ultima linea es para el acceso SUDO, que luego estaremos configurando más adelante::

	vi /etc/sssd/sssd.conf
	
Agregamos las siguientes lineas al archivo y remplazamos el  ‘ldap_uri‘, ‘ldap_search_base‘ y ‘sudoers_base‘ apropiadamente::

	[domain/default]
	id_provider = ldap
	autofs_provider = ldap
	auth_provider = ldap
	chpass_provider = ldap
	ldap_uri = ldap://ldapmaster.dominio.local
	ldap_search_base = dc=dominio,dc=local
	#sudoers_base ou=sudo,dc=dominio,dc=local
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

Para ver el LOG::

	 tail -f /var/log/sssd/sssd.log

La siguiente configuración es para que el Pluggable Authentication Module (PAM) al hacer inicio de sesión se cree el home directory de dicho usuario.

Esta edicion se realiza en el archivo /etc/pam.d/common-session::

	vi /etc/pam.d/common-session

Agregue la siguiente linea justo debajo de la linea, session optional pam_sss.so::

	session required        pam_mkhomedir.so skel=/etc/skel/ umask=0022
	
Quedaria algo como esto::

	...
	# since the modules above will each just jump around
	session required pam_permit.so
	# and here are more per-package modules (the "Additional" block)
	session required pam_unix.so 
	session optional pam_sss.so 
	session required        pam_mkhomedir.so skel=/etc/skel/ umask=0022
	session optional pam_systemd.so 
	# end of pam-auth-update config


Step 3 – Probar la autenticación del Cliente OpenLDAP Authentication
--------------------------------------------------------------------

Una vez se haya completado las configuraciones, podremos realizar pruebas, podemos realizar pruebas con los usuarios disponibles en el Servidor de OpenLDAP.

Buscamos los usuarios disponibles en el servidor de OpenLDAP::

	ldapsearch -x -b "ou=people,dc=dominio,dc=local"
	

Es posible utilizar el SSH::

	ssh testuser@192.168.0.201
	
Ejemplo de la salida del comando anterior::

	[Carlos.Gomez.LAPF37H10J] ➤ ssh testuser@192.168.0.201
	testuser@192.168.0.201's password:
	Creating directory '/home/testuser'.
	Linux ldapclient2.dominio.local 5.10.0-24-amd64 #1 SMP Debian 5.10.179-5 (2023-08-08) x86_64
	
	The programs included with the Debian GNU/Linux system are free software;
	the exact distribution terms for each program are described in the
	individual files in /usr/share/doc/*/copyright.
	
	Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
	permitted by applicable law.
	/usr/bin/xauth:  file /home/testuser/.Xauthority does not exist
	testuser@ldapclient2:~$
	
	testuser@ldapclient2:~$ id
	uid=2000(testuser) gid=2000(testuser) groups=2000(testuser)
	testuser@ldapclient2:~$

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

	vi sudoers.ldif

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

	$ vi defaults.ldif
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

	$ vi sudo_user.ldif
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

	ldapadd -x -D cn=Manager,dc=dominio,dc=local -W -f sudo_user.ldif
	
Una vez agregado, regresamos al Cliente OpenLDAP y modificamos el siguiente archivo::

	##On the LDAP client##
	vim /etc/nsswitch.conf
	
Y en el archivo, agregamos esta linea::

	sudoers: files sss
	
Una vez aplicadas las modificaciones, reiniciamos el servicio::

	systemctl restart sssd

Ahora probamos si sudo fue agregado al usuario, recuerda que debes tener instalado **sudo**::	

	[Carlos.Gomez.LAPF37H10J] ➤ ssh testuser@192.168.0.201
	testuser@192.168.0.201's password:
	Linux ldapclient2.dominio.local 5.10.0-24-amd64 #1 SMP Debian 5.10.179-5 (2023-08-08) x86_64
	
	The programs included with the Debian GNU/Linux system are free software;
	the exact distribution terms for each program are described in the
	individual files in /usr/share/doc/*/copyright.
	
	Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
	permitted by applicable law.
	Last login: Fri Aug 18 01:22:10 2023 from 192.168.0.1
	testuser@ldapclient2:~$
	testuser@ldapclient2:~$ sudo bash
	[sudo] password for testuser:
	root@ldapclient2:/home/testuser# id
	uid=0(root) gid=0(root) groups=0(root)
	root@ldapclient2:/home/testuser#


