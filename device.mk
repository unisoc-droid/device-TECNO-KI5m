$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/compression.mk)
$(call inherit-product, vendor/tecno/TECNO-KI5m/TECNO-KI5m-vendor.mk)

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
# already provided by the prebuilt V218 vendor image. checkpoint_gc is omitted
# because that prebuilt vendor image has no bin/checkpoint_gc.

PRODUCT_COPY_FILES += \
    device/tecno/TECNO-KI5m/rootdir/fstab.KI5m:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/first_stage_ramdisk/fstab.KI5m \
    device/tecno/TECNO-KI5m/rootdir/init.insmod.cfg:$(TARGET_COPY_OUT_VENDOR_DLKM)/lib/modules/init.insmod.cfg
