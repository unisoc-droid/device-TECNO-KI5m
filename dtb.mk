# Build the single wrapped base DTB from the in-tree KI5m DTS.
# Included by vendor/lineage/build/tasks/kernel.mk via BOARD_CUSTOM_DTBIMG_MK.

# BOARD_CUSTOM_DTBIMG_MK skips kernel.mk's $(DTB_OUT) rule - recreate it.
$(DTB_OUT):
	mkdir -p $(DTB_OUT)

$(INSTALLED_DTBIMAGE_TARGET): $(DTC) $(DTB_OUT)
	@echo "Building dtb.img for KI5m"
	$(hide) find $(DTB_OUT)/arch/$(KERNEL_ARCH)/boot/dts -type f -name '*.dtb' | xargs rm -f
	$(call make-dtb-target,$(KERNEL_DEFCONFIG))
	$(call make-dtb-target,$(TARGET_KERNEL_DTB))
	$(hide) cat $(DTB_OUT)/arch/$(KERNEL_ARCH)/boot/dts/sprd/ums9230-ki5m-base.dtb > $@
	$(hide) touch -c $@
