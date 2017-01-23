#!/bin/bash
#
# Script para agregar perfiles sudo al directorio LDAP
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

case $1 in
"-h"|"-H"|"--help"|"--ayuda"|"--HELP"|"--ayuda"|"/?"|"?")
        echo ""
        helpsudoprofileadd
        echo ""
        exit 0
esac

if [ -z "$1" ]
then
        echo ""
        echo "Debe espeficiar el nombre del grupo SUDO"
        echo "Si tiene dudas sobre el uso del script use la ayuda:"
        echo "sudoprofileadd-ldap --help"
        echo "Abortando"
        echo ""
        exit 0
fi

if [ -z "$2" ]
then
	echo ""
	echo "Debe especificar la plantilla SUDO a usar"
	echo "La plantilla debe existir en el directorio siguiente:"
	echo "\"$sudotemplates\""
	echo ""
	exit 0
fi

mytemplate="$sudotemplates/$2"

if [ -f $mytemplate ]
then
	echo ""
	echo "Procesando nuevo perfil sudo \"$1\" con la siguiente plantilla:"
	echo "\"$mytemplate\""
	echo ""
else
	echo ""
	echo "No existe el archivo $mytemplate"
	echo "Abortando.."
	echo ""
	exit 0
fi

mynewsudoprofile="$tmpsdir/sudoprofile-$1.ldiff"

cp $mytemplate $mynewsudoprofile

sed -r -i "s/PROFILE/$1/" $mynewsudoprofile

echo "Fue creada la plantilla SUDO siguiente:"
echo "\"$mynewsudoprofile\""
echo "Revise su plantilla y agreguela com el comando siguiente:"
echo ""
echo "ldiff2dir-add.sh $mynewsudoprofile"
echo ""
