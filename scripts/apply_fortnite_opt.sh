#!/system/bin/sh
SCRIPT_DIR=${0%/*}
MODDIR=${1:-${SCRIPT_DIR%/scripts}}
[ -d "$MODDIR/config" ] || MODDIR="/data/adb/modules/fortnite_120hz_boost"
SRC_DIR="$MODDIR/config"
DATA_DIR="/data/data/com.epicgames.fortnite"
FORT_DIR="$DATA_DIR/files"
UE_DIR="$FORT_DIR/UnrealGame/FortniteGame/FortniteGame"
CONF_DIR="$UE_DIR/Saved/Config/Android"
SD_UE_DIR="/sdcard/Android/data/com.epicgames.fortnite/files/UnrealGame/FortniteGame/FortniteGame"

log_apply() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [APPLY] $1"
}

if [ "$(getprop sys.user.0.ce_available)" != "true" ]; then
    log_apply "ERROR: CE storage not unlocked yet; skipping config deployment."
    exit 1
fi

if [ ! -d "$DATA_DIR" ]; then
    log_apply "WARN: $DATA_DIR not found; skipping config deployment."
    exit 0
fi

FORT_UG=$(stat -c '%u:%g' "$DATA_DIR" 2>/dev/null)
[ -z "$FORT_UG" ] && FORT_UG="10387:10387"

mkdir -p "$CONF_DIR" 2>/dev/null
chown "$FORT_UG" "$CONF_DIR" 2>/dev/null
chcon u:object_r:app_data_file:s0 "$CONF_DIR" 2>/dev/null

# 1. Deploy/patch and immutable-lock GameUserSettings.ini (preserve existing user HUD/account data)
if [ -f "$SRC_DIR/GameUserSettings.ini" ]; then
    GUS="$CONF_DIR/GameUserSettings.ini"
    chattr -i "$GUS" 2>/dev/null
    chmod 0644 "$GUS" 2>/dev/null
    deploy_ok=0
    if [ -s "$GUS" ]; then
        GUS_TMP="$GUS.tmp"
        if awk '
        function flush_fort(    i, k) {
            if (in_fort && !fort_done) {
                for (i = 1; i <= nf; i++) {
                    k = fk[i]
                    if (!(k in seen)) {
                        print k "=" o[k]
                        seen[k] = 1
                    }
                }
                fort_done = 1
            }
        }
        function flush_sg(    i, k) {
            if (in_sg && !sg_done) {
                for (i = 1; i <= ns; i++) {
                    k = sk[i]
                    if (!(k in seen)) {
                        print k "=" o[k]
                        seen[k] = 1
                    }
                }
                sg_done = 1
            }
        }
        BEGIN {
            o["bUseDynamicResolution"] = "False"
            o["bMotionBlur"] = "False"
            o["bShowGrass"] = "False"
            o["bShowFPS"] = "True"
            o["bStopRenderingInBackground"] = "False"
            o["LatencyTweak2"] = "1"
            o["FortAntiAliasingMethod"] = "Disabled"
            o["NeverUpscaledResolutionQuality"] = "75.000000"
            o["bUseNanite"] = "False"
            o["DesiredGlobalIlluminationQuality"] = "0"
            o["DesiredReflectionQuality"] = "0"
            o["PreNaniteGlobalIlluminationQuality"] = "0"
            o["PreNaniteReflectionQuality"] = "0"
            o["b120FpsMode"] = "True"
            o["FrontendFrameRateLimit"] = "120"
            o["bIsEnergySavingEnabledIdle"] = "False"
            o["bIsEnergySavingEnabledFocusLoss"] = "False"
            o["EnergySavingLevelFocusLoss"] = "0"
            o["MobileFPSMode"] = "Mode_120Fps"
            o["bUseVSync"] = "False"
            o["FrameRateLimit"] = "120.000000"
            nf = split("bUseDynamicResolution,bMotionBlur,bShowGrass,bShowFPS,bStopRenderingInBackground,LatencyTweak2,FortAntiAliasingMethod,NeverUpscaledResolutionQuality,bUseNanite,DesiredGlobalIlluminationQuality,DesiredReflectionQuality,PreNaniteGlobalIlluminationQuality,PreNaniteReflectionQuality,b120FpsMode,FrontendFrameRateLimit,bIsEnergySavingEnabledIdle,bIsEnergySavingEnabledFocusLoss,EnergySavingLevelFocusLoss,MobileFPSMode,bUseVSync,FrameRateLimit", fk, ",")

            o["sg.ResolutionQuality"] = "75.000000"
            o["sg.ViewDistanceQuality"] = "0"
            o["sg.AntiAliasingQuality"] = "0"
            o["sg.ShadowQuality"] = "0"
            o["sg.GlobalIlluminationQuality"] = "0"
            o["sg.ReflectionQuality"] = "0"
            o["sg.PostProcessQuality"] = "0"
            o["sg.TextureQuality"] = "0"
            o["sg.EffectsQuality"] = "0"
            o["sg.FoliageQuality"] = "0"
            o["sg.ShadingQuality"] = "0"
            o["sg.LandscapeQuality"] = "0"
            ns = split("sg.ResolutionQuality,sg.ViewDistanceQuality,sg.AntiAliasingQuality,sg.ShadowQuality,sg.GlobalIlluminationQuality,sg.ReflectionQuality,sg.PostProcessQuality,sg.TextureQuality,sg.EffectsQuality,sg.FoliageQuality,sg.ShadingQuality,sg.LandscapeQuality", sk, ",")
        }
        {
            sub(/\r$/, "")
            if ($0 ~ /^\[.*\]$/) {
                flush_fort()
                flush_sg()
                in_fort = ($0 == "[/Script/FortniteGame.FortGameUserSettings]")
                in_sg = ($0 == "[ScalabilityGroups]")
                if (in_fort) saw_fort = 1
                if (in_sg) saw_sg = 1
                print
                next
            }
            if ($0 !~ /^[[:space:]]*;/ && index($0, "=") > 0) {
                pos = index($0, "=")
                k = substr($0, 1, pos - 1)
                if (k in o) {
                    print k "=" o[k]
                    seen[k] = 1
                    next
                }
            }
            print
        }
        END {
            flush_fort()
            flush_sg()
            if (!saw_fort) {
                print ""
                print "[/Script/FortniteGame.FortGameUserSettings]"
                in_fort = 1
                flush_fort()
            }
            if (!saw_sg) {
                print ""
                print "[ScalabilityGroups]"
                in_sg = 1
                flush_sg()
            }
        }
        ' "$GUS" > "$GUS_TMP" && mv -f "$GUS_TMP" "$GUS"; then
            deploy_ok=1
        else
            rm -f "$GUS_TMP" 2>/dev/null
        fi
    else
        if cp -f "$SRC_DIR/GameUserSettings.ini" "$GUS"; then
            deploy_ok=1
        fi
    fi

    if [ "$deploy_ok" = "1" ]; then
        chown "$FORT_UG" "$GUS" 2>/dev/null
        chmod 0644 "$GUS" 2>/dev/null
        chcon u:object_r:app_data_file:s0 "$GUS" 2>/dev/null
        if chattr +i "$GUS" 2>/dev/null; then
            if lsattr "$GUS" 2>/dev/null | awk '{print $1}' | grep -q 'i'; then
                log_apply "GameUserSettings.ini deployed and chattr +i verified."
            else
                log_apply "ERROR: chattr +i verification failed on $GUS"
            fi
        else
            log_apply "ERROR: chattr +i failed on $GUS"
        fi
    else
        log_apply "ERROR: failed to deploy GameUserSettings.ini"
    fi
fi

# 2. Deploy DeviceProfiles.ini, Engine.ini, Scalability.ini (writable/readable by app, non-immutable so UE can inspect without crashing)
for ini in DeviceProfiles.ini Engine.ini Scalability.ini; do
    if [ -f "$SRC_DIR/$ini" ]; then
        TARGET="$CONF_DIR/$ini"
        chattr -i "$TARGET" 2>/dev/null
        if cp -f "$SRC_DIR/$ini" "$TARGET"; then
            chown "$FORT_UG" "$TARGET" 2>/dev/null
            chmod 0644 "$TARGET" 2>/dev/null
            chcon u:object_r:app_data_file:s0 "$TARGET" 2>/dev/null
            log_apply "$ini deployed."
        else
            log_apply "ERROR: failed to copy $ini"
        fi
    fi
done

# 3. Deploy UECommandLine.txt to internal and sdcard search paths (remove stale UE4CommandLine.txt)
if [ -f "$SRC_DIR/UECommandLine.txt" ]; then
    for target in "$FORT_DIR/UECommandLine.txt" "$FORT_DIR/UnrealGame/FortniteGame/UECommandLine.txt" "$UE_DIR/UECommandLine.txt"; do
        cp -f "$SRC_DIR/UECommandLine.txt" "$target" 2>/dev/null
        chown "$FORT_UG" "$target" 2>/dev/null
        chmod 0644 "$target" 2>/dev/null
        chcon u:object_r:app_data_file:s0 "$target" 2>/dev/null
    done
    if [ -d "$SD_UE_DIR" ]; then
        cp -f "$SRC_DIR/UECommandLine.txt" "$SD_UE_DIR/UECommandLine.txt" 2>/dev/null
        chmod 0664 "$SD_UE_DIR/UECommandLine.txt" 2>/dev/null
        rm -f "$SD_UE_DIR/UE4CommandLine.txt" 2>/dev/null
    fi
    log_apply "UECommandLine.txt deployed."
fi

# 4. Android GameManager 120 FPS override & default 120Hz display mode (avoid 144Hz->72FPS)
cmd display set-user-preferred-display-mode 2400 3392 120.00001 >/dev/null 2>&1
cmd game set --fps 120 com.epicgames.fortnite >/dev/null 2>&1
cmd game mode custom com.epicgames.fortnite >/dev/null 2>&1
log_apply "Display preferred 120Hz (2400x3392@120.00001) & GameManager custom 120 FPS applied."

exit 0
