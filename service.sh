#!/system/bin/sh
MODDIR=${0%/*}
[ "$MODDIR" = "$0" ] && MODDIR="/data/adb/modules/fortnite_120hz_boost"
[ -d "$MODDIR/scripts" ] || MODDIR="/data/adb/modules/fortnite_120hz_boost"
LOGFILE="/data/local/tmp/fortnite_120hz_boost.log"

log_svc() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SERVICE] $1" >> "$LOGFILE" 2>/dev/null
}

# Wait for boot AND CE storage availability (prevents missing /data/data before unlock)
while [ "$(getprop sys.boot_completed)" != "1" ] || [ "$(getprop sys.user.0.ce_available)" != "true" ]; do
    sleep 2
done

log_svc "Boot & CE storage ready. Initializing fortnite_120hz_boost..."

# Sync refresh_rate_config.xml to /data/system for dynamic framework detection
if [ -f "$MODDIR/config/refresh_rate_config.xml" ]; then
    cp -f "$MODDIR/config/refresh_rate_config.xml" /data/system/refresh_rate_config.xml 2>/dev/null
    chown system:system /data/system/refresh_rate_config.xml 2>/dev/null
    chmod 0644 /data/system/refresh_rate_config.xml 2>/dev/null
    chcon u:object_r:system_data_file:s0 /data/system/refresh_rate_config.xml 2>/dev/null
fi

# Deploy and lock Fortnite configs + GameManager mode
if [ -f "$MODDIR/scripts/apply_fortnite_opt.sh" ]; then
    /system/bin/sh "$MODDIR/scripts/apply_fortnite_opt.sh" "$MODDIR" >> "$LOGFILE" 2>&1
fi

# Spawn state-driven watcher with single-instance watchdog
if [ -f "$MODDIR/scripts/fortnite_watcher.sh" ]; then
    rm -f /data/local/tmp/fortnite_120hz_boost.pid 2>/dev/null
    (
        while :; do
            if [ ! -f "$MODDIR/scripts/fortnite_watcher.sh" ] || [ -f "$MODDIR/disable" ] || [ -f "$MODDIR/remove" ]; then
                break
            fi
            nohup /system/bin/sh "$MODDIR/scripts/fortnite_watcher.sh" >/dev/null 2>&1 &
            W_PID=$!
            while kill -0 "$W_PID" 2>/dev/null; do
                sleep 15
            done
            wait "$W_PID" 2>/dev/null
            sleep 3
        done
    ) &
    log_svc "Fortnite 120Hz watcher watchdog spawned."
fi

exit 0
