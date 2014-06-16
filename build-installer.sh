#!/bin/bash

backup=`pwd`
DIR="$( cd "$( dirname "$0" )" && pwd )"
cd $DIR

sh build-source.sh
cd installer

echo "Building installer..."

tgz="/home/teejee/projects/pbuilder/"
dsc="/home/teejee/projects/builds/selene*.dsc"

chmod u+x ./install.sh

# build installer -------------------------------------

for arch in i386 amd64
do

rm -rf ${arch}
mkdir -p ${arch}

sudo pbuilder --build  --buildresult ${arch} --basetgz "${tgz}base-${arch}.tgz" ${dsc}

#check for errors
if [ $? -ne 0 ]; then
	cd "$backup"
	echo "Failed"
	exit 1
fi

dpkg-deb -x ${arch}/selene*.deb ${arch}/extracted

cp -p --no-preserve=ownership -t ${arch}/extracted ./install.sh

makeself ${arch}/extracted ./selene-latest-${arch}.run "selene (${arch})" ./install.sh 

#check for errors
if [ $? -ne 0 ]; then
	cd "$backup"
	echo "Failed"
	exit 1
fi

cp -p --no-preserve=ownership ./${arch}/selene*.deb ./selene-latest-${arch}.deb 

done

cd "$backup"
