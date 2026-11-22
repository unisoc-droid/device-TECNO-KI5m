$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/compression.mk)

# Vendor integration. Proprietary blobs are not redistributable, so they are
# provisioned once (see vendor/tecno/TECNO-KI5m/README.md). Fail with an
# actionable message instead of silently building an incomplete vendor image.
KI5M_VENDOR_PATH := vendor/tecno/TECNO-KI5m
KI5M_VENDOR_BLOB := $(KI5M_VENDOR_PATH)/proprietary/vendor/bin/adbtestmode
KI5M_VENDOR_IMAGE := $(KI5M_VENDOR_PATH)/prebuilt/vendor.img

ifeq ($(KI5M_USE_PREBUILT_VENDORIMAGE),true)
  ifeq ($(wildcard $(KI5M_VENDOR_IMAGE)),)
    $(error KI5m: KI5M_USE_PREBUILT_VENDORIMAGE=true but $(KI5M_VENDOR_IMAGE) is missing. Stage the verified V218 image or unset the flag.)
  endif
else
  ifeq ($(wildcard $(KI5M_VENDOR_BLOB)),)
    $(error KI5m: proprietary blobs are not provisioned. Run once from the ROM root: cd $(KI5M_VENDOR_PATH) && ./extract-files.sh /path/to/stock/vendor.img (or pre-extracted vendor dump), then retry lunch/mka.)
  endif
  $(call inherit-product, $(KI5M_VENDOR_PATH)/TECNO-KI5m-vendor.mk)
endif

PRODUCT_USE_DYNAMIC_PARTITIONS := true
PRODUCT_EXTRA_VNDK_VERSIONS += 31
PRODUCT_OTA_ENFORCE_VINTF_KERNEL_REQUIREMENTS := true

# Standard AOSP/Lineage A/B OTA payload. The generic full_base chain does not
# inherit generic_system.mk, which is where these would otherwise come from.
PRODUCT_PACKAGES += \
    update_engine \
    update_engine_sideload \
    update_verifier \
    otapreopt_script

AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_system=true \
    POSTINSTALL_PATH_system=system/bin/otapreopt_script \
    FILESYSTEM_TYPE_system=erofs \
    POSTINSTALL_OPTIONAL_system=true

# Dynamic partitions cannot be flashed by the bootloader-only fastboot path.
PRODUCT_PACKAGES += \
    fastbootd \
    android.hardware.fastboot@1.1-impl-mock

# Not added on purpose: android.hardware.boot@1.2 and health@2.1 HALs are
# provided by the OEM blobs / prebuilt V218 vendor filesystem.
# checkpoint_gc is absent from stock vendor.

PRODUCT_COPY_FILES += \
    device/tecno/TECNO-KI5m/rootdir/fstab.KI5m:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/first_stage_ramdisk/fstab.KI5m \
    device/tecno/TECNO-KI5m/rootdir/init.insmod.cfg:$(TARGET_COPY_OUT_VENDOR_DLKM)/lib/modules/init.insmod.cfg
