# Panduan build & membaca device tree KI5m

Dokumen ini menjelaskan **bentuk device tree "mainstream"** yang dihasilkan
`aospdtgen` dari dump `dumpyara`, lalu memetakannya ke tree KI5m ini.
Semua perintah build di bawah **dijalankan pengguna di server build**;
agent hanya melakukan riset, cross-check source, dan partial test.

## 1. Sumber internet (dicek 22 November 2026)

| Referensi | Fakta penting |
|---|---|
| [sebaubuntu-python/aospdtgen](https://github.com/sebaubuntu-python/aospdtgen) | Generator device tree LineageOS dari dump Treble (Android >8, VNDK). Python ≥3.9, lisensi Apache-2.0. |
| [PyPI aospdtgen](https://pypi.org/project/aospdtgen/) | Versi terbaru **1.2.1** (2026-02-11); sama dengan yang dipakai untuk KI5m. |
| [sebaubuntu-python/dumpyara](https://github.com/sebaubuntu-python/dumpyara) | Dumper versi Python: `pip install dumpyara`, `python -m dumpyara <OTA>`. Mendukung A/B OTA, `super.img`, `payload.bin`, image sparse/LZ4, EROFS. |
| [AndroidDumps/dumpyara](https://github.com/AndroidDumps/dumpyara) | Dumper shell asli: `bash setup.sh`, `bash dumpyara.sh "<OTA>" <token>`. Perlu token GitHub bila hasil dump mau di-push. |
| [aospdtgen source: device_tree.py](https://github.com/sebaubuntu-python/aospdtgen/blob/master/aospdtgen/device_tree.py) | Menentukan layout dump yang diharapkan dan file apa saja yang dihasilkan. |

CLI generator (dari README resmi):

```sh
pip install aospdtgen
python -m aospdtgen --help
python -m aospdtgen -o out/device /path/to/dumpyara-dump
# --no-proprietary-files bila blob akan dipakai dari vendor image prebuilt
```

## 2. Apa yang sebenarnya dilakukan aospdtgen

Dari `device_tree.py` versi 1.2.1:

1. Cari partisi **wajib** `system/` (atau `system/system/`) dan `vendor/`;
   keduanya harus punya `build.prop`. Partisi lain
   (`system_ext/`, `product/`, `odm/`, `vendor_dlkm/`, …) dikenali kalau punya
   `build.prop` di lokasi yang dikenal.
2. Gabungkan semua `build.prop` → `DeviceInfo` (nama, codename, API level,
   platform, patch level).
3. Ambil **file `vendor/etc/fstab.*` pertama** dan tulis ulang sebagai
   `rootdir/etc/fstab.<device>`. Ini fstab **lengkap** (logical partition +
   metadata + data + cache + USB + prodnv/tranfs), bukan fstab first-stage.
4. Ekstrak boot image: kernel, ramdisk, dtb/dtbo → `prebuilts/`.
5. Salin `vendor/bin/*.sh`, `vendor/etc/init/hw/*.rc`, dan `*.rc` dari
   recovery ramdisk ke `rootdir/`.
6. Hasilkan `Android.bp`, `Android.mk`, `AndroidProducts.mk`, `BoardConfig.mk`,
   `device.mk`, `lineage_<device>.mk`, `vendor.prop`, `manifest.xml`,
   `extract-files.py`, `setup-makefiles.py`, `proprietary-files.txt`, README.

Jadi output generator = **kerangka**, bukan ROM yang langsung build. Bagian
yang selalu butuh keputusan manusia: AVB/key/rollback, fstab first-stage,
sumber kernel (prebuilt vs source build), modul vendor, dan kontrak OTA.

## 3. Peta file: generator vs KI5m

| File generated | KI5m | Alasan |
|---|---|---|
| `BoardConfig.mk` | `BoardConfig.mk` | Opsi A AVB, `gki_defconfig` + `ki5m_early.config`, offset vendor_boot v4, `TARGET_USERIMAGES_USE_EXT4/F2FS`, `TARGET_RECOVERY_PIXEL_FORMAT`. |
| `device.mk` | `device.mk` | `virtual_ab_ota/compression.mk` + paket OTA/fastbootd standar; tidak menyalin HAL boot/health generik karena vendor prebuilt menyediakannya. |
| `lineage_<device>.mk` | `lineage_ki5m.mk` | Nama produk sengaja `lineage_ki5m` agar `lunch` pendek; `PRODUCT_SHIPPING_API_LEVEL := 31`. |
| `rootdir/etc/fstab.KI5m` (fstab lengkap) | `rootdir/fstab.KI5m` (first-stage) | Hanya partisi logical + metadata + misc yang dipakai first-stage. `/data` dan `/cache` tidak dimount di first stage. |
| `prebuilts/kernel`, `prebuilts/dtb.img`, `prebuilts/dtbo.img` | tidak ada | KI5m membangun kernel dari `kernel/tecno/TECNO-KI5m`; DTB/DTBO dibuat oleh `dtb.mk` / `dtbo.mk`. |
| `proprietary-files.txt`, `extract-files.sh`, `setup-makefiles.sh` | ada | Vendor tree standar `extract-utils` (346 blob OEM). Blob tidak di-commit; disediakan sekali dari firmware stock berlisensi. Image prebuilt tetap sebagai fallback opsional. |
| `Android.bp`, `Android.mk`, `rootdir/Android.{bp,mk}` | ada di vendor | `soong_namespace`, 5 `prebuilt_etc_xml`, `prebuilt_hidl_interfaces`, 19 symlink vendor. rootdir device disalin lewat `PRODUCT_COPY_FILES`. |
| VINTF/props stock | `vendor/prebuilt/inspection/` | Metadata hasil ekstraksi sebagai bukti sumber; tidak dipakai sebagai pengganti build. |
| — | `lineage.dependencies`, `dtb.mk`, `dtbo.mk` | Standar LineageOS: roomservice mencari vendor/kernel, kernel.mk menyertakan rule DTB/DTBO. |

## 4. Fakta perangkat (ADB read-only, 22 November 2026)

```
ro.treble.enabled            true
ro.vndk.version              31
ro.build.ab_update           true
ro.boot.dynamic_partitions   true
ro.product.first_api_level   31
ro.board.platform            ums9230
/proc/device-tree/model      Spreadtrum UMS9230 1H10 SoC
```

Ini memenuhi syarat aospdtgen (Treble + VNDK) dan menjelaskan kenapa tree
memakai A/B + dynamic + virtual A/B + VNDK31. Perangkat saat ini menjalankan
GSI Android 16, jadi `ro.boot.virtual_ab` tidak bisa dipakai sebagai bukti
konfigurasi ROM KI5m.

## 5. Menyiapkan server build (dijalankan pengguna)

1. Inisialisasi manifest LineageOS 20 seperti biasa, lalu tambahkan local
   manifest untuk tiga repo KI5m:

   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <manifest>
     <remote name="unisoc" fetch="git@github.com:"/>
     <project path="device/tecno/TECNO-KI5m" name="unisoc-droid/device-TECNO-KI5m" remote="unisoc" revision="lineage-20.0"/>
     <project path="vendor/tecno/TECNO-KI5m" name="unisoc-droid/vendor-TECNO-KI5m" remote="unisoc" revision="lineage-20.0"/>
     <project path="kernel/tecno/TECNO-KI5m" name="unisoc-droid/kernel-TECNO-KI5m" remote="unisoc" revision="lineage-20.0"/>
   </manifest>
   ```

   Simpan sebagai `.repo/local_manifests/ki5m.xml`, lalu `repo sync` untuk
   tiga path tersebut.

2. Blob OEM sudah **di-track** di `vendor/tecno/TECNO-KI5m/proprietary/`
   (351 file, ~76 MiB), mengikuti konvensi vendor tree Redmi A5 / POCO C71
   (`serenity`). Tidak ada ekstraksi atau provisioning di server. Script
   `extract-files.sh` tetap ada hanya untuk regenerasi/audit dari firmware
   stock berlisensi (SHA-256
   `fed3cf42811d3ddde84d558e1abb916e292cac4d56e8bd9beb1b69947ffb7207`).
   Image mentah tidak di-commit dan tidak dipakai dalam build normal.

3. Dari root ROM (tiga perintah standar):

   ```sh
   source build/envsetup.sh
   lunch lineage_ki5m-userdebug
   mka bacon
   ```

   Tidak ada export tambahan, ekstraksi manual, atau patch build file sama
   sekali setelah checkout.

   `lineage.dependencies` sudah berisi vendor + kernel, sehingga roomservice
   tidak perlu entri manual untuk keduanya.

## 6. Kenalan cepat dengan source (disarankan sebelum build)

- Bandingkan `BoardConfig.mk` dengan `/tmp/opencode/ki5m-aospdtgen/BoardConfig.mk`
  (atau hasil generator baru). Selisih yang disengaja tercantum di bagian 3.
- Jalankan checker parsial (aman, tanpa build):

  ```sh
  python3 -B ki5m_phase0g_analysis/check_main_boot.py --self-test
  python3 -B ki5m_phase0g_analysis/check_main_boot.py --output /tmp/ki5m-check.json
  ```

  `KERNEL_SOURCE_INPUTS` tetap **BLOCKED** di workspace lokal sampai kernel
  tersinkron di `kernel/tecno/TECNO-KI5m` pada server; ini bukan FAIL.
- Cek read-only target dengan ADB seperti bagian 4; jangan menjalankan
  perangkat/recovery sebagai pengganti boot utama.

## 7. Knob debug (matikan sebelum produksi)

| Variabel | Efek |
|---|---|
| `KI5M_DEBUG_PERMISSIVE ?= true` | Menambah `androidboot.selinux=permissive` ke cmdline vendor_boot. |
| `KI5M_AVB_DISABLE_VERIFICATION ?= true` | Menambah `--flags 3` ke top-level vbmeta (verification + dm-verity dimatikan). Layout chain Opsi A tidak berubah; stock memakai flags 0. |

Contoh build produksi nanti:

```sh
mka KI5M_DEBUG_PERMISSIVE=false KI5M_AVB_DISABLE_VERIFICATION=false
```

## 8. Batas bukti

Source sudah mengikuti bentuk device tree mainstream, tetapi **belum ada**
bukti Soong graph, ABI, image final, VINTF gabungan, OTA, atau boot target
berulang. Key test lokal bukan key stock; trust bootloader dan rollback counter
masih **UNKNOWN**. Lihat `KI5m_B04_AVB_Contract_Audit.md` dan
`KI5m_IMPLEMENTATION_STATUS.md` di workspace untuk status gate terbaru.
