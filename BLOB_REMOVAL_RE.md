# AOSP-provided blob removal: reverse-engineering evidence

Scope: quantify the two risks raised before the first flash — `gralloc.default.so`
and the dropped HAL service/rc pairs — using the stock binaries and AOSP source in
this tree. No build, no device. All paths relative to the AOSP root.

## 1. `gralloc.default.so` — risk downgraded to low

Claim under test: *the stock Unisoc `gralloc.default.so` is device-specific gralloc,
so replacing it with the AOSP build breaks graphics.*

Evidence (stock blob `proprietary/vendor/lib64/hw/gralloc.default.so`, preserved):

| Probe | Result |
|---|---|
| `file` | ELF aarch64, Android 31, stripped |
| `readelf -d` NEEDED | `liblog libcutils libc++ libc libm libdl` — no `libion`, no `libdrm` |
| mangled exports | `gralloc_lock`, `gralloc_unlock`, `gralloc_register_buffer`, `gralloc_unregister_buffer`, `fb_device_open`, `mapFrameBufferLocked`, `terminateBuffer`, `mapBuffer` |
| strings | `Graphics Memory Allocator Module`, `Error mapping the framebuffer (%s)`, `FBIOPUT_VSCREENINFO failed`, `/dev/fb%u` |

All eight symbols and all four strings exist in AOSP
`hardware/libhardware/modules/gralloc/` (`gralloc.cpp:84`, `framebuffer.cpp:88,131,188,289`).
Conclusion: the stock blob is the AOSP **framebuffer gralloc**, rebuilt by the
Unisoc BSP at SDK 31 — not a custom allocator.

Two further facts:

- `build/make/target/product/base_vendor.mk:54` adds `gralloc.default`
  unconditionally, so the AOSP one always exists in the image; it cannot simply
  be disabled.
- The real allocation path on this device is the HIDL allocator service, not the
  fb module: `proprietary/vendor.prop:93` sets
  `ro.surface_flinger.start_graphics_allocator_service=false`, and the tracked
  `android.hardware.graphics.allocator@4.0-impl-arm.so` is an ARM `mapper`
  implementation (`arm::mapper::common::*`, NEEDED `libion` + `libdrm`).

Residual risk: cosmetic only. AOSP 13 compiles the same source with default
`GRALLOC_FRAMEBUFFER_NUM`/`TARGET_USE_PAN_DISPLAY`. fb gralloc is a fallback;
`hwcomposer.ums9230.so` (tracked) is the display path.

Device-specific dependency closure of the tracked graphics blobs was checked and
is intact — `libmemion.so`, `libpowerhal_cli.so`,
`vendor.sprd.hardware.enhance@1.0.so` are all still in `proprietary-files.txt`.

## 2. Dropped HAL service + rc pairs — quantified

Each dropped rc was diffed against the AOSP rc now used instead
(`git show deab997^:proprietary/vendor/etc/init/<name>` vs the AOSP file).

| Outcome | Count | Files |
|---|---|---|
| Byte-identical | 4 | `nfc@1.2`, `sensors@1.0`, `boringssl_self_test`, `rebootescrow-default` |
| Only cpuset → `task_profiles` migration | 8 | `audio.service`, `fingerprint@2.1`, `cas@1.2`, `drm@1.4.clearkey`, `graphics.composer@2.1`, `health@2.1`, `media.omx@1.0`, `vndservicemanager` |
| Behavioural delta | 2 | see below |

`task_profiles` is the AOSP 13 replacement for `writepid /dev/cpuset/...`;
`audio.service` additionally gains `SYS_NICE` + `rlimit rtprio 10 10`, and
`health@2.1` gains `BLOCK_SUSPEND`. Both are upstream improvements.

### 2a. `vendor_flash_recovery.rc` — reachable delta

AOSP `bootable/recovery/applypatch/vendor_flash_recovery.rc` marks the service
`disabled` and starts it only from
`on property:persist.vendor.recovery_update=true`. Stock ran it unconditionally.
Effect: recovery-partition refresh on A/B OTA now requires that property.
Mitigation if desired: set `persist.vendor.recovery_update=true`.

### 2b. Camera provider — the one real functional loss

Stock rc had an extra line absent from AOSP's:

```
interface vendor.transsion.hardware.camera.imgalgoservice@1.0::IImgAlgoService internal/0
```

The stock `android.hardware.camera.provider@2.4-service` binary is the only
process that can serve that interface (it is the only `bin/` match for
`imgalgoservice`; the AOSP camera provider, GCC libs and `-impl-sprd` do **not**
link it — `readelf -d android.hardware.camera.provider@2.4-impl-sprd.so` has no
`imgalgoservice` entry).

Consequence: with the AOSP binary + rc, `IImgAlgoService` is no longer
registered. The 2.4 provider API and the sprd HAL chain still work, so camera
bring-up should proceed; TECNO image-algorithm post-processing degrades.
Revisit only if the camera fails on device.

## 3. VINTF



A regression was found and fixed while doing this: commit `52da421` deleted the
`vendor/etc/vintf/manifest/` entries from `proprietary-files.txt` believing the
`Android.bp` `prebuilt_etc_xml` modules would keep installing them. Later
regenerations rebuild `Android.bp` from that list, so the modules disappeared
too — 27 manifests existed on disk with **no install rule**, i.e. an empty vendor
VINTF manifest. All 27 were restored (`3e5aa51`).

Then each restored manifest was checked for an AOSP module shipping the same
`vintf_fragments` filename:

- 6 dropped — AOSP installs them: `fingerprint@2.1-service`,
  `gatekeeper@1.0-service.trusty`, `health@2.1`,
  `manifest_android.hardware.drm@1.4-service.clearkey`, `rebootescrow-default`,
  `wifi@1.0-service`.
- 3 kept — owning AOSP module is not built here (its daemon is a tracked blob):
  `memtrack.xml` (Pixel module), `wifi.hostapd.xml`, `wifi.supplicant.xml`.
- Verified the AOSP gatekeeper trusty manifest declares
  `android.hardware.gatekeeper` 1.0 `IGatekeeper`/`default`, identical to stock,
  and its rc is byte-equivalent to the stock one.

Remaining manifests still declare every HAL whose binary was dropped
(checked gatekeeper, sensors, fingerprint, health).

## 4. Detector

`vendor/tecno/TECNO-KI5m/tools/find-install-collisions.sh` now has two passes:
exact Soong `installs-*.mk` comparison, and a static Make/bp module-name pass for
`base_rules.mk` collisions. 352 Soong collisions were fixed; of 23 static hits,
all are modules not in this product graph (audio policy configs, cuttlefish,
gchips, hostapd/wpa_supplicant) and are intentionally kept.

## 5. Still owner-gated

Kernel build, dtb/dtbo, VINTF runtime check, firmware load, first boot, camera
and display behaviour. Nothing here is a boot proof.
