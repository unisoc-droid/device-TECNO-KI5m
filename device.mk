$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/compression.mk)

# Vendor blobs are tracked in vendor/tecno/TECNO-KI5m/proprietary/ (serenity
# convention), so a clean checkout needs no extraction step. The optional
# prebuilt-image fallback remains available for bring-up only.
KI5M_VENDOR_PATH := vendor/tecno/TECNO-KI5m
KI5M_VENDOR_IMAGE := $(KI5M_VENDOR_PATH)/prebuilt/vendor.img

ifeq ($(KI5M_USE_PREBUILT_VENDORIMAGE),true)
  ifeq ($(wildcard $(KI5M_VENDOR_IMAGE)),)
    $(error KI5m: KI5M_USE_PREBUILT_VENDORIMAGE=true but $(KI5M_VENDOR_IMAGE) is missing. Unset the flag to use the tracked blobs.)
  endif
else
  $(call inherit-product, $(KI5M_VENDOR_PATH)/TECNO-KI5m-vendor.mk)
endif

# Stock vendor properties. The stock /vendor/build.prop is build-produced, so
# its content lives here instead of being shipped as a blob. Use the file-based
# mechanism; PRODUCT_VENDOR_PROPERTIES expects key=value, not a file path.
TARGET_VENDOR_PROP := $(KI5M_VENDOR_PATH)/vendor.prop

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
# provided by the tracked OEM blobs. checkpoint_gc is absent from stock.

PRODUCT_COPY_FILES += \
    device/tecno/TECNO-KI5m/rootdir/fstab.KI5m:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/first_stage_ramdisk/fstab.KI5m \
    device/tecno/TECNO-KI5m/rootdir/init.insmod.cfg:$(TARGET_COPY_OUT_VENDOR_DLKM)/lib/modules/init.insmod.cfg
