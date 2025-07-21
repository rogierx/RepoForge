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
            .font(.system(size: 8.75, weight: .medium, design: .monospaced))
            .foregroundColor(.primary)
            .multilineTextAlignment(.center)
            .lineLimit(nil)
        }
        .frame(maxWidth: .infinity)
    }
}

struct RecentsASCIIView: View {
    var body: some View {
        Text("""
        ██████╗ ███████╗ ██████╗███████╗███╗   ██╗████████╗███████╗
        ██╔══██╗██╔════╝██╔════╝██╔════╝████╗  ██║╚══██╔══╝██╔════╝
        ██████╔╝█████╗  ██║     █████╗  ██╔██╗ ██║   ██║   ███████╗
        ██╔══██╗██╔══╝  ██║     ██╔══╝  ██║╚██╗██║   ██║   ╚════██║
        ██║  ██║███████╗╚██████╗███████╗██║ ╚████║   ██║   ███████║
        ╚═╝  ╚═╝╚══════╝ ╚═════╝╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝
        """)
        .font(.system(size: 10.5, weight: .medium, design: .monospaced))
        .foregroundColor(.primary)
        .multilineTextAlignment(.center)
        .lineLimit(nil)
    }
}

struct BookmarksASCIIView: View {
    var body: some View {
        Text("""
        ██████╗  ██████╗  ██████╗ ██╗  ██╗███╗   ███╗ █████╗ ██████╗ ██╗  ██╗███████╗
        ██╔══██╗██╔═══██╗██╔═══██╗██║ ██╔╝████╗ ████║██╔══██╗██╔══██╗██║ ██╔╝██╔════╝
        ██████╔╝██║   ██║██║   ██║█████╔╝ ██╔████╔██║███████║██████╔╝█████╔╝ ███████╗
        ██╔══██╗██║   ██║██║   ██║██╔═██╗ ██║╚██╔╝██║██╔══██║██╔══██╗██╔═██╗ ╚════██║
        ██████╔╝╚██████╔╝╚██████╔╝██║  ██╗██║ ╚═╝ ██║██║  ██║██║  ██║██║  ██╗███████║
        ╚═════╝  ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝
        """)
        .font(.system(size: 10.5, weight: .medium, design: .monospaced))
        .foregroundColor(.primary)
        .multilineTextAlignment(.center)
        .lineLimit(nil)
    }
}

#Preview {
    VStack(spacing: 20) {
        AppLogoView(size: 32)
        RecentsASCIIView()
        BookmarksASCIIView()
    }
    .padding()
} 