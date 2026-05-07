# HC-EN101 device definition for OpenWrt layerscape image Makefile
#
# Boot flow (from U-Boot printenv):
#   QSPI NOR: RCW(64KB@0x0) + U-Boot(640KB@0x100000)
#   eMMC:     p1(ext4,fitImage) + p2(squashfs,rootfs)
#   U-Boot:   ext4load mmc 0:1 0xa0000000 fitImage; bootm 0xa0000000
#
# This device uses eMMC as the primary boot storage for kernel+rootfs.
# The QSPI NOR flash only stores bootloader (RCW + U-Boot) and is NOT
# reprogrammed by the OpenWrt image.
#
# Inherits from Device/fsl-sdboot template which provides:
#   - KERNEL = kernel-bin | gzip | fit gzip (fitImage with DTB embedded)
#   - IMAGES = sdcard.img.gz sysupgrade.bin
#   - IMAGE/sysupgrade.bin = sysupgrade-tar | append-metadata

define Device/hctele_hc-en101
  $(Device/fsl-sdboot)
  DEVICE_VENDOR := HuaichenTelecom
  DEVICE_MODEL := HC-EN101
  DEVICE_ALT_MODEL := TE1104H0
  DEVICE_DTS := fsl-ls1012a-hc-en101
  DEVICE_DTS_DIR := $(DTS_DIR)/freescale
  DEVICE_PACKAGES := \
    layerscape-ppfe \
    kmod-ppfe \
    kmod-gpio-button-hotplug \
    kmod-leds-gpio
  IMAGE/sdcard.img.gz := \
    ls-clean | \
    ls-append-sdhead $(1) | pad-to 16M | \
    ls-append-kernel | pad-to $(LS_SD_ROOTFSPART_OFFSET)M | \
    append-rootfs | pad-to $(LS_SD_IMAGE_SIZE)M | gzip
endef
TARGET_DEVICES += hctele_hc-en101
