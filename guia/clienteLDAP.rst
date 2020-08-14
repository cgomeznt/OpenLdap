Configurar un cliente LDAP para que use un server LDAP
==========================================================

Con esto configuramos un Centos 7 para que se pueda autenticar con un server LDAP, con esta técnica permite que tenga usuarios locales que se puedan autenticar también y utilice los del LDAP.

Instalar los paquetes necesarios en un servidor cliente de LDAP, son 20 Mb aproximadamente::

	yum -y install authconfig openldap-clients nss-pam-ldapd


Permitimos la autenticación de usuarios con el servidor de LDAP, ejecutamos el siguiente comando para agregar el servidor cliente al LDAP para una simple sing-on. Remplace "192.168.1.5" con la IP del servidor LDAP o el hostname.::

	# authconfig --enableldap --enableldapauth --ldapserver=192.168.1.5 --ldapbasedn="dc=dominio,dc=local" --enablemkhomedir --update
	getsebool:  SELinux is disabled
	# 

Reiniciar el servicio del Cliente Server::

	systemctl restart  nslcd

Verificar el Login en el LDAP. Usaremos el comando getent para obtener las entradas del LDAP en el servidor LDAP::

	# getent passwd cgomez
	 cgomez:x:9999:100:cgomez [Admin (at) dominio]:/home/cgomez:/bin/bash
	[root@client01 ~]#


Ahora para verificar el usuario hacemos el inicio por ssh y colocamos la clave que esta almacenada en el LDAP server de este usuario::

	$ ssh cgomez@192.168.1.4
	cgomez@192.168.1.4's password: 
	Creating directory '/home/cgomez'.
	[cgomez@client01 ~]$ id
	uid=9999(cgomez) gid=100(users) grupos=100(users)

