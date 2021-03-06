#!/gabriel/busybox sh

BB=/gabriel/busybox

DO_NOT_RUN()
{
	if [ "$($BB mount | grep rootfs | cut -c 26-27 | grep -c ro)" -ge "0" ]; then
		$BB mount -o remount,rw /;
	fi;
	$BB mount -o remount,rw /system;

# update passwd and group files for busybox.
echo "root:x:0:0::/:/sbin/sh" > /system/etc/passwd;
echo "system:x:1000:0::/:/sbin/sh" >> /system/etc/passwd;
echo "radio:x:1001:0::/:/sbin/sh" >> /system/etc/passwd;
echo "bluetooth:x:1002:0::/:/sbin/sh" >> /system/etc/passwd;
echo "wifi:x:1010:0::/:/sbin/sh" >> /system/etc/passwd;
echo "dhcp:x:1014:0::/:/sbin/sh" >> /system/etc/passwd;
echo "media:x:1013:0::/:/sbin/sh" >> /system/etc/passwd;
echo "gps:x:1021:0::/:/sbin/sh" >> /system/etc/passwd;
echo "nfc:x:1027:0::/:/sbin/sh" >> /system/etc/passwd;
$BB chmod 755 /system/etc/passwd;
$BB chown 0.0 /system/etc/passwd;

echo "root:x:0:root" > /system/etc/group;
echo "system:x:1000:system" >> /system/etc/group;
echo "radio:x:1001:radio" >> /system/etc/group;
echo "bluetooth:x:1002:bluetooth" >> /system/etc/group;
echo "wifi:x:1010:wifi" >> /system/etc/group;
echo "dhcp:x:1014:dhcp" >> /system/etc/group;
echo "media:x:1013:media" >> /system/etc/group;
echo "gps:x:1021:gps" >> /system/etc/group;
echo "nfc:x:1027:nfc" >> /system/etc/group;
echo "sdcard_r:x:1028:sdcard_r" >> /system/etc/group;
echo "cache:x:2001:cache" >> /system/etc/group;
$BB chmod 755 /system/etc/group;
$BB chown 0.0 /system/etc/group;

CLEAN_BUSYBOX()
{
	for f in *; do
		case "$($BB readlink "$f")" in *usybox*)
			$BB rm "$f"
		;;
		esac
	done;
}

# Cleanup the old busybox symlinks
cd /system/xbin/;
CLEAN_BUSYBOX;

cd /system/bin/;
CLEAN_BUSYBOX;

cd /;

# Install latest busybox to ROM
$BB cp /gabriel/busybox /system/xbin/;

/system/xbin/busybox --install -s /system/xbin/
chmod 06755 /system/xbin/busybox;
if [ -e /system/xbin/su ]; then
	$BB chmod 06755 /system/xbin/su;
fi;
if [ -e /system/xbin/daemonsu ]; then
	$BB chmod 06755 /system/xbin/daemonsu;
fi;
}

$BB sh /gabriel/ext/post-init.sh;
