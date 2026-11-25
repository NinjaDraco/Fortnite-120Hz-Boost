SKIPMOUNT=false
PROPFILE=true
POSTFSDATA=true
LATESTARTSERVICE=true

ui_print "********************************************************"
ui_print "*  Fortnite 120Hz Boost & CPU Optimizer (OPD2415)      *"
ui_print "*  Compatible with OnePlus-Pad-90W-Smart-Charge v3.4+  *"
ui_print "********************************************************"

# Clean up legacy fortnite_root_optimizer module & daemon if present
if [ -d "/data/adb/modules/fortnite_root_optimizer" ] || [ -d "/data/adb/modules_update/fortnite_root_optimizer" ]; then
    ui_print "- Cleaning up legacy fortnite_root_optimizer..."
    pkill -f "fortnite_guardian.sh" 2>/dev/null
    rm -f /data/local/tmp/fortnite_guardian.pid /data/local/tmp/fortnite_guardian.log /data/local/tmp/fortnite_optimizer.log 2>/dev/null
    if [ -d "/data/adb/modules/fortnite_root_optimizer" ]; then
        touch /data/adb/modules/fortnite_root_optimizer/disable 2>/dev/null
        touch /data/adb/modules/fortnite_root_optimizer/remove 2>/dev/null
        rm -rf /data/adb/modules/fortnite_root_optimizer 2>/dev/null
    fi
    rm -rf /data/adb/modules_update/fortnite_root_optimizer 2>/dev/null
fi

ui_print "- Setting module permissions..."
set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/post-fs-data.sh" 0 0 0755
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/uninstall.sh" 0 0 0755
set_perm_recursive "$MODPATH/scripts" 0 0 0755 0755

if [ -f "$MODPATH/sepolicy.rule" ]; then
    ui_print "- Applying SELinux policy rules..."
    magiskpolicy --apply "$MODPATH/sepolicy.rule" --live 2>/dev/null
fi

if [ "$(getprop sys.user.0.ce_available)" = "true" ] && [ -d "/data/data/com.epicgames.fortnite" ]; then
    ui_print "- Deploying Fortnite 120Hz configs..."
    /system/bin/sh "$MODPATH/scripts/apply_fortnite_opt.sh" "$MODPATH"
else
    ui_print "- Configs will deploy automatically after unlock/boot."
fi

ui_print "- Done! Reboot to activate bind-mounts and state watcher."
