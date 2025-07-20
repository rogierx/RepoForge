import SwiftUI

struct FileTreeView: View {
    @ObservedObject var fileNode: FileNode
    @State private var isExpanded = true
    private let level: Int
    
    // Using a simple let for the service now.
    let tokenService: TokenCountingService

    init(fileNode: FileNode, level: Int = 0, tokenService: TokenCountingService) {
        self.fileNode = fileNode
        self.level = level
        self.tokenService = tokenService
    }

    var body: some View {
        if fileNode.isDirectory {
            DisclosureGroup(isExpanded: $isExpanded) {
                ForEach(fileNode.children) { child in
                    FileTreeView(fileNode: child, level: level + 1, tokenService: tokenService)
                }
            } label: {
                FileRow(fileNode: fileNode, level: level, tokenService: tokenService)
            }
        } else {
            FileRow(fileNode: fileNode, level: level, tokenService: tokenService)
        }
    }
}

struct FileRow: View {
    @ObservedObject var fileNode: FileNode
    let level: Int
    let tokenService: TokenCountingService

    var body: some View {
        HStack {
            // Indentation
            Spacer().frame(width: CGFloat(level * 20))

            // Icon
            Image(systemName: fileNode.isDirectory ? "folder.fill" : "doc.text.fill")
                .foregroundColor(fileNode.isDirectory ? .blue : .gray)

            // File Name
            Text(fileNode.name)
                .lineLimit(1)
            
            Spacer()

            // Inclusion checkbox
            Button(action: {
                fileNode.updateInclusion(isIncluded: !fileNode.isIncluded, includeChildren: true)
            }) {
                Image(systemName: fileNode.isIncluded ? "checkmark.square" : "square")
                    .foregroundStyle(fileNode.isIncluded ? .blue : .secondary)
            }
            .buttonStyle(PlainButtonStyle())

            // Token/File Count
            Text(formattedCount)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private var formattedCount: String {
        if fileNode.isDirectory {
            return "\(tokenService.formatTokenCount(fileNode.totalTokenCount)) • \(fileNode.totalFileCount) files"
        } else {
            return tokenService.formatTokenCount(fileNode.tokenCount)
        }
    }
}

struct FileTreeHeaderView: View {
    @ObservedObject var rootNode: FileNode
    let tokenService: TokenCountingService

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(rootNode.name)
                .font(.title)
                .fontWeight(.bold)
            
            let statistics: ProcessingStatistics = tokenService.calculateStatistics(for: rootNode)
            
            HStack {
                StatItem(label: "Included Files", value: "\(statistics.includedFiles)")
                Spacer()
                StatItem(label: "Total Tokens", value: tokenService.formatTokenCount(statistics.includedTokens))
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
    }
}

struct StatItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
        }
    }
}

struct FileTreeView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleNode = FileNode(name: "Preview Repo", path: "", type: .directory)
        let childFile = FileNode(name: "File.swift", path: "File.swift", type: .file, size: 1024)
        let childDir = FileNode(name: "SubFolder", path: "SubFolder", type: .directory)
        childFile.tokenCount = 256
        sampleNode.addChild(childFile)
        sampleNode.addChild(childDir)
        
        let tokenService = TokenCountingService()

        return VStack {
            FileTreeHeaderView(rootNode: sampleNode, tokenService: tokenService)
            FileTreeView(fileNode: sampleNode, tokenService: tokenService)
        }
    }
} 