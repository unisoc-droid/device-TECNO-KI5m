KI5M_DEVICE_PATH := device/tecno/TECNO-KI5m
KI5M_VENDOR_PATH := vendor/tecno/TECNO-KI5m
KI5M_KERNEL_DIST := $(KI5M_DEVICE_PATH)/kernel-dist

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

# The separate kernel build exports a distribution under this product's device tree.
TARGET_PREBUILT_KERNEL := $(KI5M_KERNEL_DIST)/Image
TARGET_KERNEL_VERSION := 5.15
BOARD_KERNEL_IMAGE_NAME := Image
BOARD_BOOT_HEADER_VERSION := 4
BOARD_KERNEL_BASE := 0x0
BOARD_KERNEL_PAGESIZE := 4096
# Keep early UART diagnostics in the vendor_boot command line as well as the DT.
# DEBUG BRING-UP: permissive SELinux for first test builds. Set to false before production.
KI5M_DEBUG_PERMISSIVE ?= true
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
# AOSP concatenates *.dtb in this directory. Stage exactly one wrapped base DTB.
BOARD_PREBUILT_DTBIMAGE_DIR := $(KI5M_KERNEL_DIST)/dtb
BOARD_PREBUILT_DTBOIMAGE := $(KI5M_KERNEL_DIST)/dtbo.img

BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT := true
BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE := true
TARGET_RECOVERY_FSTAB := $(KI5M_DEVICE_PATH)/rootdir/fstab.KI5m

TARGET_COPY_OUT_VENDOR := vendor
TARGET_COPY_OUT_VENDOR_DLKM := vendor_dlkm
TARGET_COPY_OUT_PRODUCT := product
TARGET_COPY_OUT_SYSTEM_EXT := system_ext
BOARD_PREBUILT_VENDORIMAGE := $(KI5M_VENDOR_PATH)/prebuilt/vendor.img
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

ki5m_kernel_inputs := Image .config kernel.release modules.builtin \
    ki5m_first_stage_modules ki5m_vendor_modules dtb/ki5m.dtb dtbo.img
ki5m_missing_inputs := $(filter-out $(wildcard $(addprefix $(KI5M_KERNEL_DIST)/,$(ki5m_kernel_inputs))), \
    $(addprefix $(KI5M_KERNEL_DIST)/,$(ki5m_kernel_inputs)))
ifneq ($(strip $(ki5m_missing_inputs)),)
$(error Stage the KI5m kernel distribution and DT tables. Missing $(ki5m_missing_inputs))
endif
ifneq ($(wildcard $(BOARD_PREBUILT_DTBIMAGE_DIR)/*.dtb),$(BOARD_PREBUILT_DTBIMAGE_DIR)/ki5m.dtb)
$(error Stage exactly one wrapped base DTB in $(BOARD_PREBUILT_DTBIMAGE_DIR))
endif
BOARD_KERNEL_CONFIG_FILE := $(KI5M_KERNEL_DIST)/.config
BOARD_KERNEL_VERSION := $(shell cat $(KI5M_KERNEL_DIST)/kernel.release)
ki5m_builtin_modules := $(notdir $(shell cat $(KI5M_KERNEL_DIST)/modules.builtin))
ki5m_early_modules := $(shell cat $(KI5M_KERNEL_DIST)/ki5m_first_stage_modules)
BOARD_VENDOR_RAMDISK_KERNEL_MODULES := $(addprefix $(KI5M_KERNEL_DIST)/, \
    $(filter-out $(ki5m_builtin_modules),$(ki5m_early_modules)))
BOARD_VENDOR_RAMDISK_KERNEL_MODULES_LOAD := $(BOARD_VENDOR_RAMDISK_KERNEL_MODULES)
BOARD_VENDOR_RAMDISK_RECOVERY_KERNEL_MODULES_LOAD := $(BOARD_VENDOR_RAMDISK_KERNEL_MODULES)
BOARD_DO_NOT_STRIP_VENDOR_RAMDISK_MODULES := true

ki5m_vendor_modules := $(shell cat $(KI5M_KERNEL_DIST)/ki5m_vendor_modules)
BOARD_VENDOR_KERNEL_MODULES := $(addprefix $(KI5M_KERNEL_DIST)/, \
    $(filter-out $(ki5m_builtin_modules),$(ki5m_vendor_modules)))
BOARD_VENDOR_KERNEL_MODULES_LOAD := $(BOARD_VENDOR_KERNEL_MODULES)
BOARD_DO_NOT_STRIP_VENDOR_MODULES := true

ki5m_required_files := $(BOARD_VENDOR_RAMDISK_KERNEL_MODULES) $(BOARD_VENDOR_KERNEL_MODULES) $(BOARD_PREBUILT_VENDORIMAGE)
ki5m_missing_files := $(filter-out $(wildcard $(ki5m_required_files)),$(ki5m_required_files))
ifneq ($(strip $(ki5m_missing_files)),)
$(error Missing KI5m inputs $(ki5m_missing_files))
endif

# Local AVB configuration supplies device-authorized keys and chain descriptors.
-include $(KI5M_VENDOR_PATH)/BoardConfigVendor.mk
