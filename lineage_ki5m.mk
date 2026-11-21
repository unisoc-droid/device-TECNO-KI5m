$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)
$(call inherit-product, device/tecno/TECNO-KI5m/device.mk)

PRODUCT_NAME := lineage_ki5m
PRODUCT_DEVICE := TECNO-KI5m
PRODUCT_BRAND := TECNO
PRODUCT_MODEL := TECNO KI5m
PRODUCT_MANUFACTURER := TECNO
PRODUCT_SHIPPING_API_LEVEL := 31
