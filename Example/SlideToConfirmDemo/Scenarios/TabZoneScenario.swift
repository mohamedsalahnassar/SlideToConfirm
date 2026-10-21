import SlideToConfirm
import SwiftUI

/// The control takes the tab bar's place as a pull-down track on a trailing vertical bar, as on
/// iPhone Duo's outer display. On a task screen the tabs step aside and the control grows out of
/// the space they leave. The bar stays on the trailing hardware edge in every language, so the
/// control never mirrors.
struct TabZoneScenario: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var step: Step = Step(rawValue: UserDefaults.standard.string(forKey: "step") ?? "") ?? .form
    @State private var tabsOnReview: TabsOnReview = TabsOnReview(rawValue: UserDefaults.standard.string(forKey: "tabs") ?? "") ?? .hidden
    @State private var showsAllTabs = false

    enum Step: String { case form, review, sent }

    enum TabsOnReview: String, CaseIterable, Identifiable {
        case hidden, minimized
        var id: String { rawValue }
    }

    private let barWidth: CGFloat = 72
    private let zoneWidth: CGFloat = 56

    var body: some View {
        let copy = DuoCopy(model.language)
        HStack(spacing: 0) {
            content(copy)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(EdgeInsets(top: 12, leading: 20, bottom: 20, trailing: 8))
                .demoLanguage(model.language)
            verticalBar(copy)
                .frame(width: barWidth)
        }
        .environment(\.layoutDirection, .leftToRight)
        .background(DS.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .animation(.spring(response: 0.5, dampingFraction: 0.82), value: step)
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: showsAllTabs)
    }

    // MARK: Content

    @ViewBuilder
    private func content(_ copy: DuoCopy) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            switch step {
            case .form:
                Text(copy.formTitle).font(.system(size: 28, weight: .bold)).foregroundStyle(DS.ink)
                payee(copy).padding(.top, 16)
                VStack(alignment: .leading, spacing: 4) {
                    Text(copy.amount).font(.system(size: 13)).foregroundStyle(DS.ink2)
                    AmountText(size: 30)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .card(padding: 16)
                .padding(.top, 12)
                options(copy).padding(.top, 12)
                Spacer(minLength: 16)
                Button {
                    showsAllTabs = false
                    step = .review
                } label: {
                    Text(copy.review)
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(DS.accent, in: Capsule())
                        .foregroundStyle(.white)
                }
                .accessibilityIdentifier("duo.review")
            case .review:
                Text(copy.reviewTitle).font(.system(size: 28, weight: .bold)).foregroundStyle(DS.ink)
                Text(copy.toLine).font(.system(size: 15)).foregroundStyle(DS.ink2).padding(.top, 16)
                AmountText(size: 34).padding(.top, 2)
                VStack(spacing: 0) {
                    DetailRow(title: Text(copy.from), value: Text(copy.fromValue))
                    Divider().overlay(DS.line)
                    DetailRow(title: Text(copy.reference), value: Text(copy.referenceValue))
                    Divider().overlay(DS.line)
                    DetailRow(title: Text(copy.fee), value: Text(verbatim: "AED 0.00").environment(\.layoutDirection, .leftToRight))
                    Divider().overlay(DS.line)
                    DetailRow(title: Text(copy.arrives), value: Text(copy.arrivesValue))
                }
                .padding(.horizontal, 16)
                .card(padding: 0)
                .padding(.top, 16)
                Spacer(minLength: 16)
                HStack(spacing: 10) {
                    Text(copy.hint).font(.system(size: 15, weight: .semibold))
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.right").font(.system(size: 17, weight: .bold))
                        .environment(\.layoutDirection, .leftToRight)
                }
                .foregroundStyle(DS.accentInk)
                .padding(.horizontal, 18)
                .frame(minHeight: 52)
                .background(DS.accentSoft, in: Capsule())
            case .sent:
                Spacer()
                VStack(spacing: 10) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 64, height: 64)
                        .background(DS.success, in: Circle())
                        .transition(.scale.combined(with: .opacity))
                    Text(copy.sent).font(.system(size: 22, weight: .bold)).foregroundStyle(DS.ink).padding(.top, 8)
                    Text(copy.sentDetail).font(.system(size: 15)).foregroundStyle(DS.ink2)
                }
                .frame(maxWidth: .infinity)
                Spacer()
                Button {
                    step = .form
                } label: {
                    Text(copy.done)
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(DS.accentSoft, in: Capsule())
                        .foregroundStyle(DS.accentInk)
                }
            }
        }
        .transition(.opacity)
        .id(step)
    }

    private func payee(_ copy: DuoCopy) -> some View {
        HStack(spacing: 12) {
            Avatar(initials: "SA")
            VStack(alignment: .leading, spacing: 2) {
                Text(copy.payee).font(.system(size: 15, weight: .semibold)).foregroundStyle(DS.ink)
                Text(copy.payeeDetail).font(.system(size: 13)).foregroundStyle(DS.ink2)
            }
            Spacer(minLength: 0)
        }
        .card(padding: 14)
    }

    private func options(_ copy: DuoCopy) -> some View {
        @Bindable var model = model
        return VStack(alignment: .leading, spacing: 10) {
            Text(copy.tabsOnReview).font(.system(size: 13, weight: .semibold)).foregroundStyle(DS.ink2)
            Picker(copy.tabsOnReview, selection: $tabsOnReview) {
                Text(copy.hidden).tag(TabsOnReview.hidden)
                Text(copy.minimized).tag(TabsOnReview.minimized)
            }
            .pickerStyle(.segmented)
            Picker("Language", selection: $model.language) {
                ForEach(DemoLanguage.allCases) { Text(verbatim: $0.title).tag($0) }
            }
            .pickerStyle(.segmented)
        }
        .card(padding: 14)
    }

    // MARK: Vertical bar

    private func verticalBar(_ copy: DuoCopy) -> some View {
        VStack(spacing: 12) {
            Group {
                switch step {
                case .form:
                    glassButton("xmark", label: copy.close) { dismiss() }
                case .review:
                    glassButton("chevron.left", label: copy.back) { step = .form }
                case .sent:
                    glassButton("square.and.arrow.up", label: copy.share) {}
                }
            }
            .padding(.top, 8)

            Spacer(minLength: 0)

            if step == .review && !showsAllTabs {
                GeometryReader { proxy in
                    SlideToConfirm(labels: model.language == .arabic ? .sendMoneyArabic : .sendMoney) {
                        try await Task.sleep(for: .seconds(1.3))
                    }
                    .slideToConfirmConfiguration(.verticalBar)
                    .onSlideToConfirmStateChange { state in
                        guard state.phase == .success else { return }
                        Task {
                            try? await Task.sleep(for: .milliseconds(700))
                            step = .sent
                        }
                    }
                    .frame(height: min(300, proxy.size.height))
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .demoLanguage(model.language)
                    .accessibilityIdentifier("duo.control")
                }
                .frame(width: zoneWidth)
                .frame(maxHeight: 300)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if step != .review || tabsOnReview == .minimized || showsAllTabs {
                tabCapsule(minimized: step == .review && tabsOnReview == .minimized && !showsAllTabs)
                    .transition(.scale(scale: 0.6, anchor: .bottom).combined(with: .opacity))
            }
        }
        .frame(maxHeight: .infinity)
        .padding(.bottom, 20)
    }

    private func glassButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(DS.ink)
                .frame(width: 48, height: 48)
                .background(.regularMaterial, in: Circle())
                .overlay(Circle().strokeBorder(DS.line))
                .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        }
        .accessibilityLabel(label)
    }

    private func tabCapsule(minimized: Bool) -> some View {
        let symbols = ["house", "wallet.pass", "arrow.left.arrow.right", "creditcard", "square.grid.2x2"]
        return VStack(spacing: 4) {
            if minimized {
                tabButton(symbols[2], selected: true)
                    .onTapGesture { showsAllTabs = true }
            } else {
                ForEach(Array(symbols.enumerated()), id: \.offset) { index, symbol in
                    tabButton(symbol, selected: index == 2)
                }
            }
        }
        .padding(.vertical, 6)
        .frame(width: zoneWidth)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(DS.line))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
    }

    private func tabButton(_ symbol: String, selected: Bool) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 18, weight: .medium))
            .foregroundStyle(selected ? Color.white : DS.ink)
            .frame(width: 44, height: 44)
            .background(selected ? DS.accent : .clear, in: Circle())
            .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

/// Copy for the vertical-bar flow, in English and Arabic.
private struct DuoCopy {
    let formTitle, payee, payeeDetail, amount, review, reviewTitle, toLine: String
    let from, fromValue, reference, referenceValue, fee, arrives, arrivesValue: String
    let hint, sent, sentDetail, done, back, close, share: String
    let tabsOnReview, hidden, minimized: String

    init(_ language: DemoLanguage) {
        let isolate = { (value: String) in "\u{2066}\(value)\u{2069}" }
        switch language {
        case .english:
            formTitle = "Send money"; payee = "Sara Ahmed"; payeeDetail = "Saved payee · ··8890"; amount = "Amount"
            review = "Review"; reviewTitle = "Review"; toLine = "To Sara Ahmed · ··8890"
            from = "From"; fromValue = "Current ··4521"; reference = "Reference"; referenceValue = "October rent"
            fee = "Fee"; arrives = "Arrives"; arrivesValue = "Today"
            hint = "Slide or hold on the right to send"; sent = "Sent"; sentDetail = "AED 2,500.00 to Sara Ahmed"
            done = "Done"; back = "Back"; close = "Close"; share = "Share receipt"
            tabsOnReview = "Tabs on Review"; hidden = "Hidden"; minimized = "Minimized"
        case .arabic:
            formTitle = "إرسال الأموال"; payee = "سارة أحمد"; payeeDetail = "مستفيد محفوظ · " + isolate("··8890"); amount = "المبلغ"
            review = "مراجعة"; reviewTitle = "مراجعة"; toLine = "إلى سارة أحمد · " + isolate("··8890")
            from = "من"; fromValue = "الجاري " + isolate("··4521"); reference = "المرجع"; referenceValue = "إيجار أكتوبر"
            fee = "الرسوم"; arrives = "الوصول"; arrivesValue = "اليوم"
            hint = "اسحب أو اضغط مطولاً يميناً للإرسال"; sent = "تم الإرسال"; sentDetail = isolate("2,500.00") + " درهم إلى سارة أحمد"
            done = "تم"; back = "رجوع"; close = "إغلاق"; share = "مشاركة الإيصال"
            tabsOnReview = "التبويبات في المراجعة"; hidden = "مخفية"; minimized = "مصغّرة"
        }
    }
}
