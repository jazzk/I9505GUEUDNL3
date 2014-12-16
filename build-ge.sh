#!/bin/sh
KERNEL_DIR=`readlink -f .`
PARENT_DIR=`readlink -f ..`
KERNEL_TYPE="custom_ge_lp"
KERNEL_ID="custom-ge-lp-eur"
RAMFS_TMP="$PARENT_DIR/tmp/ramdisk"
RAMFS_SOURCE="$PARENT_DIR/includes/$KERNEL_TYPE/ramdisk"
ZIPFS_SOURCE="$PARENT_DIR/includes/$KERNEL_TYPE/zip"
WORKING_DIR="$PARENT_DIR/out/$KERNEL_ID"

#setup folders
mkdir -p $PARENT_DIR/tmp
mkdir -p $WORKING_DIR
cp -R $ZIPFS_SOURCE/* $WORKING_DIR

#remove previous zip
rm $WORKING_DIR.zip

#remove previous modules from source
find -name '*.ko' -exec rm -rf {} \;

#generate kernel config
export ARCH=arm
export CROSS_COMPILE=/home/jazz/prebuilts/arm-eabi-4.7/bin/arm-eabi-
#make jf_defconfig VARIANT_DEFCONFIG=jf_eur_defconfig SELINUX_DEFCONFIG=selinux_defconfig || exit 1
make jf_defconfig VARIANT_DEFCONFIG=jf_tmo_defconfig SELINUX_DEFCONFIG=selinux_defconfig || exit 1

#build kernel
make -j2 || exit 1

#copy modules into working directory
find -name '*.ko' -exec cp -av {} $WORKING_DIR/system/lib/modules/ \;

#build ramfs
./mkbootfs $RAMFS_SOURCE | gzip > $RAMFS_TMP.gz

cd $KERNEL_DIR

#pack ramfs and zImage into boot.img
./mkbootimg --kernel $KERNEL_DIR/arch/arm/boot/zImage --ramdisk $RAMFS_TMP.gz --cmdline "console=null androidboot.hardware=jgedlte user_debug=31 msm_rtb.filter=0x3F ehci-hcd.park=3" -o $WORKING_DIR/boot.img --base "0x80200000" --ramdiskaddr "0x82200000"

#create zip
cd $WORKING_DIR
zip -v -r $PARENT_DIR/out/$KERNEL_ID.zip .

#clean folders
rm -rf $PARENT_DIR/tmp
rm -rf $WORKING_DIR
