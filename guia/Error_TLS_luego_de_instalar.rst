
OpenLDAP después de instalar no inicia por error de TLS
==========================================================

Luego de haber ejecutado la instalación cotidiana de OpenLDAP al tratar de iniciar con systemctl no iniciaba y al visualizar journalctl -xe se observa este error::

	ago 31 16:22:39 appserver slapd[7876]: main: TLS init def ctx failed: -1


Se corrige con la ejecución de los siguientes comandos::

	$ sudo /usr/libexec/openldap/create-certdb.sh
	$ sudo /usr/libexec/openldap/generate-server-cert.sh 
