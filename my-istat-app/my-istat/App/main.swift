import SwiftUI

@main
struct VigilApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("Vigil", systemImage: "cpu") {
            MenuContentView()
        }

        Settings {
            PreferencesWindow()
        }
    }
}
