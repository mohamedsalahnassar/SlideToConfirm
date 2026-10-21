import SwiftUI
import UIKit

/// The demo app's design tokens. Light and dark values follow the system appearance.
enum DS {
    static let background = Color(light: 0xF5F6F9, dark: 0x07090F)
    static let surface = Color(light: 0xFFFFFF, dark: 0x121724)
    static let surfaceRaised = Color(light: 0xF2F4F8, dark: 0x0D111B)
    static let sunken = Color(light: 0xEBEEF4, dark: 0x0A0D15)
    static let ink = Color(light: 0x0E1220, dark: 0xF3F5FA)
    static let ink2 = Color(light: 0x555D74, dark: 0xA3AABF)
    static let ink3 = Color(light: 0x8A91A6, dark: 0x737B92)
    static let line = Color(light: 0xE3E7EF, dark: 0x222A3B)
    static let line2 = Color(light: 0xD5DAE5, dark: 0x2C3448)
    static let accent = Color(light: 0x2343D6, dark: 0x5B77FF)
    static let accentInk = Color(light: 0x1F3BC0, dark: 0xAEBBFF)
    static let accentSoft = Color(light: 0xE6EAFB, dark: 0x3D5CF5, darkOpacity: 0.20)
    static let success = Color(light: 0x1A7F45, dark: 0x2FA866)
    static let successSoft = Color(light: 0xE3F3EA, dark: 0x2FA866, darkOpacity: 0.16)
    static let danger = Color(light: 0xC62F3A, dark: 0xFF6B73)
    static let dangerSoft = Color(light: 0xFCE9EA, dark: 0xFF6B73, darkOpacity: 0.14)
    static let warning = Color(light: 0x5A4524, dark: 0xF1D3A1)
    static let warningSoft = Color(light: 0xFFF6E8, dark: 0xF1B450, darkOpacity: 0.10)
    static let codeBackground = Color(light: 0x0E1220, dark: 0x0A0D15)

    /// Fixed stage colors for previewing the control on known surfaces.
    static let stageLight = Color(hex: 0xF2F4F8)
    static let stageDark = Color(hex: 0x07090F)
    static let brand = Color(hex: 0x13246F)
    static let brandAccent = Color(hex: 0x2343D6)

    static let cornerRadius: CGFloat = 20
    static let gutter: CGFloat = 20
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(uiColor: UIColor(hex: hex, alpha: opacity))
    }

    init(light: UInt32, dark: UInt32, darkOpacity: CGFloat = 1) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: dark, alpha: darkOpacity) : UIColor(hex: light, alpha: 1)
        })
    }
}

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}

// MARK: - Typography

extension Font {
    static let dsDisplay = Font.system(size: 34, weight: .bold, design: .default)
    static let dsTitle = Font.system(size: 26, weight: .bold)
    static let dsHeadline = Font.system(size: 17, weight: .semibold)
    static let dsBody = Font.system(size: 15)
    static let dsLead = Font.system(size: 17)
    static let dsCaption = Font.system(size: 13)
    static let dsEyebrow = Font.system(size: 12, weight: .semibold)
    static let dsMono = Font.system(size: 12.5, design: .monospaced)
}

// MARK: - Components

struct Eyebrow: View {
    let text: LocalizedStringKey
    var color: Color = DS.accentInk

    init(_ text: LocalizedStringKey, color: Color = DS.accentInk) {
        self.text = text
        self.color = color
    }

    var body: some View {
        Text(text)
            .font(.dsEyebrow)
            .tracking(1)
            .textCase(.uppercase)
            .foregroundStyle(color)
    }
}

struct SectionHeader: View {
    let eyebrow: LocalizedStringKey
    let title: LocalizedStringKey
    var lead: LocalizedStringKey?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow(eyebrow)
            Text(title)
                .font(.dsTitle)
                .tracking(-0.5)
                .foregroundStyle(DS.ink)
                .fixedSize(horizontal: false, vertical: true)
            if let lead {
                Text(lead)
                    .font(.dsBody)
                    .foregroundStyle(DS.ink2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CardModifier: ViewModifier {
    var padding: CGFloat = 20
    var background: Color = DS.surface

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(background, in: RoundedRectangle(cornerRadius: DS.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.cornerRadius, style: .continuous)
                    .strokeBorder(DS.line, lineWidth: 1)
            )
    }
}

extension View {
    func card(padding: CGFloat = 20, background: Color = DS.surface) -> some View {
        modifier(CardModifier(padding: padding, background: background))
    }
}

struct Chip: View {
    let title: LocalizedStringKey
    let detail: LocalizedStringKey

    var body: some View {
        HStack(spacing: 6) {
            Text(title).fontWeight(.semibold).foregroundStyle(DS.ink)
            Text(detail).foregroundStyle(DS.ink2)
        }
        .font(.dsCaption)
        .padding(.horizontal, 12)
        .frame(height: 32)
        .background(DS.surfaceRaised, in: Capsule())
        .overlay(Capsule().strokeBorder(DS.line, lineWidth: 1))
    }
}

struct Badge: View {
    enum Style { case accent, soft, success, danger }
    let text: LocalizedStringKey
    var style: Style = .accent

    var body: some View {
        Text(text)
            .font(.system(size: 11.5, weight: .bold))
            .tracking(0.2)
            .padding(.horizontal, 8)
            .frame(height: 22)
            .foregroundStyle(foreground)
            .background(background, in: Capsule())
    }

    private var foreground: Color {
        switch style {
        case .accent: return .white
        case .soft: return DS.ink2
        case .success: return DS.success
        case .danger: return DS.danger
        }
    }

    private var background: Color {
        switch style {
        case .accent: return DS.accent
        case .soft: return DS.sunken
        case .success: return DS.successSoft
        case .danger: return DS.dangerSoft
        }
    }
}

struct IconTile: View {
    let symbol: String
    let colors: [Color]
    var size: CGFloat = 44

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
            .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: symbol)
                    .font(.system(size: size * 0.42, weight: .semibold))
                    .foregroundStyle(.white)
            )
            .shadow(color: (colors.last ?? .black).opacity(0.25), radius: 6, y: 3)
    }
}

/// A bullet list row with a bold lead-in.
struct Bullet: View {
    let title: LocalizedStringKey
    let detail: LocalizedStringKey

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Circle().fill(DS.line2).frame(width: 6, height: 6).alignmentGuide(.firstTextBaseline) { $0[.bottom] }
            (Text(title).fontWeight(.semibold).foregroundStyle(DS.ink) + Text(" ") + Text(detail).foregroundStyle(DS.ink2))
                .font(.system(size: 14))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// Lays children out in rows, wrapping when a row is full.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var alignment: HorizontalAlignment = .leading

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(width: proposal.width ?? .infinity, subviews: subviews)
        let width = rows.map(\.width).max() ?? 0
        let height = rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(0, rows.count - 1))
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(width: bounds.width, subviews: subviews) {
            var x: CGFloat
            switch alignment {
            case .center: x = bounds.minX + (bounds.width - row.width) / 2
            case .trailing: x = bounds.maxX - row.width
            default: x = bounds.minX
            }
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y + (row.height - size.height) / 2), proposal: .unspecified)
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = [Row()]
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let needed = rows[rows.count - 1].indices.isEmpty ? size.width : rows[rows.count - 1].width + spacing + size.width
            if needed > width, !rows[rows.count - 1].indices.isEmpty {
                rows.append(Row())
            }
            var row = rows[rows.count - 1]
            row.width = row.indices.isEmpty ? size.width : row.width + spacing + size.width
            row.height = max(row.height, size.height)
            row.indices.append(index)
            rows[rows.count - 1] = row
        }
        return rows
    }
}

/// A rounded, colored backdrop to preview a control on a light, dark or brand surface.
enum StageSurface: String, CaseIterable, Identifiable {
    case light, dark, brand

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .brand: return "Brand"
        }
    }

    var color: Color {
        switch self {
        case .light: return DS.stageLight
        case .dark: return DS.stageDark
        case .brand: return DS.brand
        }
    }

    var colorScheme: ColorScheme { self == .light ? .light : .dark }

    var theme: SlideToConfirmThemeChoice { self == .brand ? .brand : .standard }

    var secondaryText: Color {
        self == .light ? Color(hex: 0x555D74) : .white.opacity(0.68)
    }
}

/// Built-in themes the demo lets you pick.
enum SlideToConfirmThemeChoice: String, CaseIterable, Identifiable {
    case standard, brand, destructive, positive, monochrome, custom

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .standard: return "Standard"
        case .brand: return "Brand"
        case .destructive: return "Destructive"
        case .positive: return "Positive"
        case .monochrome: return "Mono"
        case .custom: return "Custom"
        }
    }
}
