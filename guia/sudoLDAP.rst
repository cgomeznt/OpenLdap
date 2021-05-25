Configurar SUDO via OpenLDAP Server
===================================

Configurar SUDO a través de OpenLDAP Server. Además de poder proporcionar derechos de sudo en un sistema local, sudo también se puede configurar a través de LDAP. Proporcionar SUDO a través de OpenLDAP elimina la necesidad de otorgar a los usuarios privilegios sudo a través del archivo sudoers del sistema local.

Configurar el schema SUDO en el servidor OpenLDAP
+++++++++++++++++++++++++++++++++++++++++++++++++++++++ 

Para configurar SUDO a través del servidor OpenLDAP, debe cargar y habilitar los esquemas sudo OpenLDAP. por favor ver **Agregar schema sudo a LDAP utilizando OLC**

Create OpenLDAP SUDOers Organization Unit (ou)
++++++++++++++++++++++++++++++++++++++++++++++++++

Antes de poder configurar SUDO a través de OpenLDAP Server, debe crear SUDOers en la estructura de directorios de su organización.::

	# vi sudoersou.ldif
	dn: ou=SUDOers,dc=dominio,dc=local
	objectclass: organizationalUnit
	ou: SUDOers
	description: Demo LDAP SUDO Entry


Crear entrada defaults en SUDOers OpenLDAP OU
+++++++++++++++++++++++++++++++++++++++++++++

De acuerdo con las páginas de manual de sudoers.ldap, sudo primero busca la entrada cn=defaults en la unidad organizativa SUDOers. Si se encuentra, el atributo sudoOption de valores múltiples se analiza de la misma manera que una línea predeterminada global en /etc/sudoers.


Convertir archivo sudoers a LDAP LDIF
+++++++++++++++++++++++++++++++++++++++

Se necesita convertir el archivo /etc/sudoers en formato LDIF y con este formato OpenLDAP lo podemos modificar a gusto.


OpenLDAP generalmente se envía con un script perl, sudoers2ldif, que se usa para convertir el archivo sudoers en un archivo LDIF de OpenLDAP.

También viene con otra herramienta llamada cvtsudoers que puede ayudarlo a lograr la misma tarea que el script sudoers2ldif.

Aqui esta el contenido del script sudoers2ldif::

	#!/usr/bin/env perl
	#
	# Copyright (c) 2007, 2010-2011, 2013 Todd C. Miller <Todd.Miller@courtesan.com>
	#
	# Permission to use, copy, modify, and distribute this software for any
	# purpose with or without fee is hereby granted, provided that the above
	# copyright notice and this permission notice appear in all copies.
	#
	# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
	# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
	# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
	# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
	# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
	# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
	# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
	#

	use strict;

	#
	# Converts a sudoers file to LDIF format in prepration for loading into
	# the LDAP server.
	#

	# BUGS:
	#   Does not yet handle multiple lines with : in them
	#   Does not yet remove quotation marks from options
	#   Does not yet escape + at the beginning of a dn
	#   Does not yet handle line wraps correctly
	#   Does not yet handle multiple roles with same name (needs tiebreaker)
	#
	# CAVEATS:
	#   Sudoers entries can have multiple RunAs entries that override former ones,
	#	with LDAP sudoRunAs{Group,User} applies to all commands in a sudoRole

	my %RA;
	my %UA;
	my %HA;
	my %CA;
	my $base=$ENV{SUDOERS_BASE} or die "$0: Container SUDOERS_BASE undefined\n";
	my @options=();

	my $did_defaults=0;
	my $order = 0;

	# parse sudoers one line at a time
	while (<>){

	  # remove comment
	  s/#.*//;

	  # line continuation
	  $_.=<> while s/\\\s*$//s;

	  # cleanup newline
	  chomp;

	  # ignore blank lines
	  next if /^\s*$/;

	  if (/^Defaults\s+/i) {
	    my $opt=$';
	    $opt=~s/\s+$//; # remove trailing whitespace
	    push @options,$opt;
	  } elsif (/^(\S+)\s+([^=]+)=\s*(.*)/) {

	    # Aliases or Definitions
	    my ($p1,$p2,$p3)=($1,$2,$3);
	    $p2=~s/\s+$//; # remove trailing whitespace
	    $p3=~s/\s+$//; # remove trailing whitespace

	    if ($p1 eq "User_Alias") {
	      $UA{$p2}=$p3;
	    } elsif ($p1 eq "Runas_Alias") {
	      $RA{$p2}=$p3;
	    } elsif ($p1 eq "Host_Alias") {
	      $HA{$p2}=$p3;
	    } elsif ($p1 eq "Cmnd_Alias") {
	      $CA{$p2}=$p3;
	    } else {
	      if (!$did_defaults++){
		# do this once
		print "dn: cn=defaults,$base\n";
		print "objectClass: top\n";
		print "objectClass: sudoRole\n";
		print "cn: defaults\n";
		print "description: Default sudoOption's go here\n";
		print "sudoOption: $_\n" foreach @options;
		printf "sudoOrder: %d\n", ++$order;
		print "\n";
	      }
	      # Definition
	      my @users=split /\s*,\s*/,$p1;
	      my @hosts=split /\s*,\s*/,$p2;
	      my @cmds= split /\s*,\s*/,$p3;
	      @options=();
	      print "dn: cn=$users[0],$base\n";
	      print "objectClass: top\n";
	      print "objectClass: sudoRole\n";
	      print "cn: $users[0]\n";
	      # will clobber options
	      print "sudoUser: $_\n"   foreach expand(\%UA,@users);
	      print "sudoHost: $_\n"   foreach expand(\%HA,@hosts);
	      foreach (@cmds) {
		if (s/^\(([^\)]+)\)\s*//) {
		  my @runas = split(/:\s*/, $1);
		  if (defined($runas[0])) {
		    print "sudoRunAsUser: $_\n" foreach expand(\%RA, split(/,\s*/, $runas[0]));
		  }
		  if (defined($runas[1])) {
		    print "sudoRunAsGroup: $_\n" foreach expand(\%RA, split(/,\s*/, $runas[1]));
		  }
		}
	      }
	      print "sudoCommand: $_\n" foreach expand(\%CA,@cmds);
	      print "sudoOption: $_\n" foreach @options;
	      printf "sudoOrder: %d\n", ++$order;
	      print "\n";
	    }

	  } else {
	    print "parse error: $_\n";
	  }

	}

	#
	# recursively expand hash elements
	sub expand{
	  my $ref=shift;
	  my @a=();

	  # preen the line a little
	  foreach (@_){
	    # if NOPASSWD: directive found, mark entire entry as not requiring
	    s/NOPASSWD:\s*// && push @options,"!authenticate";
	    s/PASSWD:\s*// && push @options,"authenticate";
	    s/NOEXEC:\s*// && push @options,"noexec";
	    s/EXEC:\s*// && push @options,"!noexec";
	    s/SETENV:\s*// && push @options,"setenv";
	    s/NOSETENV:\s*// && push @options,"!setenv";
	    s/LOG_INPUT:\s*// && push @options,"log_input";
	    s/NOLOG_INPUT:\s*// && push @options,"!log_input";
	    s/LOG_OUTPUT:\s*// && push @options,"log_output";
	    s/NOLOG_OUTPUT:\s*// && push @options,"!log_output";
	    s/[[:upper:]]+://; # silently remove other tags
	    s/\s+$//; # right trim
	  }

	  # do the expanding
	  push @a,$ref->{$_} ? expand($ref,split /\s*,\s*/,$ref->{$_}):$_ foreach @_;
	  @a;
	}


Crear una variable de entorno bash que defina la entrada de la unidad organizativa de SUDOers creada anteriormente.::

	export SUDOERS_BASE="ou=SUDOers,dc=dominio,dc=local"
	echo $SUDOERS_BASE


A continuación, convertir el archivo /etc/sudoers en un archivo LDAP ldif para crear la entrada SUDOers o predeterminada requerida.::

	perl sudoers2ldif /etc/sudoers > sudoers_defaults.ldif

Consultamos el contenido del archivo sudoers_defaults.ldif::

	cat sudoers_defaults.ldif

	dn: cn=defaults,ou=SUDOers,dc=dominio,dc=local
	objectClass: top
	objectClass: sudoRole
	cn: defaults
	description: Default sudoOption's go here
	sudoOption: !visiblepw
	sudoOption: always_set_home
	sudoOption: match_group_by_gid
	sudoOption: always_query_group_plugin
	sudoOption: env_reset
	sudoOption: env_keep =  "COLORS DISPLAY HOSTNAME HISTSIZE KDEDIR LS_COLORS"
	sudoOption: env_keep += "MAIL PS1 PS2 QTDIR USERNAME LANG LC_ADDRESS LC_CTYPE"
	sudoOption: env_keep += "LC_COLLATE LC_IDENTIFICATION LC_MEASUREMENT LC_MESSAGES"
	sudoOption: env_keep += "LC_MONETARY LC_NAME LC_NUMERIC LC_PAPER LC_TELEPHONE"
	sudoOption: env_keep += "LC_TIME LC_ALL LANGUAGE LINGUAS _XKB_CHARSET XAUTHORITY"
	sudoOption: secure_path = /sbin:/bin:/usr/sbin:/usr/bin
	sudoOrder: 1

	dn: cn=root,ou=SUDOers,dc=dominio,dc=local
	objectClass: top
	objectClass: sudoRole
	cn: root
	sudoUser: root
	sudoHost: ALL
	sudoRunAsUser: ALL
	sudoCommand: ALL
	sudoOrder: 2

	dn: cn=%wheel,ou=SUDOers,dc=dominio,dc=local
	objectClass: top
	objectClass: sudoRole
	cn: %wheel
	sudoUser: %wheel
	sudoHost: ALL
	sudoRunAsUser: ALL
	sudoCommand: ALL
	sudoOrder: 3

Como puede ver, el archivo sudoers en formato LDAP ldif contiene la unidad organizativa SUDOers, los atributos sudoOption de varios valores, el usuario raíz cn y el grupo de ruedas definido.


Atributos de sudo usados ​​arriba::

	sudoOption: Similar to Defaults option in /etc/sudoers file.
	For example, below are the /etc/sudoers options and how you can use them on LDAP SUDO:
		NOPASSWD: !authenticate
		PASSWD: authenticate
		NOEXEC: noexec
		EXEC: !noexec
		SETENV: setenv
		NOSETENV: !setenv
		LOG_INPUT: log_input
		NOLOG_INPUT: !log_input
		LOG_OUTPUT: log_output
		NOLOG_OUTPUT: !log_output

**sudoUser**: define un nombre de usuario, ID de usuario (prefijado con '#'), nombre o ID de grupo Unix (prefijado con '%' o '% #' respectivamente), grupo de red de usuario (prefijado con '+') o no Unix nombre de grupo o ID (con el prefijo '%:' o '%: #' respectivamente)

**sudoHost**: un nombre de host, dirección IP, red IP o grupo de red de host (con el prefijo "+") o TODO el valor para que coincida con cualquier host.

**sudoRunAsUser**: Un nombre de usuario o uid (con el prefijo '#') con el que se pueden ejecutar los comandos o un grupo Unix (con el prefijo '%') o un grupo de red de usuarios (con el prefijo '+') que contiene una lista de usuarios que se puede ejecutar como. TODO el valor coincide con cualquier usuario.

**sudoCommand**: especifica un nombre de comando de Unix completo con argumentos de línea de comando opcionales. Utilice TODO para hacer coincidir cualquier comando.


Por lo tanto, antes de actualizar la base de datos OpenLDAP con las configuraciones de SUDOers, puede modificar el archivo LDAP de SUDOers anterior.

Por ejemplo, elimine el usuario root definido y el grupo de wheel y agregue los usuarios a los que desea asignar derechos SUDO a través de LDAP en los clientes remotos.

Además, remita los atributos sudoOrder.::

	vi modified-sudoer2ldif.ldif

	dn: cn=defaults,ou=SUDOers,dc=dominio,dc=local
	objectClass: top
	objectClass: sudoRole
	cn: defaults
	description: Carlos-demo SUDO via LDAP
	sudoOption: !visiblepw
	sudoOption: always_set_home
	sudoOption: match_group_by_gid
	sudoOption: always_query_group_plugin
	sudoOption: env_reset
	sudoOption: env_keep =  "COLORS DISPLAY HOSTNAME HISTSIZE KDEDIR LS_COLORS"
	sudoOption: env_keep += "MAIL PS1 PS2 QTDIR USERNAME LANG LC_ADDRESS LC_CTYPE"
	sudoOption: env_keep += "LC_COLLATE LC_IDENTIFICATION LC_MEASUREMENT LC_MESSAGES"
	sudoOption: env_keep += "LC_MONETARY LC_NAME LC_NUMERIC LC_PAPER LC_TELEPHONE"
	sudoOption: env_keep += "LC_TIME LC_ALL LANGUAGE LINGUAS _XKB_CHARSET XAUTHORITY"
	sudoOption: env_keep+=SSH_AUTH_SOCK
	sudoOption: secure_path = /sbin:/bin:/usr/sbin:/usr/bin

	dn: cn=sudo,ou=SUDOers,dc=dominio,dc=local
	objectClass: top
	objectClass: sudoRole
	cn: sudo
	sudoUser: cgomez
	sudoHost: ALL
	sudoRunAsUser: ALL
	sudoCommand: ALL

	dn: cn=%wheel,ou=SUDOers,dc=dominio,dc=local
	objectClass: top
	objectClass: sudoRole
	cn: %wheel
	sudoUser: %wheel
	sudoHost: ALL
	sudoRunAsUser: ALL
	sudoCommand: ALL

En lo anterior, creamos una entrada llamada sudo en SUDOers ou y asignamos a un usuario llamado cgomez los derecho de SUDO para ejecutar todos los comandos como cualquier usuario en cualquier sistema, que es similar a la línea de abajo en el archivo /etc/sudoers.::

	cgomez ALL=(ALL:ALL) ALL

Tenga en cuenta que el usuario debe existir en la base de datos OpenLDAP.


Si necesita agregar otro usuario a la función anterior::

	vi add-new-user-sudo-role.ldif
	dn: cn=sudo,ou=SUDOers,dc=dominio,dc=local
	changetype: modify
	add: sudoUser
	sudoUser: jgoncalves

Lo introducimos en el LDAP::

	ldapmodify -Y EXTERNAL -H ldapi:/// -f add-new-user-sudo-role.ldif


Para crear un rol de sudo diferente, digamos para permitir que los usuarios ejecuten comandos específicos, vea a continuación. Los nombres de los roles pueden ser descriptivos.

Por ejemplo, para permitir que un usuario llamado bgomez ejecute el comando useradd solo con sudo, cree un archivo ldif como se muestra a continuación y actualice la base de datos OpenLDAP.::

	vi sudo-specific-cmd.ldif
	dn: cn=cmdrole,ou=SUDOers,dc=dominio,dc=local
	objectClass: top
	objectClass: sudoRole
	cn: cmdrole
	sudoUser: bgomez
	sudoHost: ALL
	sudoRunAsUser: ALL
	sudoCommand: /usr/sbin/useradd

Lo introducimos en el LDAP::

	ldapadd -Y EXTERNAL -H ldapi:/// -f sudo-specific-cmd.ldif

Configurar LDAP SUDO NOPASSWD
+++++++++++++++++++++++++++++

A veces es posible que desee permitir que algunos usuarios ejecuten el comando SUDO sin que se solicite la contraseña a ldap-sudo-nopasswd.

Para ello, puede utilizar la opción NOPASSWD OpenLDAP SUDO,!authenticate con el atributo sudoOption. Ver ejemplo a continuación::

	dn: cn=lsanche,ou=SUDOers,dc=dominio,dc=local
	cn: lsanche
	objectClass: top
	objectClass: sudoRole
	sudoCommand: ALL
	sudoHost: ALL
	sudoOption: !authenticate
	sudoRunasUser: ALL
	sudoUser: lsanche

Este usuario ejecutará todos los comandos SUDO sin contraseña.

Para listar la SUDOers OU, simplemente ejecute::

	export SUDOERS_BASE=ou=SUDOers,dc=dominio,dc=local

	ldapsearch -b "$SUDOERS_BASE" -D cn=ldapadm,dc=dominio,dc=local -W -x sudoUser

En el Cliente LDAP
++++++++++++++++++++

Agregamos unas lineas en el archivo /etc/sudo-ldap.conf::

	vi /etc/sudo-ldap.conf
	# agregar las siguientes lineas 
	uri ldap://192.168.1.5
	sudoers_base ou=SUDOers,dc=dominio,dc=local

Tambien editamos y agregamos las lineas en el archivo /etc/nsswitch.conf::

	vi /etc/nsswitch.conf
	# Agregar esta linea
	sudoers: files ldap


Links utilizados:
https://kifarunix.com/how-to-configure-sudo-via-openldap-server/
https://forums.centos.org/viewtopic.php?t=73807&p=311162
