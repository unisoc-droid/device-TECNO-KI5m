# Build dtbo.img from the in-tree KI5m overlay DTS.
# Included by vendor/lineage/build/tasks/kernel.mk via BOARD_CUSTOM_DTBOIMG_MK.

$(BOARD_PREBUILT_DTBOIMAGE): $(DTBO_OUT) $(DTC)
	@echo "Building dtbo.img for KI5m"
	$(hide) find $(DTBO_OUT)/arch/$(KERNEL_ARCH)/boot/dts -type f -name '*.dtbo' | xargs rm -f
	$(call make-dtbo-target,$(KERNEL_DEFCONFIG))
	$(call make-dtbo-target,$(TARGET_KERNEL_DTBO))
	$(hide) cat $(DTBO_OUT)/arch/$(KERNEL_ARCH)/boot/dts/sprd/ums9230-ki5m-overlay.dtbo > $@
	$(hide) touch -c $@
