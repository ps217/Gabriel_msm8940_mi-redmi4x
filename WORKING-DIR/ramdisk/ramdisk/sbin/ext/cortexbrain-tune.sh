#!/sbin/busybox sh

#Credits:
# Zacharias.maladroit
# Voku1987
# Collin_ph@xda
# Dorimanx@xda
# Gokhanmoral@xda
# Johnbeetee
# Alucard_24@xda
# Mostafaz@xda

# TAKE NOTE THAT LINES PRECEDED BY A "#" IS COMMENTED OUT.
#
# This script must be activated after init start =< 25sec or parameters from /sys/* will not be loaded.

BB=/sbin/busybox

# change mode for /tmp/
ROOTFS_MOUNT=$(mount | grep rootfs | cut -c26-27 | grep -c rw)
if [ "$ROOTFS_MOUNT" -eq "0" ]; then
	mount -o remount,rw /;
fi;
chmod -R 777 /tmp/;

# ==============================================================
# GLOBAL VARIABLES || without "local" also a variable in a function is global
# ==============================================================

FILE_NAME=$0;
DATA_DIR=/data/.gabriel;

# ==============================================================
# INITIATE
# ==============================================================

# For CHARGER CHECK.
echo "1" > /data/gabriel_cortex_sleep;

rm -f /cache/power_efficient
rm -f /cache/fsync_enabled;
rm -f /cache/lc_corectl_state;
rm -f /cache/devfreq_max;
rm -f /cache/devfreq_min;

# ==============================================================
# KERNEL-TWEAKS
# ==============================================================
KERNEL_TWEAKS()
{
		echo "0" > /proc/sys/vm/oom_kill_allocating_task;
		echo "0" > /proc/sys/vm/panic_on_oom;
		echo "30" > /proc/sys/kernel/panic;
		echo "0" > /proc/sys/kernel/panic_on_oops;
}
KERNEL_TWEAKS;

# ==============================================================
# RAM CLEANUP
# ==============================================================

RAM_CLEANUP()
{
	MEM_ALL=`free | grep Mem | awk '{ print $2 }'`;
	MEM_USED=`free | grep Mem | awk '{ print $3 }'`;
	MEM_USED_CALC=$(($MEM_USED*100/$MEM_ALL));

	# do clean cache only if cache uses 80% of free memory.
	if [ "$MEM_USED_CALC" -gt "80" ]; then
		sync;
		sleep 1;
		sysctl -w vm.drop_caches=2;
	fi;
}

# ==============================================================
# TWEAKS: if Screen-ON
# ==============================================================
AWAKE_MODE()
{
if [ "$(cat /data/gabriel_cortex_sleep)" -eq "1" ]; then
	echo "$(cat /cache/power_efficient)" > /sys/module/workqueue/parameters/power_efficient;

	echo "$(cat /cache/fsync_enabled)" > /sys/module/sync/parameters/fsync_enabled;

	echo "$(cat /cache/lc_corectl_state)" > /sys/devices/system/cpu/cpu4/core_ctl/max_cpus;

	echo "$(cat /cache/devfreq_max)" > /sys/class/devfreq/1c00000.qcom,kgsl-3d0/max_freq;
	echo "$(cat /cache/devfreq_min)" > /sys/class/devfreq/1c00000.qcom,kgsl-3d0/min_freq;

	echo "1" > /sys/kernel/printk_mode/printk_mode;

	RAM_CLEANUP;

	echo "0" > /data/gabriel_cortex_sleep
fi
}

# ==============================================================
# TWEAKS: if Screen-OFF
# ==============================================================
SLEEP_MODE()
{
	echo "$(cat /sys/module/workqueue/parameters/power_efficient)" > /cache/power_efficient;
	echo "1" > /sys/module/workqueue/parameters/power_efficient;

	echo "$(cat /sys/module/sync/parameters/fsync_enabled)" > /cache/fsync_enabled;
	echo "1" > /sys/module/sync/parameters/fsync_enabled;

	echo "$(cat /sys/devices/system/cpu/cpu4/core_ctl/max_cpus)" > /cache/lc_corectl_state;
	echo "0" > /sys/devices/system/cpu/cpu4/core_ctl/max_cpus;

	echo "$(cat /sys/class/devfreq/1c00000.qcom,kgsl-3d0/max_freq)" > /cache/devfreq_max;
	echo "$(cat /sys/class/devfreq/1c00000.qcom,kgsl-3d0/min_freq)" > /cache/devfreq_min;
	echo "320000000" > /sys/class/devfreq/1c00000.qcom,kgsl-3d0/max_freq;
	echo "216000000" > /sys/class/devfreq/1c00000.qcom,kgsl-3d0/min_freq;

	echo "0" > /sys/kernel/printk_mode/printk_mode;

	echo "1" > /data/gabriel_cortex_sleep
}

# ==============================================================
# Background process to check screen state
# ==============================================================

while :
	do
	while [ "$(cat /sys/module/state_notifier/parameters/state_suspended)" == "Y" ]; do
		sleep "3"
	done
	# AWAKE State. all system ON
	AWAKE_MODE;

	while [ "$(cat /sys/module/state_notifier/parameters/state_suspended)" == "N" ]; do
		sleep "3"
	done
	# SLEEP state. All system to power save
	SLEEP_MODE;
done
