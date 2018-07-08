#!/bin/bash

RDIR=$(readlink -f .)
WD=$RDIR/WORKING-DIR
DTS=arch/arm/boot/dts/qcom/msm8940-pmi8950-qrd-sku7-full.dts
TSU=$WD/anykernel/treble-supported
TUSU=$WD/anykernel/treble-unsupported

function buid_supported() {
patch -p1 --ignore-whitespace < patch/treble.patch

$RDIR/TOOLSET/dtc -I dts -O dtb -o $TSU/msm8940-pmi8950-qrd-sku7-full.dtb $DTS
$RDIR/TOOLSET/dtc -I dts -O dtb -o $TUSU/msm8940-pmi8950-qrd-sku7-full.dtb $DTS

rm $DTS*.orig
git checkout arch/arm/boot/dts/qcom/*.dts*
}

function build_unsupported() {
$RDIR/TOOLSET/dtc -I dts -O dtb -o $TUSU/msm8940-pmi8950-qrd-sku7-full-nt.dtb $DTS
}

function commit_process() {
git add $WD/anykernel/treble-*
git commit -m "ramdisk: regenerate device tree blobs";
}

buid_supported;
build_unsupported;
git status;
echo " ";

select CHOICE in commit unstage_dtbs cancel; do
	case "$CHOICE" in
		"commit")
			commit_process;
			break;;
		"unstage_dtbs")
			git checkout $WD/anykernel/treble-*;
			break;;
		"cancel")
			break;;
	esac;
done;
