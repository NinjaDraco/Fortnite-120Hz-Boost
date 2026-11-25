#!/system/bin/sh
##########################################################################################
# Fortnite 120Hz Boost & CPU Optimizer Watcher (OPD2415 / SM8750P)
# State-driven low-overhead daemon: zero dumpsys/settings spam while idle or in-match.
##########################################################################################

MODDIR="/data/adb/modules/fortnite_120hz_boost"
LOG_FILE="/data/local/tmp/fortnite_120hz_boost.log"
PID_FILE="/data/local/tmp/fortnite_120hz_boost.pid"
CONF_FILE="/data/data/com.epicgames.fortnite/files/UnrealGame/FortniteGame/FortniteGame/Saved/Config/Android/GameUserSettings.ini"

if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE" 2>/dev/null)
    if [ -n "$OLD_PID" ] && [ "$OLD_PID" != "$$" ] && kill -0 "$OLD_PID" 2>/dev/null; then
        exit 0
    fi
fi
echo $$ > "$PID_FILE"

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WATCHER] $1" >> "$LOG_FILE" 2>/dev/null
}

rotate_log() {
    if [ -f "$LOG_FILE" ]; then
        sz=$(wc -c < "$LOG_FILE" 2>/dev/null || echo 0)
        if [ "$sz" -gt 65536 ] 2>/dev/null; then
            tail -n 150 "$LOG_FILE" > "$LOG_FILE.tmp" 2>/dev/null
            mv "$LOG_FILE.tmp" "$LOG_FILE" 2>/dev/null
        fi
    fi
}

write_if_diff() {
    val="$1"
    path="$2"
    [ -e "$path" ] || return 0
    cur=$(cat "$path" 2>/dev/null)
    if [ "$cur" != "$val" ]; then
        chmod 0666 "$path" 2>/dev/null
        echo "$val" > "$path" 2>/dev/null
    fi
}

apply_120hz_display() {
    settings put system peak_refresh_rate 120.0 2>/dev/null
    settings put system min_refresh_rate 120.0 2>/dev/null
    settings put system user_refresh_rate 120.0 2>/dev/null
    settings put global user_preferred_refresh_rate 120.00001 2>/dev/null
    settings put system oplus_max_refresh_rate 120 2>/dev/null
    settings put system oplus_game_refresh_rate 120 2>/dev/null
    settings put secure oplus_customize_screen_refresh_rate 3 2>/dev/null
    settings put global oplus_customize_screen_refresh_rate 3 2>/dev/null
    settings put secure oplus_refreshrate_override 0 2>/dev/null
    cmd display set-user-preferred-display-mode 2400 3392 120.00001 >/dev/null 2>&1
    cmd game set --fps 120 com.epicgames.fortnite >/dev/null 2>&1
    cmd game mode custom com.epicgames.fortnite >/dev/null 2>&1
}

apply_gaming_tuning() {
    # Keep Prime cluster (CPUs 6-7) unlocked at 4.32GHz; cap Oryon-L (policy0) at 3.07GHz
    # to curb 6-core heat buildup before skin hits 60C thermal throttling.
    write_if_diff "3072000" /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq
    write_if_diff "4320000" /sys/devices/system/cpu/cpufreq/policy6/scaling_max_freq
    write_if_diff "748800" /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq
    write_if_diff "1017600" /sys/devices/system/cpu/cpufreq/policy6/scaling_min_freq

    # Lower scx target_loads (90 -> 72) for snappier frequency ramp on UE5 bursts
    write_if_diff "72" /sys/devices/system/cpu/cpufreq/policy0/scx/target_loads
    write_if_diff "72" /sys/devices/system/cpu/cpufreq/policy6/scx/target_loads

    # Ensure top-app and g-others cpusets include all 8 cores (undo 0-5 sub-bucket cap)
    write_if_diff "0-7" /dev/cpuset/top-app/cpus
    write_if_diff "0-7" /dev/cpuset/top-app/g-others/cpus

    # uclamp latency sensitivity + floor for top-app threads
    write_if_diff "1" /dev/cpuctl/top-app/cpu.uclamp.latency_sensitive
    write_if_diff "20.00" /dev/cpuctl/top-app/cpu.uclamp.min
    write_if_diff "max" /dev/cpuctl/top-app/cpu.uclamp.max

    # Clear CPU cluster thermal cooling state cleanly (keep 0644 perms)
    for cd in /sys/class/thermal/cooling_device32/cur_state /sys/class/thermal/cooling_device33/cur_state; do
        if [ -e "$cd" ]; then
            chmod 0644 "$cd" 2>/dev/null
            cur=$(cat "$cd" 2>/dev/null)
            [ "$cur" != "0" ] && echo 0 > "$cd" 2>/dev/null
        fi
    done

    # WALT sched_boost hint if present
    [ -e /proc/sys/walt/sched_boost ] && write_if_diff "1" /proc/sys/walt/sched_boost

    # Adreno 830 full dynamic band
    write_if_diff "160000000" /sys/class/kgsl/kgsl-3d0/devfreq/min_freq
    write_if_diff "1100000000" /sys/class/kgsl/kgsl-3d0/devfreq/max_freq

    # Esports raw touch
    if [ -d /proc/touchpanel ]; then
        echo 1 > /proc/touchpanel/game_switch_enable 2>/dev/null
        echo 0 > /proc/touchpanel/sensitive_level 2>/dev/null
        echo 0 > /proc/touchpanel/smooth_level 2>/dev/null
    fi
}

guard_gaming_nodes() {
    # Pure sysfs check/repair while Fortnite is foregrounded (zero dumpsys/settings IPC)
    p0=$(cat /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq 2>/dev/null || echo 0)
    [ "$p0" -lt 2745600 ] 2>/dev/null && write_if_diff "3072000" /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq
    p6=$(cat /sys/devices/system/cpu/cpufreq/policy6/scaling_max_freq 2>/dev/null || echo 0)
    [ "$p6" -lt 4089600 ] 2>/dev/null && write_if_diff "4320000" /sys/devices/system/cpu/cpufreq/policy6/scaling_max_freq

    write_if_diff "72" /sys/devices/system/cpu/cpufreq/policy0/scx/target_loads
    write_if_diff "72" /sys/devices/system/cpu/cpufreq/policy6/scx/target_loads
    write_if_diff "0-7" /dev/cpuset/top-app/cpus
    write_if_diff "0-7" /dev/cpuset/top-app/g-others/cpus
    write_if_diff "1" /dev/cpuctl/top-app/cpu.uclamp.latency_sensitive
    write_if_diff "20.00" /dev/cpuctl/top-app/cpu.uclamp.min
    write_if_diff "1100000000" /sys/class/kgsl/kgsl-3d0/devfreq/max_freq

    for cd in /sys/class/thermal/cooling_device32/cur_state /sys/class/thermal/cooling_device33/cur_state; do
        if [ -e "$cd" ]; then
            cur=$(cat "$cd" 2>/dev/null)
            if [ "$cur" != "0" ]; then
                chmod 0644 "$cd" 2>/dev/null
                echo 0 > "$cd" 2>/dev/null
            fi
        fi
    done
}

restore_idle_defaults() {
    write_if_diff "90" /sys/devices/system/cpu/cpufreq/policy0/scx/target_loads
    write_if_diff "90" /sys/devices/system/cpu/cpufreq/policy6/scx/target_loads
    write_if_diff "0" /dev/cpuctl/top-app/cpu.uclamp.latency_sensitive
    write_if_diff "0.00" /dev/cpuctl/top-app/cpu.uclamp.min
    write_if_diff "0-5" /dev/cpuset/top-app/g-others/cpus
    # Avoid racing with smart_power_daemon.sh when it takes over DAILY/VIDEO/SCREEN_OFF
    sp_pid=$(cat /data/local/tmp/smart_power_daemon.pid 2>/dev/null)
    if [ -z "$sp_pid" ] || ! kill -0 "$sp_pid" 2>/dev/null; then
        write_if_diff "3532800" /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq
        write_if_diff "4320000" /sys/devices/system/cpu/cpufreq/policy6/scaling_max_freq
    fi
}

is_fortnite_foreground() {
    p="$1"
    [ -n "$p" ] && [ -d "/proc/$p" ] || return 1
    dpms=$(cat /sys/class/drm/card0-DSI-1/dpms 2>/dev/null)
    [ -z "$dpms" ] || [ "$dpms" = "On" ] || return 1
    cpuset=$(cat "/proc/$p/cpuset" 2>/dev/null)
    case "$cpuset" in
        /top-app*) return 0 ;;
    esac
    oom=$(cat "/proc/$p/oom_score_adj" 2>/dev/null)
    [ "$oom" = "0" ] && return 0
    return 1
}

ensure_gus_immutable() {
    if [ -f "$CONF_FILE" ]; then
        if ! lsattr "$CONF_FILE" 2>/dev/null | awk '{print $1}' | grep -q 'i'; then
            chattr +i "$CONF_FILE" 2>/dev/null
            log_msg "Reinforced chattr +i on GameUserSettings.ini"
        fi
    fi
}

log_msg "Watcher started (PID: $$). Waiting for com.epicgames.fortnite..."
FORT_PID=""
ACTIVE=0

while :; do
    if [ -f "$MODDIR/disable" ] || [ -f "$MODDIR/remove" ]; then
        [ "$ACTIVE" = "1" ] && restore_idle_defaults
        exit 0
    fi

    rotate_log

    if [ -z "$FORT_PID" ] || [ ! -d "/proc/$FORT_PID" ]; then
        FORT_PID=$(pidof com.epicgames.fortnite 2>/dev/null | awk '{print $1}')
    fi

    if [ -n "$FORT_PID" ] && is_fortnite_foreground "$FORT_PID"; then
        if [ "$ACTIVE" = "0" ]; then
            ACTIVE=1
            log_msg "Fortnite active/foreground (PID: $FORT_PID). Applying 120Hz lock & CPU/scx/uclamp tuning."
            ensure_gus_immutable
            apply_120hz_display
            apply_gaming_tuning
        else
            guard_gaming_nodes
        fi
    else
        if [ "$ACTIVE" = "1" ]; then
            ACTIVE=0
            log_msg "Fortnite exited/backgrounded/screen-off. Restoring idle scx/uclamp defaults."
            restore_idle_defaults
        fi
    fi

    sleep 4
done
