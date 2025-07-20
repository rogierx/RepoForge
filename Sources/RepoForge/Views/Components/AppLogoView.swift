import SwiftUI

struct AppLogoView: View {
    let size: CGFloat
    
    init(size: CGFloat = 48) {
        self.size = size
    }
    
    var body: some View {
        Group {
            // Try multiple approaches to load the logo
            if let logoImage = loadLogoImage() {
                Image(nsImage: logoImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.22))
                    .grayscale(1.0) // Convert to black and white
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            } else {
                // Use the actual app icon as fallback
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.22))
                    .grayscale(1.0) // Convert to black and white
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
        }
    }
    
    private func loadLogoImage() -> NSImage? {
        // Try multiple loading approaches
        
        // Approach 1: Direct bundle resource
        if let logoUrl = Bundle.main.url(forResource: "RepoForge-Logo", withExtension: "png"),
           let logoImage = NSImage(contentsOf: logoUrl) {
            return logoImage
        }
        
        // Approach 2: Try with different bundle paths
        if let logoImage = NSImage(named: NSImage.Name("RepoForge-Logo")) {
            return logoImage
        }
        
        // Approach 3: Try finding in Resources folder specifically
        if let resourcePath = Bundle.main.resourcePath,
           let logoImage = NSImage(contentsOfFile: resourcePath + "/RepoForge-Logo.png") {
            return logoImage
        }
        
        // Approach 4: Try the root project logo
        if let logoUrl = Bundle.main.url(forResource: "repoforge-logo", withExtension: "png"),
           let logoImage = NSImage(contentsOf: logoUrl) {
            return logoImage
        }
        
        return nil
    }
}

#Preview {
    VStack(spacing: 20) {
        AppLogoView(size: 32)
        AppLogoView(size: 48)
        AppLogoView(size: 64)
        AppLogoView(size: 128)
    }
    .padding()
} 