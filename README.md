# device/tecno/TECNO-KI5m — LineageOS 20

Standard LineageOS device tree for TECNO KI5m (UMS9230, Android 13 / 5.15).

## Repositories

| Path | Repository | Branch |
|---|---|---|
| `device/tecno/TECNO-KI5m` | `unisoc-droid/device-TECNO-KI5m` | `lineage-20.0` |
| `vendor/tecno/TECNO-KI5m` | `unisoc-droid/vendor-TECNO-KI5m` | `lineage-20.0` |
| `kernel/tecno/TECNO-KI5m` | `unisoc-droid/kernel-TECNO-KI5m` | `lineage-20.0` |

`lineage.dependencies` declares the vendor and kernel trees for `repo sync`.

## Build inputs that are not committed

- `vendor/tecno/TECNO-KI5m/prebuilt/vendor.img` — stock V218 vendor image
  (803 MB, above GitHub's per-file limit). Stage it on the server.
- Kernel source is built from `gki_defconfig` + `ki5m_early.fragment`; no
  prebuilt kernel image or kernel-dist directory is required.

## Configuration

- AVB Option A: `system`, `system_ext`, `product` and `vendor/vendor_dlkm` keep
  the V218 chained-vbmeta layout. Option B remains a config-only fallback.
- First test build: `KI5M_DEBUG_PERMISSIVE ?= true` adds
  `androidboot.selinux=permissive`. Set it to `false` for production.
- Early UART: `earlycon console=ttyS1,115200n8 loglevel=7`.

No build, device flash, or boot claim has been made from this tree.
