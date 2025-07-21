import SwiftUI

@main
struct RepoForgeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 900, height: 600)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About repoforge") {
                    NSApplication.shared.orderFrontStandardAboutPanel(
                        options: [
                            NSApplication.AboutPanelOptionKey.applicationName: "repoforge",
                            NSApplication.AboutPanelOptionKey.applicationVersion: "1.0"
                        ]
                    )
                }
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        ensureSingleInstance()
        
        Task { @MainActor in
            setAppIcon()
            
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
            
            if let window = NSApp.windows.first {
                window.title = ""
                window.titleVisibility = .hidden
                window.titlebarAppearsTransparent = true
                window.styleMask.insert(.fullSizeContentView)
                window.makeKeyAndOrderFront(nil)
            }
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    private func ensureSingleInstance() {
        let runningApps = NSWorkspace.shared.runningApplications
        let repoForgeApps = runningApps.filter { app in
            return app.bundleIdentifier?.contains("RepoForge") == true && app.processIdentifier != NSRunningApplication.current.processIdentifier
        }
        
        for app in repoForgeApps {
            app.terminate()
        }
    }
    
    @MainActor
    private func setAppIcon() {
        var iconSet = false
        
        let workspaceURL = Bundle.main.bundleURL.deletingLastPathComponent().deletingLastPathComponent()
        let appiconURL = workspaceURL.appendingPathComponent("appicon.png")
        
        if FileManager.default.fileExists(atPath: appiconURL.path) {
            if let icon = NSImage(contentsOf: appiconURL) {
                NSApp.applicationIconImage = icon
                iconSet = true
                print("✓ App icon loaded from appicon.png")
            }
        }
        
        if !iconSet, let iconPath = Bundle.main.path(forResource: "AppIcon", ofType: "icns") {
            if let icon = NSImage(contentsOfFile: iconPath) {
                NSApp.applicationIconImage = icon
                print("✓ App icon loaded from AppIcon.icns")
            }
        }
        
        if !iconSet {
            let currentDirIcon = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("appicon.png")
            if FileManager.default.fileExists(atPath: currentDirIcon.path) {
                if let icon = NSImage(contentsOf: currentDirIcon) {
                    NSApp.applicationIconImage = icon
                    iconSet = true
                    print("✓ App icon loaded from current directory appicon.png")
                }
            }
        }
        
        if !iconSet {
            print("⚠️ Could not load app icon from appicon.png or AppIcon.icns")
        }
    }
}
