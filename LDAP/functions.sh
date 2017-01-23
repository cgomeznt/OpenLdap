#!/bin/bash
#
# Funciones para directorio LDAP de autenticacion de servidores
#
# Reynaldo Martinez P - Gotic-ccun
# Marzo del 2011
#

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

#
# Variables basicas usadas por el script
#
configdir="/usr/local/ldapprovision/etc"
libsdir="/usr/local/ldapprovision/libs"
tmpsdir="/usr/local/ldapprovision/tmp"
binduser=`/bin/cat $configdir/readwritebindusr.txt`
bindpass=`/bin/cat $configdir/readwritebindusrpass.txt`
searchbase=`/bin/cat $configdir/searchbase.txt`
baseuidnumber=`/bin/cat $configdir/baseuid.txt`
basegidnumber=`/bin/cat $configdir/basegid.txt`
ldapserver=`/bin/cat $configdir/ldap-server.txt`
reserveduidlist="$configdir/reserved-accounts.txt"
reservedgidlist="$configdir/reserved-groups.txt"
usrtemplate="$libsdir/ldap-template-user.txt"
usrtemplatemod="$libsdir/ldap-template-user-modify.txt"
grptemplate="$libsdir/ldap-template-group.txt"
grptemplatemod="$libsdir/ldap-template-group-modify.txt"
sudotemplates="$configdir/sudoprofiles"
passtemplate="$libsdir/ldap-template-user-pass.txt"

# 
# Function para obtener el ultimo UID-Number en el directorio
#
function lastuidnumber(){
	myuid=`ldapsearch -x -b $searchbase -h $ldapserver -D $binduser -w $bindpass objectclass=shadowAccount uidnumber|grep -i uidNumber|grep -v requesting|awk '{print $2}'|sort|uniq|sort -r|head -n 1`
	if [ -z $myuid ]
	then
		echo $baseuidnumber
	elif [ $myuid -lt $baseuidnumber ]
	then
		echo $baseuidnumber
	else
		echo $myuid
	fi
}

#
# Funcion para obtener el ultimo GID-Number en el directorio
#
function lastgidnumber(){
	mygid=`ldapsearch -x -b $searchbase -h $ldapserver -D $binduser -w $bindpass objectclass=posixGroup gidnumber|grep -i gidNumber|grep -v requesting|awk '{print $2}'|sort|uniq|sort -r|head -n 1`
	if [ -z $mygid ]
	then
		echo $basegidnumber
	elif [ $mygid -lt $basegidnumber ]
	then
		echo $basegidnumber
	else
		echo $mygid
	fi
}

#
# Funcion para validar si un usuario existe
#
function checkuserexist(){
	mystatusuid=`ldapsearch -x -b ou=users,$searchbase -h $ldapserver -D $binduser -w $bindpass uid=$1|grep -c ^dn:.\*uid=$1`
	echo $mystatusuid
}

#
# Funcion para validar si un grupo existe
#
function checkgroupexist(){
	ldapsearch -x -b ou=groups,$searchbase -h $ldapserver -D $binduser -w $bindpass cn=$1|grep -c ^cn:.\*$1
}

#
# Funcion para validar si un perfil sudo existe
#
function checksudoprofileexist(){
	ldapsearch -x -b ou=sudoers,$searchbase -h $ldapserver -D $binduser -w $bindpass cn=$1|grep -c ^cn:.\*$1
}

#
# Funcion para revisar si la cuenta esta reservada
#
function checkreserveduid(){
	cat $reserveduidlist|grep -c ^$1$
}

#
# Funcion para revisar si el grupo esta reservado
#
function checkreservedgid(){
	cat $reservedgidlist|grep -c ^$1$
}

#
# Funcion para obtener el gidNumber de un grupo
#
function getgidnumber(){
	ldapsearch -x -b ou=groups,$searchbase -h $ldapserver -D $binduser -w $bindpass cn=$1 gidNumber|grep gidNumber:|awk '{print $2}'
}

#
# Funcion para obtener el uidNumber de un usuario
#
function getuidnumber(){
	ldapsearch -x -b ou=users,$searchbase -h $ldapserver -D $binduser -w $bindpass uid=$1 uidNumber|grep -i uidNumber:|awk '{print $2}'
}

#
# Funcion para obtener el gidNumber de un usuario
#
function getusergidnumber(){
	 ldapsearch -x -b ou=users,$searchbase -h $ldapserver -D $binduser -w $bindpass uid=$1 gidNumber|grep -i gidNumber:|awk '{print $2}'
}

#
# Function para obtener el cn de un grupo basado en el gidNUmber
#
function getgroupcn(){
	ldapsearch -x -b ou=groups,$searchbase -h $ldapserver -D $binduser -w $bindpass gidNumber=$1|grep -i "cn:"|awk '{print $2}'
}

#
# Funcion para obtener la data de un grupo
#
function listentrydatagroup(){
	ldapsearch -x -b ou=groups,$searchbase -h $ldapserver -D $binduser -w $bindpass $1 |grep ":"|grep -v "\#"|egrep -v '(search:|result:)'
}

#
# Funcion para obtener la data de un usuario
#
function listentrydatauser(){
        ldapsearch -x -b ou=users,$searchbase -h $ldapserver -D $binduser -w $bindpass $1 |grep ":"|grep -v "\#"|egrep -v '(search:|result:)'
}

#
# Funcion para obtener la data de un perfil sudo
#
function listentrydatasudoprofile(){
	ldapsearch -x -b ou=sudoers,$searchbase -h $ldapserver -D $binduser -w $bindpass $1 |grep ":"|grep -v "\#"|egrep -v '(search:|result:)'
}

#
# Funcion para agregar un LDIFF al directorio
#
function addentrytoladp(){
	ldapadd -x -D $binduser -w $bindpass -h $ldapserver -f $1
}

#
# Funcion para agregar un LDIFF al directorio en modo modificacion
#
function modentryinladp(){
        ldapmodify -x -D $binduser -w $bindpass -h $ldapserver -f $1
}

#
# Funcion para eliminar una entrada en el directorio
#
function deleteentryonldap(){
	ldapdelete -x -D $binduser -w $bindpass -h $ldapserver $1
}

#
# Funcion de ayuda para comando useradd-ldap
#
helpuseradd(){
	echo ""
	echo "Comando useradd-ldap"
	echo ""
	echo "El comando requiere 8 parametros obligatorios y acepta un noveno opcional:"
	echo "1.- Nombre real del usuario"
	echo "2.- Directorio \"home\" del usuario"
	echo "3.- Grupo (ya existente) del usuario"
	echo "4.- Dias de expiracion del password"
	echo "5.- Nombre de la cuenta"
	echo "6.- Password de la cuenta"
	echo "7.- Forzar cambio de password en el primer login - coloce la palabra \"force\""
	echo "8.- Modo de password - crypt o clear"
	echo "9.- template: Si existe este parametro y se llama template, solo se crea el LDIFF"
	echo "TODOS los parametros deben venir entre comillas simples"
	echo ""
	echo "Ejemplo:"
	echo "./useradd-ldap.sh 'Pepe Trueno' '/var/users/ptrueno' 'looneytunes' '30' 'ptrueno' 'P@ssw0rd' 'force' 'clear'"
	echo "./useradd-ldap.sh 'Pepe Trueno' '/var/users/ptrueno' 'looneytunes' '30' 'ptrueno' 'P@ssw0rd' 'noforce' 'clear' 'template'"
	echo ""
}

#
# Funcion de ayuda para comando userdel-ldap
#
helpuserdel(){
	echo ""
	echo "Comando userdel-ldap"
	echo ""
	echo "El comando requiere como unico parametro obligatorio el login del usuario:"
	echo "./userdel-ldap.sh ptrueno"
	echo ""
	echo "El comando soporta el parametro opcional \"-y\". Este parametro forza la"
	echo "eliminacion del usuario sin preguntar por confirmacion:"
	echo ""
	echo "./userdel-ldap.sh ptrueno -y"
	echo ""
}

#
# Funcion de ayuda para comando groupadd-ldap
#
helpgroupadd(){
	echo ""
	echo "Comando groupadd-ldap"
	echo ""
	echo "El comando soporta dos parametros obligatorios y uno opcional:"
	echo "TODOS los parametros deben ir entre comillas simples"
	echo "1.- Descripcion del Grupo"
	echo "2.- Nombre del grupo"
	echo "3.- template: Si existe este parametro y se llama template solo se crea el ldiff"
	echo ""
	echo "ejemplo:"
	echo "./groupadd-ldap.sh 'Loneey Tunes Inc.' 'looneytunes'"
	echo "./groupadd-ldap.sh 'Loneey Tunes Inc.' 'looneytunes' 'template'"
	echo ""
}

#
# Funcion de ayuda para comando groupdel-ldap
#
helpgroupdel(){
        echo ""
        echo "Comando groupdel-ldap"
        echo ""
        echo "El comando requiere como unico parametro obligatorio el grupo a eliminar:"
        echo "./groupdeldel-ldap.sh looneytunes"
        echo ""
        echo "El comando soporta el parametro opcional \"-y\". Este parametro forza la"
        echo "eliminacion del grupo sin preguntar por confirmacion:"
        echo ""
        echo "./groupdel-ldap.sh looneytunes -y"
        echo ""
}

#
# Funcion de ayuda para comando usermod-ldap
#
helpusermod(){
        echo ""
        echo "Comando usermod-ldap"
        echo ""
        echo "El comando requiere 8 parametros obligatorios y acepta un noveno opcional:"
        echo "1.- Nombre real del usuario"
        echo "2.- Directorio \"home\" del usuario"
        echo "3.- Grupo (ya existente) del usuario"
        echo "4.- Dias de expiracion del password"
        echo "5.- Nombre de la cuenta"
        echo "6.- Password de la cuenta"
        echo "7.- Forzar cambio de password en el primer login - coloce la palabra \"force\""
	echo "8.- Modo de password - crypt o clear"
        echo "9.- template: Si existe este parametro y se llama template, solo se crea el LDIFF"
        echo "TODOS los parametros deben venir entre comillas simples"
        echo ""
        echo "Ejemplo:"
        echo "./usermod-ldap.sh 'Pepe Trueno' '/var/users/ptrueno' 'looneytunes' '30' 'ptrueno' 'P@ssw0rd' 'force' 'clear'"
        echo "./usermod-ldap.sh 'Pepe Trueno' '/var/users/ptrueno' 'looneytunes' '30' 'ptrueno' 'P@ssw0rd' 'noforce' 'clear' 'template'"
        echo ""
	echo "NOTA: El usuario DEBE existir en el directorio"
	echo ""
}

#
# Funcion de ayuda para comando groupadd-ldap
#
helpgroupmod(){
        echo ""
        echo "Comando groupmod-ldap"
        echo ""
        echo "El comando soporta dos parametros obligatorios y uno opcional:"
        echo "TODOS los parametros deben ir entre comillas simples"
        echo "1.- Descripcion del Grupo"
        echo "2.- Nombre del grupo"
        echo "3.- template: Si existe este parametro y se llama template solo se crea el ldiff"
        echo ""
        echo "ejemplo:"
        echo "./groupmod-ldap.sh 'Loneey Tunes Inc.' 'looneytunes'"
        echo "./groupmod-ldap.sh 'Loneey Tunes Inc.' 'looneytunes' 'template'"
        echo ""
	echo "NOTA: El grupo DEBE existir en el directorio"
	echo ""
}

#
# Funcion de ayuda para comando userinfo-ldap
#
helpuserinfo(){
	echo ""
	echo "Comando userinfo-ldap.sh"
	echo ""
	echo "Requiere como parametro obligatorio el nombre de usuario"
	echo ""
	echo "Ejemplo:"
	echo "./userinfo-ldap.sh ptrueno"
	echo ""
}

#
# Funcion de ayuda para comando groupinfo-ldap
#
helpgroupinfo(){
        echo ""
        echo "Comando groupinfo-ldap.sh"
        echo ""
        echo "Requiere como parametro obligatorio el nombre del grupo"
        echo ""
        echo "Ejemplo:"
        echo "./groupinfo-ldap.sh looneytunes"
        echo ""
}

#
# Funcion de ayuda para comando sudoprofileinfo-ldap
#
helpsudoprofileinfo(){
	echo ""
	echo "Comando sudoprofileinfo-ldap.sh"
	echo ""
	echo "Requiere como parametro obligatorio el nombre del perfil sudo"
	echo ""
	echo "Ejemplo:"
	echo "./sudoprofileinfo-ldap.sh %looneytunes"
	echo ""
}

#
# Funcion de ayuda para comando ldiff2dir-add.sh 
#
helpldiff2diradd(){
	echo ""
	echo "Comando ldiff2dir-add.sh"
	echo ""
	echo "El comando requiere como parametro obligatorio el archivo LDIFF"
	echo "que sera agregado en el directorio"
	echo "El archivo debe haber sido generado previamente por los comandos"
	echo "useradd-ldap.sh o groupadd-ldap.sh con la opcion \"template\""
	echo "Si coloca como segunda opcion \"-y\" no se pedira confirmacion"
	echo ""
	echo "Ejemplo:"
	echo "./ldiff2dir-add.sh /usr/local/ldapprovision/tmp/group-creation.looneytunes.ldif"
	echo "./ldiff2dir-add.sh /usr/local/ldapprovision/tmp/user-creation.ptrueno.ldif -y"
	echo ""
}

#
# Funcion de ayuda para comando ldiff2dir-mod.sh 
#
helpldiff2dirmod(){
        echo ""
        echo "Comando ldiff2dir-mod.sh"
        echo ""
        echo "El comando requiere como parametro obligatorio el archivo LDIFF"
        echo "que sera agregado en el directorio en modo MODIFY"
        echo "El archivo debe haber sido generado previamente por los comandos"
        echo "usermod-ldap.sh o groupmod-ldap.sh con la opcion \"template\""
	echo "Si coloca como segunda opcion \"-y\" no se pedira confirmacion"
        echo ""
        echo "Ejemplo:"
        echo "./ldiff2dir-mod.sh /usr/local/ldapprovision/tmp/group-modify.looneytunes.ldif"
        echo "./ldiff2dir-mod.sh /usr/local/ldapprovision/tmp/user-modify.ptrueno.ldif -y"
        echo ""
}

#
# Funcion para comando sudoprofileadd-ldap.sh
#
helpsudoprofileadd(){
	echo ""
	echo "Comando sudoprofileadd-ldap.sh"
	echo ""
	echo "El comando requiere dos parametros obligatorios:"
	echo "1.- Nombre del perfil sudo (grupo o usuario)"
	echo "2.- Nombre de la plantilla a usar"
	echo "Las plantillas se ubican en el directorio \"$sudotemplates\""
	echo ""
	echo "Ejemplos"
	echo "./sudoprofileadd-ldap.sh %looneytunes sudotemplate-profile-1.txt"
	echo "./sudoprofileadd-ldap.sh ptrueno sudotemplate-profile-2.txt"
	echo "El primer ejemplo agregar el perfil para el grupo looneytunes mientras que"
	echo "el segundo agrega un perfil para un usuario"
	echo ""
	echo "El script crea la plantilla en el directorio \"$tmpsdir\" en formato LDIFF"
	echo "Luego se debe llamar al comando \"ldiff2dir-add.sh\" para incluir los datos"
	echo "en el directorio LDAP."
	echo ""
}

#
# Funcion para ayuda comando sudoprofiledel-ldap.sh
#
helpsudoprofiledel(){
	echo ""
	echo "Comando sudoprofiledel-ldap.sh"
	echo ""
	echo "El comando requiere un solo parametro obligatorio y soporta"
	echo "un parametro opcional"
	echo ""
	echo "1.- Nombre del perfil sudo entre comillas simples"
	echo "2.- (opcional) - \"-y\" para no preguntar por confirmacion"
	echo ""
	echo "Ejemplos:"
	echo "./sudoprofiledel-ldap.sh 'ptrueno'"
	echo "./sudoprofiledel-ldap.sh 'ptrueno' -y"
	echo "./sudoprofiledel-ldap.sh '%looneytunes'"
	echo "./sudoprofiledel-ldap.sh '%looneytunes' -y"
	echo ""
}

#
# Funcion de ayuda para comando password-ldap.sh
#
helppassword(){
	echo ""
	echo "Comando password-ldap.sh"
	echo ""
	echo "El comando requiere tres parametros y soporta uno opcional"
	echo ""
	echo "1.- Nombre de usuario"
	echo "2.- Modo de password - debe ser \"crypt\" o \"clear\"."
	echo "3.- Password (en clear o crypt dependiendo de la opcion anterior)"
	echo "4.- (opcional) template - crea un template en lugar de ejecutar el cambio".
	echo ""
	echo "Ejemplo:"
	echo "./password-ldap.sh ptrueno clear 'P@ssw0rd'"
	echo "./password-ldap.sh ptrueno crypt '\$1\$h864ApI1\$0yWfJSh5Ek2Dhj8gXfWBp1' template"
	echo "NOTA: El password siempre debe ir entre comillas simples".
	echo ""
}

#
#
#
