import SwiftUI

/// Predefined actions for button remapping.
///
/// These map to HID++ CIDs or virtual actions that the MX Master 3S supports.
/// For CID-based remaps, the device maps the button to behave like another button.
/// For "Default", the remap is cleared (CID 0).
enum ButtonAction: String, Hashable, CaseIterable, CustomStringConvertible, Sendable {
    case defaultAction
    case middleClick
    case back
    case forward
    case previousDesktop
    case nextDesktop
    case missionControl
    case appExpose
    case showDesktop
    case appSwitcher
    case closeWindow
    case copy
    case paste
    case playPause
    case mute
    case volumeDown
    case volumeUp
    case gestureButton
    case smartShiftToggle
    case doNothing

    static let configurableButtonActions: [ButtonAction] = [
        .defaultAction,
        .middleClick,
        .back,
        .forward,
        .previousDesktop,
        .nextDesktop,
        .missionControl,
        .appExpose,
        .showDesktop,
        .appSwitcher,
        .closeWindow,
        .copy,
        .paste,
        .playPause,
        .mute,
        .volumeDown,
        .volumeUp,
        .doNothing,
    ]

    /// The same predefined software actions are valid for thumb gestures.
    static let gestureActions = configurableButtonActions

    /// The CID to send as remap target (0 = restore default).
    var remapCID: UInt16 {
        switch self {
        case .defaultAction: return 0
        case .middleClick: return 82
        case .back: return 83
        case .forward: return 86
        case .previousDesktop, .nextDesktop,
             .missionControl, .appExpose, .showDesktop, .appSwitcher,
             .closeWindow, .copy, .paste,
             .playPause, .mute, .volumeDown, .volumeUp:
            return 0
        case .gestureButton: return 195
        case .smartShiftToggle: return 196
        case .doNothing: return 0   // Divert + no handler = do nothing
        }
    }

    /// Whether this action requires diverting the button to software.
    var requiresDivert: Bool {
        switch self {
        case .defaultAction, .gestureButton, .smartShiftToggle:
            return false
        default:
            return true
        }
    }

    var description: String {
        displayName
    }

    /// Human-readable action name.
    var displayName: String {
        switch self {
        case .defaultAction: return "默认"
        case .middleClick: return "中键点击"
        case .back: return "后退"
        case .forward: return "前进"
        case .previousDesktop: return "上一个桌面"
        case .nextDesktop: return "下一个桌面"
        case .missionControl: return "调度中心"
        case .appExpose: return "App Exposé"
        case .showDesktop: return "显示桌面"
        case .appSwitcher: return "切换应用"
        case .closeWindow: return "关闭窗口"
        case .copy: return "复制"
        case .paste: return "粘贴"
        case .playPause: return "播放/暂停"
        case .mute: return "静音"
        case .volumeDown: return "降低音量"
        case .volumeUp: return "提高音量"
        case .gestureButton: return "手势"
        case .smartShiftToggle: return "SmartShift"
        case .doNothing: return "无操作"
        }
    }

    /// SF Symbol name for this action.
    var systemImage: String {
        switch self {
        case .defaultAction: return "arrow.uturn.backward"
        case .middleClick: return "computermouse"
        case .back: return "chevron.left"
        case .forward: return "chevron.right"
        case .previousDesktop: return "rectangle.leadinghalf.inset.filled.arrow.leading"
        case .nextDesktop: return "rectangle.trailinghalf.inset.filled.arrow.trailing"
        case .missionControl: return "rectangle.3.group"
        case .appExpose: return "macwindow.on.rectangle"
        case .showDesktop: return "macwindow"
        case .appSwitcher: return "arrow.triangle.2.circlepath"
        case .closeWindow: return "xmark.rectangle"
        case .copy: return "doc.on.doc"
        case .paste: return "doc.on.clipboard"
        case .playPause: return "playpause"
        case .mute: return "speaker.slash"
        case .volumeDown: return "speaker.wave.1"
        case .volumeUp: return "speaker.wave.3"
        case .gestureButton: return "hand.draw"
        case .smartShiftToggle: return "arrow.up.arrow.down.circle"
        case .doNothing: return "nosign"
        }
    }

    /// Create from a remap target CID.
    static func from(cid: UInt16) -> ButtonAction {
        switch cid {
        case 0: return .defaultAction
        case 82: return .middleClick
        case 83: return .back
        case 86: return .forward
        case 195: return .gestureButton
        case 196: return .smartShiftToggle
        default: return .defaultAction
        }
    }
}

/// A compact picker dropdown for assigning a predefined action.
struct ActionPicker: View {
    let buttonName: String
    @Binding var currentAction: ButtonAction
    var actions: [ButtonAction] = ButtonAction.allCases
    var onChanged: ((ButtonAction) -> Void)?

    var body: some View {
        HStack(spacing: 8) {
            Text(buttonName)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(minWidth: 64, maxWidth: 110, alignment: .leading)

            Spacer()

            Picker("", selection: $currentAction) {
                ForEach(actions, id: \.self) { action in
                    Label(action.displayName, systemImage: action.systemImage)
                        .tag(action)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(maxWidth: 150)
            .onChange(of: currentAction) { _, newAction in
                onChanged?(newAction)
            }
        }
    }
}
