#!/usr/bin/env bash
#
# See: https://github.com/metaa/pie-device-brobwind-rpi3
#

set -o errexit

echo -e '\n# Installing stuff\n'
apt-get update
apt-get install -y openjdk-8-jdk python git-core gnupg flex bison gperf build-essential zip curl zlib1g-dev gcc-multilib g++-multilib libc6-dev-i386 lib32ncurses5-dev x11proto-core-dev libx11-dev lib32z-dev libgl1-mesa-dev libxml2-utils xsltproc unzip

echo -e '\n# Configuring git\n'
git config --global user.email "you@example.com"
git config --global user.name "Your Name"

echo -e '\n# Installing repo\n'
mkdir -p ~/bin
PATH=~/bin:$PATH
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo

echo -e '\n# AOSP repo init\n'
rm -rf rpibuild
mkdir rpibuild
cd rpibuild
repo init -u https://android.googlesource.com/platform/manifest -b android-9.0.0_r8

echo -e '\n# Device mods init\n'
mkdir -pv device/brobwind
git clone git://github.com/metaa/pie-device-brobwind-rpi3 device/brobwind/rpi3
mkdir -p .repo/local_manifests
ln -sv ../../device/brobwind/rpi3/local_manifest.xml .repo/local_manifests/

echo -e '\n# Running sync. THIS MAY TAKE A WHILE\n'
repo sync

echo -e '\n# Patching the DisplayContent file\n'
sed 's/mSurfaceSize = Math.max(mBaseDisplayHeight, mBaseDisplayWidth) \* 2/mSurfaceSize = (int)(Math.max(mBaseDisplayHeight, mBaseDisplayWidth) * 1.4)/' frameworks/base/services/core/java/com/android/server/wm/DisplayContent.java

echo -e '\n# Configuring build\n'
. build/envsetup.sh
lunch rpi3-eng

echo -e '\n# Building\n'
m -j

echo -e '\n# Flashing to disk file\n'
OUT=`realpath .`/out
dd if=/dev/zero of=$OUT/sdcard.img bs=1 count=0 seek=32GB
sudo OUT=${OUT} device/brobwind/rpi3/boot/create_partition_table.sh $OUT/sdcard.img

echo -e '\n# Done! ...?'
