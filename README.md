# MXControl

<p align="center">
  <a href="#中文">中文</a> · <a href="#english">English</a>
</p>

> 一款直接通过 HID++ 2.0 控制 Logitech MX 鼠标和键盘的原生 macOS 菜单栏应用。

<a id="中文"></a>

## 中文

### 项目简介

MXControl 使用 Swift 6、SwiftUI、IOKit 和 CoreBluetooth 构建，无第三方运行时依赖。它可以通过 Bolt/Unifying USB 接收器或 macOS 暴露的蓝牙 HID++ 接口控制设备，并在无法取得完整 HID++ 访问时，通过标准 BLE GATT 服务读取电量和设备信息。

这个版本重点完善了原生中文界面、HID++ 高分辨率平滑滚动、鼠标按键动作、拇指手势、USB/BLE 信息合并、蓝牙重连恢复、按设备保存设置以及低电量通知。

### 鼠标功能

当前主要针对 **MX Master 3S**。

#### 滚轮与指针

- 在棘轮和自由滚动模式之间切换
- 开启或关闭 SmartShift 自动切换
- 调节 SmartShift 力度
- 通过 HID++ 高分辨率通知直接接收主滚轮数据
- 根据滚动速度进行加速，慢速保持精细，快速滚动最高约 4 倍放大
- 按显示器刷新率输出平滑像素滚动，未知刷新率时回退到约 120 Hz
- 棘轮模式采用更直接的响应，自由滚动模式使用更长惯性
- 调节滚动速度（1.0–10.0 倍）
- 调节滚动惯性（0.80–0.98）
- 设置自然滚动方向
- 单独反转侧边滚轮方向
- 单独调节侧边滚轮速度（0.5–5.0 倍）
- 保留当前修饰键，因此 `Command + 滚轮` 等组合操作仍可用于缩放
- 只处理鼠标滚轮事件，不修改触控板滚动
- 修改 DPI，范围和步长由设备能力动态决定

关闭应用或重新扫描前，MXControl 会把高分辨率滚轮目标恢复给 macOS，避免退出后滚轮失效。

#### 鼠标按键配置

中键、后退键和前进键可以分别设置为：

| 动作 | 实际行为 |
|---|---|
| 默认 | 恢复该按键的默认行为 |
| 中键 | 模拟中键点击 |
| 后退 | 向当前应用发送 `Command + [` |
| 前进 | 向当前应用发送 `Command + ]` |
| 上一个桌面 | 切换到左侧桌面 |
| 下一个桌面 | 切换到右侧桌面 |
| 调度中心 / App Exposé / 显示桌面 | 打开对应的 macOS 窗口管理界面 |
| 切换应用 / 关闭窗口 | 发送 `Command + Tab` / `Command + W` |
| 复制 / 粘贴 | 发送 `Command + C` / `Command + V` |
| 播放/暂停 / 静音 / 降低音量 / 提高音量 | 发送对应的系统媒体键 |
| 无操作 | 接收按键事件但不执行动作 |

#### 拇指手势按钮

| 操作 | 动作 |
|---|---|
| 点击 | 调度中心 |
| 按住并向左拖动 | 切换到右侧桌面 |
| 按住并向右拖动 | 切换到左侧桌面 |
| 按住并向上拖动 | 调度中心 |
| 按住并向下拖动 | App Exposé |

可以在高级设置中调节：

- 点击时限：100–400 ms
- 拖动阈值：50–500 个原始 HID 单位

手势动作目前是固定映射，不能自定义为任意快捷键。

#### 电量与设备信息

- 显示电量百分比和充电状态
- 每 5 分钟刷新一次完整 HID++ 设备的电量
- 电量不高于 20% 时发送低电量通知
- 电量不高于 10% 时发送严重低电量通知
- 设备开始充电后重置通知状态，避免同一充电周期重复提醒
- 显示 Easy-Switch 当前主机、主机名称、总线类型和操作系统类型

Easy-Switch 在当前版本中只展示主机信息，不提供切换按钮。

### 键盘功能

当前主要针对 **MX Keys Mini**。

- 显示电量百分比和充电状态
- 开启或关闭背光
- 调节背光亮度，级数由设备能力决定
- 在标准 `F1–F12` 与媒体键优先模式之间切换
- 显示 Easy-Switch 当前主机、主机名称、总线类型和操作系统类型
- 支持与鼠标相同的定时电量刷新和低电量通知
- 按设备保存背光、亮度和功能键模式
- 可清除保存设置并重新读取设备状态

### 连接与设备发现

| 连接路径 | 能力 |
|---|---|
| Bolt/Unifying USB 接收器 | 探测接收器上的 1–6 号设备，并根据设备公开的 HID++ 功能提供完整控制 |
| macOS IOKit 蓝牙 HID++ | 当系统允许打开设备接口时，提供与 USB 路径相同的完整 HID++ 控制 |
| CoreBluetooth BLE 降级路径 | 只读取电量、制造商、型号、固件版本和序列号，不发送 HID++ 控制命令 |

其他连接行为：

- USB 与蓝牙同时发现同一设备时优先使用 USB 控制
- 使用稳定设备标识、型号和严格名称匹配合并 USB、IOKit BLE 与 CoreBluetooth 信息
- CoreBluetooth 扫描窗口为 15 秒，扫描结束后保留已建立连接
- BLE 断开后请求自动重连
- BLE HID++ 重新连接后重新启用滚轮目标、拇指手势和鼠标按键接管状态
- BLE 接口被其他程序独占时，每 5 秒重试一次，最多持续约 5 分钟
- 支持手动刷新当前设备和重新扫描全部设备

### 应用与设置

- 原生中文 SwiftUI 菜单栏界面
- 根据设备能力动态显示可用控制项
- 显示功能加载失败和设置写入失败信息
- 设备设置写入失败时不保存失败值
- 设置按设备名称保存在 `UserDefaults`
- 设备重连后逐项恢复设置，临时 HID++ 错误最多重试 3 次
- 单项恢复失败不会阻止其他设置恢复
- 支持清除单个设备的全部已保存设置并重新读取
- 支持登录时启动
- 支持隐藏菜单栏图标，并可从访达或 Spotlight 重新打开
- 无账号、无遥测、无网络服务依赖

### 已测试设备

| 设备 | USB 接收器 | BLE HID++ | CoreBluetooth 信息 |
|---|---:|---:|---:|
| MX Master 3S | 已测试 | 已测试 | 电量与设备信息 |
| MX Keys Mini | 已测试 | 已测试 | 电量与设备信息 |

其他 Logitech HID++ 2.0 设备可能被发现，但具体控制项取决于设备公开的功能。未知设备只显示基础信息。完整 BLE 控制还取决于 macOS 是否向应用开放该设备的 HID++ 集合。

### 当前限制

- 只对 MX Master 3S 和 MX Keys Mini 做过完整验证
- CoreBluetooth 本身不能在 macOS 15+ 上作为 HID++ 命令通道
- Logi Options+ 或其他进程独占 BLE HID 接口时，完整控制可能暂时不可用
- 拇指手势动作不可自定义，只能调节点击时限和拖动阈值
- 自定义按键动作目前只覆盖中键、后退键和前进键
- 设备层已实现指针速度读写，但当前界面尚未提供调节入口
- Easy-Switch 只显示主机信息，不能从应用内切换主机
- 不支持按应用配置、SmartActions、Flow 或 Logitech 账号

### 构建

要求：

- macOS 15.0 或更高版本
- Xcode Command Line Tools
- Logitech HID++ 2.0 兼容设备

```bash
git clone https://github.com/JokerNg/MXControl.git
cd MXControl

# 直接运行
make run

# 构建 DMG，默认使用 ad-hoc 签名
make dmg
```

如需使用自己的签名证书：

```bash
make dmg SIGNING_IDENTITY="Developer ID Application: Your Name (TEAMID)"
```

### 权限

首次启动后，请在“系统设置 → 隐私与安全性”中授予：

- **输入监控**：打开 USB/BLE HID++ 设备接口
- **辅助功能**：发布平滑滚动、手势、快捷键、媒体键及鼠标按键动作
- **蓝牙**：通过 CoreBluetooth 读取 BLE 电量和设备信息
- **通知**：发送低电量提醒

<a id="english"></a>

## English

### Overview

MXControl is built with Swift 6, SwiftUI, IOKit, and CoreBluetooth, with no third-party runtime dependencies. It controls devices through a Bolt/Unifying receiver or the Bluetooth HID++ interface exposed by macOS. When full HID++ access is unavailable, it falls back to standard BLE GATT services for battery and device information.

This fork focuses on a native Chinese interface, HID++ high-resolution smooth scrolling, configurable mouse-button actions, thumb gestures, USB/BLE metadata merging, BLE reconnect recovery, per-device settings, and low-battery notifications.

### Mouse features

The primary tested mouse is the **MX Master 3S**.

#### Scrolling and pointer

- Switch between ratchet and free-spin wheel modes
- Enable or disable automatic SmartShift switching
- Adjust SmartShift force
- Receive main-wheel input directly from HID++ high-resolution notifications
- Apply event-rate acceleration, from precise slow scrolling up to about 4× at high speed
- Emit smooth pixel scrolling at the display refresh rate, with a roughly 120 Hz fallback
- Use a snappier profile in ratchet mode and longer momentum in free-spin mode
- Adjust scroll speed from 1.0× to 10.0×
- Adjust scroll momentum from 0.80 to 0.98
- Configure natural scrolling
- Reverse the thumb wheel independently
- Adjust thumb-wheel speed from 0.5× to 5.0×
- Preserve current modifier flags so combinations such as `Command + Scroll` continue to zoom
- Leave trackpad scrolling untouched
- Adjust DPI using the range and step reported by the device

Before quitting or rescanning, MXControl returns the high-resolution wheel target to macOS so normal scrolling continues after the app exits.

#### Mouse button configuration

The middle, Back, and Forward buttons can each be configured independently:

| Action | Behavior |
|---|---|
| Default | Restore the selected button's default behavior |
| Middle click | Simulate a middle-button click |
| Back | Send `Command + [` to the frontmost app |
| Forward | Send `Command + ]` to the frontmost app |
| Previous desktop | Switch to the workspace on the left |
| Next desktop | Switch to the workspace on the right |
| Mission Control / App Exposé / Show Desktop | Open the corresponding macOS window-management view |
| Switch application / Close window | Send `Command + Tab` / `Command + W` |
| Copy / Paste | Send `Command + C` / `Command + V` |
| Play/Pause / Mute / Volume down / Volume up | Send the corresponding system media key |
| Do nothing | Receive the button event without performing an action |

#### Thumb gesture button

| Gesture | Action |
|---|---|
| Click | Mission Control |
| Hold and drag left | Switch to the workspace on the right |
| Hold and drag right | Switch to the workspace on the left |
| Hold and drag up | Mission Control |
| Hold and drag down | App Exposé |

Advanced settings expose:

- Click time limit: 100–400 ms
- Drag threshold: 50–500 raw HID units

Gesture actions are currently fixed; only the timing and movement threshold are configurable.

#### Battery and device information

- Battery percentage and charging state
- Battery refresh every 5 minutes for full HID++ devices
- Low-battery notification at or below 20%
- Critical-battery notification at or below 10%
- Notification state resets when charging begins
- Easy-Switch current host, host names, bus type, and operating system type

Easy-Switch host information is read-only in the current version.

### Keyboard features

The primary tested keyboard is the **MX Keys Mini**.

- Battery percentage and charging state
- Backlight toggle
- Backlight brightness using the level count reported by the device
- Standard `F1–F12` versus media-key mode
- Easy-Switch current host, host names, bus type, and operating system type
- Periodic battery refresh and low-battery notifications
- Per-device persistence for backlight, brightness, and function-key mode
- Clear saved settings and reload the current device state

### Transport and discovery

| Path | Capability |
|---|---|
| Bolt/Unifying USB receiver | Probes receiver slots 1–6 and enables controls based on the HID++ features reported by each device |
| macOS IOKit Bluetooth HID++ | Provides the same full HID++ control when macOS allows the device interface to be opened |
| CoreBluetooth BLE fallback | Reads battery, manufacturer, model, firmware revision, and serial number only; it does not send HID++ commands |

Additional connection behavior:

- Prefers USB control when the same device is available over USB and BLE
- Merges USB, IOKit BLE, and CoreBluetooth information using stable identity, model, and strict name matching
- Scans with CoreBluetooth for 15 seconds while keeping established connections alive
- Requests automatic CoreBluetooth reconnection after disconnects
- Re-arms scroll targeting, thumb gestures, and configurable mouse-button diversion after BLE HID++ reconnects
- Retries an exclusively locked BLE HID interface every 5 seconds for up to about 5 minutes
- Supports manual device refresh and full rescanning

### App and settings

- Native SwiftUI menu bar interface with Chinese localization
- Shows controls dynamically based on device capabilities
- Reports feature-load and setting-write failures in the UI
- Does not persist a value when its device write fails
- Stores settings per device in `UserDefaults`
- Restores settings independently after reconnect, with up to 3 retries for transient HID++ errors
- Continues restoring other settings if one setting fails
- Clears all saved settings for a selected device and reloads its current state
- Launch at login
- Hide the menu bar icon and reopen from Finder or Spotlight
- No account, telemetry, or network service dependency

### Tested devices

| Device | USB receiver | BLE HID++ | CoreBluetooth information |
|---|---:|---:|---:|
| MX Master 3S | Tested | Tested | Battery and device information |
| MX Keys Mini | Tested | Tested | Battery and device information |

Other Logitech HID++ 2.0 devices may be discovered, but available controls depend on the features reported by the device. Unknown devices expose basic information only. Full BLE control also depends on macOS exposing the device's HID++ collection.

### Current limitations

- Full validation currently covers only the MX Master 3S and MX Keys Mini
- CoreBluetooth is not an HID++ command channel on macOS 15+
- Full BLE control may be temporarily unavailable while Logi Options+ or another process owns the HID interface
- Thumb gesture actions are fixed; only timing and drag threshold are configurable
- Custom actions currently cover the middle, Back, and Forward buttons only
- Pointer-speed read/write exists in the device layer but is not exposed in the current UI
- Easy-Switch host information is read-only
- No per-app profiles, SmartActions, Flow, or Logitech account

### Build

Requirements:

- macOS 15.0 or later
- Xcode Command Line Tools
- Logitech HID++ 2.0 compatible device

```bash
git clone https://github.com/JokerNg/MXControl.git
cd MXControl

# Run directly
make run

# Build a DMG with the default ad-hoc signature
make dmg
```

To use your own signing certificate:

```bash
make dmg SIGNING_IDENTITY="Developer ID Application: Your Name (TEAMID)"
```

### Permissions

After the first launch, grant:

- **Input Monitoring** to open USB/BLE HID++ device interfaces
- **Accessibility** to post smooth scrolling, gestures, workspace switching, and side-button actions
- **Bluetooth** to read BLE battery and device information through CoreBluetooth
- **Notifications** for low-battery alerts

## License

[MIT](LICENSE). Copyright © 2026 Wisnu Wicaksono and MXControl contributors.

This project is derived from [wiscaksono/MXControl](https://github.com/wiscaksono/MXControl).
It is an independent, unofficial project and is not affiliated with or endorsed by Logitech.
Logitech and related marks belong to their respective owners.
