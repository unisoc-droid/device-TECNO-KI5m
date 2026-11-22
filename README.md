# device/tecno/TECNO-KI5m — LineageOS 20

Standard LineageOS 20 device tree for TECNO KI5m (UMS9230 / T606 / qogirl6,
Android 13 / API 33, android13-5.15 kernel).

Verified product: `lineage_ki5m` (`PRODUCT_DEVICE := TECNO-KI5m`).
Verified lunch target: `lineage_ki5m-userdebug`.

See [BUILD_GUIDE.md](BUILD_GUIDE.md) for the aospdtgen/dumpyara reference and
the intentional differences from a generated tree.

## Repositories (branch `lineage-20.0`)

| Path | Repository |
|---|---|
| `device/tecno/TECNO-KI5m` | `unisoc-droid/device-TECNO-KI5m` |
| `vendor/tecno/TECNO-KI5m` | `unisoc-droid/vendor-TECNO-KI5m` |
| `kernel/tecno/TECNO-KI5m` | `unisoc-droid/kernel-TECNO-KI5m` |

`lineage.dependencies` plus `lineage-20.0.xml` (local manifest) declare all
three. No post-checkout symlink or build-file edit is required.

## One-time provisioning before the first build

Proprietary blobs are not committed. After `repo sync`, run once:

```bash
cd vendor/tecno/TECNO-KI5m
./extract-files.sh /path/to/stock/vendor.img
cd ../../..
```

This populates `proprietary/` and refreshes the generated makefiles. `device.mk`
fails with an explicit message if this step was skipped. The stock image is
never needed for routine builds once blobs are provisioned.

## Routine build (owner, dedicated server)

```bash
source build/envsetup.sh
lunch lineage_ki5m-userdebug
mka bacon
```

No extra exports, manual extraction or patching is needed after provisioning.

## Configuration notes

- Kernel built from source: `gki_defconfig` + `ki5m_early.config` +
  `ki5m_soc.config` + `ki5m_device.config`; `BSP_BUILD_KI5M=y` selects the
  in-tree KI5m DTS/DTBO, built by `dtb.mk` / `dtbo.mk`.
- AVB Option A: chained `vbmeta_system_ext` / `vbmeta_product`, vendor merged.
- Bring-up defaults `KI5M_DEBUG_PERMISSIVE ?= true` and
  `KI5M_AVB_DISABLE_VERIFICATION ?= true`; set both to `false` for production.
- Early UART: `earlycon console=ttyS1,115200n8 loglevel=7`.
- Vendor SELinux from stock V218 CIL: `BOARD_VENDOR_SEPOLICY_DIRS`. Property
  names pass `check_prop_prefix.py --strict` with the shipping-API-33 allowed
  prefixes; no `BUILD_BROKEN_*` namespace workaround is used.

No build, device flash, or boot claim has been made from this tree.
