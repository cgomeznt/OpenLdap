#!/bin/bash
#
# Script para modificar usuarios en el directorio LDAP
#
# Reynaldo Martinez P - Gotic-ccun
# Marzo del 2011
#


PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

#
# Verifico si el usuario ejecutor es root. Si no es root, se aborta !!
#

amiroot=`whoami`

case $amiroot in
root)
        echo ""
        ;;
*)
	echo ""
        echo "ALERTA: Solo el usuario root puede ejecutar este script"
        echo "abortando"
        echo ""
        exit 0
        ;;
esac

#
# Llamo a mi libreria de funciones comunes para todos los scripts
#
. /usr/local/ldapprovision/libs/functions.sh


#
# Variables basicas usadas por el script y existentes en functions.sh
#
# configdir="/usr/local/ldapprovision/etc"
# libsdir="/usr/local/ldapprovision/libs"
# tmpsdir="/usr/local/ldapprovision/tmp"
# binduser=`/bin/cat $configdir/readonlybindusr.txt`
# bindpass=`/bin/cat $configdir/readonlybindusrpass.txt`
# searchbase=`/bin/cat $configdir/searchbase.txt`
# baseuidnumber=`/bin/cat $configdir/baseuid.txt`
# basegidnumber=`/bin/cat $configdir/basegid.txt`
# ldapserver=`/bin/cat $configdir/ldap-server.txt`
# reserveduidlist="$configdir/reserved-accounts.txt"
# reservedgidlist="$configdir/reserved-groups.txt"
# usrtemplate="$libsdir/ldap-template-user.txt"
# usrtemplatemod="$libsdir/ldap-template-user-modify.txt"
# grptemplate="$libsdir/ldap-template-group.txt"
# grptemplatemod="$libsdir/ldap-template-group-modify.txt"
# sudotemplates="$configdir/sudoprofiles"

realname=$1
homedir=$2
group=$3
passexpire=$4
account=$5
password=$6
passchgforce=$7
cryptmode=$8
template=$9

amiroot=`whoami`

case $amiroot in
root)
	echo ""
	;;
*)
	echo "ALERTA: Solo el usuario root puede ejecutar este script"
	echo "abortando"
	echo ""
	exit 0
	;;
esac

case $1 in
"-h"|"-H"|"--help"|"--ayuda"|"--HELP"|"--ayuda"|"/?"|"?")
	echo ""
	helpusermod
	echo ""
	exit 0
esac

if [ -z "$1" ]
then
	echo ""
	echo "Debe espeficiar el nombre real"
	echo "Si tiene dudas sobre el uso del script use la ayuda:"
	echo "usermod-ldap --help"
	echo "Abortando"
	echo ""
	exit 0
fi

if [ -z "$2" ]
then
	echo ""
	echo "Debe espeficicar el directorio de usuario"
	echo "Abortando"
	echo ""
	exit 0
fi

if [ -z "$3" ]
then
	echo ""
	echo "Debe especificar el grupo"
	echo "Abortando"
	echo ""
	exit 0
fi

if [ -z "$4" ]
then
	echo ""
	echo "Debe especificar la duracion en dias del password"
	echo "Abortando"
	echo ""
	exit 0
fi

if [ -z "$5" ]
then
	echo ""
	echo "Debe especificar la cuenta de usuario"
	echo "Abortando"
	echo ""
	exit 0
fi

if [ -z "$6" ]
then
	echo ""
	echo "Debe especificar el password"
	echo "Abortando"
	echo ""
	exit 0
fi

if [ -z "$7" ]
then
	echo ""
	echo "Debe especificar si va a forzar el cambio de passwod"
	echo "en el primer login.. debe colocar force"
	echo "para obligar el cambio de password"
	echo ""
	exit 0
fi

if [ -z "$8" ]
then
        echo ""
        echo "Debe especificar crypt o clear para el tipo de password"
        echo ""
fi

# passcrypt=`slappasswd -c {CRYPT} -s $6`

case $cryptmode in
clear|CLEAR)
        passcrypt=`slappasswd -c {CRYPT} -s $password`
        ;;
crypt|CRYPT)
        passcrypt="{CRYPT}$password"
        ;;
*)
        echo ""
        echo "La opcion debe ser o \"clear\" o \"crypt\""
        echo "Abortando..."
        echo ""
        exit 0
        ;;
esac


echo ""
echo "Nombre Real: $1"
echo "Directorio: $2"
echo "grupo: $3"
echo "Duracion pass: $4"
echo "Cuenta: $5"
echo "Password (plain): $6"
echo "Password (crypt): $passcrypt"
echo ""

userexist=`checkuserexist $account`
groupexist=`checkgroupexist $group`
uidreserved=`checkreserveduid $account`
gidreserved=`checkreservedgid $group`

if [ $gidreserved == 1 ]
then
        echo ""
        echo "ALERTA ALERTA !!. El grupo \"$group\" esta en lista de reservados para"
        echo "uso interno del sistema operativo"
        echo "Abortando operacion"
        echo ""
        exit 0
fi


if [ $userexist == 0 ]
then
	echo ""
	echo "ALERTA ALERTA !!. El usuario \"$account\" no existe en LDAP"
	echo "no se puede modificar un usuario que no existe !!"
	echo "Abortando operacion"
	echo ""
	exit 0
fi

if [ $groupexist == 0 ]
then
	echo ""
	echo "ALERTA ALERTA !!. No existe el grupo \"$group\" en LDAP"
	echo "El grupo \"$group\" debe ser creado antes del usuario"
	echo "Abortando operacion"
	echo ""
	exit 0
fi

cp $usrtemplatemod $tmpsdir/account-modify.$account.ldiff

myldiff="$tmpsdir/account-modify.$account.ldiff"

# cat $myldiff

case $passchgforce in
force|FORCE)
	lastchange="0"
	;;
*)
	lastchange=`echo \`date +%s\`"/(3600*24)"|bc`
	;;
esac

myuid=`getuidnumber $account`
mygid=`getgidnumber $group`

echo "UID para $account: $myuid"
echo "GID para $account: $mygid"

sed -r -i "s/USERNAME/$account/" $myldiff
sed -r -i "s/COMPLETENAME/$realname/" $myldiff
sed -r -i "s/MAXDAYS/$passexpire/" $myldiff
sed -r -i "s/DATE/$lastchange/" $myldiff
sed -r -i "s/UIDNUMBER/$myuid/" $myldiff
sed -r -i "s/GIDNUMBER/$mygid/" $myldiff
echo "replace: homeDirectory" >> $myldiff
echo "homeDirectory: $homedir" >> $myldiff
echo "-" >> $myldiff
echo "replace: userPassword" >> $myldiff
echo "userPassword: $passcrypt" >> $myldiff
echo "-" >> $myldiff

case $template in
template|TEMPLATE)
	echo ""
	echo "Archivo LDIFF creado en $myldiff"
	echo "Opcion \"template\" utilizada"
	echo "El usuario no fue modificado en el directorio"
	echo "proceso finalizado en este punto...."
	echo ""
	exit 0
esac

echo ""
echo "Modificando entrada en el directorio"

modentryinladp $myldiff

rm $myldiff
echo "Enlistando nueva data para el usuario \"$account\":"
echo ""
listentrydatauser "uid=$account"
echo ""
