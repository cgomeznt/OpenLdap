Agregar esquemas al OpenLDAP
================================

Para cargar los schemas authldap.schema y qmail.schema.
para authldap.schema podemos instalar courier-ldap y luego copiarlo de /usr/share/doc/courier-authlib-ldap/authldap.schema.gz o descargarlo de "https://github.com/toddr/courier/blob/master/courier-authlib/authldap.schema"
si instalamos el courier-ldap hariamos esto::

	# gunzip -d /usr/share/doc/courier-authlib-ldap/authldap.schema.gz -c > /etc/ldap/schema/authldap.schema
	# ls schema/
	# vi schema/authldap.schema  <--- le cargamos todo el contenido del authldap.schema que descargamos
	# vi schema/qmail.schema  <--- le cargamos todo el contenido del qmail.schema que descargamos

creamos un fichero schema.convert y copiamos el siguiente texto en su interior con los esquemas a incluir::

	include /etc/ldap/schema/core.schema
	include /etc/ldap/schema/cosine.schema
	include /etc/ldap/schema/nis.schema
	include /etc/ldap/schema/inetorgperson.schema
	include /etc/ldap/schema/qmail.schema
	include /etc/ldap/schema/authldap.schema

Convertimos los ficheros de esquema a ficheros ldif::

	# mkdir ldif_out
	# slaptest -f schema.convert -F ldif_out/
	config file testing succeeded
	# ls ldif_out/cn\=config/cn\=schema/
	cn={0}core.ldif    cn={2}nis.ldif      cn={4}qmail.ldif
	cn={1}cosine.ldif  cn={3}inetorgperson.ldif  cn={5}authldap.ldif

Esto convertirá los ficheros a formato ldif, pero tendremos que editarlo antes de poder importarlo::

	# vi ldif_out/cn\=config/cn\=schema/cn\=\{5\}authldap.ldif
	y cambiamos las primeras entradas para que coincidan con las siguientes
	dn: cn=authldap,cn=schema,cn=config
	...
	cn: authldap

	# vi ldif_out/cn\=config/cn\=schema/cn\=\{4\}qmail.ldif
	y cambiamos las primeras entradas para que coincidan con las siguientes
	dn: cn=qmail,cn=schema,cn=config
	...
	cn: qmail

y borramos las siguientes líneas del final de los fichero "cn\=\{4\}qmail.ldif y cn\=\{5\}authldap.ldif" (el contenido numérico variará dependiendo de la fecha, hora, en la que se realice la conversión.::

	structuralObjectClass: olcSchemaConfig
	entryUUID: 8344f43c-9d7c-102e-8f0e-f3f0ff664b39
	creatorsName: cn=config
	createTimestamp: 20100124213810Z
	entryCSN: 20100124213810.691146Z#000000#000#000000
	modifiersName: cn=config
	modifyTimestamp: 20100124213810Z

Finalmente cargamos los esquemas en OpenLDAP::

	# ldapadd -Q -Y EXTERNAL -H ldapi:/// -f ldif_out/cn\=config/cn\=schema/cn\=\{4\}qmail.ldif
	adding new entry "cn=qmail,cn=schema,cn=config"
	# ldapadd -Q -Y EXTERNAL -H ldapi:/// -f ldif_out/cn\=config/cn\=schema/cn\=\{5\}authldap.ldif
	adding new entry "cn=authldap,cn=schema,cn=config"
