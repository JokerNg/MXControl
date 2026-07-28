# MXControl

<p align="center">
  <a href="#中文">中文</a> · <a href="#english">English</a>
</p>

<a id="中文"></a>

## 中文

MXControl 是一款适用于 Logitech MX 设备的轻量级原生 macOS 菜单栏应用。它通过 HID++ 2.0 直接与设备通信，无需账号、遥测服务或常驻的 Electron 后台。

项目支持 Bolt/Unifying USB 接收器和低功耗蓝牙连接，提供滚轮、SmartShift、DPI、按键、背光、电量及 Easy-Switch 主机信息等常用控制功能。应用使用 SwiftUI 编写，保持原生且轻量。

### 主要功能

**鼠标（MX Master 3S）**

- HID++ 高分辨率平滑滚动及滚动加速
- 棘轮/自由滚动模式和 SmartShift 力度调节
- DPI、自然滚动和侧边滚轮方向设置
- 后退/前进键可映射为浏览操作、上一个/下一个桌面或无操作
- 拇指手势支持调度中心、App Exposé 和桌面切换
- 电量、充电状态和 Easy-Switch 主机信息

**键盘（MX Keys Mini）**

- 背光开关和亮度调节
- Fn 键模式切换
- 电量、充电状态和 Easy-Switch 主机信息

**连接与应用**

- 同时支持 Bolt/Unifying USB 接收器和低功耗蓝牙
- 自动合并同一设备的 USB 与蓝牙信息，优先使用 USB 控制
- 设备重连后自动恢复已保存的设置
- 原生中文 SwiftUI 菜单栏界面
- 支持登录时启动，无账号、无遥测

### 支持设备

已测试：

- MX Master 3S（USB + BLE）
- MX Keys Mini（USB + BLE）

其他通过 Bolt 或 Unifying 接收器连接的 HID++ 2.0 设备可能只能显示基础信息。蓝牙直连需要在代码中登记设备 PID。

### 构建与运行

```bash
git clone https://github.com/JokerNg/MXControl.git
cd MXControl
make dmg
```

要求：

- macOS 15.0 或更高版本
- Xcode Command Line Tools
- Logitech HID++ 2.0 兼容设备

首次启动后，请在“系统设置 → 隐私与安全性”中授予：

- **输入监控**：访问蓝牙 HID 设备
- **辅助功能**：平滑滚动和手势操作

<a id="english"></a>

## English

MXControl is a lightweight native macOS menu bar app for Logitech MX devices. It communicates directly with devices over HID++ 2.0 without requiring an account, telemetry service, or persistent Electron background process.

The app supports Bolt/Unifying USB receivers and Bluetooth Low Energy, with controls for scrolling, SmartShift, DPI, buttons, keyboard backlight, battery status, and Easy-Switch host information. It is built with SwiftUI to remain native and lightweight.

### Features

**Mouse (MX Master 3S)**

- HID++ high-resolution smooth scrolling and acceleration
- Ratchet/free-spin modes and SmartShift force adjustment
- DPI, natural scrolling, and thumb-wheel direction settings
- Back/forward buttons can perform browser navigation, switch desktops, or do nothing
- Thumb gestures for Mission Control, App Exposé, and desktop switching
- Battery, charging status, and Easy-Switch host information

**Keyboard (MX Keys Mini)**

- Backlight toggle and brightness
- Fn key mode
- Battery, charging status, and Easy-Switch host information

**Transport and app**

- Bolt/Unifying USB receiver and Bluetooth Low Energy support
- Merges USB and BLE information for the same device while preferring USB control
- Restores saved settings after reconnecting
- Native SwiftUI menu bar interface with Chinese localization
- Launch at login, no account, and no telemetry

### Supported devices

Tested:

- MX Master 3S (USB + BLE)
- MX Keys Mini (USB + BLE)

Other HID++ 2.0 devices connected through a Bolt or Unifying receiver may expose only basic information. Direct BLE support requires the device PID to be registered in code.

### Build and run

```bash
git clone https://github.com/JokerNg/MXControl.git
cd MXControl
make dmg
```

Requirements:

- macOS 15.0 or later
- Xcode Command Line Tools
- Logitech HID++ 2.0 compatible device

After the first launch, grant the following permissions in System Settings → Privacy & Security:

- **Input Monitoring** for BLE HID device access
- **Accessibility** for smooth scrolling and gesture actions

## License

[MIT](LICENSE). Copyright © 2026 Wisnu Wicaksono and MXControl contributors.

This project is derived from [wiscaksono/MXControl](https://github.com/wiscaksono/MXControl).
It is an independent, unofficial project and is not affiliated with or endorsed by Logitech.
Logitech and related marks belong to their respective owners.
