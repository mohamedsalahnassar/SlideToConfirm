import SlideToConfirm
import SwiftUI

/// The design's primary flow: review a transfer, slide or hold to send, then a receipt.
struct SendMoneyScenario: View {
    @Environment(AppModel.self) private var model
    @State private var step: Step = Step(rawValue: UserDefaults.standard.string(forKey: "step") ?? "") ?? .review
    @State private var failsNextSend = false
    @State private var attempt = 0

    enum Step: String { case review, receipt }

    var body: some View {
        let copy = SendCopy(model.language)
        ZStack {
            DS.background.ignoresSafeArea()
            switch step {
            case .review:
                review(copy)
                    .transition(.asymmetric(insertion: .move(edge: .leading), removal: .opacity))
            case .receipt:
                Receipt(copy: copy) {
                    attempt += 1
                    withAnimation(.smooth(duration: 0.4)) { step = .review }
                }
                .transition(.asymmetric(insertion: .scale(scale: 0.96).combined(with: .opacity), removal: .opacity))
            }
        }
        .navigationTitle(step == .review ? copy.reviewTitle : "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { LanguagePicker() }
        }
        .demoLanguage(model.language)
    }

    private func review(_ copy: SendCopy) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Avatar(initials: "SA", size: 44)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(copy.payee).font(.system(size: 16, weight: .semibold)).foregroundStyle(DS.ink)
                        Text(copy.payeeDetail).font(.system(size: 13)).foregroundStyle(DS.ink2)
                    }
                    Spacer()
                }
                .card(padding: 16)

                VStack(alignment: .leading, spacing: 4) {
                    Text(copy.sendingLine).font(.system(size: 15)).foregroundStyle(DS.ink2)
                    AmountText(size: 40)
                }
                .padding(.horizontal, 4)

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

                Toggle(isOn: $failsNextSend) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(copy.simulateFailure).font(.system(size: 15, weight: .semibold)).foregroundStyle(DS.ink)
                        Text(copy.simulateFailureDetail).font(.system(size: 13)).foregroundStyle(DS.ink2)
                    }
                }
                .tint(DS.danger)
                .card(padding: 16)
                .accessibilityIdentifier("send.simulateFailure")
            }
            .padding(.horizontal, DS.gutter)
            .padding(.vertical, 16)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .safeAreaInset(edge: .bottom) {
            BottomConfirmBar {
                SlideToConfirm(labels: model.language == .arabic ? .sendMoneyArabic : .sendMoney) {
                    try await Task.sleep(for: .seconds(1.3))
                    if failsNextSend {
                        failsNextSend = false
                        throw SlideToConfirmFailure(copy.networkError)
                    }
                }
                .slideToConfirmAccessibilityAlert(copy.alertTitle, message: copy.alertMessage)
                .onSlideToConfirmStateChange { state in
                    guard state.phase == .success else { return }
                    Task {
                        try? await Task.sleep(for: .milliseconds(700))
                        withAnimation(.smooth(duration: 0.45)) { step = .receipt }
                    }
                }
                .accessibilityLabel(copy.accessibilityName)
                .accessibilityIdentifier("send.control")
                .id(attempt)

                Text(copy.footnote)
                    .font(.system(size: 12))
                    .foregroundStyle(DS.ink3)
            }
        }
    }
}

private struct Receipt: View {
    let copy: SendCopy
    let done: () -> Void
    @State private var bounce = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 10) {
                ZStack {
                    Circle().fill(DS.successSoft).frame(width: 112, height: 112)
                    Circle().fill(DS.success).frame(width: 76, height: 76)
                    Image(systemName: "checkmark")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.white)
                        .symbolEffect(.bounce, value: bounce)
                }
                .padding(.bottom, 10)
                Text(copy.sent).font(.system(size: 28, weight: .bold)).foregroundStyle(DS.ink)
                Text(copy.sentDetail).font(.system(size: 16)).foregroundStyle(DS.ink2)
            }
            VStack(spacing: 0) {
                DetailRow(title: Text(copy.reference), value: Text(copy.referenceValue))
                Divider().overlay(DS.line)
                DetailRow(title: Text(copy.transactionID), value: Text(verbatim: "TRX-48 211 907").environment(\.layoutDirection, .leftToRight))
                Divider().overlay(DS.line)
                DetailRow(title: Text(copy.arrives), value: Text(copy.arrivesValue))
            }
            .padding(.horizontal, 16)
            .card(padding: 0)
            .padding(.top, 28)
            Spacer()
            VStack(spacing: 10) {
                ShareLink(item: copy.sentDetail) {
                    Label(copy.share, systemImage: "square.and.arrow.up")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(DS.accentSoft, in: Capsule())
                        .foregroundStyle(DS.accentInk)
                }
                Button(action: done) {
                    Text(copy.done)
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(DS.accent, in: Capsule())
                        .foregroundStyle(.white)
                }
                .accessibilityIdentifier("send.done")
            }
        }
        .padding(.horizontal, DS.gutter)
        .padding(.bottom, 12)
        .frame(maxWidth: 560)
        .onAppear { bounce += 1 }
    }
}

struct Avatar: View {
    let initials: String
    var size: CGFloat = 40

    var body: some View {
        Text(verbatim: initials)
            .font(.system(size: size * 0.38, weight: .semibold))
            .foregroundStyle(DS.accentInk)
            .frame(width: size, height: size)
            .background(DS.accentSoft, in: Circle())
            .environment(\.layoutDirection, .leftToRight)
    }
}

struct AmountText: View {
    var size: CGFloat = 34

    var body: some View {
        Text(verbatim: "AED 2,500.00")
            .font(.system(size: size, weight: .bold))
            .tracking(-0.8)
            .monospacedDigit()
            .foregroundStyle(DS.ink)
            .environment(\.layoutDirection, .leftToRight)
    }
}

struct LanguagePicker: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Picker("Language", selection: $model.language) {
            ForEach(DemoLanguage.allCases) { language in
                Text(verbatim: language.title).tag(language)
            }
        }
        .pickerStyle(.menu)
        .environment(\.layoutDirection, .leftToRight)
        .accessibilityIdentifier("languagePicker")
    }
}

/// Copy for the send-money flow, in English and Arabic.
struct SendCopy {
    let reviewTitle: String
    let payee: String
    let payeeDetail: String
    let sendingLine: String
    let from: String
    let fromValue: String
    let reference: String
    let referenceValue: String
    let fee: String
    let arrives: String
    let arrivesValue: String
    let simulateFailure: String
    let simulateFailureDetail: String
    let networkError: String
    let alertTitle: LocalizedStringKey
    let alertMessage: LocalizedStringKey
    let accessibilityName: String
    let footnote: String
    let sent: String
    let sentDetail: String
    let transactionID: String
    let share: String
    let done: String

    init(_ language: DemoLanguage) {
        let isolate = { (value: String) in "\u{2066}\(value)\u{2069}" }
        switch language {
        case .english:
            reviewTitle = "Review transfer"
            payee = "Sara Ahmed"
            payeeDetail = "Saved payee · ··8890"
            sendingLine = "You are sending"
            from = "From"
            fromValue = "Current account ··4521"
            reference = "Reference"
            referenceValue = "October rent"
            fee = "Fee"
            arrives = "Arrives"
            arrivesValue = "Today, within minutes"
            simulateFailure = "Simulate a failed send"
            simulateFailureDetail = "The next send throws, so you can see the shake and retry."
            networkError = "Not sent · no connection"
            alertTitle = "Send AED 2,500.00 to Sara Ahmed?"
            alertMessage = "The money arrives today, within minutes."
            accessibilityName = "Send AED 2,500.00 to Sara Ahmed"
            footnote = "Locked from commit until the server answers. No double sends."
            sent = "Sent"
            sentDetail = "AED 2,500.00 to Sara Ahmed"
            transactionID = "Transaction"
            share = "Share receipt"
            done = "Done"
        case .arabic:
            reviewTitle = "مراجعة التحويل"
            payee = "سارة أحمد"
            payeeDetail = "مستفيد محفوظ · " + isolate("··8890")
            sendingLine = "أنت ترسل"
            from = "من"
            fromValue = "الحساب الجاري " + isolate("··4521")
            reference = "المرجع"
            referenceValue = "إيجار أكتوبر"
            fee = "الرسوم"
            arrives = "الوصول"
            arrivesValue = "اليوم، خلال دقائق"
            simulateFailure = "محاكاة فشل الإرسال"
            simulateFailureDetail = "سيفشل الإرسال التالي لترى الاهتزاز وإعادة المحاولة."
            networkError = "لم يُرسل · لا يوجد اتصال"
            alertTitle = "إرسال ٢٬٥٠٠٫٠٠ درهم إلى سارة أحمد؟"
            alertMessage = "تصل الأموال اليوم، خلال دقائق."
            accessibilityName = "إرسال ٢٬٥٠٠ درهم إلى سارة أحمد"
            footnote = "مقفل منذ التأكيد حتى يرد الخادم. لا إرسال مزدوج."
            sent = "تم الإرسال"
            sentDetail = isolate("2,500.00") + " درهم إلى سارة أحمد"
            transactionID = "المعاملة"
            share = "مشاركة الإيصال"
            done = "تم"
        }
    }
}
