#!/sbin/busybox sh

# Kernel Tuning by Dorimanx.
# Kernel Tuning by Mostafaz.

BB=/sbin/busybox

# protect init from oom
if [ -f /system/xbin/su ]; then
	su -c echo "-1000" > /proc/1/oom_score_adj;
fi;

OPEN_RW()
{
	if [ "$($BB mount | grep rootfs | cut -c 26-27 | grep -c ro)" -ge "0" ]; then
		$BB mount -o remount,rw /;
	fi;
	$BB mount -o remount,rw /system;
}
OPEN_RW;

# some nice thing for dev
if [ ! -e /cpufreq ]; then
	$BB ln -s /sys/devices/system/cpu/cpu0/cpufreq/ /cpufreq0;
	$BB ln -s /sys/devices/system/cpu/cpu4/cpufreq/ /cpufreq4;
	$BB ln -s /sys/module/msm_thermal/parameters/ /cputemp;
fi;

# create init.d folder if missing
if [ ! -d /system/etc/init.d ]; then
	mkdir -p /system/etc/init.d/
	$BB chmod 755 /system/etc/init.d/;
fi;

OPEN_RW;

CRITICAL_PERM_FIX()
{
	# critical Permissions fix
	$BB chown -R root:root /tmp;
	$BB chown -R root:root /res;
	$BB chown -R root:root /sbin;
	$BB chmod -R 777 /tmp/;
	$BB chmod -R 775 /res/;
	$BB chmod -R 06755 /sbin/ext/;
	$BB chmod 06755 /sbin/busybox;
	$BB chmod 06755 /system/xbin/busybox;
}
CRITICAL_PERM_FIX;

# oom and mem perm fix
$BB chmod 666 /sys/module/lowmemorykiller/parameters/cost;
$BB chmod 666 /sys/module/lowmemorykiller/parameters/adj;
$BB chmod 666 /sys/module/lowmemorykiller/parameters/minfree

$BB chmod 666 /sys/module/msm_thermal/parameters/*

$BB chown system system /sys/devices/platform/kcal_ctrl.0/kcal
$BB chown system system /sys/devices/platform/kcal_ctrl.0/kcal_cont
$BB chown system system /sys/devices/platform/kcal_ctrl.0/kcal_hue
$BB chown system system /sys/devices/platform/kcal_ctrl.0/kcal_invert
$BB chown system system /sys/devices/platform/kcal_ctrl.0/kcal_sat
$BB chown system system /sys/devices/platform/kcal_ctrl.0/kcal_val
$BB chmod 0664 /sys/devices/platform/kcal_ctrl.0/kcal
$BB chmod 0664 /sys/devices/platform/kcal_ctrl.0/kcal_cont
$BB chmod 0664 /sys/devices/platform/kcal_ctrl.0/kcal_hue
$BB chmod 0664 /sys/devices/platform/kcal_ctrl.0/kcal_invert
$BB chmod 0664 /sys/devices/platform/kcal_ctrl.0/kcal_sat
$BB chmod 0664 /sys/devices/platform/kcal_ctrl.0/kcal_val

#    chown system:system /sys/devices/virtual/graphics/fb0/hbm
#    chmod 0664 /sys/devices/virtual/graphics/fb0/hbm

$BB chown system system /sys/class/devfreq/1c00000.qcom,kgsl-3d0/governor
$BB chown system system /sys/class/devfreq/1c00000.qcom,kgsl-3d0/max_freq
$BB chown system system /sys/class/devfreq/1c00000.qcom,kgsl-3d0/min_freq
$BB chmod 0664 /sys/class/devfreq/1c00000.qcom,kgsl-3d0/governor
$BB chmod 0664 /sys/class/devfreq/1c00000.qcom,kgsl-3d0/max_freq
$BB chmod 0664 /sys/class/devfreq/1c00000.qcom,kgsl-3d0/min_freq

    # cpufreq settings
$BB chown system system /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
$BB chown system system /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq
$BB chown system system /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
$BB chown system system /sys/devices/system/cpu/cpu4/cpufreq/scaling_min_freq
$BB chown system system /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
$BB chown system system /sys/devices/system/cpu/cpu4/cpufreq/scaling_governor
$BB chmod 0664 /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
$BB chmod 0664 /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq
$BB chmod 0664 /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
$BB chmod 0664 /sys/devices/system/cpu/cpu4/cpufreq/scaling_min_freq
$BB chmod 0664 /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
$BB chmod 0664 /sys/devices/system/cpu/cpu4/cpufreq/scaling_governor

if [ ! -d /data/.gabriel ]; then
	$BB mkdir -p /data/.gabriel;
fi;

if [ ! -d /data/.gabriel/logs ]; then
	$BB mkdir -p /data/.gabriel/logs;
fi;

#echo 1 > /sys/module/workqueue/parameters/power_efficient;
echo 0 > /sys/module/msm_thermal/core_control/enabled;
echo 1 > /cputemp/enabled;

echo 12288 > /proc/sys/vm/min_free_kbytes
echo 10 > /proc/sys/vm/swappiness
echo 1500 > /proc/sys/vm/dirty_writeback_centisecs

echo 1 > /sys/module/lowmemorykiller/parameters/enable_adaptive_lmk
#echo "18432,23040,27648,51256,150296,200640" > /sys/module/lowmemorykiller/parameters/minfree
echo "18432,23040,27648,51256,89600,115200" > /sys/module/lowmemorykiller/parameters/minfree
#echo 202640 > /sys/module/lowmemorykiller/parameters/vmpressure_file_min
echo 128000 > /sys/module/lowmemorykiller/parameters/vmpressure_file_min

echo 0 > /proc/sys/kernel/sched_boost
echo 90 > /proc/sys/kernel/sched_downmigrate
echo 95 > /proc/sys/kernel/sched_upmigrate
echo 400000 > /proc/sys/kernel/sched_freq_inc_notify
echo 400000 > /proc/sys/kernel/sched_freq_dec_notify
echo 3 > /proc/sys/kernel/sched_spill_nr_run
echo 100 > /proc/sys/kernel/sched_init_task_load

echo 0 > /sys/devices/system/cpu/cpu0/sched_mostly_idle_freq
echo 0 > /sys/devices/system/cpu/cpu4/sched_mostly_idle_freq

    # Little cluster
echo 0 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/use_sched_load
echo 0 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/above_hispeed_delay
echo 100 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/go_hispeed_load
echo 0 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/hispeed_freq
echo "70 768000:60 902400:85 998400:90 1094400:95" > /sys/devices/system/cpu/cpu4/cpufreq/interactive/target_loads
echo 20000 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/timer_rate
echo 40000 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/min_sample_time
echo 1 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/ignore_hispeed_on_notif
echo 80000 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/max_freq_hysteresis
echo 30000 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/timer_slack
echo 1 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/io_is_busy

    # big cluster
echo 0 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/use_sched_load
echo "20000 1209600:40000 1344000:20000" > /sys/devices/system/cpu/cpu0/cpufreq/interactive/above_hispeed_delay
echo 85 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/go_hispeed_load
echo 1094400 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/hispeed_freq
echo "90 1344000:95" > /sys/devices/system/cpu/cpu0/cpufreq/interactive/target_loads
echo 30000 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/timer_rate
echo 30000 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/min_sample_time
echo 1 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/ignore_hispeed_on_notif
echo 80000 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/max_freq_hysteresis
echo 30000 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/timer_slack
echo 1 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/io_is_busy

# Prevent mmc from scaling its clk down when performing writes
#echo 1 > /sys/class/mmc_host/mmc0/clk_scaling/scale_down_in_low_wr_load


if [ "$(cat /sys/block/zram0/disksize)" -ne "1048576000" ]; then
	if [ -e /dev/block/zram0 ]; then
		# for on the fly changes we need to shutdown ZRAM first
		$BB swapoff /dev/block/zram0 >/dev/null 2>&1;
		echo "1" > /sys/block/zram0/reset;
		echo "lz4" > /sys/block/zram0/comp_algorithm;
		echo "6" > /sys/block/zram0/max_comp_streams;
		# setting size of ZRAM swap drive
		echo "1GB" > /sys/block/zram0/disksize;
		# creating SWAP from ZRAM drive
		$BB mkswap /dev/block/zram0 >/dev/null;
		# activating ZRAM swap
		$BB swapon /dev/block/zram0;
	fi;
fi;

# disable block iostats/rotational and set io-scheduler
for i in /sys/block/*/queue; do
	echo 0 > $i/iostats
	echo 0 > $i/rotational
	echo zen > $i/scheduler
	echo 128 > $i/read_ahead_kb
done;

# start CORTEX by tree root, so it's will not be terminated.
if [ "$(pgrep -f "cortexbrain-tune.sh" | wc -l)" -eq "0" ]; then
	nohup sh /sbin/ext/cortexbrain-tune.sh > /data/.gabriel/cortex.txt &
fi;

OPEN_RW;

$BB nohup $BB run-parts /system/etc/init.d/ > /data/.gabriel/init.d.txt &

if [ -e /system/etc/init.d/99SuperSUDaemon ]; then
	$BB nohup $BB sh /system/etc/init.d/99SuperSUDaemon > /data/.gabriel/root.txt &
else
	echo "no root script in init.d";
fi;

# Load parameters for Synapse
DEBUG=/data/.gabriel/;
BUSYBOX_VER=$(busybox | grep "BusyBox v" | cut -c0-15);
echo "$BUSYBOX_VER" > $DEBUG/busybox_ver;

$BB mount -o remount,ro /system;
