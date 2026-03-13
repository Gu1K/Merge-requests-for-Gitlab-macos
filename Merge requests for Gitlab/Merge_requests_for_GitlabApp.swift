import SwiftUI

@main
struct Merge_requests_for_GitlabApp: App {
    @AppStorage("gitlabToken") private var apiToken: String = ""
    
    var body: some Scene {
        // Fenêtre confortable : 500x600
        MenuBarExtra("GitLab MR", systemImage: "tray.and.arrow.down.fill") {
            ContentView()
                .frame(width: 500, height: 1000)
        }
        .menuBarExtraStyle(.window)
        
        Settings {
            SettingsView()
        }
    }
}
