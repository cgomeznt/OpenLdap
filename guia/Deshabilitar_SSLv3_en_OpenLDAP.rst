Deshabilitar SSLv3 en OpenLDAP - CentOS7
==============================================

Para deshabilitar SSLv3 en OpenLDAP se debe crear en el directorio "/etc/openldap/slapd.d" el siguiente archivo ::

	cat > nossl.ldif <<EOF
	dn: cn=config
	changetype: modify
	add: olcTLSProtocolMin
	olcTLSProtocolMin: 3.2
	EOF

Luego se debe ejecutar el siguiente comando para agregar la configuración al LDAP::

	ldapmodify -Y EXTERNAL -H ldapi:/// -f nossl.ldif

	SASL/EXTERNAL authentication started
	SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
	SASL SSF: 0
	modifying entry "cn=config"

Con esto se deshabilita el SSLv3 y se deja habilitado TLSv1.1/TLSv1.2, lo podemos consultar utilizando el comando::

	nmap --script ssl-enum-ciphers -p636 192.168.75.137 (Ip o hostname del equipo)

	Starting Nmap 6.40 ( http://nmap.org ) at 2023-06-08 11:43 -04
	Nmap scan report for 192.168.75.137
	Host is up (0.000092s latency).
	PORT    STATE SERVICE
	636/tcp open  ldapssl
	| ssl-enum-ciphers:
	|   TLSv1.1:
	|     ciphers:
	|       TLS_RSA_WITH_3DES_EDE_CBC_SHA - strong
	|       TLS_RSA_WITH_AES_128_CBC_SHA - strong
	|       TLS_RSA_WITH_AES_256_CBC_SHA - strong
	|       TLS_RSA_WITH_CAMELLIA_128_CBC_SHA - strong
	|       TLS_RSA_WITH_CAMELLIA_256_CBC_SHA - strong
	|       TLS_RSA_WITH_IDEA_CBC_SHA - weak
	|       TLS_RSA_WITH_RC4_128_MD5 - strong
	|       TLS_RSA_WITH_RC4_128_SHA - strong
	|       TLS_RSA_WITH_SEED_CBC_SHA - strong
	|     compressors:
	|       NULL
	|   TLSv1.2:
	|     ciphers:
	|       TLS_RSA_WITH_3DES_EDE_CBC_SHA - strong
	|       TLS_RSA_WITH_AES_128_CBC_SHA - strong
	|       TLS_RSA_WITH_AES_128_CBC_SHA256 - strong
	|       TLS_RSA_WITH_AES_128_GCM_SHA256 - strong
	|       TLS_RSA_WITH_AES_256_CBC_SHA - strong
	|       TLS_RSA_WITH_AES_256_CBC_SHA256 - strong
	|       TLS_RSA_WITH_AES_256_GCM_SHA384 - strong
	|       TLS_RSA_WITH_CAMELLIA_128_CBC_SHA - strong
	|       TLS_RSA_WITH_CAMELLIA_256_CBC_SHA - strong
	|       TLS_RSA_WITH_IDEA_CBC_SHA - weak
	|       TLS_RSA_WITH_RC4_128_MD5 - strong
	|       TLS_RSA_WITH_RC4_128_SHA - strong
	|       TLS_RSA_WITH_SEED_CBC_SHA - strong
	|     compressors:
	|       NULL
	|_  least strength: weak

	Nmap done: 1 IP address (1 host up) scanned in 0.36 seconds

Si se requiere dejar unicamente TLSv1.2 podemos modificar el archivo "nossl.ldif"  cambiando el campo "add" por "replace" y colocando olcTLSProtocolMin: 3.3 como aparece a continuación::

	cat > nossl.ldif <<EOF
	dn: cn=config
	changetype: modify
	replace: olcTLSProtocolMin
	olcTLSProtocolMin: 3.3
	EOF

Luego se vuelve a ejecutar el comando::

	ldapmodify -Y EXTERNAL -H ldapi:/// -f nossl.ldif

	SASL/EXTERNAL authentication started
	SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
	SASL SSF: 0
	modifying entry "cn=config"

Se realiza la consulta nuevamente usando el comando::

	nmap --script ssl-enum-ciphers -p636 192.168.75.137 (Ip o hostname del equipo)

	Starting Nmap 6.40 ( http://nmap.org ) at 2023-06-08 11:44 -04
	Nmap scan report for 192.168.75.137
	Host is up (0.00011s latency).
	PORT    STATE SERVICE
	636/tcp open  ldapssl
	| ssl-enum-ciphers:
	|   TLSv1.2:
	|     ciphers:
	|       TLS_RSA_WITH_3DES_EDE_CBC_SHA - strong
	|       TLS_RSA_WITH_AES_128_CBC_SHA - strong
	|       TLS_RSA_WITH_AES_128_CBC_SHA256 - strong
	|       TLS_RSA_WITH_AES_128_GCM_SHA256 - strong
	|       TLS_RSA_WITH_AES_256_CBC_SHA - strong
	|       TLS_RSA_WITH_AES_256_CBC_SHA256 - strong
	|       TLS_RSA_WITH_AES_256_GCM_SHA384 - strong
	|       TLS_RSA_WITH_CAMELLIA_128_CBC_SHA - strong
	|       TLS_RSA_WITH_CAMELLIA_256_CBC_SHA - strong
	|       TLS_RSA_WITH_IDEA_CBC_SHA - weak
	|       TLS_RSA_WITH_RC4_128_MD5 - strong
	|       TLS_RSA_WITH_RC4_128_SHA - strong
	|       TLS_RSA_WITH_SEED_CBC_SHA - strong
	|     compressors:
	|       NULL
	|_  least strength: weak

	Nmap done: 1 IP address (1 host up) scanned in 0.33 seconds
