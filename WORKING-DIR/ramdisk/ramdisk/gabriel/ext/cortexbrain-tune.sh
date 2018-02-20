#!/gabriel/busybox sh

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

BB=/gabriel/busybox

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
TELE_DATA=init;

# ==============================================================
# INITIATE
# ==============================================================

# get values from profile
PROFILE=`cat $DATA_DIR/.active.profile`;
. $DATA_DIR/${PROFILE}.profile;

# check if dumpsys exist in ROM
if [ -e /system/bin/dumpsys ]; then
	DUMPSYS_STATE=1;
else
	DUMPSYS_STATE=0;
fi;

# For CHARGER CHECK.
echo "1" > /data/gabriel_cortex_sleep;

rm -f /cache/fsync_enabled;
rm -f /cache/lc_corectl_state;

# ==============================================================
# FILES FOR VARIABLES
# ==============================================================

# WIFI HELPER
WIFI_HELPER_AWAKE="$DATA_DIR/WIFI_HELPER_AWAKE";
WIFI_HELPER_TMP="$DATA_DIR/WIFI_HELPER_TMP";
echo "1" > $WIFI_HELPER_TMP;

# MOBILE HELPER
MOBILE_HELPER_AWAKE="$DATA_DIR/MOBILE_HELPER_AWAKE";
MOBILE_HELPER_TMP="$DATA_DIR/MOBILE_HELPER_TMP";
echo "1" > $MOBILE_HELPER_TMP;

# ==============================================================
# I/O-TWEAKS
# ==============================================================
IO_TWEAKS()
{
if [ "$cortexbrain_io" == "on" ]; then

	local i="";

	local MMC=$(find /sys/block/mmc*);
	for i in $MMC; do
		echo "$scheduler" > "$i"/queue/scheduler;
		echo "0" > "$i"/queue/rotational;
		echo "0" > "$i"/queue/iostats;
	done;

	# This controls how many requests may be allocated
	# in the block layer for read or write requests.
	# Note that the total allocated number may be twice
	# this amount, since it applies only to reads or writes
	# (not the accumulated sum).
	echo "128" > /sys/block/mmcblk0/queue/nr_requests; # default: 128

	# our storage is 16/32GB, best is 1024KB readahead
	# see https://github.com/Keff/samsung-kernel-msm7x30/commit/a53f8445ff8d947bd11a214ab42340cc6d998600#L1R627
	echo "$read_ahead_kb" > /sys/block/mmcblk0/queue/read_ahead_kb;
	echo "$read_ahead_kb" > /sys/block/mmcblk0/bdi/read_ahead_kb;

	echo "$read_ahead_kb_ext" > /sys/block/mmcblk1/queue/read_ahead_kb;
	echo "$read_ahead_kb_ext" > /sys/block/mmcblk1/bdi/read_ahead_kb;

	echo "45" > /proc/sys/fs/lease-break-time;

fi;
}
IO_TWEAKS;

# ==============================================================
# IO-SCHEDULER
# ==============================================================

IO_SCHEDULER()
{
	local state="$1";

	if [ "$state" == "awake" ]; then
		/res/uci.sh scheduler $scheduler
		echo $scheduler_ext_awake > /sys/block/mmcblk1/queue/scheduler;
	elif [ "$state" == "sleep" ]; then
		/res/uci.sh scheduler $scheduler_int_sleep
		echo $scheduler_ext_sleep > /sys/block/mmcblk1/queue/scheduler;
	fi;

	log -p i -t $FILE_NAME "*** ENTROPY ***: $state - $PROFILE";
}

# ==============================================================
# KERNEL-TWEAKS
# ==============================================================
KERNEL_TWEAKS()
{
if [ "$cortexbrain_kernel_tweaks" == "on" ]; then
	echo "0" > /proc/sys/vm/oom_kill_allocating_task;
	echo "0" > /proc/sys/vm/panic_on_oom;
	echo "30" > /proc/sys/kernel/panic;
	echo "0" > /proc/sys/kernel/panic_on_oops;
fi;
}
KERNEL_TWEAKS;

# ==============================================================
# MEMORY-TWEAKS
# ==============================================================
MEMORY_TWEAKS()
{
if [ "$cortexbrain_memory" == "on" ]; then
	echo "$dirty_background_ratio" > /proc/sys/vm/dirty_background_ratio; # default: 20
	echo "$dirty_ratio" > /proc/sys/vm/dirty_ratio; # default: 25
	echo "4" > /proc/sys/vm/min_free_order_shift; # default: 4
	echo "1" > /proc/sys/vm/overcommit_memory; # default: 1
	echo "50" > /proc/sys/vm/overcommit_ratio; # default: 50
	echo "3" > /proc/sys/vm/page-cluster; # default: 3
	echo "8192" > /proc/sys/vm/min_free_kbytes; #default: 2572
	# mem calc here in pages. so 16384 x 4 = 64MB reserved for fast access by kernel and VM
	echo "32768" > /proc/sys/vm/mmap_min_addr; #default: 32768
fi;
}
MEMORY_TWEAKS;

# ==============================================================
# ENTROPY-TWEAKS
# ==============================================================

ENTROPY()
{
	local state="$1";

	if [ "$state" == "awake" ]; then
		/res/uci.sh entropytweaks $entropy_awake
	elif [ "$state" == "sleep" ]; then
		/res/uci.sh entropytweaks $entropy_sleep
	fi;

	log -p i -t $FILE_NAME "*** ENTROPY ***: $state - $PROFILE";
}

# ==============================================================
# CLOCK-FREQUENCY-SCALE
# ==============================================================

CLOCK_FREQ_SCALE()
{
	local state="$1";

	if [ "$state" == "awake" ]; then
		/res/uci.sh devfreq_soc_gov $devfreq_soc_gov
	elif [ "$state" == "sleep" ]; then
		/res/uci.sh devfreq_soc_gov $devfreq_soc_gov_suspend
	fi;

	log -p i -t $FILE_NAME "*** CLOCK-FREQUENCY-SCALE ***: $state - $PROFILE";
}

# ==============================================================
# BCL-STATE
# ==============================================================

BCL_STATE()
{
	local state="$1";

	if [ "$state" == "awake" ]; then
		/res/uci.sh bcl $bcl
	elif [ "$state" == "sleep" ]; then
		/res/uci.sh bcl $bcl_suspend
	fi;

	log -p i -t $FILE_NAME "*** BATTERY-CURRENT-LIMIT ***: $state - $PROFILE";
}

# ==============================================================
# FIREWALL-TWEAKS
# ==============================================================
FIREWALL_TWEAKS()
{
	if [ "$cortexbrain_firewall" == "on" ]; then
		# ping/icmp protection
		echo "1" > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts; # 1
		echo "1" > /proc/sys/net/ipv4/icmp_echo_ignore_all; # 0
		echo "1" > /proc/sys/net/ipv4/icmp_ignore_bogus_error_responses; # 1

		log -p i -t $FILE_NAME "*** FIREWALL_TWEAKS ***: enabled";

		return 1;
	else
		return 0;
	fi;
}
FIREWALL_TWEAKS;

# ==============================================================
# WIFI-NET-TWEAKS
# ==============================================================

WIFI_SET()
{
	local state="$1";

	if [ "$state" == "off" ]; then
		svc wifi disable;
		echo "1" > $WIFI_HELPER_AWAKE;
	elif [ "$state" == "on" ]; then
		svc wifi enable;
	fi;

	log -p i -t $FILE_NAME "*** WIFI ***: $state";
}

WIFI()
{
	local state="$1";

	if [ "$state" == "sleep" ]; then
		if [ "$cortexbrain_auto_tweak_wifi" == "on" ]; then
			if [ "$cortexbrain_auto_tweak_wifi_sleep_delay" -eq "0" ]; then
				WIFI_SET "off";
			else
				(
					echo "0" > $WIFI_HELPER_TMP;
					# screen time out but user want to keep it on and have wifi
					sleep 10;
					if [ `cat $WIFI_HELPER_TMP` -eq "0" ]; then
						# user did not turned screen on, so keep waiting
						local SLEEP_TIME_WIFI=$(( $cortexbrain_auto_tweak_wifi_sleep_delay - 10 ));
						log -p i -t $FILE_NAME "*** DISABLE_WIFI $cortexbrain_auto_tweak_wifi_sleep_delay Sec Delay Mode ***";
						sleep $SLEEP_TIME_WIFI;
						if [ `cat $WIFI_HELPER_TMP` -eq "0" ]; then
							# user left the screen off, then disable wifi
							WIFI_SET "off";
						fi;
					fi;
				)&
			fi;
		else
			echo "0" > $WIFI_HELPER_AWAKE;
		fi;
	elif [ "$state" == "awake" ]; then
		if [ "$cortexbrain_auto_tweak_wifi" == "on" ]; then
			echo "1" > $WIFI_HELPER_TMP;
			if [ `cat $WIFI_HELPER_AWAKE` -eq "1" ]; then
				WIFI_SET "on";
			fi;
		fi;
	fi;
}

MOBILE_DATA_SET()
{
	local state="$1";

	if [ "$state" == "off" ]; then
		svc data disable;
		echo "1" > $MOBILE_HELPER_AWAKE;
	elif [ "$state" == "on" ]; then
		svc data enable;
	fi;

	log -p i -t $FILE_NAME "*** MOBILE DATA ***: $state";
}

MOBILE_DATA_STATE()
{
	DATA_STATE_CHECK=0;

	if [ $DUMPSYS_STATE -eq "1" ]; then
		local DATA_STATE=`echo "$TELE_DATA" | awk '/mDataConnectionState/ {print $1}' | head -n 1`;

		if [ "$DATA_STATE" != "mDataConnectionState=0" ]; then
			DATA_STATE_CHECK=1;
		fi;
	fi;
}

MOBILE_DATA()
{
	local state="$1";

	if [ "$cortexbrain_auto_tweak_mobile" == "on" ]; then
		if [ "$state" == "sleep" ]; then
			MOBILE_DATA_STATE;
			if [ "$DATA_STATE_CHECK" -eq "1" ]; then
				if [ "$cortexbrain_auto_tweak_mobile_sleep_delay" -eq "0" ]; then
					MOBILE_DATA_SET "off";
				else
					(
						echo "0" > $MOBILE_HELPER_TMP;
						# screen time out but user want to keep it on and have mobile data
						sleep 10;
						if [ `cat $MOBILE_HELPER_TMP` -eq "0" ]; then
							# user did not turned screen on, so keep waiting
							local SLEEP_TIME_DATA=$(( $cortexbrain_auto_tweak_mobile_sleep_delay - 10 ));
							log -p i -t $FILE_NAME "*** DISABLE_MOBILE $cortexbrain_auto_tweak_mobile_sleep_delay Sec Delay Mode ***";
							sleep $SLEEP_TIME_DATA;
							if [ `cat $MOBILE_HELPER_TMP` -eq "0" ]; then
								# user left the screen off, then disable mobile data
								MOBILE_DATA_SET "off";
							fi;
						fi;
					)&
				fi;
			else
				echo "0" > $MOBILE_HELPER_AWAKE;
			fi;
		elif [ "$state" == "awake" ]; then
			echo "1" > $MOBILE_HELPER_TMP;
			if [ `cat $MOBILE_HELPER_AWAKE` -eq "1" ]; then
				MOBILE_DATA_SET "on";
			fi;
		fi;
	fi;
}

CPU_CENTRAL_CONTROL()
{
	local state="$1";

	if [ "$cortexbrain_cpu" == "on" ]; then

		if [ "$state" == "awake" ]; then

			if [ "$(cat /sys/module/msm_performance/parameters/cpu_max_freq | awk '{print $1}' | cut -d : -f 2)" -ne "$cpu_b_max_freq" ]; then
				echo "0:$cpu_b_max_freq 1:$cpu_b_max_freq 2:$cpu_b_max_freq 3:$cpu_b_max_freq" > /sys/module/msm_performance/parameters/cpu_max_freq
			fi;
			if [ "$(cat /sys/module/msm_performance/parameters/cpu_max_freq | awk '{print $5}' | cut -d : -f 2)" -ne "$cpu_l_max_freq" ]; then
				echo "4:$cpu_l_max_freq 5:$cpu_l_max_freq 6:$cpu_l_max_freq 7:$cpu_l_max_freq" > /sys/module/msm_performance/parameters/cpu_max_freq
			fi;
			if [ "$(cat /sys/module/msm_performance/parameters/cpu_min_freq | awk '{print $1}' | cut -d : -f 2)" -ne "$cpu_b_min_freq" ]; then
				echo "0:$cpu_b_min_freq 1:$cpu_b_min_freq 2:$cpu_b_min_freq 3:$cpu_b_min_freq" > /sys/module/msm_performance/parameters/cpu_min_freq
			fi;
			if [ "$(cat /sys/module/msm_performance/parameters/cpu_min_freq | awk '{print $5}' | cut -d : -f 2)" -ne "$cpu_l_min_freq" ]; then
				echo "4:$cpu_l_min_freq 5:$cpu_l_min_freq 6:$cpu_l_min_freq 7:$cpu_l_min_freq" > /sys/module/msm_performance/parameters/cpu_min_freq
			fi;

			if [ -e /res/uci_boot.sh ]; then
				/res/uci_boot.sh power_mode $power_mode > /dev/null;
			else
				/res/uci.sh power_mode $power_mode > /dev/null;
			fi;

		elif [ "$state" == "sleep" ]; then

			if [ "$(cat /sys/module/msm_performance/parameters/cpu_max_freq | awk '{print $1}' | cut -d : -f 2)" -ne "$suspend_max_freq_cb" ]; then
				echo "0:$suspend_max_freq_cb 1:$suspend_max_freq_cb 2:$suspend_max_freq_cb 3:$suspend_max_freq_cb" > /sys/module/msm_performance/parameters/cpu_max_freq
			fi;

			if [ "$(cat /sys/module/msm_performance/parameters/cpu_max_freq | awk '{print $5}' | cut -d : -f 2)" -ne "$suspend_max_freq_cl" ]; then
				echo "4:$suspend_max_freq_cl 5:$suspend_max_freq_cl 6:$suspend_max_freq_cl 7:$suspend_max_freq_cl" > /sys/module/msm_performance/parameters/cpu_max_freq
			fi;

			if [ "$(cat /sys/module/msm_performance/parameters/cpu_min_freq | awk '{print $1}' | cut -d : -f 2)" != "902000" ]; then
				echo "0:902000 1:902000 2:902000 3:902000" > /sys/module/msm_performance/parameters/cpu_min_freq
			fi;

			if [ "$(cat /sys/module/msm_performance/parameters/cpu_min_freq | awk '{print $5}' | cut -d : -f 2)" != "768000" ]; then
				echo "4:768000 5:768000 6:768000 7:768000" > /sys/module/msm_performance/parameters/cpu_min_freq
			fi;


		fi;
	else
		if [ "$state" == "awake" ]; then

			echo "0:$cpu_b_min_freq 1:$cpu_b_min_freq 2:$cpu_b_min_freq 3:$cpu_b_min_freq" > /sys/module/msm_performance/parameters/cpu_min_freq
			echo "4:$cpu_l_min_freq 5:$cpu_l_min_freq 6:$cpu_l_min_freq 7:$cpu_l_min_freq" > /sys/module/msm_performance/parameters/cpu_min_freq

			if [ -e /res/uci_boot.sh ]; then
				/res/uci_boot.sh power_mode $power_mode > /dev/null;
			else
				/res/uci.sh power_mode $power_mode > /dev/null;
			fi;

		elif [ "$state" == "sleep" ]; then

			if [ "$(cat /sys/module/msm_performance/parameters/cpu_min_freq | awk '{print $1}' | cut -d : -f 2)" != "902000" ]; then
				echo "0:902000 1:902000 2:902000 3:902000" > /sys/module/msm_performance/parameters/cpu_min_freq
			fi;

			if [ "$(cat /sys/module/msm_performance/parameters/cpu_min_freq | awk '{print $5}' | cut -d : -f 2)" != "768000" ]; then
				echo "4:768000 5:768000 6:768000 7:768000" > /sys/module/msm_performance/parameters/cpu_min_freq
			fi;

		fi;

	fi;
}

# ==============================================================
# TWEAKS: if Screen-ON
# ==============================================================
AWAKE_MODE()
{
if [ "$(cat /data/gabriel_cortex_sleep)" -eq "1" ]; then

	if [ "$power_efficient" == "on" ]; then
		echo "1" > /sys/module/workqueue/parameters/power_efficient
	else
		echo "0" > /sys/module/workqueue/parameters/power_efficient
	fi

	echo "$(cat /cache/fsync_enabled)" > /sys/module/sync/parameters/fsync_enabled;

	echo "$(cat /cache/lc_corectl_state)" > /sys/devices/system/cpu/cpu4/core_ctl/max_cpus;

	if [ "$run" == "on" ]; then
		echo "1" > /sys/kernel/mm/uksm/run # to be enable if sleep state was off.
		echo "$uksm_gov_on" > /sys/kernel/mm/uksm/cpu_governor
		echo "$max_cpu_percentage" > /sys/kernel/mm/uksm/max_cpu_percentage
	fi

	ENTROPY "awake";
	IO_SCHEDULER "awake";
	CLOCK_FREQ_SCALE "awake";
	BCL_STATE "awake";
	CPU_CENTRAL_CONTROL "awake";

	WIFI "awake";
	MOBILE_DATA "awake";

#	echo "1" > /sys/kernel/printk_mode/printk_mode;

	echo "0" > /data/gabriel_cortex_sleep
fi
}

# ==============================================================
# TWEAKS: if Screen-OFF
# ==============================================================
SLEEP_MODE()
{
	# we only read the config when the screen turns off ...
	PROFILE=$(cat "$DATA_DIR"/.active.profile);
	. "$DATA_DIR"/"$PROFILE".profile;

	# we only read tele-data when the screen turns off ...
	if [ "$DUMPSYS_STATE" -eq "1" ]; then
		TELE_DATA=`dumpsys telephony.registry`;
	fi;

	echo "1" > /sys/module/workqueue/parameters/power_efficient;

	echo "$(cat /sys/module/sync/parameters/fsync_enabled)" > /cache/fsync_enabled;
	echo "1" > /sys/module/sync/parameters/fsync_enabled;

	echo "$(cat /sys/devices/system/cpu/cpu4/core_ctl/max_cpus)" > /cache/lc_corectl_state;
	echo "2" > /sys/devices/system/cpu/cpu4/core_ctl/max_cpus;

	if [ "$run" == "on" ] && [ "$uksm_sleep" == "on" ]; then
		echo "$uksm_gov_sleep" > /sys/kernel/mm/uksm/cpu_governor
		echo "$max_cpu_percentage_sleep" > /sys/kernel/mm/uksm/max_cpu_percentage
	elif [ "$run" == "on" ] && [ "$uksm_sleep" == "off" ]; then
		echo "0" > /sys/kernel/mm/uksm/run
	fi

	ENTROPY "sleep";
	IO_SCHEDULER "sleep";
	CLOCK_FREQ_SCALE "sleep";
	BCL_STATE "sleep";
	CPU_CENTRAL_CONTROL "sleep";

	WIFI "sleep";
	MOBILE_DATA "sleep";

#	echo "0" > /sys/kernel/printk_mode/printk_mode;

	echo "1" > /data/gabriel_cortex_sleep
}

# ==============================================================
# Background process to check screen state
# ==============================================================

# Dynamic value do not change/delete
cortexbrain_background_process=1;

if [ "$cortexbrain_background_process" -eq "1" ]; then
	while :
		do
		while [ "$(cat /sys/module/ft5x06_ts/parameters/sleep_state)" -ne "0" ]; do
			sleep "3"
		done
		# AWAKE State. all system ON
		AWAKE_MODE;

		while [ "$(cat /sys/module/ft5x06_ts/parameters/sleep_state)" -ne "1" ]; do
			sleep "3"
		done
		# SLEEP state. All system to power save
		SLEEP_MODE;
	done
fi;
