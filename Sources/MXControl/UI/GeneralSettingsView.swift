import SwiftUI

/// Compact app-level settings displayed inside the menu bar popover.
struct GeneralSettingsView: View {
    @Binding var launchAtLogin: Bool
    @Binding var hideAppUntilReopened: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
                GeneralSettingsSection(title: "启动") {
                    ToggleRow(
                        label: "登录时启动",
                        isOn: $launchAtLogin,
                        subtitle: "登录系统时自动启动 MXControl。"
                    )
                }

                GeneralSettingsSection(title: "显示") {
                    ToggleRow(
                        label: "隐藏 MXControl",
                        isOn: $hideAppUntilReopened,
                        subtitle: "隐藏菜单栏图标。可从“访达”或 Spotlight 重新打开 MXControl。"
                    )
                }
            }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
    }
}

private struct GeneralSettingsSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.tertiary)

            VStack(spacing: 0) {
                content
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
        }
    }
}
