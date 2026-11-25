#!/system/bin/sh
PID_FILE="/data/local/tmp/fortnite_120hz_boost.pid"
CONF_DIR="/data/data/com.epicgames.fortnite/files/UnrealGame/FortniteGame/FortniteGame/Saved/Config/Android"

if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE" 2>/dev/null)
    if [ -n "$OLD_PID" ]; then
        kill "$OLD_PID" 2>/dev/null
    fi
fi
pkill -f "fortnite_watcher.sh" 2>/dev/null

rm -f /data/local/tmp/fortnite_120hz_boost.* 2>/dev/null

for ini in GameUserSettings.ini DeviceProfiles.ini Engine.ini Scalability.ini; do
    if [ -f "$CONF_DIR/$ini" ]; then
        chattr -i "$CONF_DIR/$ini" 2>/dev/null
    fi
done

cmd game mode standard com.epicgames.fortnite >/dev/null 2>&1
