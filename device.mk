$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/compression.mk)

PRODUCT_USE_DYNAMIC_PARTITIONS := true
PRODUCT_EXTRA_VNDK_VERSIONS += 31
PRODUCT_OTA_ENFORCE_VINTF_KERNEL_REQUIREMENTS := true

PRODUCT_COPY_FILES += \
    device/tecno/TECNO-KI5m/rootdir/fstab.KI5m:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/first_stage_ramdisk/fstab.KI5m \
    device/tecno/TECNO-KI5m/rootdir/init.insmod.cfg:$(TARGET_COPY_OUT_VENDOR_DLKM)/lib/modules/init.insmod.cfg
