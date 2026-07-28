import SwiftUI

/// A labeled row with a toggle switch, sized for compact menu bar UI.
struct ToggleRow: View {
    let label: String
    @Binding var isOn: Bool
    var subtitle: String?
    var onChange: ((Bool) async throws -> Void)?

    @State private var isApplying = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 12))

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Toggle("", isOn: Binding(
                get: { isOn },
                set: { newValue in
                    guard let onChange else {
                        isOn = newValue
                        return
                    }

                    let oldValue = isOn
                    isOn = newValue
                    isApplying = true
                    Task { @MainActor in
                        do {
                            try await onChange(newValue)
                        } catch {
                            isOn = oldValue
                        }
                        isApplying = false
                    }
                }
            ))
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
                .disabled(isApplying)
        }
    }
}
