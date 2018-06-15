#!/bin/bash

export RDIR=$(readlink -f .)
export ARCH=arm64
export WD=$RDIR/WORKING-DIR
export KERNEL_DEFCONFIG=santoni_defconfig
export BUILD_CROSS_COMPILE=android-toolchain-arm64/bin/aarch64-linux-android-
export BUILD_JOB_NUMBER=`grep processor /proc/cpuinfo|wc -l`
export CC=android-toolchain-arm64/clang/bin/clang
export CLANG_TRIPLE=aarch64-linux-gnu-
export CLANG_VERSION="$(${CC} --version | head -n 1)"
KBUILD_LOUP_CFLAGS="-Wno-unknown-warning-option -Wno-sometimes-uninitialized -Wno-vectorizer-no-neon -Wno-pointer-sign -Wno-sometimes-uninitialized -Wno-tautological-constant-out-of-range-compare -Wno-literal-conversion -Wno-enum-conversion -Wno-parentheses-equality -Wno-typedef-redefinition -Wno-constant-logical-operand -Wno-array-bounds -Wno-empty-body -Wno-non-literal-null-conversion -O2"
export QCOM=arch/arm/boot/dts/qcom
export TSU=$WD/anykernel/treble-supported
export TUSU=$WD/anykernel/treble-unsupported
export DTB=msm8940-pmi8950-qrd-sku7_S88536AA2
export PATCH=treble.patch

function compile_image() {
rm -f $QCOM/$DTB.dtb

#FIXME:find the proper way to compile dtsi.
echo "generating .config"
make -j$BUILD_JOB_NUMBER ARCH=$ARCH \
		CROSS_COMPILE=$BUILD_CROSS_COMPILE \
		$KERNEL_DEFCONFIG | grep :

echo "compiling..."
make -j$BUILD_JOB_NUMBER ARCH=$ARCH \
		CROSS_COMPILE="$BUILD_CROSS_COMPILE" \
		CC="ccache $CC" CLANG_TRIPLE="$CLANG_TRIPLE" \
		KBUILD_LOUP_CFLAGS="$KBUILD_LOUP_CFLAGS" | grep :
}

function buid_supported() {
patch -p1 --ignore-whitespace < patch/$PATCH

compile_image;

cp -v $QCOM/$DTB.dtb $TSU/$DTB.dtb
cp -v $QCOM/$DTB.dtb $TUSU/$DTB.dtb

git checkout arch/arm/boot/dts/qcom/*.dts*
}

function build_unsupported() {
compile_image;

cp -v $QCOM/$DTB.dtb $TUSU/$DTB-nt.dtb
}

buid_supported;
build_unsupported;
git status;

echo " ";
select CHOICE in commit unstage_dtbs cancel; do
	case "$CHOICE" in
		"commit")
			git add $WD/anykernel/treble-*
			git commit -m "ramdisk: regenerate device tree blobs";
			break;;
		"unstage_dtbs")
			git checkout $WD/anykernel/treble-*;
			break;;
		"cancel")
			break;;
	esac;
done;
