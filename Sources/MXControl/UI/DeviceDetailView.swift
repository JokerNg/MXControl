import SwiftUI

/// Per-device detail view displayed when clicking a device in the menu bar.
/// Reads DeviceManager from environment for save operations.
struct DeviceDetailView: View {
    let device: LogiDevice
    let bleInfo: BLEDeviceInfo?

    var body: some View {
        VStack(spacing: 0) {
            deviceControls

            if let bleInfo, hasUsefulBLEInfo(bleInfo) {
                Divider()
                .padding(.horizontal, 12)
                BLEMetadataSection(
                    info: bleInfo,
                    showsBattery: !device.hasFeature(BatteryFeature.featureId)
                )
            }
        }
    }

    @ViewBuilder
    private var deviceControls: some View {
        if let mouse = device as? MouseDevice {
            MouseDetailView(mouse: mouse)
        } else if let keyboard = device as? KeyboardDevice {
            KeyboardDetailView(keyboard: keyboard)
        } else {
            GenericDeviceView(device: device)
        }
    }

    private func hasUsefulBLEInfo(_ info: BLEDeviceInfo) -> Bool {
        (!device.hasFeature(BatteryFeature.featureId) && info.batteryLevel != nil)
            || info.manufacturer != nil
            || info.modelNumber != nil
            || info.firmwareRevision != nil
            || info.serialNumber != nil
    }
}

private struct BLEMetadataSection: View {
    let info: BLEDeviceInfo
    let showsBattery: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("设备信息")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.tertiary)
                .textCase(.uppercase)

            if showsBattery, let battery = info.batteryLevel {
                HStack {
                    Text("电量")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Spacer()
                    BatteryIndicator(level: battery, isCharging: false)
                }
            }

            BLEDeviceInfoRows(info: info)

            Label("来自低功耗蓝牙的补充信息", systemImage: "antenna.radiowaves.left.and.right")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

// MARK: - Compact Row Helper

/// Reusable row: HStack(spacing: 8) with vertical padding.
private func row<C: View>(@ViewBuilder content: () -> C) -> some View {
    HStack(spacing: 8) {
        content()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.vertical, 6)
}

/// Separator between sections.
private var separator: some View {
    Divider()
}

// MARK: - Mouse Detail View

struct MouseDetailView: View {
    @Bindable var mouse: MouseDevice
    @Environment(DeviceManager.self) private var deviceManager
    @State private var settingError: String?

    var body: some View {
        if !mouse.isFeaturesLoaded {
            loadingView
        } else {
            VStack(alignment: .leading, spacing: 0) {
                    // Battery
                    if mouse.hasFeature(BatteryFeature.featureId) {
                        batteryRow
                        separator
                    }

                    // Feature load error / connection warning
                    if let error = mouse.featureLoadError {
                        featureWarningBanner(error)
                        separator
                    }

                    if let settingError {
                        featureWarningBanner(settingError, prefix: "")
                        separator
                    }

                    // Wheel Mode picker (Ratchet / Free Spin)
                    if mouse.hasFeature(SmartShiftFeature.featureId) {
                        wheelModeSection
                        separator
                    }

                    // SmartShift toggle
                    if mouse.hasFeature(SmartShiftFeature.featureId) {
                        smartShiftToggleSection
                        separator
                    }

                    // Smooth Scroll toggle (+ accessibility warning)
                    smoothScrollSection
                    separator

                    // Natural Scrolling
                    if mouse.hasFeature(HiResScrollFeature.featureId) {
                        scrollDirectionSection
                        separator
                    }

                    // Invert Thumb Wheel
                    if mouse.hasFeature(ThumbWheelFeature.featureId) && mouse.thumbWheelSupportsInversion {
                        thumbWheelSection
                        separator
                    }

                    // Diverted configurable mouse-button actions
                    if hasConfigurableButtons {
                        buttonSection
                        separator
                    }

                    // Host Info
                    if !mouse.hosts.isEmpty {
                        hostInfoSection
                        separator
                    }

                    // Advanced (DPI, SmartShift Force, Scroll Speed/Momentum, Gesture thresholds)
                    advancedSection
                    separator

                    // Reset
                    resetSection
                }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Save

    private func save() {
        SettingsStore.save(mouse: mouse)
    }

    private func commitSetting(
        _ name: String,
        operation: () async throws -> Void
    ) async throws {
        do {
            try await operation()
            settingError = nil
            save()
        } catch {
            settingError = "\(name)设置失败：\(error.localizedDescription)"
            debugLog("[UI] \(name) setting failed: \(error)")
            throw error
        }
    }

    // MARK: - Reset (inline confirmation — .alert() dismisses MenuBarExtra)

    @State private var showResetConfirm = false
    @State private var resetHovered = false

    private var resetSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showResetConfirm {
                VStack(spacing: 10) {
                    Text("清除所有已保存设置并从设备重新读取？")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)

                    HStack(spacing: 8) {
                        ResetActionButton(label: "取消", isDestructive: false) {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                showResetConfirm = false
                            }
                        }

                        ResetActionButton(label: "清除", isDestructive: true) {
                            SettingsStore.clearMouseSettings(deviceName: mouse.name)
                            Task {
                                mouse.isFeaturesLoaded = false
                                await mouse.loadMouseFeatures()
                            }
                            withAnimation(.easeInOut(duration: 0.15)) {
                                showResetConfirm = false
                            }
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )
            } else {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        showResetConfirm = true
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 10))
                        Text("清除已保存设置")
                            .font(.system(size: 12))
                    }
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(resetHovered
                                ? Color(nsColor: .selectedContentBackgroundColor).opacity(0.12)
                                : Color(nsColor: .controlBackgroundColor))
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .onHover { resetHovered = $0 }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Battery

    private var batteryRow: some View {
        row {
            Text("电量")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .leading)

            Spacer()

            BatteryIndicator(level: mouse.batteryLevel, isCharging: mouse.batteryCharging)

            Text(mouse.batteryStatus.description)
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
            Text("正在加载功能…")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    // MARK: - Wheel Mode (picker only)

    private var wheelModeSection: some View {
        row {
            Text("滚轮")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .leading)

            Spacer()

            Picker("", selection: Binding(
                get: { mouse.smartShiftWheelMode },
                set: { newMode in
                    let oldMode = mouse.smartShiftWheelMode
                    mouse.smartShiftWheelMode = newMode
                    Task {
                        do {
                            try await commitSetting("滚轮模式") {
                                try await mouse.setSmartShift(wheelMode: newMode)
                            }
                        } catch {
                            mouse.smartShiftWheelMode = oldMode
                        }
                    }
                }
            )) {
                Text("棘轮").tag(SmartShiftFeature.WheelMode.ratchet)
                Text("自由滚动").tag(SmartShiftFeature.WheelMode.freeSpin)
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .frame(maxWidth: 160)
        }
    }

    // MARK: - SmartShift Toggle (no Force slider — that's in Advanced)

    private var smartShiftToggleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ToggleRow(
                label: "SmartShift",
                isOn: $mouse.smartShiftActive,
                subtitle: "自动切换棘轮与自由滚动模式"
            ) { enabled in
                try await commitSetting("SmartShift") {
                    try await mouse.setSmartShift(autoDisengage: enabled ? 50 : 0)
                }
            }
        }
        .padding(.vertical, 6)
    }

    // MARK: - Feature Warning Banner

    private func featureWarningBanner(
        _ error: String,
        prefix: String = "部分功能加载失败："
    ) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 10))
                .foregroundStyle(.orange)
            Text("\(prefix)\(error)")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Smooth Scroll (toggle + accessibility warning only)

    private var smoothScrollSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ToggleRow(
                label: "平滑滚动",
                isOn: $mouse.smoothScrollEnabled,
                subtitle: "平滑处理滚轮输入（自由滚动模式效果最佳）"
            ) { enabled in
                if enabled {
                    MacActions.requestAccessibilityPermission()
                }
                save()
            }

            if mouse.smoothScrollEnabled && !MacActions.hasAccessibilityPermission() {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 10))
                        .foregroundStyle(.orange)
                    Text("需要“辅助功能”权限。请前往“系统设置”>“隐私与安全性”>“辅助功能”中授权。")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.vertical, 6)
    }

    // MARK: - Advanced (custom disclosure — full row is clickable)

    @State private var showAdvanced = false

    private var advancedSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showAdvanced.toggle()
                }
            } label: {
                HStack {
                    Text("高级设置")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(showAdvanced ? 90 : 0))
                }
                .contentShape(Rectangle())
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)

            if showAdvanced {
                VStack(alignment: .leading, spacing: 4) {
                    // DPI
                    if mouse.hasFeature(AdjustableDPIFeature.featureId) {
                        SliderRow(
                            label: "DPI",
                            intValue: $mouse.currentDPI,
                            range: mouse.dpiMin...mouse.dpiMax,
                            step: mouse.dpiStep,
                            suffix: " DPI"
                        ) { dpi in
                            try await commitSetting("DPI") {
                                try await mouse.setDPI(dpi)
                            }
                        }
                    }

                    // SmartShift Force
                    if mouse.hasFeature(SmartShiftFeature.featureId) && mouse.smartShiftActive {
                        SliderRow(
                            label: "SmartShift 力度",
                            intValue: $mouse.smartShiftTorque,
                            range: 1...mouse.smartShiftMaxForce,
                            step: 1
                        ) { torque in
                            try await commitSetting("SmartShift 力度") {
                                try await mouse.setSmartShift(torque: torque)
                            }
                        }
                    }

                    // Smooth Scroll Speed
                    if mouse.smoothScrollEnabled {
                        SliderRow(
                            label: "滚动速度",
                            value: $mouse.smoothScrollSpeed,
                            range: 1.0...10.0,
                            step: 0.5,
                            format: "%.1f",
                            suffix: "x"
                        ) { _ in
                            save()
                        }

                        SliderRow(
                            label: "滚动惯性",
                            value: $mouse.smoothScrollMomentum,
                            range: 0.80...0.98,
                            step: 0.01,
                            format: "%.2f"
                        ) { _ in
                            save()
                        }
                    }

                    // Gesture thresholds
                    if mouse.gestureEngine != nil {
                        Text("手势按钮")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.tertiary)
                            .textCase(.uppercase)
                            .padding(.top, 6)
                            .padding(.bottom, 2)

                        if !MacActions.hasAccessibilityPermission() {
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.orange)
                                Text("手势功能需要“辅助功能”权限。")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.tertiary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        SliderRow(
                            label: "点击时限",
                            intValue: Binding(
                                get: { Int(mouse.gestureClickTimeLimit * 1000) },
                                set: { mouse.gestureClickTimeLimit = Double($0) / 1000.0 }
                            ),
                            range: 100...400,
                            step: 10,
                            suffix: "ms"
                        ) { _ in
                            save()
                        }

                        SliderRow(
                            label: "拖动阈值",
                            intValue: $mouse.gestureDragThreshold,
                            range: 50...500,
                            step: 10
                        ) { _ in
                            save()
                        }
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }

    // MARK: - Scroll Direction

    private var scrollDirectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ToggleRow(
                label: "自然滚动",
                isOn: $mouse.hiResInverted,
                subtitle: "内容随手指移动方向滚动"
            ) { inverted in
                try await commitSetting("自然滚动") {
                    try await mouse.setHiResScroll(hiRes: mouse.hiResEnabled, inverted: inverted)
                }
            }
        }
        .padding(.vertical, 6)
    }

    // MARK: - Thumb Wheel

    private var thumbWheelSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ToggleRow(
                label: "反转侧边滚轮",
                isOn: $mouse.thumbWheelInverted,
                subtitle: "关闭时跟随自然滚动，开启时方向相反"
            ) { inverted in
                try await commitSetting("侧边滚轮方向") {
                    try await mouse.setThumbWheelInverted(inverted)
                }
            }

            if mouse.smoothScrollEnabled {
                SliderRow(
                    label: "侧边滚轮速度",
                    value: $mouse.smoothScrollThumbSpeed,
                    range: 0.5...5.0,
                    step: 0.5,
                    format: "%.1f",
                    suffix: "x"
                ) { _ in
                    save()
                }
            }
        }
        .padding(.vertical, 6)
    }

    // (Gesture thresholds moved into Advanced section)

    // MARK: - Buttons

    private var hasConfigurableButtons: Bool {
        mouse.buttons.contains {
            $0.isDivertable && (
                $0.controlId == SpecialKeysFeature.KnownCID.middleButton.rawValue
                    || $0.controlId == SpecialKeysFeature.KnownCID.backButton.rawValue
                    || $0.controlId == SpecialKeysFeature.KnownCID.forwardButton.rawValue
            )
        }
    }

    private var buttonSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("按键")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.tertiary)
                .textCase(.uppercase)
                .padding(.top, 10)
                .padding(.bottom, 2)

            configurableButtonPicker(
                controlId: SpecialKeysFeature.KnownCID.middleButton.rawValue,
                name: "中键"
            )
            configurableButtonPicker(
                controlId: SpecialKeysFeature.KnownCID.backButton.rawValue,
                name: "后退键"
            )
            configurableButtonPicker(
                controlId: SpecialKeysFeature.KnownCID.forwardButton.rawValue,
                name: "前进键"
            )
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private func configurableButtonPicker(controlId: UInt16, name: String) -> some View {
        if mouse.buttons.contains(where: { $0.controlId == controlId && $0.isDivertable }) {
            ActionPicker(
                buttonName: name,
                controlId: controlId,
                currentAction: Binding(
                    get: { mouse.sideButtonAction(for: controlId) },
                    set: { mouse.setSideButtonAction($0, for: controlId) }
                ),
                actions: ButtonAction.configurableButtonActions
            ) { _ in
                save()
            }
        }
    }

    // MARK: - Host Info

    private var hostInfoSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Easy-Switch")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.tertiary)
                .textCase(.uppercase)
                .padding(.top, 10)
                .padding(.bottom, 2)

            ForEach(mouse.hosts) { host in
                row {
                    Image(systemName: host.index == mouse.currentHostIndex
                        ? "checkmark.circle.fill"
                        : "circle")
                        .font(.system(size: 10))
                        .foregroundStyle(host.index == mouse.currentHostIndex ? .green : .secondary)

                    Text(host.name)
                        .font(.system(size: 12))
                        .lineLimit(1)

                    Spacer()

                    Text("\(host.busType.description) \(host.osType.description)")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Keyboard Detail View

struct KeyboardDetailView: View {
    @Bindable var keyboard: KeyboardDevice
    @Environment(DeviceManager.self) private var deviceManager
    @State private var settingError: String?

    var body: some View {
        if !keyboard.isFeaturesLoaded {
            VStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text("正在加载功能…")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                    // Battery
                    if keyboard.hasFeature(BatteryFeature.featureId) {
                        batteryRow
                        separator
                    }

                    if let settingError {
                        settingErrorBanner(settingError)
                        separator
                    }

                    // Backlight
                    if keyboard.backlightFeatureId != nil {
                        backlightSection
                        separator
                    }

                    // Fn Inversion
                    if keyboard.fnInversionFeatureId != nil {
                        fnInversionSection
                        separator
                    }

                    // Host Info
                    if !keyboard.hosts.isEmpty {
                        hostInfoSection
                        separator
                    }

                    // Reset
                    resetSection
                }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }

    private func save() {
        SettingsStore.save(keyboard: keyboard)
    }

    private func commitSetting(
        _ name: String,
        operation: () async throws -> Void
    ) async throws {
        do {
            try await operation()
            settingError = nil
            save()
        } catch {
            settingError = "\(name)设置失败：\(error.localizedDescription)"
            debugLog("[UI] \(name) setting failed: \(error)")
            throw error
        }
    }

    private func settingErrorBanner(_ error: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 10))
                .foregroundStyle(.orange)
            Text(error)
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Reset (inline confirmation — .alert() dismisses MenuBarExtra)

    @State private var showResetConfirm = false
    @State private var resetHovered = false

    private var resetSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showResetConfirm {
                VStack(spacing: 10) {
                    Text("清除所有已保存设置并从设备重新读取？")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)

                    HStack(spacing: 8) {
                        ResetActionButton(label: "取消", isDestructive: false) {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                showResetConfirm = false
                            }
                        }

                        ResetActionButton(label: "清除", isDestructive: true) {
                            SettingsStore.clearKeyboardSettings(deviceName: keyboard.name)
                            Task {
                                keyboard.isFeaturesLoaded = false
                                await keyboard.loadKeyboardFeatures()
                            }
                            withAnimation(.easeInOut(duration: 0.15)) {
                                showResetConfirm = false
                            }
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )
            } else {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        showResetConfirm = true
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 10))
                        Text("清除已保存设置")
                            .font(.system(size: 12))
                    }
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(resetHovered
                                ? Color(nsColor: .selectedContentBackgroundColor).opacity(0.12)
                                : Color(nsColor: .controlBackgroundColor))
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .onHover { resetHovered = $0 }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Battery

    private var batteryRow: some View {
        row {
            Text("电量")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .leading)

            Spacer()

            BatteryIndicator(level: keyboard.batteryLevel, isCharging: keyboard.batteryCharging)

            Text(keyboard.batteryStatus.description)
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Backlight

    private var backlightSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ToggleRow(
                label: "背光",
                isOn: $keyboard.backlightEnabled,
                subtitle: "键盘照明"
            ) { enabled in
                debugLog("[UI] Backlight toggle: enabled=\(enabled)")
                try await commitSetting("背光") {
                    try await keyboard.setBacklight(enabled: enabled, level: keyboard.backlightLevel)
                }
            }

            if keyboard.backlightEnabled {
                SliderRow(
                    label: "亮度",
                    intValue: $keyboard.backlightLevel,
                    range: 0...keyboard.backlightMaxLevel,
                    step: 1
                ) { level in
                    debugLog("[UI] Backlight level: \(level)")
                    try await commitSetting("背光亮度") {
                        try await keyboard.setBacklight(enabled: keyboard.backlightEnabled, level: level)
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }

    // MARK: - Fn Inversion

    private var fnInversionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Note: The MX Keys Mini 0x40A3 protocol uses inverted semantics from
            // what Solaar docs suggest. fnState=0x00 from device means "F-keys are
            // primary" and fnState=0x01 means "media keys are primary" (the default).
            // We flip the binding so the UI toggle "Standard Function Keys" = ON
            // correctly sends fnState=0x00 (which makes F-keys primary on the device).
            ToggleRow(
                label: "标准功能键",
                isOn: Binding(
                    get: { !keyboard.fnInverted },
                    set: { keyboard.fnInverted = !$0 }
                ),
                subtitle: "将 F1–F12 用作标准功能键，按住 Fn 使用媒体功能"
            ) { wantStandardFKeys in
                let protocolValue = !wantStandardFKeys
                debugLog("[UI] Fn inversion toggle: wantStdFKeys=\(wantStandardFKeys) → protocol fnInverted=\(protocolValue)")
                try await commitSetting("标准功能键") {
                    try await keyboard.setFnInversion(protocolValue)
                }
            }
        }
        .padding(.vertical, 6)
    }

    // MARK: - Host Info

    private var hostInfoSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Easy-Switch")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.tertiary)
                .textCase(.uppercase)
                .padding(.top, 10)
                .padding(.bottom, 2)

            ForEach(keyboard.hosts) { host in
                row {
                    Image(systemName: host.index == keyboard.currentHostIndex
                        ? "checkmark.circle.fill"
                        : "circle")
                        .font(.system(size: 10))
                        .foregroundStyle(host.index == keyboard.currentHostIndex ? .green : .secondary)

                    Text(host.name)
                        .font(.system(size: 12))
                        .lineLimit(1)

                    Spacer()

                    Text("\(host.busType.description) \(host.osType.description)")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Reset Action Button

/// Styled button for inline reset confirmation (Cancel / Clear).
private struct ResetActionButton: View {
    let label: String
    let isDestructive: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: isDestructive ? .medium : .regular))
                .foregroundStyle(isDestructive ? .red : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isHovered
                            ? (isDestructive
                                ? Color.red.opacity(0.12)
                                : Color(nsColor: .selectedContentBackgroundColor).opacity(0.12))
                            : Color.clear)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Generic Device View (fallback)

struct GenericDeviceView: View {
    let device: LogiDevice

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 26))
                .foregroundStyle(.secondary)

            Text(device.name)
                .font(.system(size: 13, weight: .medium))

            Text("未知设备类型，暂无可用控制项")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}
