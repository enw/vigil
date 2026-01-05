import Cocoa

@main
struct my_istat: App {
    var body: some Scene {
        MenuBarExtra("cavestat", systemImage: "cpu") {
            MenuContentView()
        }

        Settings {
            PreferencesWindow()
        }
    }
}
