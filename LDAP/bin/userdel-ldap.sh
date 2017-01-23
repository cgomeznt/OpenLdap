#!/bin/bash
#
# Script para eliminar usuarios en el directorio LDAP
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

if [ -z "$1" ]
then
        echo ""
        echo "Debe espeficiar el usuario"
        echo "Si tiene dudas sobre el uso del script use la ayuda:"
        echo "userdel-ldap --help"
        echo "Abortando"
        echo ""
        exit 0
fi


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

case $1 in
"-h"|"-H"|"--help"|"--ayuda"|"--HELP"|"--ayuda"|"/?"|"?")
        echo ""
        helpuserdel
        echo ""
        exit 0
esac


account=$1

checkuser=`checkuserexist $account`

if [ $checkuser == "1" ]
then
	echo ""
	echo "Usuario \"$account\" existe en el directorio LDAP"
else
	echo ""
	echo "El usuario \"$account\" NO EXISTE en el directorio LDAP"
	echo "abortando operacion"
	echo ""
	exit 0
fi

case $2 in
	"-y"|"-Y")
	answer="y"
	;;
	*)
	echo -n "Desea borrar el usuario \"$account\" ? [y/n]:"
	read -n 1 answer
	echo ""
	;;
esac

# echo -n "Desea borrar el usuario \"$account\" ? [y/n]:"
# read -n 1 answer
# echo ""
# echo "answer is $answer"

case $answer in
y|Y)
	echo ""
	echo "Eliminando usuario \"$account\" del directorio LDAP"
	echo ""
	;;
*)
	echo ""
	echo "El usuario \"$account\" no fue eliminado - abortado por el admin"
	echo ""
	exit 0
esac

# Se llama a la funcion para eliminar la entrada

deleteentryonldap "uid=$account,ou=users,$searchbase"

checkuseragain=`checkuserexist $account`

if [ $checkuseragain == "1" ]
then
	echo ""
	echo "No pudo eliminarse el usuario \"$account\""
	echo ""
else
	echo ""
	echo "El usuario \"$account\" fue eliminado exitosamente del directorio LDAP"
	echo ""
fi

