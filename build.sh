#!/bin/bash
rm .version
green='\033[01;32m'
red='\033[01;31m'
blink_red='\033[05;31m'
restore='\033[0m'

clear

THREAD="-j16"
KERNEL="Image"
DTBIMAGE="dtb"
DEFCONFIG="benzo_defconfig"


KERNEL_DIR="/media/otherhd/benzoCore64/benzoCore"
WHEREAMI="/media/otherhd/benzoCore64"
REPACK_DIR="${KERNEL_DIR}/out/anykernel2"
PATCH_DIR="${REPACK_DIR}/patch"
MODULES_DIR="${REPACK_DIR}/modules"
ZIP_MOVE="${KERNEL_DIR}/out"
ZIMAGE_DIR="${KERNEL_DIR}/arch/arm64/boot"
export CROSS_COMPILE=${WHEREAMI}/aarch64-7.0/bin/aarch64-

BASE_AK_VER="benzoCore64"
VER="M1"
AK_VER="$BASE_AK_VER$VER"

function clean_all {
		rm -rf $MODULES_DIR/**
		cd /media/otherhd/benzoCore64/benzoCore/out/kernel
		rm -rf $DTBIMAGE
		git reset --hard > /dev/null 2>&1
		git clean -f -d > /dev/null 2>&1
		cd $KERNEL_DIR
		echo
		make clean && make mrproper
}

function make_kernel {
		echo
		make $DEFCONFIG
		make $THREAD
		
}

function make_modules {
		rm `echo $MODULES_DIR"/**"`
		find $KERNEL_DIR -name '*.ko' -exec cp -v {} $MODULES_DIR \;
}

function make_dtb {
		$REPACK_DIR/tools/dtbToolCM -2 -o $REPACK_DIR/$DTBIMAGE -s 2048 -p scripts/dtc/ arch/arm64/boot/
}

function make_boot {
		cp -vr $ZIMAGE_DIR/Image.gz-dtb /media/otherhd/benzoCore64/benzoCore/out/kernel/zImage
		
		. appendramdisk.sh
}


function make_zip {
		cd /media/otherhd/benzoCore64/benzoCore/out
		zip -r9 benzoCore64-$VER.zip *
		mv  `echo $AK_VER`.zip $ZIP_MOVE
		cd $KERNEL_DIR
}


export LOCALVERSION=~`echo $AK_VER`
export LOCALVERSION=~`echo $AK_VER`
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_BUILD_USER=benzo
export KBUILD_BUILD_HOST=xanaxdroid


DATE_START=$(date +"%s")
echo -e "${green}"
echo "Building benzoCore64"
echo "-----------------"
echo -e "${restore}"
echo
while read -p "Do you want to clean stuffs (y/n)? " cchoice
do
case "$cchoice" in
	y|Y )
		clean_all
		echo
		echo "All Cleaned now."
		break
		;;
	n|N )
		break
		;;
	* )
		echo
		echo "Invalid try again!"
		echo
		;;
esac
done

echo

while read -p "Do you want to build?" dchoice
do
case "$dchoice" in
	y|Y )
		make_kernel
		make_dtb
		make_modules
		make_boot
		make_zip
		break
		;;
	n|N )
		break
		;;
	* )
		echo
		echo "Invalid try again!"
		echo
		;;
esac
done


echo -e "${green}"
echo "-------------------"
echo "Build Completed in:"
echo -e "${restore}"

DATE_END=$(date +"%s")
DIFF=$(($DATE_END - $DATE_START))
echo "Time: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
echo

