# Fortnite 120Hz Boost & CPU Optimizer (OnePlus Pad 3 / OPD2415)

Dedicated Magisk / KernelSU / APatch module for **OnePlus Pad 3 (`OPD2415` / Snapdragon 8 Elite `SM8750`)** engineered to lock native 120 FPS in *Fortnite* (`com.epicgames.fortnite`) and run seamlessly alongside **[OnePlus-Pad-90W-Smart-Charge](https://github.com/NinjaDraco/OnePlus-Pad-90W-Smart-Charge)** (`v3.4.0+`).

---

## Core Features

1. **Systemless 120Hz Display & Thermal Cap Fix**
   - Bind-mounts `refresh_rate_config.xml` (`rateId="3-3-3-3"`, `disableViewOverride="true"`, `adfr="false"`) to `/my_product/etc/` and `/mnt/vendor/my_product/etc/` and syncs to `/data/system/` on boot.
   - Bind-mounts `thermallevel_to_fps.xml` (144 -> 120) to `/vendor/etc/display/` to eliminate 144Hz -> 72 FPS VSYNC halving.
2. **Low-Overhead State-Driven Watcher (`fortnite_watcher.sh`)**
   - Activates only while `com.epicgames.fortnite` is foregrounded with screen on (`dpms=On`).
   - Tunes `policy0`/`policy6` frequencies (`3.07GHz` / `4.32GHz`), `scx/target_loads=72`, `0-7` cpusets, `top-app` `uclamp`, full Adreno 830 band (`160MHz-1100MHz`), and 540Hz raw touch.
   - Automatically yields `scaling_max_freq` restoration back to `smart_power_daemon.sh` when exiting to idle/video/screen-off.
3. **CE-Safe UE5 Config Overrides**
   - Waits for `sys.user.0.ce_available=true` before touching `/data/data/com.epicgames.fortnite`.
   - Patches `GameUserSettings.ini` in-place (preserving your account, HUD layout, and audio mix) and protects it with `chattr +i`, alongside `DeviceProfiles.ini`, `Engine.ini`, `Scalability.ini`, and `UECommandLine.txt`.
4. **Clean Legacy Migration & Uninstall**
   - `customize.sh` removes legacy `fortnite_root_optimizer` if present.
   - `uninstall.sh` stops the watcher, cleans `/data/local/tmp/fortnite_120hz_boost.*`, and runs `chattr -i` on `GameUserSettings.ini`.

---

## Installation

> [!IMPORTANT]
> Download **`release/Fortnite_120Hz_Boost_v1.0.0.zip`** from the [Releases page](https://github.com/NinjaDraco/Fortnite-120Hz-Boost/releases) or `release/` folder.
> Do **not** use GitHub's green `Code -> Download ZIP` archive for flashing.

1. Flash `Fortnite_120Hz_Boost_v1.0.0.zip` in **Magisk** / **KernelSU** / **APatch**.
2. (Recommended) Use alongside **OnePlus-Pad-90W-Smart-Charge v3.4.0+** for 90W smart charging, speaker boost, and automatic `FORTNITE_BYPASS` handoff.
3. Reboot your tablet.
