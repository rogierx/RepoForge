import SwiftUI

@main
struct RepoForgeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 900, height: 600)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure single instance
        ensureSingleInstance()
        
        // Set the app icon - try appicon.png first, then fall back to AppIcon.icns
        Task { @MainActor in
            setAppIcon()
            
            // Bring app to front and focus
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
            
            // Make sure app appears in dock
            if let window = NSApp.windows.first {
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
        
        // Terminate other instances
        for app in repoForgeApps {
            app.terminate()
        }
    }
    
    @MainActor
    private func setAppIcon() {
        var iconSet = false
        
        // Try appicon.png from the workspace root (when running from source)
        let workspaceURL = Bundle.main.bundleURL.deletingLastPathComponent().deletingLastPathComponent()
        let appiconURL = workspaceURL.appendingPathComponent("appicon.png")
        
        if FileManager.default.fileExists(atPath: appiconURL.path) {
            if let icon = NSImage(contentsOf: appiconURL) {
                NSApp.applicationIconImage = icon
                iconSet = true
                print("✓ App icon loaded from appicon.png")
            }
        }
        
        // Fallback to bundled AppIcon.icns
        if !iconSet, let iconPath = Bundle.main.path(forResource: "AppIcon", ofType: "icns") {
            if let icon = NSImage(contentsOfFile: iconPath) {
                NSApp.applicationIconImage = icon
                print("✓ App icon loaded from AppIcon.icns")
            }
        }
        
        // Additional fallback - try appicon.png from current directory
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
