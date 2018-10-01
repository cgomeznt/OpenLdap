Respaldo y Restauracion de OpenLDAP II
=====================================

Hay dos formas de hacer respaldo a un OpenLDAP, (backup de la BD backend o DUMP a un LDIF).
Importante recordar que los nombres DNS, hosts deben estar tal cual como estaba antes.

Respaldando
+++++++++++++++++

Aquí vamos a utilizar la técnica del DUMP a un LDIF

Hacemos el respaldo de la configuracion del LDAP.::

	slapcat -v -n 0 -l /opt/respaldoLDAP/config.diff

Hacemos el respaldo de la DATA del LDAP.::

	slapcat -v -n 2 -l /opt/respaldoLDAP/data2.diff

Restauración
+++++++++++++++

Para hacer la Recuperacion o restauracion es:
Detenemos el servicio del LDAP.::

	systemctl stop slapd
 
Realizamos respaldo del directorio obsoleto slapd.d.::

	# ls -ld /etc/openldap/slapd.d
	drwxr-xr-x 3 ldap ldap 4096 Jul 16 06:57 /etc/openldap/slapd.d
	
	# mv /etc/openldap/slapd.d /etc/openldap/slapd.d.`date '+%Y-%m-%d'`
	#mkdir /etc/openldap/slapd.d

Ahora recreamos la configuración con slapadd.::

	# slapadd -n 0 -F /etc/openldap/slapd.d -l /opt/respaldoLDAP/config.ldif

Otorgamos los permisos correspondientes.::

	# chown -R ldap:ldap /etc/openldap/slapd.d

Restauramos la DATA.::

	# ls -ld /var/lib/ldap
	drwxr-xr-x 3 ldap ldap 4096 Jul 16 06:57 /var/lib/ldap
	
	# mv /var/lib/ldap /var/lib/ldap`date '+%Y-%m-%d'`
	# mkdir /var/lib/ldap

	# slapadd -n 2 -F /etc/openldap/slapd.d -l /opt/respaldoLDAP/data2.ldif

Otorgamos los permisos correspondientes.::

	# chown -R ldap:ldap /var/lib/ldap

Culmina la restauración, iniciamos el servicio de LDAP.::

	# systemctl start slapd
 
NOTA: Si utiliza alguna replicap debe agregar -wi para que el otro server pueda sincronizar, ejemplo.::

	slapadd -n 2 -F /etc/openldap/slapd.d -l /opt/respaldoLDAP/data2.ldif -w
