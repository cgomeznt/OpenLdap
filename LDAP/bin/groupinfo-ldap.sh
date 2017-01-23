#!/bin/bash
#
# Script para mostrar informacion de un grupo en el directorio LDAP
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
        echo "Debe espeficiar el grupo"
        echo "Si tiene dudas sobre el uso del script use la ayuda:"
        echo "groupinfo-ldap --help"
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
        helpgroupinfo
        echo ""
        exit 0
esac

group=$1

checkgroup=`checkgroupexist $group`

if [ $checkgroup == "0" ]
then
        echo ""
        echo "El grupo \"$group\" NO EXISTE en el directorio LDAP"
        echo "abortando operacion"
        echo ""
        exit 0
fi

groupgid=`getgidnumber $group`

echo ""
echo "Informacion para el grupo $group"

echo ""
listentrydatagroup "cn=$group"
echo ""
echo "Los siguientes usuarios pertenencen al grupo \"$group\":"
echo ""
ldapsearch -x -b ou=users,$searchbase -D $binduser -w $bindpass gidnumber=$groupgid uid|grep "uid:"
echo ""
