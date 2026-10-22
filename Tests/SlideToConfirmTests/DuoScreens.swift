#if canImport(SwiftUI) && (os(iOS) || os(macOS))
import SwiftUI
import XCTest
@testable import SlideToConfirm

// iPhone Duo screens for the README, drawn at the display sizes estimated in the design:
// the outer display closed (466 × 678 pt), the inner display open in landscape (890 × 626 pt) and
// in portrait (626 × 890 pt). The controls are the real SlideToConfirm and HoldToConfirmButton,
// frozen in preview states.

// MARK: - Model

/// How the phone is held, and the display that shows.
enum DuoPosture {
    /// Closed: the outer display, with the vertical bar on the trailing hardware edge.
    case closed
    /// Open: the inner display in landscape; the bar stays on the trailing edge.
    case open
    /// Open and turned: the inner display in portrait; the bars go horizontal.
    case portrait

    var size: CGSize {
        switch self {
        case .closed: return CGSize(width: 466, height: 678)
        case .open: return CGSize(width: 890, height: 626)
        case .portrait: return CGSize(width: 626, height: 890)
        }
    }

    var cornerRadius: CGFloat { self == .closed ? 40 : 32 }

    /// Where the 72 pt vertical bar starts.
    var barX: CGFloat { self == .closed ? 394 : 818 }
    var statusY: CGFloat { self == .closed ? 44 : 20 }
    var topY: CGFloat { self == .closed ? 92 : 72 }
    /// Where the bar's tab zone starts. It ends 20 pt above the bottom edge.
    var zoneTop: CGFloat { self == .closed ? 300 : 250 }
}

/// Where the control sits and what it is.
enum DuoPlacement {
    enum Tabs { case hidden, minimized }
    enum RingSpot { case tabZone, aboveTabs, thumbHeight }

    /// The pill: a pull-down track in the bar's tab zone, or a horizontal track in portrait.
    case track(Tabs)
    /// The 48 pt hold ring in an ordinary bar item.
    case ring(RingSpot)
}

enum DuoLanguage {
    case english, arabic

    var direction: LayoutDirection { self == .arabic ? .rightToLeft : .leftToRight }
}

/// Design tokens for the device screens, in light and dark.
struct DuoTokens {
    let scheme: ColorScheme
    private var dark: Bool { scheme == .dark }

    var page: Color { dark ? Color(stcHex: 0x0B0E16) : Color(stcHex: 0xF7F8FB) }
    var background: Color { dark ? Color(stcHex: 0x07090F) : Color(stcHex: 0xF2F4F8) }
    var surface: Color { dark ? Color(stcHex: 0x131826) : .white }
    var line: Color { dark ? Color(stcHex: 0x232A3B) : Color(stcHex: 0xE8EBF1) }
    var cardEdge: Color { dark ? .white.opacity(0.06) : .clear }
    var hinge: Color { dark ? .white.opacity(0.06) : Color(stcHex: 0x0E1220).opacity(0.06) }
    var cameraRing: Color { dark ? Color(stcHex: 0x1F2433) : Color(stcHex: 0xD5D9E3) }
    var ink: Color { dark ? Color(stcHex: 0xF3F5FA) : Color(stcHex: 0x0E1220) }
    var ink2: Color { dark ? Color(stcHex: 0xA3AABF) : Color(stcHex: 0x555D74) }
    var ink3: Color { dark ? Color(stcHex: 0x737B92) : Color(stcHex: 0x8A91A6) }
    var accent: Color { dark ? Color(stcHex: 0x5B77FF) : Color(stcHex: 0x2343D6) }
    var accentInk: Color { dark ? Color(stcHex: 0xAEBBFF) : Color(stcHex: 0x1F3BC0) }
    var accentSoft: Color { dark ? Color(stcHex: 0x3D5CF5).opacity(0.2) : Color(stcHex: 0xE6EAFB) }
    var glass: Color { dark ? Color(stcHex: 0x1E2434).opacity(0.92) : .white.opacity(0.92) }
    var glassEdge: Color { dark ? .white.opacity(0.08) : Color(stcHex: 0x0E1220).opacity(0.06) }
    var frame: Color { dark ? .black : Color(stcHex: 0x0B0D12) }
    var frameEdge: Color { dark ? Color(stcHex: 0x2A3142) : Color(stcHex: 0x2A2F3A) }
    var shadow: Color { dark ? .black.opacity(0.5) : Color(stcHex: 0x0E1220).opacity(0.18) }
    var spec: Color { dark ? Color(stcHex: 0xAEBBFF) : Color(stcHex: 0x2343D6) }
}

/// The copy on the review screen, from the design.
struct DuoCopy {
    let reviewTitle, reviewTitleLong, toLine, sending, details, payee, payeeDetail: String
    let trackHint, ringHint: String
    let shortRows: [(String, String)]
    let longRows: [(String, String)]
    let track: SlideToConfirmLabels
    let ring: SlideToConfirmLabels

    init(_ language: DuoLanguage) {
        let isolate = { (value: String) in "\u{2066}\(value)\u{2069}" }
        switch language {
        case .english:
            reviewTitle = "Review"; reviewTitleLong = "Review transfer"; toLine = "To Sara Ahmed · ··8890"
            sending = "You are sending"; details = "Details"; payee = "Sara Ahmed"; payeeDetail = "Saved payee · ··8890"
            trackHint = "Slide or hold on the right to send"; ringHint = "Hold the ring on the right to send"
            shortRows = [("From", "Current ··4521"), ("Reference", "October rent"), ("Fee", "AED 0.00"), ("Arrives", "Today")]
            longRows = [("From", "Current account ··4521"), ("Reference", "October rent"), ("Fee", "AED 0.00"), ("Arrives", "Today, within minutes")]
            track = SlideToConfirmLabels(
                idle: Text(verbatim: "Slide or hold to send"), armed: Text(verbatim: "Release to send"),
                holding: Text(verbatim: "Keep holding…"), processing: Text(verbatim: "Sending…"),
                success: Text(verbatim: "Sent"), failure: Text(verbatim: "Not sent · try again")
            )
            ring = SlideToConfirmLabels(
                idle: Text(verbatim: "Hold to send"), holding: Text(verbatim: "Keep holding…"),
                processing: Text(verbatim: "Sending…"), success: Text(verbatim: "Sent")
            )
        case .arabic:
            reviewTitle = "مراجعة"; reviewTitleLong = "مراجعة التحويل"; toLine = "إلى سارة أحمد · " + isolate("··8890")
            sending = "أنت ترسل"; details = "التفاصيل"; payee = "سارة أحمد"; payeeDetail = "مستفيد محفوظ · " + isolate("··8890")
            trackHint = "اسحب أو اضغط مطولاً يميناً للإرسال"; ringHint = "اضغط مطولاً على الدائرة يميناً للإرسال"
            shortRows = [("من", "الجاري " + isolate("··4521")), ("المرجع", "إيجار أكتوبر"), ("الرسوم", isolate("AED 0.00")), ("الوصول", "اليوم")]
            longRows = [("من", "الحساب الجاري " + isolate("··4521")), ("المرجع", "إيجار أكتوبر"), ("الرسوم", isolate("AED 0.00")), ("الوصول", "اليوم، خلال دقائق")]
            track = SlideToConfirmLabels(
                idle: Text(verbatim: "اسحب أو اضغط للإرسال"), armed: Text(verbatim: "اترك للإرسال"),
                holding: Text(verbatim: "استمر بالضغط…"), processing: Text(verbatim: "جارٍ الإرسال…"),
                success: Text(verbatim: "تم الإرسال"), failure: Text(verbatim: "لم يُرسل · حاول مجدداً")
            )
            ring = SlideToConfirmLabels(
                idle: Text(verbatim: "اضغط مطولاً للإرسال"), holding: Text(verbatim: "استمر بالضغط…"),
                processing: Text(verbatim: "جارٍ الإرسال…"), success: Text(verbatim: "تم الإرسال")
            )
        }
    }
}

private extension View {
    /// Places the view with its top-left corner at `x`, `y` in a top-leading ZStack.
    func at(x: CGFloat, y: CGFloat, width: CGFloat? = nil, height: CGFloat? = nil, alignment: Alignment = .topLeading) -> some View {
        frame(width: width, height: height, alignment: alignment).offset(x: x, y: y)
    }
}

// MARK: - Screen

/// One iPhone Duo display, in its frame, showing the review screen with the control placed.
struct DuoScreen: View {
    let posture: DuoPosture
    let placement: DuoPlacement
    let scheme: ColorScheme
    var language: DuoLanguage = .english
    var trackState: SlideToConfirmPreviewState = .holding(progress: 0.55)
    var ringState: HoldToConfirmPreviewState = .holding(progress: 0.62)
    /// Tints the screen with the right thumb's reach.
    var showsReach = false

    private var tokens: DuoTokens { DuoTokens(scheme: scheme) }
    private var copy: DuoCopy { DuoCopy(language) }
    private var size: CGSize { posture.size }

    /// The outer size of the device, frame included.
    static func outerSize(_ posture: DuoPosture) -> CGSize {
        CGSize(width: posture.size.width + 20, height: posture.size.height + 20)
    }

    var body: some View {
        let t = tokens
        ZStack(alignment: .topLeading) {
            t.background
            hinge
            switch posture {
            case .closed:
                closedContent
                bar
            case .open:
                openContent
                bar
            case .portrait:
                portraitContent
                portraitStatus
                portraitZone
            }
            if showsReach {
                ThumbReachOverlay(hand: .right, opacity: scheme == .dark ? 0.12 : 0.16)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .clipShape(RoundedRectangle(cornerRadius: posture.cornerRadius, style: .continuous))
        .padding(10)
        .background(t.frame, in: RoundedRectangle(cornerRadius: posture.cornerRadius + 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: posture.cornerRadius + 10, style: .continuous)
                .strokeBorder(t.frameEdge, lineWidth: 1)
        )
        .shadow(color: t.shadow, radius: 22, y: 10)
        // The device is physical: lay it out left to right, and mirror only the content.
        .environment(\.layoutDirection, .leftToRight)
        .environment(\.colorScheme, scheme)
    }

    // MARK: Chrome

    @ViewBuilder
    private var hinge: some View {
        switch posture {
        case .closed:
            EmptyView()
        case .open:
            Rectangle().fill(tokens.hinge).at(x: size.width / 2 - 1, y: 0, width: 2, height: size.height)
        case .portrait:
            Rectangle().fill(tokens.hinge).at(x: 0, y: size.height / 2 - 1, width: size.width, height: 2)
        }
    }

    private var battery: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 3.5).strokeBorder(tokens.ink3, lineWidth: 1.2).frame(width: 22, height: 11)
            RoundedRectangle(cornerRadius: 1.5).fill(tokens.ink).frame(width: 13, height: 7).padding(.leading, 2)
        }
        .overlay(alignment: .trailing) {
            RoundedRectangle(cornerRadius: 1).fill(tokens.ink3).frame(width: 1.5, height: 4).offset(x: 3)
        }
    }

    private var time: some View {
        Text(verbatim: "9:41").font(.system(size: 13, weight: .semibold)).foregroundStyle(tokens.ink)
    }

    private func glassButton(_ symbol: String, size: CGFloat = 48) -> some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.38, weight: .semibold))
            .foregroundStyle(tokens.ink)
            .frame(width: size, height: size)
            .background(tokens.glass, in: Circle())
            .overlay(Circle().strokeBorder(tokens.glassEdge))
    }

    private var backSymbol: String { language == .arabic ? "chevron.right" : "chevron.left" }

    // MARK: Vertical bar

    private var bar: some View {
        let zoneHeight = size.height - posture.zoneTop - 20
        return ZStack(alignment: .topLeading) {
            if posture == .closed {
                Circle()
                    .fill(Color.black)
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(tokens.cameraRing, lineWidth: 2))
                    .at(x: 30, y: 20)
            }
            VStack(spacing: 4) {
                time
                battery
            }
            .at(x: 0, y: posture.statusY, width: 72, alignment: .top)
            glassButton(backSymbol).at(x: 0, y: posture.topY, width: 72, alignment: .top)
            barZone(height: zoneHeight).at(x: 8, y: posture.zoneTop, width: 56, height: zoneHeight, alignment: .bottom)
        }
        .frame(width: 72, height: size.height, alignment: .topLeading)
        .at(x: posture.barX, y: 0)
    }

    @ViewBuilder
    private func barZone(height zoneHeight: CGFloat) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            switch placement {
            case let .track(tabs):
                let length = tabs == .minimized ? min(300, zoneHeight - 68) : 300
                SlideToConfirm(labels: copy.track) {}
                    .slideToConfirmConfiguration(.verticalBar)
                    .slideToConfirmPreviewState(trackState)
                    .frame(width: 56, height: length)
                    .environment(\.layoutDirection, language.direction)
                if tabs == .minimized {
                    verticalTabs(minimized: true).padding(.top, 12)
                }
            case let .ring(spot):
                ringItem
                switch spot {
                case .tabZone:
                    EmptyView()
                case .aboveTabs:
                    verticalTabs(minimized: true).padding(.top, 12)
                case .thumbHeight:
                    verticalTabs(minimized: false).padding(.top, 16)
                }
            }
        }
    }

    private var ringItem: some View {
        HoldToConfirmButton(labels: copy.ring, systemImage: "paperplane.fill") {}
            .holdToConfirmConfiguration(.verticalBar)
            .holdToConfirmPreviewState(ringState)
            .padding(4)
            .background(tokens.glass, in: Circle())
            .overlay(Circle().strokeBorder(tokens.glassEdge))
    }

    private static let tabSymbols = ["house", "wallet.pass", "arrow.left.arrow.right", "creditcard", "square.grid.2x2"]

    private func verticalTabs(minimized: Bool) -> some View {
        VStack(spacing: 4) {
            ForEach(minimized ? [2] : Array(0..<5), id: \.self) { index in
                Image(systemName: Self.tabSymbols[index])
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(index == 2 ? Color.white : tokens.ink)
                    .frame(width: 44, height: 44)
                    .background(index == 2 ? tokens.accent : .clear, in: Circle())
            }
        }
        .padding(.vertical, 6)
        .frame(width: 56)
        .background(tokens.glass, in: Capsule())
        .overlay(Capsule().strokeBorder(tokens.glassEdge))
    }

    // MARK: Shared content

    private var isRing: Bool {
        if case .ring = placement { return true }
        return false
    }

    private func amount(size fontSize: CGFloat) -> some View {
        Text(verbatim: "AED 2,500.00")
            .font(.system(size: fontSize, weight: .bold))
            .monospacedDigit()
            .tracking(-0.5)
            .foregroundStyle(tokens.ink)
            .lineLimit(1)
            .environment(\.layoutDirection, .leftToRight)
    }

    private func rows(_ rows: [(String, String)]) -> some View {
        VStack(spacing: 0) {
            ForEach(rows.indices, id: \.self) { index in
                HStack(spacing: 12) {
                    Text(verbatim: rows[index].0).foregroundStyle(tokens.ink2).lineLimit(1)
                    Spacer(minLength: 12)
                    Text(verbatim: rows[index].1).fontWeight(.semibold).foregroundStyle(tokens.ink).lineLimit(1)
                }
                .font(.system(size: 15))
                .frame(height: 48)
                .overlay(alignment: .bottom) {
                    if index < rows.count - 1 {
                        Rectangle().fill(tokens.line).frame(height: 1)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .background(tokens.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(tokens.cardEdge))
    }

    private func avatar(_ diameter: CGFloat) -> some View {
        Text(verbatim: "SA")
            .font(.system(size: diameter * 0.36, weight: .semibold))
            .foregroundStyle(tokens.accentInk)
            .frame(width: diameter, height: diameter)
            .background(tokens.accentSoft, in: Circle())
    }

    private var payeeCard: some View {
        HStack(spacing: 12) {
            avatar(40)
            VStack(alignment: .leading, spacing: 0) {
                Text(verbatim: copy.payee).font(.system(size: 15, weight: .semibold)).foregroundStyle(tokens.ink)
                Text(verbatim: copy.payeeDetail).font(.system(size: 13)).foregroundStyle(tokens.ink2)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(tokens.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(tokens.cardEdge))
    }

    /// Points at the bar, which is on the right in every language.
    private var hint: some View {
        HStack(spacing: 10) {
            Text(verbatim: isRing ? copy.ringHint : copy.trackHint)
                .font(.system(size: 15, weight: .semibold))
                .multilineTextAlignment(language == .arabic ? .trailing : .leading)
                .frame(maxWidth: .infinity, alignment: language == .arabic ? .trailing : .leading)
            Image(systemName: "arrow.right").font(.system(size: 17, weight: .bold))
        }
        .foregroundStyle(tokens.accentInk)
        .padding(.leading, 20)
        .padding(.trailing, 16)
        .frame(height: 52)
        .background(tokens.accentSoft, in: Capsule())
        .environment(\.layoutDirection, .leftToRight)
    }

    // MARK: Closed

    private var closedContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(verbatim: copy.reviewTitle).font(.system(size: 28, weight: .bold)).foregroundStyle(tokens.ink)
            Text(verbatim: copy.toLine).font(.system(size: 15)).foregroundStyle(tokens.ink2).padding(.top, 16)
            amount(size: 34).padding(.top, 2)
            rows(copy.shortRows).padding(.top, 16)
            Spacer(minLength: 0)
            hint
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .environment(\.layoutDirection, language.direction)
        // Physical insets: 20 pt from the screen edge, 8 pt from the bar.
        .at(x: 20, y: 20, width: posture.barX - 28, height: size.height - 40)
    }

    // MARK: Open, landscape

    private var openContent: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 0) {
                Text(verbatim: copy.reviewTitleLong).font(.system(size: 28, weight: .bold)).foregroundStyle(tokens.ink)
                payeeCard.padding(.top, 16)
                Text(verbatim: copy.sending).font(.system(size: 15)).foregroundStyle(tokens.ink2).padding(.top, 24)
                amount(size: 40).padding(.top, 2)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .environment(\.layoutDirection, language.direction)
            .at(x: 24, y: 24, width: 445 - 48, height: size.height - 44)

            VStack(alignment: .leading, spacing: 12) {
                Text(verbatim: copy.details.uppercased())
                    .font(.system(size: 13, weight: .semibold))
                    .tracking(0.5)
                    .foregroundStyle(tokens.ink2)
                    .frame(height: 34, alignment: .bottomLeading)
                rows(copy.longRows)
                Spacer(minLength: 0)
                hint
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .environment(\.layoutDirection, language.direction)
            .at(x: 445 + 24, y: 24, width: posture.barX - 445 - 32, height: size.height - 44)
        }
    }

    // MARK: Open, portrait

    private var portraitStatus: some View {
        HStack {
            time
            Spacer()
            battery
        }
        .at(x: 28, y: 14, width: size.width - 56, height: 16)
    }

    private var portraitContent: some View {
        VStack(spacing: 0) {
            ZStack {
                Text(verbatim: copy.reviewTitle).font(.system(size: 17, weight: .semibold)).foregroundStyle(tokens.ink)
                HStack {
                    glassButton(backSymbol, size: 44)
                    Spacer()
                }
            }
            .frame(height: 44)
            VStack(spacing: 0) {
                avatar(56)
                Text(verbatim: copy.payee).font(.system(size: 17, weight: .semibold)).foregroundStyle(tokens.ink).padding(.top, 12)
                Text(verbatim: copy.payeeDetail).font(.system(size: 13)).foregroundStyle(tokens.ink2).padding(.top, 2)
                amount(size: 40).padding(.top, 20)
            }
            .padding(.top, 16)
            rows(copy.longRows).padding(.top, 16)
            Spacer(minLength: 0)
        }
        .environment(\.layoutDirection, language.direction)
        .at(x: (size.width - 560) / 2, y: 44, width: 560, height: 740)
    }

    /// The horizontal bar at the bottom: the tabs, minimized, beside the control.
    private var portraitZone: some View {
        HStack(spacing: 12) {
            switch placement {
            case let .track(tabs):
                if tabs == .minimized { horizontalTab }
                SlideToConfirm(labels: copy.track) {}
                    .slideToConfirmPreviewState(trackState)
                    .frame(width: 440)
            case let .ring(spot):
                if spot != .tabZone { horizontalTab }
                HoldToConfirmButton(labels: copy.ring, systemImage: "paperplane.fill") {}
                    .holdToConfirmConfiguration(.verticalBar.with {
                        $0.labelPosition = .trailing
                        $0.labelSpacing = 10
                    })
                    .holdToConfirmPreviewState(ringState)
                    .padding(.leading, 8)
                    .padding(.trailing, 20)
                    .frame(height: 64)
                    .background(tokens.glass, in: Capsule())
                    .overlay(Capsule().strokeBorder(tokens.glassEdge))
            }
        }
        .frame(maxWidth: .infinity)
        // Horizontal bars follow the reading direction, and so does the track.
        .environment(\.layoutDirection, language.direction)
        .at(x: 24, y: 806, width: size.width - 48, height: 64)
    }

    private var horizontalTab: some View {
        Image(systemName: Self.tabSymbols[2])
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(tokens.accentInk)
            .frame(width: 52, height: 52)
            .background(tokens.accentSoft, in: Circle())
            .frame(width: 64, height: 64)
            .background(tokens.glass, in: Capsule())
            .overlay(Capsule().strokeBorder(tokens.glassEdge))
    }
}

// MARK: - Boards

/// A device with a caption under it.
struct DuoShot: Identifiable {
    let id = UUID()
    let screen: DuoScreen
    let title: String
    let detail: String
}

/// A row of devices on a page, top-aligned, each with its caption.
struct DuoBoard: View {
    let scheme: ColorScheme
    let shots: [DuoShot]

    var body: some View {
        let t = DuoTokens(scheme: scheme)
        HStack(alignment: .top, spacing: 36) {
            ForEach(shots) { shot in
                VStack(alignment: .leading, spacing: 16) {
                    shot.screen
                    VStack(alignment: .leading, spacing: 3) {
                        Text(verbatim: shot.title).font(.system(size: 17, weight: .semibold)).foregroundStyle(t.ink)
                        Text(verbatim: shot.detail).font(.system(size: 14)).foregroundStyle(t.ink2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 4)
                    .frame(width: DuoScreen.outerSize(shot.screen.posture).width, alignment: .leading)
                }
            }
        }
        .padding(40)
        .background(t.page)
        .environment(\.colorScheme, scheme)
    }
}

enum DuoBoards {
    static func overview(_ scheme: ColorScheme) -> DuoBoard {
        DuoBoard(scheme: scheme, shots: [
            DuoShot(
                screen: DuoScreen(posture: .closed, placement: .track(.hidden), scheme: scheme),
                title: "Closed · outer display",
                detail: "466 × 678 pt. The pill takes the tab zone of the trailing bar as a 300 pt pull-down track."
            ),
            DuoShot(
                screen: DuoScreen(posture: .open, placement: .ring(.aboveTabs), scheme: scheme),
                title: "Open · inner display, landscape",
                detail: "890 × 626 pt. The bar stays on the trailing edge; the 48 pt ring sits above the current tab, next to the details pane."
            ),
            DuoShot(
                screen: DuoScreen(posture: .portrait, placement: .track(.minimized), scheme: scheme),
                title: "Open · inner display, portrait",
                detail: "626 × 890 pt. The bars go horizontal: the pill runs where the tab bar was, capped at 440 pt."
            ),
        ])
    }

    static func closedTrack(_ scheme: ColorScheme) -> DuoBoard {
        DuoBoard(scheme: scheme, shots: [
            DuoShot(
                screen: DuoScreen(posture: .closed, placement: .track(.hidden), scheme: scheme),
                title: "Pill · tabs hidden",
                detail: "A 56 × 300 pt pull-down track in the tab zone, bottom-aligned 20 pt above the edge."
            ),
            DuoShot(
                screen: DuoScreen(posture: .closed, placement: .track(.minimized), scheme: scheme, trackState: .idle),
                title: "Pill · tabs minimized",
                detail: "The track shortens to 290 pt so the current tab stays one tap away below it."
            ),
            DuoShot(
                screen: DuoScreen(posture: .closed, placement: .track(.hidden), scheme: scheme, trackState: .processing),
                title: "Pill · processing",
                detail: "Hold or pull to the end: the track locks and fills while the action runs."
            ),
        ])
    }

    static func closedRing(_ scheme: ColorScheme) -> DuoBoard {
        DuoBoard(scheme: scheme, shots: [
            DuoShot(
                screen: DuoScreen(posture: .closed, placement: .ring(.tabZone), scheme: scheme),
                title: "Ring · in the tab zone",
                detail: "Tabs hidden on Review; the 48 pt ring takes their place, right under the thumb."
            ),
            DuoShot(
                screen: DuoScreen(posture: .closed, placement: .ring(.aboveTabs), scheme: scheme, ringState: .idle),
                title: "Ring · above minimized tabs",
                detail: "The tabs shrink to the current one; the ring sits right above it."
            ),
            DuoShot(
                screen: DuoScreen(posture: .closed, placement: .ring(.thumbHeight), scheme: scheme, ringState: .success),
                title: "Ring · at thumb height",
                detail: "The tabs stay as they are; the ring sits just above them, where the thumb wraps the edge."
            ),
        ])
    }

    static func open(_ scheme: ColorScheme) -> DuoBoard {
        DuoBoard(scheme: scheme, shots: [
            DuoShot(
                screen: DuoScreen(posture: .open, placement: .track(.hidden), scheme: scheme),
                title: "Pill · trailing bar",
                detail: "Open, the bar stays on the trailing edge and the pull-down track stays in its tab zone. The action hint sits in the pane next to it."
            ),
            DuoShot(
                screen: DuoScreen(posture: .open, placement: .ring(.aboveTabs), scheme: scheme, ringState: .processing),
                title: "Ring · trailing bar",
                detail: "The ring needs no extra height, so it fits however tall the open bar's zone is."
            ),
        ])
    }

    static func portrait(_ scheme: ColorScheme) -> DuoBoard {
        DuoBoard(scheme: scheme, shots: [
            DuoShot(
                screen: DuoScreen(posture: .portrait, placement: .track(.minimized), scheme: scheme),
                title: "Pill · bottom bar",
                detail: "Turned to portrait, the bars go horizontal. The pill slides toward the trailing edge, 440 pt wide, beside the current tab."
            ),
            DuoShot(
                screen: DuoScreen(posture: .portrait, placement: .ring(.aboveTabs), scheme: scheme, ringState: .idle),
                title: "Ring · bottom bar",
                detail: "The ring and its label share one bar item beside the current tab."
            ),
        ])
    }

    static func arabic(_ scheme: ColorScheme) -> DuoBoard {
        DuoBoard(scheme: scheme, shots: [
            DuoShot(
                screen: DuoScreen(posture: .closed, placement: .track(.hidden), scheme: scheme, language: .arabic),
                title: "Pill · Arabic, closed",
                detail: "Content mirrors; the bar stays on the right hardware edge and down is still down."
            ),
            DuoShot(
                screen: DuoScreen(posture: .closed, placement: .ring(.aboveTabs), scheme: scheme, language: .arabic),
                title: "Ring · Arabic, closed",
                detail: "The ring stays in the right-hand bar and fills clockwise, like a clock."
            ),
            DuoShot(
                screen: DuoScreen(posture: .portrait, placement: .track(.minimized), scheme: scheme, language: .arabic),
                title: "Pill · Arabic, portrait",
                detail: "Horizontal bars follow the reading direction: the knob starts on the right and slides left."
            ),
        ])
    }
}

// MARK: - Spec

/// The outer display with measurements and the right thumb's reach.
struct DuoSpecBoard: View {
    let scheme: ColorScheme

    var body: some View {
        let t = DuoTokens(scheme: scheme)
        HStack(alignment: .top, spacing: 36) {
            device(
                DuoScreen(posture: .closed, placement: .track(.hidden), scheme: scheme, trackState: .idle, showsReach: true),
                marks: trackMarks,
                title: "Pull-down track",
                detail: "Same footprint as the tabs: 56 pt wide, 300 pt long, ending on the same 20 pt bottom inset as the content."
            )
            device(
                DuoScreen(posture: .closed, placement: .ring(.aboveTabs), scheme: scheme, ringState: .idle, showsReach: true),
                marks: ringMarks,
                title: "Hold ring",
                detail: "A 48 pt ring in an ordinary 56 pt item: no extra height to ask the bar for. Green is the right thumb's natural reach; yellow by the corner, where it curls."
            )
        }
        .padding(40)
        .background(t.page)
        .environment(\.colorScheme, scheme)
    }

    private struct Mark {
        enum Axis { case horizontal, vertical }
        let axis: Axis
        /// Screen coordinates of the start and end of the measured span, and where the line runs.
        let from: CGFloat
        let to: CGFloat
        let at: CGFloat
        let label: String
    }

    // Screen coordinates on the 466 × 678 outer display.
    private var trackMarks: [Mark] {
        [
            Mark(axis: .horizontal, from: 394, to: 466, at: 180, label: "72 pt bar"),
            Mark(axis: .horizontal, from: 402, to: 458, at: 336, label: "56 pt"),
            Mark(axis: .vertical, from: 358, to: 658, at: 492, label: "300 pt track"),
            Mark(axis: .vertical, from: 658, to: 678, at: 492, label: "20 pt"),
            Mark(axis: .vertical, from: 0, to: 300, at: 492, label: "Tab zone starts 300 pt down"),
        ]
    }

    private var ringMarks: [Mark] {
        [
            Mark(axis: .horizontal, from: 394, to: 466, at: 180, label: "72 pt bar"),
            Mark(axis: .horizontal, from: 406, to: 454, at: 520, label: "48 pt"),
            Mark(axis: .vertical, from: 534, to: 590, at: 492, label: "Ring item · 56 pt"),
            Mark(axis: .vertical, from: 602, to: 658, at: 492, label: "Current tab"),
            Mark(axis: .vertical, from: 658, to: 678, at: 492, label: "20 pt"),
        ]
    }

    private func device(_ screen: DuoScreen, marks: [Mark], title: String, detail: String) -> some View {
        let t = DuoTokens(scheme: scheme)
        let outer = DuoScreen.outerSize(.closed)
        return VStack(alignment: .leading, spacing: 16) {
            ZStack(alignment: .topLeading) {
                screen
                ForEach(marks.indices, id: \.self) { index in
                    mark(marks[index], color: t.spec, page: t.page)
                }
                // Screen coordinates start inside the 10 pt frame.
                .offset(x: 10, y: 10)
            }
            .frame(width: outer.width + 230, height: outer.height, alignment: .topLeading)
            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: title).font(.system(size: 17, weight: .semibold)).foregroundStyle(t.ink)
                Text(verbatim: detail).font(.system(size: 14)).foregroundStyle(t.ink2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 4)
            .frame(width: outer.width + 200, alignment: .leading)
        }
    }

    @ViewBuilder
    private func mark(_ mark: Mark, color: Color, page: Color) -> some View {
        let length = mark.to - mark.from
        switch mark.axis {
        case .horizontal:
            ZStack {
                Rectangle().fill(color).frame(width: length, height: 1.5)
                HStack {
                    Rectangle().fill(color).frame(width: 1.5, height: 10)
                    Spacer(minLength: 0)
                    Rectangle().fill(color).frame(width: 1.5, height: 10)
                }
                .frame(width: length)
            }
            .frame(width: length, height: 10)
            .overlay(alignment: .top) {
                Text(verbatim: mark.label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(color)
                    .fixedSize()
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(page.opacity(0.9), in: Capsule())
                    .offset(y: -22)
            }
            .at(x: mark.from, y: mark.at - 5)
        case .vertical:
            HStack(spacing: 8) {
                ZStack {
                    Rectangle().fill(color).frame(width: 1.5, height: length)
                    VStack {
                        Rectangle().fill(color).frame(width: 10, height: 1.5)
                        Spacer(minLength: 0)
                        Rectangle().fill(color).frame(width: 10, height: 1.5)
                    }
                    .frame(height: length)
                }
                .frame(width: 10, height: length)
                Text(verbatim: mark.label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(color)
                    .fixedSize()
            }
            .frame(height: length)
            .at(x: mark.at - 5, y: mark.from)
        }
    }
}

// MARK: - Tests

@MainActor
final class DuoScreenRenderingTests: XCTestCase {

    private func render<V: View>(_ view: V) throws -> CGImage {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        return try XCTUnwrap(renderer.cgImage)
    }

    func testEveryPostureAndPlacementRendersAtTheDeviceSize() throws {
        let placements: [DuoPlacement] = [
            .track(.hidden), .track(.minimized), .ring(.tabZone), .ring(.aboveTabs), .ring(.thumbHeight),
        ]
        for posture in [DuoPosture.closed, .open, .portrait] {
            for placement in placements {
                for language in [DuoLanguage.english, .arabic] {
                    let image = try render(DuoScreen(posture: posture, placement: placement, scheme: .light, language: language))
                    let outer = DuoScreen.outerSize(posture)
                    XCTAssertEqual(image.width, Int(outer.width * 2), "\(posture) \(placement)")
                    XCTAssertEqual(image.height, Int(outer.height * 2), "\(posture) \(placement)")
                }
            }
        }
    }

    func testRingSpotsAreInReachAndThumbHeightIsNatural() {
        // Centers of the ring on the closed display, from the bar layout: 20 pt bottom inset,
        // a 56 pt item, 12 pt above a 56 pt minimized tab or 16 pt above the 248 pt full tabs.
        let size = DuoPosture.closed.size
        let x = DuoPosture.closed.barX + 36
        let bottom = size.height - 20
        func zone(_ y: CGFloat) -> ThumbReach.Zone { ThumbReach.zone(at: CGPoint(x: x, y: y), in: size, hand: .right) }

        // Near the corner the thumb curls in: reachable, but a stretch for a long hold.
        XCTAssertEqual(zone(bottom - 28), .stretch, "in the tab zone")
        XCTAssertEqual(zone(bottom - 56 - 12 - 28), .stretch, "above minimized tabs")
        XCTAssertEqual(zone(bottom - 248 - 16 - 28), .natural, "at thumb height")
    }
}
#endif
