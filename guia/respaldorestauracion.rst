Respaldo y Restauracion de OpenLDAP
=====================================

Copie este archivo que es util para los respaldos.::

	# cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG

Si quiere omitir el warning.::
	
	# slapcat -b "dc=dominio,dc=local" -l /root/ldap-respaldo.ldif

Para Respaldar
+++++++++++++++
.::

	# /usr/sbin/slapcat -v -l /home/backup/ldap.diff

Script.::

	#!/bin/sh
	LDAPBK=ldap-$( date +%y%m%d-%H%M ).ldif
	BACKUPDIR=/home/backups
	/usr/sbin/slapcat -v -b "dc=dominio,dc=local" -l $BACKUPDIR/$LDAPBK
	gzip -9 $BACKUPDIR/$LDAPBK

Para Restaurar
++++++++++++++

stop slapd.::
# /etc/init.d/slapd stop

Borrar la base de datos anterior.::

	# cd /var/lib/ldap
	# rm -rf *

Restaurar la Base de Datos con el LDIF.::

	# /usr/sbin/slapadd -l backup.ldif

Iniciar slapd.::

	# /etc/init.d/slapd start

NOTA: los permisos de /var/lib/ldap es importante.::

	# ls -ld /var/lib/ldap
	drwx------ 2 ldap ldap 4096 dic 27 20:49 /var/lib/ldap

	# ls -l /var/lib/ldap
	total 1136
	-rw-r--r-- 1 ldap ldap     4096 dic 27 20:49 alock
	-rw------- 1 ldap ldap     8192 dic 27 19:54 cn.bdb
	-rw------- 1 ldap ldap    24576 dic 27 20:49 __db.001
	-rw------- 1 ldap ldap   188416 dic 27 20:49 __db.002
	-rw------- 1 ldap ldap   270336 dic 27 20:49 __db.003
	-rw------- 1 ldap ldap    98304 dic 27 20:09 __db.004
	-rw------- 1 ldap ldap   753664 dic 27 20:49 __db.005
	-rw------- 1 ldap ldap    32768 dic 27 20:49 __db.006
	-rw-r--r-- 1 ldap ldap      921 dic 27 20:47 DB_CONFIG
	-rw------- 1 ldap ldap     8192 dic 27 19:54 dn2id.bdb
	-rw------- 1 ldap ldap    32768 dic 27 19:54 id2entry.bdb
	-rw------- 1 ldap ldap 10485760 dic 27 20:09 log.0000000001
	-rw------- 1 ldap ldap     8192 dic 27 19:54 objectClass.bdb
	-rw------- 1 ldap ldap     8192 dic 27 19:54 ou.bdb
	-rw------- 1 ldap ldap     8192 dic 27 19:54 sn.bdb
	-rw------- 1 ldap ldap     8192 dic 27 19:54 uid.bdb

