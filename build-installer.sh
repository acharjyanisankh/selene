#!/bin/bash

app_name='selene'
app_fullname='Selene'
tgz="../../pbuilder/"
dsc="../../builds/${app_name}*.dsc"
libs="../../libs"

backup=`pwd`
DIR="$( cd "$( dirname "$0" )" && pwd )"
cd $DIR

sh build-source.sh
cd installer

echo "Building installer..."

chmod u+x ./install.sh

# build installer -------------------------------------

for arch in i386 amd64
do

rm -rf ${arch}
mkdir -p ${arch}

echo ""
echo "******************************************************************************"
echo "Creating Installer (${arch})..."
echo "******************************************************************************"
echo ""

sudo pbuilder --build  --buildresult ${arch} --basetgz "${tgz}base-${arch}.tgz" ${dsc}

#check for errors
if [ $? -ne 0 ]; then
	cd "$backup"
	echo "Failed"
	exit 1
fi

PKGNAME=$(grep -R Source: ${arch}/*.changes | awk '{print $2}')
VERSION=$(grep -R Version: ${arch}/*.changes | awk '{print "v"$2}')

dpkg-deb -x ${arch}/${app_name}*.deb ${arch}/extracted

cp -p --no-preserve=ownership -t ${arch}/extracted ./install.sh
cp -p --no-preserve=ownership -t ${arch}/extracted/usr/share/${app_name}/libs ${libs}/${arch}/libgee.so.2
cp -p --no-preserve=ownership -t ${arch}/extracted/usr/share/${app_name}/libs ${libs}/${arch}/libjson-glib-1.0.so.0
chmod --recursive 0755 ${arch}/extracted/usr/share/${app_name}

makeself ${arch}/extracted ./${app_name}-${VERSION}-${arch}.run "${app_fullname} (${arch})" ./install.sh 

#check for errors
if [ $? -ne 0 ]; then
	cd "$backup"
	echo "Failed"
	exit 1
fi

cp -p --no-preserve=ownership ./${arch}/${app_name}*.deb ./${app_name}-${VERSION}-${arch}.deb 

done


cd "$backup"
