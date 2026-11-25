#!/system/bin/sh
MODDIR=${0%/*}
[ "$MODDIR" = "$0" ] && MODDIR="/data/adb/modules/fortnite_120hz_boost"
[ -d "$MODDIR/config" ] || MODDIR="/data/adb/modules/fortnite_120hz_boost"

if [ -f "$MODDIR/config/refresh_rate_config.xml" ]; then
    chcon u:object_r:system_file:s0 "$MODDIR/config/refresh_rate_config.xml" 2>/dev/null
    grep -q " /my_product/etc/refresh_rate_config.xml " /proc/mounts ||         mount -o bind "$MODDIR/config/refresh_rate_config.xml" /my_product/etc/refresh_rate_config.xml 2>/dev/null
    grep -q " /mnt/vendor/my_product/etc/refresh_rate_config.xml " /proc/mounts ||         mount -o bind "$MODDIR/config/refresh_rate_config.xml" /mnt/vendor/my_product/etc/refresh_rate_config.xml 2>/dev/null
fi

if [ -f "$MODDIR/config/thermallevel_to_fps.xml" ]; then
    chcon u:object_r:vendor_configs_file:s0 "$MODDIR/config/thermallevel_to_fps.xml" 2>/dev/null
    grep -q " /vendor/etc/display/thermallevel_to_fps.xml " /proc/mounts ||         mount -o bind "$MODDIR/config/thermallevel_to_fps.xml" /vendor/etc/display/thermallevel_to_fps.xml 2>/dev/null
fi
