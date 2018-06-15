# AnyKernel2 Ramdisk Mod Script
# osm0sis @ xda-developers

## AnyKernel setup
# begin properties
properties() {
kernel.string=Gabriel Kernel by mostafaz @ xda-developers
do.devicecheck=1
do.modules=1
do.system=1
do.cleanup=1
do.cleanuponabort=1
do.osversion=1
device.name1=santoni
device.name2=Xiaomi
device.name3=Redmi 4X
} # end properties

# shell variables
block=/dev/block/bootdevice/by-name/boot;
is_slot_device=0;
ramdisk_compression=auto;

## end setup


## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. /tmp/anykernel/tools/ak2-core.sh;

## AnyKernel file attributes
# set permissions/ownership for included ramdisk files
chmod -R 750 $ramdisk/*;
chown -R root:root $ramdisk/*;


## AnyKernel install
dump_boot;

# begin ramdisk changes

# fstab.qcom
if [ -e fstab.qcom ] || [ -e /system/vendor/etc/fstab.qcom ] && [ $(mount | grep f2fs | wc -l) -gt "0" ]; then
touch /tmp/anykernel/fstab.patch
echo "do.fstab=1" > /tmp/anykernel/fstab.patch
if [ -e fstab.qcom ]; then
insert_line fstab.qcom "data        f2fs" before "data        ext4" "/dev/block/bootdevice/by-name/userdata     /data        f2fs    nosuid,nodev,noatime,inline_xattr,data_flush      wait,check,encryptable=footer,formattable,length=-16384";
insert_line fstab.qcom "cache        f2fs" after "data        ext4" "/dev/block/bootdevice/by-name/cache     /cache        f2fs    nosuid,nodev,noatime,inline_xattr,flush_merge,data_flush wait,formattable,check";
elif [ -e /system/vendor/etc/fstab.qcom ]; then
insert_line /system/vendor/etc/fstab.qcom "data        f2fs" before "data        ext4" "/dev/block/bootdevice/by-name/userdata     /data        f2fs    nosuid,nodev,noatime,inline_xattr,data_flush      wait,check,encryptable=footer,formattable,length=-16384";
insert_line /system/vendor/etc/fstab.qcom "cache        f2fs" after "data        ext4" "/dev/block/bootdevice/by-name/cache     /cache        f2fs    nosuid,nodev,noatime,inline_xattr,flush_merge,data_flush wait,formattable,check";
fi;
fi;

if [ -e init.qcom.rc ]; then
backup_file init.qcom.rc;
insert_line init.qcom.rc "init.spectrum.rc" before "import init.qcom.usb.rc" "import /init.spectrum.rc";
else
backup_file init.rc;
insert_line init.rc "init.spectrum.rc" before "import /init.usb.rc" "import /init.spectrum.rc";
fi;
# end ramdisk changes

write_boot;

## end install
