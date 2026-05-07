# OpenWrt for Huaichen Telecom HC-EN101 (TE1104H0)

为华晨泰尔 HC-EN101 路由器编译 OpenWrt 固件的项目，基于 NXP LS1012A SoC。

## ⚠️ 重要提示

本项目基于 LS1012A-RDB 参考设计创建初始版本。**HC-EN101 与 RDB 的硬件可能存在差异**，包括：

- PHY 芯片型号和 MDIO 地址
- Flash 大小和分区布局
- LED 和按钮的 GPIO 映射
- 无线模块（如果有）

**首次编译的固件可能无法直接启动，需要根据串口日志调整设备树。**

## 🔌 串口日志采集（关键步骤）

在刷入固件前，强烈建议先采集 U-Boot 串口日志，用于修正设备树。

### 所需硬件
- USB 转 TTL 串口线（3.3V）
- 路由器 PCB 上的串口排针（通常标有 TX/RX/GND）

### 连接方式
1. 找到路由器 PCB 上的调试串口（通常为 4pin 排针）
2. 连接：GND→GND, TX→RX, RX→TX（交叉连接）
3. 串口参数：**115200 8N1**（LS1012A 默认波特率）

### 需要执行的命令
在 U-Boot 启动时按任意键中断自动启动，然后执行：

```
=> printenv
=> sf probe 0:0
=> sf read 0xa0000000 0x0 0x1000 && md 0xa0000000 0x100
=> mdio list
=> mii info
=> gpio input
=> i2c dev 0 && i2c probe
=> bdinfo
```

将所有输出发给我，我会帮你修正设备树和分区布局。

## 🚀 使用 GitHub Actions 编译

### 1. 创建 GitHub 仓库

1. 登录 [GitHub](https://github.com)
2. 点击 **New repository**
3. 名称填写：`openwrt-hc-en101`
4. 选择 **Private**（推荐，避免固件泄露）
5. 不要勾选 README / .gitignore / License
6. 点击 **Create repository**

### 2. 上传项目文件

```bash
cd openwrt-hc-en101
git init
git add .
git commit -m "Initial: OpenWrt HC-EN101 build config"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/openwrt-hc-en101.git
git push -u origin main
```

### 3. 触发编译

1. 进入仓库页面 → **Actions** 选项卡
2. 选择 **Build OpenWrt for HC-EN101** workflow
3. 点击 **Run workflow**
4. 选择 OpenWrt 版本（默认 v24.10.2）
5. 点击 **Run workflow** 按钮

### 4. 下载固件

编译约需 2-4 小时。完成后：
1. 进入 **Actions** → 对应的 workflow run
2. 在 **Artifacts** 区域下载 `openwrt-hc-en101-firmware`
3. 解压后得到固件文件

## 📦 固件文件说明

| 文件 | 用途 |
|------|------|
| `*-firmware.bin` | 完整固件，用于首次刷机（通过 U-Boot TFTP 烧写） |
| `*-sysupgrade.bin` | 升级固件，在已运行 OpenWrt 的系统上使用 |

## 🔥 刷机步骤

### 通过 U-Boot TFTP 刷入

1. 设置 TFTP 服务器（电脑上运行 tftpd 或 dnsmasq）
2. 将 `firmware.bin` 放入 TFTP 目录
3. 路由器串口连接，进入 U-Boot 命令行
4. 设置网络参数：

```bash
=> setenv ethaddr XX:XX:XX:XX:XX:XX    # 路由器LAN口MAC
=> setenv ipaddr 192.168.1.1            # 路由器IP
=> setenv serverip 192.168.1.2          # 电脑IP
```

5. 下载并烧写固件：

```bash
=> tftp a0000000 openwrt-layerscape-armv8_64b-hctele_hc-en101-squashfs-firmware.bin
=> sf probe 0:0
=> sf erase 0 +$filesize
=> sf write a0000000 0 $filesize
=> reset
```

### ⚠️ 救砖准备

刷机前请**务必备份原厂固件**：

```bash
=> sf probe 0:0
=> sf read a0000000 0 0x2000000    # 读取32MB flash
=> tftp a0000000 original-firmware.bin 0x2000000  # 上传到电脑
```

## 📁 项目文件结构

```
openwrt-hc-en101/
├── .github/workflows/build.yml   # GitHub Actions 编译流程
├── config/
│   └── hc-en101.config           # OpenWrt 编译配置
├── files/                         # 需要合并到 OpenWrt 源码的文件
│   └── target/linux/layerscape/
│       ├── armv8_64b/dts/
│       │   └── fsl-ls1012a-hc-en101.dts   # HC-EN101 设备树
│       └── image/
│           └── hc-en101.mk       # HC-EN101 镜像定义
├── patches/
│   └── dts-hc-en101.patch        # 内核 DTS Makefile 补丁
├── scripts/
│   └── apply-patches.sh          # 补丁应用脚本
└── README.md                      # 本文件
```

## 🔧 根据串口日志调整设备树

收到你的串口日志后，我需要检查以下关键信息：

| 信息项 | U-Boot 命令 | DTS 中对应位置 |
|--------|------------|---------------|
| Flash 型号 | `sf probe` | `&qspi` → `compatible`, `spi-max-frequency` |
| Flash 大小 | `sf probe` 输出 | 分区表 `reg` 属性 |
| 分区布局 | `printenv` → mtdparts | 分区 `label` 和 `reg` |
| PHY 型号 | `mii info` | `&pfe` → `phy-mode`, PHY `compatible` |
| 内存大小 | `bdinfo` | `memory@80000000` → `reg` |
| GPIO LED | `gpio status` | `leds` 节点 |
| MAC 地址 | `printenv` → ethaddr | 需在 U-Boot 中设置 |

## ❓ 常见问题

**Q: 编译失败了怎么办？**
A: 查看 Actions 页面的 build logs，常见问题：
- 依赖缺失：修改 build.yml 添加 apt 包
- DTS 语法错误：检查 fsl-ls1012a-hc-en101.dts
- 设备名不匹配：确保 config、mk、dts 三处设备名一致

**Q: 固件刷入后无法启动？**
A: 最可能的原因是设备树与实际硬件不匹配。需要串口日志来诊断。

**Q: 如何添加更多软件包？**
A: 编辑 `config/hc-en101.config`，添加 `CONFIG_PACKAGE_xxx=y`

**Q: 如何切换 OpenWrt 版本？**
A: 在触发 workflow 时修改版本号，或在 build.yml 中修改默认值

## 📄 License

OpenWrt 源码遵循 GPL-2.0 许可证。
本项目配置文件遵循 MIT 许可证。
