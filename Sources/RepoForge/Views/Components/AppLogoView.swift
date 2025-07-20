import SwiftUI

struct AppLogoView: View {
    let size: CGFloat
    
    init(size: CGFloat = 48) {
        self.size = size
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text("""
            ██████╗ ███████╗██████╗  ██████╗ 
            ██╔══██╗██╔════╝██╔══██╗██╔═══██╗
            ██████╔╝█████╗  ██████╔╝██║   ██║
            ██╔══██╗██╔══╝  ██╔═══╝ ██║   ██║
            ██║  ██║███████╗██║     ╚██████╔╝
            ╚═╝  ╚═╝╚══════╝╚═╝      ╚═════╝ 
            
            ███████╗ ██████╗ ██████╗  ██████╗ ███████╗
            ██╔════╝██╔═══██╗██╔══██╗██╔════╝ ██╔════╝
            █████╗  ██║   ██║██████╔╝██║  ███╗█████╗  
            ██╔══╝  ██║   ██║██╔══██╗██║   ██║██╔══╝  
            ██║     ╚██████╔╝██║  ██║╚██████╔╝███████╗
            ╚═╝      ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝
            """)
            .font(.system(size: 7, weight: .medium, design: .monospaced))
            .foregroundColor(.primary)
            .multilineTextAlignment(.center)
            .lineLimit(nil)
        }
        .frame(maxWidth: .infinity)
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