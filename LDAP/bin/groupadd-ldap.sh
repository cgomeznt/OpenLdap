#!/bin/bash
#
# Script para agregar grupos al directorio LDAP
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
        helpgroupadd
        echo ""
        exit 0
esac

if [ -z "$1" ]
then
        echo ""
        echo "Debe espeficiar la descripcion del grupo"
        echo "Si tiene dudas sobre el uso del script use la ayuda:"
        echo "groupadd-ldap --help"
        echo "Abortando"
        echo ""
        exit 0
fi

if [ -z "$2" ]
then
        echo ""
        echo "Debe espeficicar el nombre unix del grupo"
        echo "Abortando"
        echo ""
        exit 0
fi

grpdesc=$1
grpname=$2
template=$3


groupexist=`checkgroupexist $grpname`
gidreserved=`checkreservedgid $grpname`

if [ $gidreserved == "1" ]
then
	echo ""
	echo "ALERTA: Grupo reservado por el sistema"
	echo "abortando..."
	echo ""
	exit 0
fi

if [ $groupexist == "1" ]
then
	echo ""
	echo "ALERTA: El grupo \"$grpname\" ya existe en el directorio LDAP"
	echo "abortando..."
	echo ""
	exit 0
fi

lastgid=`lastgidnumber`
newgid=$[lastgid+1]


echo ""
echo "Grupo: $grpname"
echo "Descripción: $grpdesc"
echo "GID: $newgid "
echo ""

cp $grptemplate $tmpsdir/group-creation.$grpname.ldif

myldiff="$tmpsdir/group-creation.$grpname.ldif"

sed -r -i "s/GROUPNAME/$grpname/" $myldiff
sed -r -i "s/GROUPDESC/$grpdesc/" $myldiff
sed -r -i "s/GIDNUMBER/$newgid/" $myldiff

case $template in
template|TEMPLATE)
        echo ""
        echo "Archivo LDIFF creado en $myldiff"
        echo "Opcion \"template\" utilizada"
        echo "El grupo no fue agregado al directorio"
        echo "proceso finalizado en este punto...."
        echo ""
        exit 0
esac

echo ""
echo "Agregando entrada al directorio"

addentrytoladp $myldiff

checkgroup=`checkgroupexist $grpname`

if [ $checkgroup == 1 ]
then
        rm $myldiff
        echo ""
        echo "Grupo \"$grpname\" agregado al directorio LDAP"
        echo "Proceso terminado"
        echo ""
else
        echo ""
        echo "ALERTA !!. No se pudo agregar el grupo al directorio LDAP"
        echo ""
fi

