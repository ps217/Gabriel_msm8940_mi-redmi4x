#!/gabriel/busybox sh

BB=/gabriel/busybox

# =======================================================================
# Screen-ON
# =======================================================================
AWAKE_MODE()
{
for f in /sys/devices/platform/kcal_ctrl.0/k*; do
	KCAL=`echo "$f" | awk -F/ '{print $NF}'`;
	echo "$(cat /cache/$KCAL)" > /sys/devices/platform/kcal_ctrl.0/$KCAL;
done;
}

# =======================================================================
# Screen-OFF
# =======================================================================
SLEEP_MODE()
{
for f in /sys/devices/platform/kcal_ctrl.0/k*; do
	KCAL=`echo "$f" | awk -F/ '{print $NF}'`;
	echo "$(cat /sys/devices/platform/kcal_ctrl.0/$KCAL)" > /cache/$KCAL;
done;
}

# =======================================================================
# Background process to check screen state
# =======================================================================

# Dynamic value do not change/delete
cortexbrain_background_process=1;

if [ "$cortexbrain_background_process" -eq "1" ]; then
	while :
		do
		while [ "$(cat /sys/module/ft5x06_720p/parameters/sleep_state)" -ne "0" ]; do
			sleep "0.1"
		done
		# AWAKE State. all system ON
		AWAKE_MODE;

		while [ "$(cat /sys/module/ft5x06_720p/parameters/sleep_state)" -ne "1" ]; do
			sleep "1"
		done
		# SLEEP state. All system OFF
		SLEEP_MODE;
	done
fi;
