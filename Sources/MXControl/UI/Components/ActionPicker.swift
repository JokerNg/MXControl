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
    case gestureButton
    case smartShiftToggle
    case doNothing

    static let sideButtonActions: [ButtonAction] = [
        .defaultAction, .back, .forward, .previousDesktop, .nextDesktop, .doNothing,
    ]

    /// The CID to send as remap target (0 = restore default).
    var remapCID: UInt16 {
        switch self {
        case .defaultAction: return 0
        case .middleClick: return 82
        case .back: return 83
        case .forward: return 86
        case .previousDesktop, .nextDesktop: return 0
        case .gestureButton: return 195
        case .smartShiftToggle: return 196
        case .doNothing: return 0   // Divert + no handler = do nothing
        }
    }

    /// Whether this action requires diverting the button to software.
    var requiresDivert: Bool {
        self == .doNothing || self == .previousDesktop || self == .nextDesktop
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

/// A compact picker dropdown for remapping a mouse button to a predefined action.
struct ActionPicker: View {
    let buttonName: String
    let controlId: UInt16
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
