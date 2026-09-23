import SwiftUI

enum CrewTheme {
    static let bg = Color(hex: "#07080C") ?? .black
    static let bg2 = Color(hex: "#0E1118") ?? .black
    static let surface = Color.white.opacity(0.045)
    static let surfaceStrong = Color.white.opacity(0.07)
    static let stroke = Color.white.opacity(0.10)
    static let strokeStrong = Color.white.opacity(0.16)
    static let text = Color(hex: "#F3F5FA") ?? .white
    static let dim = Color(hex: "#9AA3B5") ?? .secondary
    static let faint = Color(hex: "#6B7384") ?? .secondary
    static let accent = Color(hex: "#7C83FF") ?? .indigo
    static let accent2 = Color(hex: "#45E0C6") ?? .mint
    static let danger = Color(hex: "#FF5C7A") ?? .red
    static let success = Color(hex: "#3DDC97") ?? .green

    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [accent, accent2],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct AtmosphereBackground: View {
    var body: some View {
        ZStack {
            CrewTheme.bg
            Circle()
                .fill(CrewTheme.accent.opacity(0.28))
                .frame(width: 520, height: 520)
                .blur(radius: 90)
                .offset(x: -220, y: -280)
            Circle()
                .fill(CrewTheme.accent2.opacity(0.18))
                .frame(width: 460, height: 460)
                .blur(radius: 100)
                .offset(x: 260, y: 220)
            Circle()
                .fill(Color.purple.opacity(0.16))
                .frame(width: 340, height: 340)
                .blur(radius: 80)
                .offset(x: 80, y: -40)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

struct CrewGlass: ViewModifier {
    var corner: CGFloat = 18

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial.opacity(0.72), in: RoundedRectangle(cornerRadius: corner, style: .continuous))
            .background(CrewTheme.surface, in: RoundedRectangle(cornerRadius: corner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.20), Color.white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.35), radius: 24, y: 12)
    }
}

extension View {
    func crewGlass(corner: CGFloat = 18) -> some View {
        modifier(CrewGlass(corner: corner))
    }
}

struct CrewAvatar: View {
    let name: String
    let identity: String
    var size: CGFloat = 36
    var speaking = false
    var sharing = false

    var body: some View {
        ZStack {
            if speaking {
                Circle()
                    .stroke(CrewTheme.accent2.opacity(0.85), lineWidth: 2)
                    .frame(width: size + 10, height: size + 10)
            }
            Circle()
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.95), color.opacity(0.55)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .overlay {
                    Text(initials)
                        .font(.system(size: size * 0.34, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .shadow(color: color.opacity(0.35), radius: 8, y: 2)
            if sharing {
                Circle()
                    .fill(CrewTheme.accent)
                    .frame(width: 12, height: 12)
                    .overlay {
                        Image(systemName: "rectangle.fill")
                            .font(.system(size: 6, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .offset(x: size * 0.34, y: size * 0.34)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: speaking)
    }

    private var color: Color {
        Color(hex: CollabMath.color(for: identity)) ?? CrewTheme.accent
    }

    private var initials: String {
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap(\.first).map(String.init)
        return letters.joined().uppercased()
    }
}

struct LivePill: View {
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(CrewTheme.success)
                .frame(width: 7, height: 7)
                .shadow(color: CrewTheme.success.opacity(0.9), radius: 4)
            Text("Live")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CrewTheme.success)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(CrewTheme.success.opacity(0.12), in: Capsule())
    }
}

struct DockButton: View {
    var icon: String
    var title: String?
    var tint: Color = CrewTheme.text
    var emphasized = false
    var warning = false
    var disabled = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                if let title {
                    Text(title)
                        .font(.system(size: 12.5, weight: .semibold))
                }
            }
            .foregroundStyle(foreground)
            .frame(height: 36)
            .padding(.horizontal, title == nil ? 0 : 12)
            .frame(minWidth: title == nil ? 36 : nil)
            .background(background, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.35 : 1)
        .animation(.easeOut(duration: 0.15), value: emphasized)
    }

    private var foreground: Color {
        if warning { return CrewTheme.danger }
        if emphasized { return .white }
        return tint
    }

    private var background: some ShapeStyle {
        if warning { return AnyShapeStyle(CrewTheme.danger.opacity(0.16)) }
        if emphasized { return AnyShapeStyle(CrewTheme.accentGradient) }
        return AnyShapeStyle(Color.white.opacity(0.06))
    }
}

struct SectionLabel: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .tracking(0.8)
            .foregroundStyle(CrewTheme.faint)
    }
}

extension Color {
    init?(hex: String) {
        var value = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.hasPrefix("#") { value.removeFirst() }
        guard value.count == 6, let int = UInt32(value, radix: 16) else { return nil }
        self.init(
            red: Double((int >> 16) & 0xFF) / 255,
            green: Double((int >> 8) & 0xFF) / 255,
            blue: Double(int & 0xFF) / 255
        )
    }
}
