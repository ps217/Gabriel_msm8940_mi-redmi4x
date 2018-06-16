#!/bin/bash

LANG=C
green='\033[01;32m'
red='\033[01;31m'
blink_red='\033[05;31m'
restore='\033[0m'

# ST stands for Stweaks while SP is Spectrum
export KERNEL_NAME=Gabriel
export KSCHED=HMP
export TWEAKER=ST
export ARCH=arm64
export BUILD_CROSS_COMPILE=android-toolchain-arm64/bin/arm-eabi-
export CROSS_COMPILE_ARM32=android-toolchain-arm64/arm32/bin/arm-eabi-
export SYSROOT=android-toolchain-arm64/aarch64-MIR4X-linux-gnu/sysroot/
export TS=TOOLSET/
export BUILD_JOB_NUMBER=`grep processor /proc/cpuinfo|wc -l`
export GIT_LOG1=`git log --oneline --decorate -n 1`
export VER=$(grep Gabriel arch/arm64/configs/gabriel_defconfig | cut -c 31-32)
export DATE=$(date +"[%Y-%m-%d]");

export RDIR=$(readlink -f .)
export OUTDIR=$RDIR/arch/$ARCH/boot
export WD=$RDIR/WORKING-DIR
export RK=$RDIR/READY-KERNEL

FUNC_CLEAN_DTB()
{
	make ARCH=$ARCH mrproper;
	make clean;

# force regeneration of .dtb and zImage files for every compile
	rm -f arch/$ARCH/boot/*.dtb
	rm -f arch/$ARCH/boot/*.cmd
	rm -f arch/$ARCH/boot/*.gz

	if [ -d $WD/temp ]; then
		rm -rf $WD/temp/*
	else
		mkdir $WD/temp
	fi;

### cleanup files creted previously
	for i in $(find "$RDIR"/ -name "boot.img"); do
		rm -fv "$i";
	done;
	for i in $(find "$RDIR"/ -name "Image"); do
		rm -fv "$i";
	done;
	for i in $(find "$RDIR"/ -name "dtb.img"); do
		rm -fv "$i";
	done;
	for i in $(find "$RDIR"/ -name "zImage"); do
		rm -fv "$i";
	done;

	git checkout android-toolchain-arm64/
}

FUNC_ADB()
{
	if [ "$(adb devices | wc -l)" -eq "3" ]; then
		echo -e "${green}"
		adb push $RK/$FILENAME.zip /sdcard/ | grep 100
		echo -e "${restore}"
	fi;
}

FUNC_BUILTIN()
{
sed -i 's/=m/=y/g' arch/$ARCH/configs/$KERNEL_DEFCONFIG
}

FUNC_ZIP_NAME()
{
	ZIPFILE=$FILENAME
	if [[ -e $RK/$ZIPFILE.zip ]] ; then
			i=0
		while [[ -e $RK/$ZIPFILE-$i.zip ]] ; do
			let i++
		done
	    FILENAME=$ZIPFILE-$i
	fi
}

FUNC_BUILD_KERNEL()
{
	echo "build config="$KERNEL_DEFCONFIG ""
	echo "git info="$GIT_LOG1 ""

	echo -e "\ncleaning..."
	FUNC_CLEAN_DTB | grep :

	echo "generating .config"
	make -j$BUILD_JOB_NUMBER ARCH=$ARCH \
			CROSS_COMPILE=$BUILD_CROSS_COMPILE \
			$KERNEL_DEFCONFIG | grep :

	echo "compiling..."

	make -j$BUILD_JOB_NUMBER ARCH=$ARCH \
			CROSS_COMPILE=$BUILD_CROSS_COMPILE \
			CC='ccache '${BUILD_CROSS_COMPILE}gcc' --sysroot='$SYSROOT'' | grep :

if [ "$(grep "=m" .config | wc -l)" -gt 0 ];then
	echo -e "compiling modules..."

	make -j$BUILD_JOB_NUMBER ARCH=$ARCH \
			CROSS_COMPILE=$BUILD_CROSS_COMPILE \
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
	echo -e "${red}"
	echo -e "Kernel STUCK in BUILD! no Image exist !"
	echo -e "${restore}"
	exit 1
fi;
}

FUNC_BUILD_RAMDISK_STK()
{
	rm -f $WD/boot.img

	# copy all selected ramdisk files to temp folder
	\cp -r $WD/ramdisk/* $WD/temp
	\cp -r $WD/$MODEL/* $WD/temp/ramdisk

	DTB=$WD/anykernel/treble-unsupported;
	cat $RDIR/arch/$ARCH/boot/Image.gz $DTB/*.dtb > $WD/temp/zImage;
	rm -f $RDIR/arch/$ARCH/boot/Image.gz;

	./$TS/mkboot $WD/temp $WD/boot.img
}

FUNC_BUILD_ZIP_STK()
{
	if [ -d $WD/temp ]; then
		rm -rf $WD/temp/*
	else
		mkdir $WD/temp
	fi;

	FILENAME=$KERNEL_NAME-$TARGET-$KSCHED-$TWEAKER-$VER-$DATE
	FUNC_ZIP_NAME

	\cp -r $WD/package/* $WD/temp

	if [ ! -d $WD/temp/boot ]; then
		mkdir $WD/temp/boot/
	fi;
	mv -f $WD/boot.img $WD/temp/boot/boot.img
	mv -f $RDIR/build.log $WD/temp/build.log
	\cp $RDIR/.config $WD/temp/kernel_config_view_only

	cd $WD/temp
	zip -r9 kernel.zip -r * -x README kernel.zip > /dev/null
	cd $RDIR

	cp $WD/temp/kernel.zip $RK/$FILENAME.zip
	md5sum $RK/$FILENAME.zip > $RK/$FILENAME.zip.md5

	FUNC_ADB
}

FUNC_BUILD_RAMDISK_ANY()
{
	if [ -d $WD/temp ]; then
		rm -rf $WD/temp/*
	else
		mkdir $WD/temp
	fi;

	# copy all selected ramdisk files to temp folder
	\cp -r $WD/anykernel/* $WD/temp
	if [ ! -d $WD/temp/kernel ]; then
		mkdir -p $WD/temp/kernel
	fi;
	mv -f $RDIR/arch/$ARCH/boot/Image.gz $WD/temp/kernel/Image.gz

	if [ ! -d $WD/temp/ramdisk ]; then
		mkdir -p $WD/temp/ramdisk
	fi;

	\cp -r $WD/ramdisk/ramdisk/* $WD/temp/ramdisk/

if [ "$(grep "=m" .config | wc -l)" -gt 0 ];then
	mkdir -p $WD/temp/modules/pronto/
	\cp -r $WD/package/system/lib/modules/* $WD/temp/modules/
	mv $WD/package/system/lib/modules/pronto/pronto_wlan.ko $WD/temp/modules/pronto/pronto_wlan.ko
fi;
}

FUNC_BUILD_ZIP_ANY()
{
	FILENAME=$KERNEL_NAME-$TARGET-$KSCHED-$TWEAKER-$VER-$DATE
	FUNC_ZIP_NAME

	mv -f $RDIR/build.log $WD/temp/build.log
	mv -f $RDIR/.config $WD/temp/kernel_config_view_only

	cd $WD/temp
	zip -r9 kernel.zip -r * -x README kernel.zip > /dev/null
	cd $RDIR

	cp $WD/temp/kernel.zip $RK/$FILENAME.zip
	md5sum $RK/$FILENAME.zip > $RK/$FILENAME.zip.md5

	FUNC_ADB
}

echo -e "${green}"
echo "----------------"
echo "Which Ramdisk ?!";
echo "----------------"
echo -e "${restore}"
select CHOICE in stock anykernel; do
	case "$CHOICE" in
		"stock")
			RAMDTYPE=STK
			break;;
		"anykernel")
			RAMDTYPE=ANY
			break;;
	esac;
done;

echo -e "${green}"
echo "----------------------"
echo "Which kernel config ?!";
echo "----------------------"
echo -e "${restore}"
select CHOICE in santoni-stock santoni-gabriel; do
	case "$CHOICE" in
		"santoni-stock")
			KERNEL_DEFCONFIG=santoni_defconfig
			break;;
		"santoni-gabriel")
			KERNEL_DEFCONFIG=gabriel_defconfig
			break;;
	esac;
done;

echo -e "${green}"
echo "----------------------"
echo "Modular or Built-in ?!";
echo "----------------------"
echo -e "${restore}"
select CHOICE in module built-in; do
	case "$CHOICE" in
		"module")
			TARGET=MIUI
			break;;
		"built-in")
			TARGET=AOSP
			FUNC_BUILTIN
			break;;
	esac;
done;

# MAIN FUNCTION
rm -rf ./build.log
(
	DATE_START=$(date +"%s")

	FUNC_BUILD_KERNEL
	FUNC_BUILD_RAMDISK_$RAMDTYPE
	FUNC_BUILD_ZIP_$RAMDTYPE

	git checkout arch/$ARCH/configs/$KERNEL_DEFCONFIG

	DATE_END=$(date +"%s")

	if [ "$(adb devices | wc -l)" -eq "3" ]; then
		echo "" # shown adb pushed file
	else
		echo -e "${green}"
		echo "File Name is: "$FILENAME
		echo -e "${restore}"
	fi;

	DATE_END=$(date +"%s")
	DIFF=$(($DATE_END - $DATE_START))
	echo "Time: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
) 2>&1	| tee -a ./build.log
