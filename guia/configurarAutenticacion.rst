Configuración de OpenLDAP como servidor de autenticación.
=========================================================

Equipamiento lógico necesario.
+++++++++++++++++++++++++++++++

1- openldap-clients-2.x
2- openldap-servers-2.x
3- authconfig
4- authconfig-gtk (opcional)
5- migrationtools

Instalación a través de yum.
++++++++++++++++++++++++++++
.::

	# yum --disablerepo=\* --enablerepo=c6-media install -y openldap openldap-clients openldap-servers \
	nss-pam-ldapd authconfig authconfig-gtk \
	migrationtools

Procedimientos.
+++++++++++++++

SELinux y el servicio ldap.
+++++++++++++++++++++++++++

El servicio slapd funcionará perfectamente con SELinux activo en modo de imposición (enforcing).

Todo el contenido del directorio /var/lib/ldap debe tener contexto tipo slapd_db_t.::

	# chcon -R -t slapd_db_t /var/lib/ldap

Lo anterior solo será necesario si se restaura un respaldo hecho a partir de un sistema sin SELinux.


Certificados para TLS/SSL.
++++++++++++++++++++++++++

Es muy importante utilizar TLS/SSL cuando se configura el sistema para fungir como servidor de autenticación, por lo cual el siguiente procedimiento es obligatorio.

Genere el directorio /etc/openldap/cacerts::

	# mkdir -p /etc/openldap/cacerts
	# cd /etc/openldap/cacert

OpenLDAP requiere primero genera una nueva autoridad certificadora. Ejecute lo siguiente::

De este juego de archivos se debe compartir cacert.pem con todos los clientes LDAP que se conectarán al servidor. Copie este archivo dentro del directorio raíz del servidor HTTP o FTP y configure los permisos de acceso para que sea accesible desde estos servicios.::

	# cp cacert.pem /var/www/html/
	# chmod 644 /var/www/html/cacert.pem

A continuación genere el certificado y firma digital para el servidor. Cabe señalar que la forma digital que será utilizada por OpenLDAP será una tipo RSA sin contraseña en formato PEM generada a partir de una firma digital con contraseña. Ejecute lo siguiente::

Configure todos los permisos necesarios para que sólo root y el grupo ldap puedan hacer uso de los certificados y firma digital. Ejecute lo siguiente.::

	# cacertdir_rehash /etc/openldap/cacert/

Genere los enlaces necesarios para el directorio /etc/openldap/cacerts::

	# chown -R root:ldap /etc/openldap/cacerts
	# chmod -R u=rwX,g=rX,o= /etc/openldap/cacerts

Edite el archivo /etc/sysconfig/ldap::

	# vi /etc/sysconfig/ldap

Alrededor de la línea 20, localice #SLAPD_LDAPS=no::

	#SLAPD_LDAPS=no

Elimine la almohadilla (#) y cambie no por yes, de modo que quede como SLAPD_LDAPS=yes.::

	SLAPD_LDAPS=yes

Creación de directorios.

Con fines de organización se creará un directorio específico para este directorio y se configurará con permisos de acceso exclusivamente al usuario y grupo ldap.::

	# mkdir /var/lib/ldap/autenticar
	# chmod 700 /var/lib/ldap/autenticar

Se requiere copiar el archivo DB_CONFIG.example dentro del directorio /var/lib/ldap/autenticar/, como el archivo DB_CONFIG. Es decir, ejecute lo siguiente::

	# cp /usr/share/openldap-servers/DB_CONFIG.example \
		/var/lib/ldap/autenticar/DB_CONFIG

Todo el contenido del directorio /var/lib/ldap/autenticar debe pertenecer al usuario y grupo ldap. Ejecute lo siguiente::

	# chown -R ldap:ldap /var/lib/ldap/autenticar

Creación de claves de acceso para LDAP.

Para crear la clave de acceso que se asignará en LDAP para el usuario administrador del directorio, ejecute lo siguiente::

	# slappasswd

Lo anterior debe devolver como salida un criptograma, similar al mostrado a continuación::

	{SSHA}Cl8vAItE3D32MLfaJfMoYTsKpUHZi831

Copie y respalde este criptograma. El texto de la salida será utilizado más adelante en el archivo /etc/openldap/slapd.conf y se definirá como clave de acceso para el usuario Manager, quien tendrá todos los privilegios sobre el directorio.

Archivo de configuración /etc/openldap/slapd.conf.

Se debe crear /etc/openldap/slapd.conf como archivo nuevo::

	# touch /etc/openldap/slapd.conf
	# vi /etc/openldap/slapd.conf

El archivo /etc/openldap/slapd.conf debe de tener definidos todos los archivos de esquema mínimos requeridos. De tal modo, el inicio del archivo debe contener algo similar a lo siguiente::

	include         /etc/openldap/schema/corba.schema
	include         /etc/openldap/schema/core.schema
	include         /etc/openldap/schema/cosine.schema
	include         /etc/openldap/schema/duaconf.schema
	include         /etc/openldap/schema/dyngroup.schema
	include         /etc/openldap/schema/inetorgperson.schema
	include         /etc/openldap/schema/java.schema
	include         /etc/openldap/schema/misc.schema
	include         /etc/openldap/schema/nis.schema
	include         /etc/openldap/schema/openldap.schema
	include         /etc/openldap/schema/ppolicy.schema
	include         /etc/openldap/schema/collective.schema
	include         /etc/openldap/schema/pmi.schema

Se deben habilitar las opciones TLSCACertificateFile, TLSCertificateFile y TLSCertificateKeyFile estableciendo como valores de éstas las rutas hacia el certificados y firma digital.::

	TLSCACertificateFile /etc/openldap/cacert/cacert.pem
	TLSCertificateFile /etc/openldap/cacert/cert.pem
	TLSCertificateKeyFile /etc/openldap/cacert/key.pem

A fin de permitir conexiones desde clientes con OpenLDAP 2.x, establecer el archivo de número de proceso y el archivo de argumentos de LDAP, deben estar presentes las siguientes opciones, con los correspondientes valores::

	allow bind_v2
	pidfile         /var/run/openldap/slapd.pid
	argsfile        /var/run/openldap/slapd.args

Para concluir con el /etc/openldap/slapd.conf, se añade lo siguiente, que tiene como finalidad el definir la configuración del nuevo directorio que en adelante se utilizará para autenticar a toda la red de área local::

	database	bdb
	suffix		"dc=dominio,dc=tld"
	rootdn		"cn=Manager,dc=dominio,dc=tld"
	rootpw       {SSHA}Cl8vAItE3D32MLfaJfMoYTsKpUHZi83
	directory	/var/lib/ldap/autenticar

	# Indices a mantener para esta base de datos
	index objectClass                       eq,pres
	index ou,cn,mail,surname,givenname      eq,pres,sub
	index uidNumber,gidNumber,loginShell    eq,pres
	index uid,memberUid                     eq,pres,sub
	index nisMapName,nisMapEntry            eq,pres,sub

Por seguridad, el archivo /etc/openldap/slapd.conf deberá tener permisos de lectura y escritura, sólo para el usuario ldap.::

	# chown ldap:ldap /etc/openldap/slapd.conf
	# chmod 600 /etc/openldap/slapd.conf

Elimine el conjunto de archivos y directorios que componen los configuración predeterminada::

Es necesario crear los archivos base para el contenido del directorio /var/lib/ldap/autenticar, por tanto ejecute lo siguiente::

	# echo "" | slapadd -f /etc/openldap/slapd.conf

Todo el contenido de los directorios /etc/ldap/slapd.d y /var/lib/ldap/autenticar deben pertenecer al usuario y grupo ldap. Ejecute lo siguiente::

	# chown -R ldap:ldap \
    /etc/openldap/slapd.d \
    /var/lib/ldap/autenticar

Restablezca los contextos de SELinux para los directorios /etc/ldap/slapd.d y /var/lib/ldap/autenticar ejecutando lo siguiente::

	# restorecon -R \
    /etc/openldap/slapd.d \
    /var/lib/ldap/autenticar

Inicio del servicio.

Inicie el servicio slapd y añada éste al resto de los servicios que arrancan junto con el sistema, ejecutando los siguientes dos mandatos::

	# service slapd start
	# chkconfig slapd on

