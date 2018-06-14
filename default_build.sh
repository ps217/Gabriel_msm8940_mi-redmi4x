#!/bin/bash
#
# Kernel compilation script
#
# Copyright (C) 2018 Gabriel Kernel
#

LANG=C
green='\033[01;32m'
red='\033[01;31m'
blink_red='\033[05;31m'
restore='\033[0m'
bold='\033[1m'

# SP stands for Spectrum while ST is Stweaks
export KERNEL_NAME=Gabriel
export KSCHED=HMP
export TWEAKER=SP

export ARCH=arm64
export KERNEL_DEFCONFIG=santoni_defconfig
export BUILD_CROSS_COMPILE=android-toolchain-arm64/bin/aarch64-linux-android-
export GCC_VERSION="$(${BUILD_CROSS_COMPILE}gcc --version | head -n 1)"
export BUILD_JOB_NUMBER=`grep processor /proc/cpuinfo|wc -l`
export GIT_LOG1=`git log --oneline --decorate -n 1`
export FILENAME=$(date +"%Y-%m-%d");
export RDIR=$(readlink -f .)
export WD=$RDIR/WORKING-DIR
export RK=$RDIR/READY-KERNEL

export CC=android-toolchain-arm64/clang/bin/clang
export CLANG_TRIPLE=aarch64-linux-gnu-
export CLANG_VERSION="$(${CC} --version | head -n 1)"
KBUILD_LOUP_CFLAGS="-Wno-unknown-warning-option -Wno-sometimes-uninitialized -Wno-vectorizer-no-neon -Wno-pointer-sign -Wno-sometimes-uninitialized -Wno-tautological-constant-out-of-range-compare -Wno-literal-conversion -Wno-enum-conversion -Wno-parentheses-equality -Wno-typedef-redefinition -Wno-constant-logical-operand -Wno-array-bounds -Wno-empty-body -Wno-non-literal-null-conversion -O2"

function echo() {
    command echo -e "$@"
}

function report_error() {
    echo ""
    echo ${blink_red}"${1}"${restore}
    echo ""
    exit
}

function header_info() {
    echo ${green}
    echo "====$(for i in $(seq ${#1}); do echo "-\c"; done)===="
    echo "==  ${1}  =="
    echo "====$(for i in $(seq ${#1}); do echo "-\c"; done)===="
    echo ${restore}
}

function clean_dtb() {
	make ARCH=$ARCH mrproper;
	make clean;

	rm -f arch/$ARCH/boot/*.dtb
	rm -f arch/$ARCH/boot/*.cmd
	rm -f arch/$ARCH/boot/*.gz

	if [ -d $WD/temp ]; then
		rm -rf $WD/temp/*
	else
		mkdir $WD/temp
	fi;

	git checkout android-toolchain-arm64/
}

function builtin() {
sed -i 's/=m/=y/g' arch/$ARCH/configs/$KERNEL_DEFCONFIG
}

function zip_name() {
	ZIPFILE=$FILENAME
	if [[ -e $RK/$ZIPFILE.zip ]] ; then
			i=0
		while [[ -e $RK/$ZIPFILE-$i.zip ]] ; do
			let i++
		done
	    FILENAME=$ZIPFILE-$i
	fi
}

function build_kernel() {
	echo "${bold}Build config: ${restore}"$KERNEL_DEFCONFIG ""
	echo "${bold}Git info: ${restore}"$GIT_LOG1 ""
	echo "${bold}clang: ${restore}"$CLANG_VERSION

	echo -e "\ncleaning..."
	clean_dtb | grep :

	echo "generating .config"
	make -j$BUILD_JOB_NUMBER ARCH=$ARCH \
			CROSS_COMPILE=$BUILD_CROSS_COMPILE \
			$KERNEL_DEFCONFIG | grep :

	echo "compiling..."

	make -j$BUILD_JOB_NUMBER ARCH=$ARCH \
			CROSS_COMPILE="$BUILD_CROSS_COMPILE" \
			CC="ccache $CC" CLANG_TRIPLE="$CLANG_TRIPLE" \
			KBUILD_LOUP_CFLAGS="$KBUILD_LOUP_CFLAGS" | grep :

if [ "$(grep "=m" .config | wc -l)" -gt 0 ];then
	echo -e "compiling modules..."

	make -j$BUILD_JOB_NUMBER ARCH=$ARCH \
			CROSS_COMPILE="$BUILD_CROSS_COMPILE" \
			CLANG_TRIPLE="$CLANG_TRIPLE" \
			KBUILD_LOUP_CFLAGS="$KBUILD_LOUP_CFLAGS" \
			modules | grep :

	if [ -d $WD/package/system/lib/modules ]; then
		rm -rf $WD/package/system/lib/modules/*
	else
		mkdir -p $WD/package/system/lib/modules
	fi;

	find . -name '*ko' ! -path "*android-toolchain-arm64/*" ! -path "*.git/*" -exec \cp '{}' $WD/package/system/lib/modules/ \;
	chmod 755 $WD/package/system/lib/modules/*

	# strip not needed debugs from modules.
	"$BUILD_CROSS_COMPILE"strip --strip-unneeded $WD/package/system/lib/modules/* 2>/dev/null
	"$BUILD_CROSS_COMPILE"strip --strip-debug $WD/package/system/lib/modules/* 2>/dev/null

	mkdir -p $WD/package/system/lib/modules/pronto
	mv $WD/package/system/lib/modules/wlan.ko $WD/package/system/lib/modules/pronto/pronto_wlan.ko
fi;

if [ ! -f $RDIR/arch/$ARCH/boot/Image.gz ]; then
	report_error "Kernel STUCK in BUILD! no Image exist !"
fi;
}

function build_ramdisk() {
	if [ -d $WD/temp ]; then
		rm -rf $WD/temp/*
		mkdir $WD/temp/kernel
	else
		mkdir $WD/temp
	fi;

	# copy all selected ramdisk files to temp folder
	\cp -r $WD/anykernel/* $WD/temp
	mv -f $RDIR/arch/$ARCH/boot/Image.gz $WD/temp/kernel/Image.gz

if [ "$(grep "=m" .config | wc -l)" -gt 0 ];then
	mkdir -p $WD/temp/modules/pronto/
	\cp -r $WD/package/system/lib/modules/* $WD/temp/modules/
	mv $WD/package/system/lib/modules/pronto/pronto_wlan.ko $WD/temp/modules/pronto/pronto_wlan.ko
fi;
}

function build_zip() {
	FILENAME=$KERNEL_NAME-$TARGET-$KSCHED-$TWEAKER-$FILENAME
	zip_name

	mv -f $RDIR/build.log $WD/temp/build.log
	mv -f $RDIR/.config $WD/temp/kernel_config_view_only

	cd $WD/temp
	zip -r9 kernel.zip -r * -x README kernel.zip > /dev/null
	cd $RDIR

	cp $WD/temp/kernel.zip $RK/$FILENAME.zip
	md5sum $RK/$FILENAME.zip > $RK/$FILENAME.zip.md5
}

header_info "MIUI or non-MIUI ?!"
select CHOICE in miui aosp; do
	case "$CHOICE" in
		"miui")
			TARGET=MIUI
			break;;
		"aosp")
			TARGET=AOSP
			builtin
			break;;
	esac;
done;

# MAIN FUNCTION
rm -rf ./build.log
(
	time_start=$(date +"%s")

	build_kernel
	build_ramdisk
	build_zip

	git checkout arch/$ARCH/configs/$KERNEL_DEFCONFIG

	echo " "
	echo "${bold}file name is: ${restore}"$FILENAME
	adb push $RK/$FILENAME.zip /sdcard/ | grep 100

	time_end=$(date +"%s")
	DIFF=$(($time_end - $time_start))
	echo "${bold}Time: ${restore}$(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
) 2>&1	| tee -a ./build.log
