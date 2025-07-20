import SwiftUI

@main
struct RepoForgeApp: App {
    
    init() {
        // Set the app icon
        if let iconPath = Bundle.main.path(forResource: "AppIcon", ofType: "icns") {
            if let icon = NSImage(contentsOfFile: iconPath) {
                NSApp.applicationIconImage = icon
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 900, height: 600)
    }
}
