# Fortnite 120Hz Boost & CPU Optimizer - Changelog

## [v1.0.1] - 2026-11-28

- **Fix Post-Reboot PID Reuse**: Clears stale `fortnite_120hz_boost.pid` in `service.sh` and verifies `/proc/$OLD_PID/cmdline` in `fortnite_watcher.sh` so an unrelated post-reboot PID never blocks watcher startup.
- **SukiSU / KernelSU Verified**: Tested and verified under SukiSU (`ksud`) alongside `OnePlus-Pad-90W-Smart-Charge` `v3.4.2`.

## [v1.0.0] - 2026-11-25

- Initial release for OnePlus Pad 3 (`OPD2415` / Snapdragon 8 Elite `SM8750`).
- **144Hz -> 120Hz Half-Rate Lock Fix**: Bind-mounts `refresh_rate_config.xml` (`rateId="3-3-3-3"`, `disableViewOverride="true"`, `adfr="false"`) and `thermallevel_to_fps.xml` (144 -> 120), preventing UE5 VSYNC 72 FPS halving.
- **CPU / Scheduler / GPU Tuning**: State-driven `fortnite_watcher.sh` unlocks `policy6` Prime cluster (4.32GHz) with thermal-balanced `policy0` (3.07GHz), `scx/target_loads=72`, full `0-7` cpuset, `uclamp` latency sensitivity, full Adreno 830 dynamic range, and 540Hz esports raw touch.
- **CE-Safe Config Overrides**: Waits for `sys.user.0.ce_available=true`, patches `GameUserSettings.ini` in-place preserving user HUD/account data and locks with `chattr +i`, plus `DeviceProfiles.ini`, `Engine.ini`, `Scalability.ini`, and `UECommandLine.txt`.
- **90W Smart Charge Synergy**: Designed to run seamlessly alongside [OnePlus-Pad-90W-Smart-Charge](https://github.com/NinjaDraco/OnePlus-Pad-90W-Smart-Charge) (`v3.4.0+`) without bind-mount or CPU scaling conflicts, and cleans up legacy `fortnite_root_optimizer` on install.
