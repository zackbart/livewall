import Foundation
import Combine
import ServiceManagement

final class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    @Published var pauseOnBattery: Bool {
        didSet { UserDefaults.standard.set(pauseOnBattery, forKey: "pauseOnBattery") }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
            updateLoginItem()
        }
    }

    @Published var lowPowerMode: Bool {
        didSet { UserDefaults.standard.set(lowPowerMode, forKey: "lowPowerMode") }
    }

    @Published var displayAssignments: [String: String] {
        didSet {
            if let data = try? JSONEncoder().encode(displayAssignments) {
                UserDefaults.standard.set(data, forKey: "displayAssignments")
            }
        }
    }

    init() {
        self.pauseOnBattery = UserDefaults.standard.object(forKey: "pauseOnBattery") as? Bool ?? true
        self.launchAtLogin = UserDefaults.standard.object(forKey: "launchAtLogin") as? Bool ?? false
        self.lowPowerMode = UserDefaults.standard.object(forKey: "lowPowerMode") as? Bool ?? false

        if let data = UserDefaults.standard.data(forKey: "displayAssignments"),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            self.displayAssignments = decoded
        } else {
            self.displayAssignments = [:]
        }
    }

    private func updateLoginItem() {
        if #unavailable(macOS 13.0) { return }
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to update login item: \(error)")
        }
    }
}
