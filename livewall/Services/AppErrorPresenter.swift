import SwiftUI
import Combine

/// A user-visible error with a clear title, explanation, and optional recovery hint.
struct AppError: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String
    let recoverySuggestion: String?

    static func == (lhs: AppError, rhs: AppError) -> Bool {
        lhs.title == rhs.title && lhs.message == rhs.message
    }
}

/// Shared, single-slot error state surfaced by services. Presents as a SwiftUI
/// alert via the `.appErrorAlert()` modifier attached once at each window root.
///
/// Services should not call `present` directly — use `AppErrorPresenter.report(...)`
/// which handles the main-actor hop from any context.
@MainActor
final class AppErrorPresenter: ObservableObject {
    static let shared = AppErrorPresenter()

    @Published var currentError: AppError?

    private init() {}

    /// Present an error. If an identical error is already showing, this is a no-op
    /// (prevents alert stomping when several displays fail simultaneously).
    func present(_ error: AppError) {
        if let current = currentError, current == error { return }
        currentError = error
    }

    func dismiss() {
        currentError = nil
    }
}

extension AppErrorPresenter {
    /// Non-isolated convenience for services and KVO callbacks to surface an
    /// error from any context. Returns immediately — the hop to the main
    /// actor is internal.
    ///
    /// This is a `nonisolated` static method on the presenter (rather than a
    /// top-level function) to avoid colliding with `NSResponder.presentError(_:)`
    /// when called from NSView subclasses.
    nonisolated static func report(
        title: String,
        message: String,
        recoverySuggestion: String? = nil
    ) {
        let error = AppError(title: title, message: message, recoverySuggestion: recoverySuggestion)
        Task { @MainActor in
            AppErrorPresenter.shared.present(error)
        }
    }
}

// MARK: - View modifier

extension View {
    /// Attach once per window root. Observes the shared presenter and shows a
    /// SwiftUI alert whenever `currentError` is non-nil.
    func appErrorAlert() -> some View {
        modifier(AppErrorAlertModifier())
    }
}

private struct AppErrorAlertModifier: ViewModifier {
    @ObservedObject private var presenter = AppErrorPresenter.shared

    func body(content: Content) -> some View {
        content.alert(
            presenter.currentError?.title ?? "Error",
            isPresented: Binding(
                get: { presenter.currentError != nil },
                set: { if !$0 { presenter.dismiss() } }
            ),
            presenting: presenter.currentError
        ) { _ in
            Button("OK", role: .cancel) { presenter.dismiss() }
        } message: { error in
            if let recovery = error.recoverySuggestion {
                Text("\(error.message)\n\n\(recovery)")
            } else {
                Text(error.message)
            }
        }
    }
}
