Ciphers fuertes en OpenLDAP - CentOS7
==============================================


Las cadenas de cifrado para openldap/NSS deben seguir un formato específico como se documenta en el artículo Cadenas de cifrado con openldap/NSS


Strongest available ciphers only::

    olcTLSCipherSuite: ECDHE-RSA-AES256-SHA384:AES256-SHA256:!RC4:HIGH:!MD5:!EDH:!EXP:!SSLV2:!eNULL


Ciphers - de valores alternativos
-----------------------------------

Strongest ciphers only::

   olcTLSCipherSuite: EECDH:EDH:CAMELLIA:ECDH:RSA:!eNULL:!SSLv2:!RC4:!DES:!EXP:!SEED:!IDEA:!3DES

Allow very old clients::

   olcTLSCipherSuite:  ALL:!ADH:!EXPORT:!SSLv2:RC4+RSA:+HIGH:+MEDIUM:+LOW


Para deshabilitar SSLv3 en OpenLDAP se debe crear en el directorio "/etc/openldap/slapd.d" el siguiente archivo ::

	cat > ciphersuite.ldif <<EOF
	dn: cn=config
	changetype: modify
	add: olcTLSCipherSuite
	olcTLSCipherSuite: ECDHE-RSA-AES256-SHA384:AES256-SHA256:!RC4:HIGH:!MD5:!EDH:!EXP:!SSLV2:!eNULL
	EOF

Luego se debe ejecutar el siguiente comando para agregar la configuración al LDAP::

	ldapmodify -Y EXTERNAL -H ldapi:/// -f ciphersuite.ldif

	SASL/EXTERNAL authentication started
	SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
	SASL SSF: 0
	modifying entry "cn=config"

Consultamos utilizando el comando::

	nmap --script ssl-enum-ciphers -p636 192.168.75.139 (Ip o hostname del equipo)

		Starting Nmap 6.40 ( http://nmap.org ) at 2023-06-21 09:26 -04
		Nmap scan report for 192.168.75.139
		Host is up (0.000053s latency).
		PORT    STATE SERVICE
		636/tcp open  ldapssl
		| ssl-enum-ciphers:
		|   TLSv1.2:
		|     ciphers:
		|       TLS_RSA_WITH_AES_128_CBC_SHA - strong
		|       TLS_RSA_WITH_AES_128_CBC_SHA256 - strong
		|       TLS_RSA_WITH_AES_128_GCM_SHA256 - strong
		|       TLS_RSA_WITH_AES_256_CBC_SHA - strong
		|       TLS_RSA_WITH_AES_256_CBC_SHA256 - strong
		|       TLS_RSA_WITH_AES_256_GCM_SHA384 - strong
		|       TLS_RSA_WITH_CAMELLIA_128_CBC_SHA - strong
		|       TLS_RSA_WITH_CAMELLIA_256_CBC_SHA - strong
		|     compressors:
		|       NULL
		|_  least strength: strong

	Nmap done: 1 IP address (1 host up) scanned in 0.35 seconds
