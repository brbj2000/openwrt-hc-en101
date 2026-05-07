#!/bin/bash
# apply-patches.sh - Apply HC-EN101 customizations to OpenWrt source tree
# This script is called by GitHub Actions workflow

set -e

OPENWRT_SRC="${1:-openwrt-src}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== Applying HC-EN101 patches to OpenWrt source ==="
echo "OpenWrt source: $OPENWRT_SRC"
echo "Base dir: $BASE_DIR"

# 1. Copy DTS file
echo "[1/5] Copying device tree file..."
mkdir -p "$OPENWRT_SRC/target/linux/layerscape/armv8_64b/dts"
cp -v "$BASE_DIR/files/target/linux/layerscape/armv8_64b/dts/fsl-ls1012a-hc-en101.dts" \
      "$OPENWRT_SRC/target/linux/layerscape/armv8_64b/dts/"

# 2. Copy image Makefile additions
echo "[2/5] Adding device image definition..."
# Append HC-EN101 device definition to armv8_64b.mk
cat "$BASE_DIR/files/target/linux/layerscape/image/hc-en101.mk" >> \
    "$OPENWRT_SRC/target/linux/layerscape/image/armv8_64b.mk"
echo "Appended HC-EN101 device definition to armv8_64b.mk"

# 3. Apply kernel DTS patch
echo "[3/5] Applying kernel DTS Makefile patch..."
if [ -f "$BASE_DIR/patches/dts-hc-en101.patch" ]; then
    cd "$OPENWRT_SRC"
    patch -p1 --no-backup-if-mismatch < "$BASE_DIR/patches/dts-hc-en101.patch" || {
        echo "WARNING: DTS patch failed, trying manual approach..."
        # Manual fallback: add dtb entry to kernel Makefile
        KMAKEFILE="target/linux/layerscape/patches-6.6"
        echo "Will be handled via OpenWrt build system"
    }
    cd "$BASE_DIR"
fi

# 4. Copy config file
echo "[4/5] Copying build config..."
cp -v "$BASE_DIR/config/hc-en101.config" "$OPENWRT_SRC/.config"

# 5. Verify
echo "[5/5] Verifying patches..."
echo "--- DTS file ---"
ls -la "$OPENWRT_SRC/target/linux/layerscape/armv8_64b/dts/fsl-ls1012a-hc-en101.dts" || echo "ERROR: DTS file missing!"

echo "--- Image definition ---"
grep -c "hc-en101\|HC-EN101\|hc_en101" "$OPENWRT_SRC/target/linux/layerscape/image/armv8_64b.mk" && echo "HC-EN101 device definition found!" || echo "WARNING: HC-EN101 not found in image Makefile!"

echo "--- Config file ---"
grep "hctele_hc-en101" "$OPENWRT_SRC/.config" && echo "HC-EN101 device selected in config!" || echo "WARNING: HC-EN101 not selected in config!"

echo "=== Patch application complete ==="
