KI5M_DEVICE_PATH := device/tecno/TECNO-KI5m
KI5M_VENDOR_PATH := vendor/tecno/TECNO-KI5m

TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_VARIANT := generic
TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv8-a
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := generic
TARGET_BOARD_PLATFORM := ums9230
BOARD_VNDK_VERSION := current

# Standard LineageOS kernel source build. The kernel repository is declared as
# a dependency in lineage.dependencies and is synced to the same path on every
# build server.
TARGET_KERNEL_SOURCE := kernel/tecno/TECNO-KI5m
TARGET_KERNEL_CONFIG := gki_defconfig ki5m_early.config ki5m_soc.config ki5m_device.config
# BSP_BUILD_KI5M=y selects the in-tree KI5m DTS (ums9230-ki5m-base.dtb and
# ums9230-ki5m-overlay.dtbo) in arch/arm64/boot/dts/sprd/Makefile. Without it
# the kernel "dtbs" target builds no KI5m device trees.
TARGET_KERNEL_ADDITIONAL_FLAGS := BSP_BUILD_KI5M=y
TARGET_KERNEL_VERSION := 5.15
BOARD_KERNEL_IMAGE_NAME := Image
BOARD_BOOT_HEADER_VERSION := 4
BOARD_KERNEL_BASE := 0x0
BOARD_KERNEL_PAGESIZE := 4096

# Keep early UART diagnostics in the vendor_boot command line as well as the DT.
# DEBUG BRING-UP: permissive SELinux for first test builds. Set to false before production.
KI5M_DEBUG_PERMISSIVE ?= true
# Vendor sepolicy converted from stock V218 has legacy allow rules that trip
# Android 13 platform neverallows. Skip secilc neverallow checks during bring-up;
# remove once the vendor policy is cleaned up for the target platform version.
SELINUX_IGNORE_NEVERALLOWS := true
BOARD_KERNEL_CMDLINE := earlycon console=ttyS1,115200n8 loglevel=7
ifeq ($(KI5M_DEBUG_PERMISSIVE),true)
BOARD_KERNEL_CMDLINE += androidboot.selinux=permissive
endif
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION) \
    --kernel_offset 0x00008000 --ramdisk_offset 0x05400000 \
    --tags_offset 0x00000100 --dtb_offset 0x01f00000
BOARD_RAMDISK_USE_LZ4 := true
BOARD_BOOTIMAGE_PARTITION_SIZE := 67108864
BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE := 104857600
BOARD_DTBOIMG_PARTITION_SIZE := 8388608
BOARD_INCLUDE_DTB_IN_BOOTIMG := true
BOARD_KERNEL_SEPARATED_DTBO := true
BOARD_CUSTOM_DTBIMG_MK := $(KI5M_DEVICE_PATH)/dtb.mk
BOARD_CUSTOM_DTBOIMG_MK := $(KI5M_DEVICE_PATH)/dtbo.mk
# The KI5m kernel has no "dtbo.img" aggregate target; both dtb.mk and dtbo.mk
# invoke the kernel "dtbs" target, which builds ums9230-ki5m-base.dtb and
# ums9230-ki5m-overlay.dtbo (both are listed in dtb-y).
TARGET_KERNEL_DTB := dtbs
TARGET_KERNEL_DTBO := dtbs

BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT := true
BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE := true
TARGET_RECOVERY_FSTAB := $(KI5M_DEVICE_PATH)/rootdir/fstab.KI5m
# Stock V218 vendor.prop: ro.minui.pixel_format=RGBX_8888.
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888
# Stock fstab: metadata/cache/vendor_dlkm are ext4, userdata is f2fs.
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true

TARGET_COPY_OUT_VENDOR := vendor
TARGET_COPY_OUT_VENDOR_DLKM := vendor_dlkm
TARGET_COPY_OUT_PRODUCT := product
TARGET_COPY_OUT_SYSTEM_EXT := system_ext
# No odm partition here (fstab mounts neither /odm nor /odm_dlkm); stock
# /vendor/odm and /vendor/odm_dlkm are plain subdirectories of vendor.img.
# TARGET_COPY_OUT_ODM removed: no separate odm partition.
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_SYSTEM_EXTIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_VENDOR_DLKMIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_SUPER_PARTITION_SIZE := 5872025600
BOARD_SUPER_PARTITION_GROUPS := group_unisoc
BOARD_GROUP_UNISOC_SIZE := 5867831296
BOARD_GROUP_UNISOC_PARTITION_LIST := system system_ext vendor product vendor_dlkm
AB_OTA_UPDATER := true
AB_OTA_PARTITIONS := boot vendor_boot dtbo system system_ext vendor product vendor_dlkm \
    vbmeta vbmeta_system vbmeta_system_ext vbmeta_product vbmeta_vendor

# Option A: preserve the V218 chained-vbmeta layout.
# system_ext and product keep separate chained vbmeta images; vendor stays merged.
# The local build/make rules are extended for these two groups; Option B fallback
# only needs this block and rootdir/fstab.KI5m reverted to the merged system group.
BOARD_AVB_ENABLE := true
# DEBUG BRING-UP: flags 3 disables AVB verification and dm-verity hashtrees.
# Set to false once the stock key/rollback contract is proven; this does not
# change the Option A chained-vbmeta layout.
KI5M_AVB_DISABLE_VERIFICATION ?= true
ifeq ($(KI5M_AVB_DISABLE_VERIFICATION),true)
BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flags 3
# fstab.KI5m mounts system_ext/product/vendor via avb=vbmeta_<name>, so those
# chained images are read directly. Flags on the top-level vbmeta do not
# propagate to them; each one needs the same bring-up flag.
BOARD_AVB_MAKE_VBMETA_SYSTEM_IMAGE_ARGS += --flags 3
BOARD_AVB_MAKE_VBMETA_SYSTEM_EXT_IMAGE_ARGS += --flags 3
BOARD_AVB_MAKE_VBMETA_PRODUCT_IMAGE_ARGS += --flags 3
BOARD_AVB_MAKE_VBMETA_VENDOR_IMAGE_ARGS += --flags 3
endif
KI5M_AVB_CHAIN_KEY := external/avb/test/data/testkey_rsa4096.pem
BOARD_AVB_VBMETA_SYSTEM := system
BOARD_AVB_VBMETA_SYSTEM_KEY_PATH := $(KI5M_AVB_CHAIN_KEY)
BOARD_AVB_VBMETA_SYSTEM_ALGORITHM := SHA256_RSA4096
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX := 1
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX_LOCATION := 2
BOARD_AVB_VBMETA_SYSTEM_EXT := system_ext
BOARD_AVB_VBMETA_SYSTEM_EXT_KEY_PATH := $(KI5M_AVB_CHAIN_KEY)
BOARD_AVB_VBMETA_SYSTEM_EXT_ALGORITHM := SHA256_RSA4096
BOARD_AVB_VBMETA_SYSTEM_EXT_ROLLBACK_INDEX := 1
BOARD_AVB_VBMETA_SYSTEM_EXT_ROLLBACK_INDEX_LOCATION := 3
BOARD_AVB_VBMETA_PRODUCT := product
BOARD_AVB_VBMETA_PRODUCT_KEY_PATH := $(KI5M_AVB_CHAIN_KEY)
BOARD_AVB_VBMETA_PRODUCT_ALGORITHM := SHA256_RSA4096
BOARD_AVB_VBMETA_PRODUCT_ROLLBACK_INDEX := 1
BOARD_AVB_VBMETA_PRODUCT_ROLLBACK_INDEX_LOCATION := 5
BOARD_AVB_VBMETA_VENDOR := vendor vendor_dlkm
BOARD_AVB_VBMETA_VENDOR_KEY_PATH := $(KI5M_AVB_CHAIN_KEY)
BOARD_AVB_VBMETA_VENDOR_ALGORITHM := SHA256_RSA4096
BOARD_AVB_VBMETA_VENDOR_ROLLBACK_INDEX := 1
BOARD_AVB_VBMETA_VENDOR_ROLLBACK_INDEX_LOCATION := 4

# Module load lists live in the kernel tree, next to the defconfig fragments.
ki5m_module_lists := $(TARGET_KERNEL_SOURCE)/android/ki5m_first_stage_modules \
    $(TARGET_KERNEL_SOURCE)/android/ki5m_vendor_modules
ki5m_missing_module_lists := $(filter-out $(wildcard $(ki5m_module_lists)),$(ki5m_module_lists))
ifneq ($(strip $(ki5m_missing_module_lists)),)
$(error Stage the KI5m kernel source. Missing $(ki5m_missing_module_lists))
endif
ki5m_first_stage_modules := $(shell cat $(TARGET_KERNEL_SOURCE)/android/ki5m_first_stage_modules)
ki5m_vendor_modules := $(shell cat $(TARGET_KERNEL_SOURCE)/android/ki5m_vendor_modules)
BOOT_KERNEL_MODULES := $(ki5m_first_stage_modules)
BOARD_VENDOR_RAMDISK_KERNEL_MODULES_LOAD := $(ki5m_first_stage_modules)
BOARD_VENDOR_KERNEL_MODULES_LOAD := $(ki5m_vendor_modules)

# Vendor SEPolicy from stock V218 /vendor/etc/selinux (converted from CIL).
BOARD_VENDOR_SEPOLICY_DIRS += device/tecno/TECNO-KI5m/sepolicy/vendor

# Vendor-specific BoardConfig values (including the prebuilt vendor image path).
-include $(KI5M_VENDOR_PATH)/BoardConfigVendor.mk
