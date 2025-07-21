
import Foundation
import UniformTypeIdentifiers

class FileNode: Identifiable, ObservableObject, Hashable, @unchecked Sendable {
    let id = UUID()
    let name: String
    let path: String
    let type: FileType
    var size: Int
    @Published var children: [FileNode] = []
    @Published var isExpanded = false
    @Published var isIncluded = true
    @Published var content: String?
    
    @Published var totalFileCount: Int
    @Published var totalTokenCount: Int
    
    @Published var tokenCount: Int = 0
    
    weak var parent: FileNode?
    
    enum FileType: String {
        case file, directory, symlink, submodule
    }
    
    var isDirectory: Bool {
        return type == .directory
    }
    
    var category: FileTypeCategories.Category {
        return FileTypeCategories.shared.category(for: name)
    }

    init(name: String, path: String, type: FileType, size: Int = 0, content: String? = nil) {
        self.name = name
        self.path = path
        self.type = type
        self.size = size
        self.content = content
        
        self.totalFileCount = (type == .file) ? 1 : 0
        self.tokenCount = 0
        self.totalTokenCount = 0
    }
    
    func addChild(_ node: FileNode) {
        children.append(node)
        node.parent = self
        
        self.totalFileCount += node.totalFileCount
        self.totalTokenCount += node.totalTokenCount
    }
    
    func addTokens(_ count: Int) {
        self.tokenCount += count
        
        var current = self
        while let parent = current.parent {
            parent.totalTokenCount += count
            current = parent
        }
    }


    
    static func == (lhs: FileNode, rhs: FileNode) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    

    func generateTreeString(prefix: String = "") -> String {
        var result = "\(prefix)\(name)\n"
        let childPrefix = prefix.replacingOccurrences(of: "├── ", with: "│   ").replacingOccurrences(of: "└── ", with: "    ")
        
        let sortedChildren = children.sorted { $0.name < $1.name }

        for (index, child) in sortedChildren.enumerated() {
            let newPrefix = index == sortedChildren.count - 1 ? "└── " : "├── "
            result += child.generateTreeString(prefix: childPrefix + newPrefix)
        }
        
        return result
    }

    func sort(by option: SortOption, ascending: Bool) {
        for child in children {
            if child.isDirectory {
                child.sort(by: option, ascending: ascending)
            }
        }
        
        children.sort { (node1, node2) -> Bool in
            let result: Bool
            switch option {
            case .name:
                result = node1.name.localizedStandardCompare(node2.name) == .orderedAscending
            case .size:
                result = node1.size < node2.size
            case .tokens:
                result = node1.totalTokenCount < node2.totalTokenCount
            }
            return ascending ? result : !result
        }
    }
    
    enum SortOption {
        case name, size, tokens
    }
    
    
    func updateInclusion(isIncluded: Bool, includeChildren: Bool) {
        self.isIncluded = isIncluded
        if includeChildren {
            for child in children {
                child.updateInclusion(isIncluded: isIncluded, includeChildren: true)
            }
        }
        var root = self
        while let parent = root.parent {
            root = parent
        }
        root.recalculateCounts()
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name("FileNodeChanged"), object: nil)
        }
    }
    
    func recalculateCounts() {
        if isDirectory {
            for child in children {
                child.recalculateCounts()
            }
            totalFileCount = children.reduce(0) { $0 + ($1.isIncluded ? $1.totalFileCount : 0) }
            totalTokenCount = children.reduce(0) { $0 + ($1.isIncluded ? $1.totalTokenCount : 0) }
        } else {
            totalFileCount = 1
            totalTokenCount = tokenCount
        }
    }
    
    func updateInclusionBasedOnSettings(includeVirtualEnvironments: Bool) {
        self.isIncluded = !FileNode.shouldExcludeByDefault(
            path: self.path,
            name: self.name,
            includeVirtualEnvironments: includeVirtualEnvironments
        )
    }
    
    static func shouldExcludeByDefault(path: String, name: String, includeVirtualEnvironments: Bool) -> Bool {
        let excludedDirs = [
            ".git", ".github", ".vscode", "node_modules",
            "__pycache__", ".pytest_cache", ".tox",
            "build", "dist", ".build", "target", "out"
        ]
        
        if !includeVirtualEnvironments {
            let virtualEnvDirs = ["venv", ".venv", "env", ".env", "virtualenv"]
            if virtualEnvDirs.contains(name.lowercased()) {
                return true
            }
        }
        
        if excludedDirs.contains(name.lowercased()) {
            return true
        }
        
        let excludedExtensions = [
            ".lock", ".log", ".DS_Store", ".zip", ".gz", ".tar",
            ".png", ".jpg", ".jpeg", ".gif", ".svg", ".ico",
            ".mp4", ".mov", ".avi", ".webm",
            ".pdf", ".doc", ".docx", ".xls", ".xlsx"
        ]
        
        let fileExtension = URL(fileURLWithPath: name).pathExtension
        if excludedExtensions.contains(".\(fileExtension.lowercased())") {
            return true
        }
        
        return false
    }
} 