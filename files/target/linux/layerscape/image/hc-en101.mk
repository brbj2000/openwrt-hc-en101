# Add HC-EN101 device definition to OpenWrt layerscape image Makefile
# This patch should be applied to: target/linux/layerscape/image/armv8_64b.mk
# 
# Place this as a standalone file; the build workflow will merge it.

define Device/hctele_hc-en101
  DEVICE_VENDOR := HuaichenTelecom
  DEVICE_MODEL := HC-EN101
  DEVICE_ALT_MODEL := TE1104H0
  DEVICE_DTS := fsl-ls1012a-hc-en101
  DEVICE_DTS_DIR := $(DTS_DIR)/freescale
  DEVICE_PACKAGES := layerscape-ppfe kmod-ppfe \
    kmod-gpio-button-hotplug kmod-leds-gpio
  BLOCKSIZE := 256KiB
  IMAGE_SIZE := 64m
  IMAGES := firmware.bin sysupgrade.bin
  KERNEL := kernel-bin | gzip | fit gzip $$(DEVICE_DTS_DIR)/$$(DEVICE_DTS).dtb
  KERNEL_INITRAMFS := kernel-bin | gzip | fit gzip $$(DEVICE_DTS_DIR)/$$(DEVICE_DTS).dtb
  IMAGE/firmware.bin := \
    ls-clean | \
    ls-append $(1)-bl2.pbl | pad-to 1M | \
    ls-append $(1)-fip.bin | pad-to 5M | \
    ls-append $(1)-uboot-env.bin | pad-to 10M | \
    ls-append pfe.itb | pad-to 15M | \
    ls-append-dtb $$(DEVICE_DTS) | pad-to 16M | \
    append-kernel | pad-to $$(BLOCKSIZE) | \
    append-rootfs | pad-rootfs | check-size
  IMAGE/sysupgrade.bin := \
    append-kernel | pad-to $$(BLOCKSIZE) | \
    append-rootfs | pad-rootfs | \
    check-size $(LS_SYSUPGRADE_IMAGE_SIZE) | append-metadata
endef
TARGET_DEVICES += hctele_hc-en101
