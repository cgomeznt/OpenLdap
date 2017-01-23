#!/bin/bash
#
# Script para modificar password de usuarios en el directorio LDAP
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
# passtemplate="$libsdir/ldap-template-user-pass.txt"

account="$1"
cryptmode="$2"
password="$3"
template="$4"

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
	helppassword
	echo ""
	exit 0
esac

if [ -z "$1" ]
then
	echo ""
	echo "Debe espeficiar el nombre de usuario"
	echo "Si tiene dudas sobre el uso del script use la ayuda:"
	echo "password-ldap --help"
	echo "Abortando"
	echo ""
	exit 0
fi

if [ -z "$2" ]
then
	echo ""
	echo "Debe espeficicar el modo crypt - crypt o clear"
	echo "Abortando"
	echo ""
	exit 0
fi

if [ -z "$3" ]
then
	echo ""
	echo "Debe especificar el password, ya sea clear o crypt"
	echo "Abortando"
	echo ""
	exit 0
fi


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

echo "Password encriptado: \"$passcrypt\""


userexist=`checkuserexist $account`

if [ $userexist == 0 ]
then
	echo ""
	echo "ALERTA ALERTA !!. El usuario \"$account\" no existe en LDAP"
	echo "no se puede modificar el password de un usuario que no existe !!"
	echo "Abortando operacion"
	echo ""
	exit 0
fi


cp $passtemplate $tmpsdir/password-modify.$account.ldiff

myldiff="$tmpsdir/password-modify.$account.ldiff"


sed -r -i "s/USERNAME/$account/" $myldiff
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

echo "Enlistando nueva data para el usuario \"$account\":"
echo ""
listentrydatauser "uid=$account"
echo ""
