#!/bin/bash
#
# Script para agregar un LDIFF en el directorio LDAP
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
        echo "Debe espeficiar el archivo LDIFF"
        echo "Si tiene dudas sobre el uso del script use la ayuda:"
        echo "ldiff2dir-add.sh --help"
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
        helpldiff2diradd
        echo ""
        exit 0
esac

if [ -f $1 ]
then
	echo ""
	echo "Procesando archivo LDIFF $1"
	echo ""
else
	echo ""
	echo "No existe el archivo $1"
	echo "abortando operacion..."
	echo ""
	exit 0
fi

case $2 in
        "-y"|"-Y")
        answer="y"
        ;;
        *)
        echo -n "Desea agregar el LDIFF \"$1\" ? [y/n]:"
        read -n 1 answer
        echo ""
        ;;
esac

# echo -n "Desea agregar el LDIFF \"$1\" ? [y/n]:"
# read -n 1 answer
# echo ""

case $answer in
"y"|"Y")
	echo ""
	echo "Agregando $1 al directorio LDAP"
	echo ""
	;;
*)
	echo ""
	echo "Abortado por el administrador"
	echo ""
	exit 0
	;;
esac

#grep "dn:" ../tmp/group-creation.looneytunes.ldif|cut -d: -f2|cut -d, -f1
mydnis=`grep "dn:" $1|cut -d: -f2|cut -d, -f1|awk '{print $1}'`

mydnexist=`ldapsearch -x -b $searchbase -D $binduser -w $bindpass $mydnis|grep -c dn:`

if [ $mydnexist == 0 ]
then
        echo "Procesando dn: $mydnis"
        echo ""
else
        echo "ALERTA ALERTA !!. El dn \"$mydnis\" YA existe en el directorio LDAP"
        echo "abortando el resto de la operacion"
        echo ""
        exit 0
fi

realmodify=`grep -c changetype:.\*modify $1`

if [ $realmodify == 1 ]
then
        echo "ALERTA: El archivo es para un MODIFY de LDAP"
        echo "abortando el resto de la operacion"
        echo ""
        exit 0
fi


addentrytoladp $1

echo ""
echo "La entrada \"$mydnis\" se muestra a continuacion:"
echo ""
ldapsearch -x -b $searchbase -D $binduser -w $bindpass $mydnis|grep ":"|grep -v "\#"|egrep -v '(search:|result:)'
echo ""

