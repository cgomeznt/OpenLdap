
LDAP DB maintenance
====================

Confirmar transacciones activas almacenadas en la base de datos cada media noche::

  * 0 * * * /usr/bin/db_checkpoint -1 -h /var/lib/ldap

Eliminar archivos de registro inactivos diez minutos después medianoche::

  10 0 * * * /usr/bin/db_archive -d -h /var/lib/ldap

