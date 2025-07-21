
import Foundation
import SwiftUI
import Combine

struct SavedOutput: Identifiable, Codable {
    let id: UUID
    let name: String
    let content: String
    let fileCount: Int
    let tokenCount: Int
    let createdAt: Date
    
    init(name: String, content: String, fileCount: Int, tokenCount: Int, createdAt: Date) {
        self.id = UUID()
        self.name = name
        self.content = content
        self.fileCount = fileCount
        self.tokenCount = tokenCount
        self.createdAt = createdAt
    }
}

struct RecentRepository: Identifiable, Codable, Hashable {
    let id: UUID
    let path: String
    let type: RepositoryType
    let processedAt: Date
    
    enum RepositoryType: String, Codable, CaseIterable {
        case github = "GitHub"
        case local = "Local"
    }
    
    init(path: String, type: RepositoryType, processedAt: Date = Date()) {
        self.id = UUID()
        self.path = path
        self.type = type
        self.processedAt = processedAt
    }
}

@MainActor
class MainViewModel: ObservableObject {
    
    
    @Published var githubURL: String = ""
    @Published var localPath: String = ""
    @Published var accessToken: String = ""
    @Published var saveURL: Bool = false
    @Published var saveToken: Bool = false
    @Published var includeVirtualEnvironments: Bool = false
    @Published var repoType: RepoType = .github
    
    enum RepoType: String, CaseIterable {
        case github = "GitHub"
        case local = "Local"
    }
    
    @Published var isLoading: Bool = false
    @Published var isGeneratingOutput: Bool = false
    @Published var errorMessage: String?
    
    @Published var currentRepository: Repository?
    @Published var fileTree: FileNode?
    @Published var generatedOutput = ""
    
    @Published var selectedTab = 0
    @Published var activePage: ActivePage = .main
    @Published var verboseLogs: [String] = []
    
    enum ActivePage {
        case main
        case fileTree
        case output
        case recents
        case bookmarks
    }
    
    @Published var recentRepositories: [RecentRepository] = []
    @Published var bookmarkedRepositories: [String] = []
    @Published var savedOutputs: [SavedOutput] = []
    @Published var isCurrentOutputBookmarked: Bool = false
    @Published var newBookmarksCount: Int = 0
    
    
    private var githubService: GitHubService?
    let tokenService = TokenCountingService()
    private let outputService: OutputService
    private let persistenceService = PersistenceService()
    
    
    private var fetchTask: Task<Void, Never>?
    private var generateTask: Task<Void, Never>?
    
    
    init() {
        self.outputService = OutputService(tokenService: self.tokenService)
        loadPersistedData()
    }
    
    private func loadPersistedData() {
        self.githubURL = persistenceService.retrieveGitHubURL() ?? ""
        self.accessToken = persistenceService.retrieveGitHubToken() ?? ""
        if !githubURL.isEmpty { self.saveURL = true }
        if !accessToken.isEmpty { self.saveToken = true }
        
        self.recentRepositories = persistenceService.loadRecents()
        self.bookmarkedRepositories = persistenceService.loadBookmarks()
        self.savedOutputs = persistenceService.loadSavedOutputs()
    }
    
    
    func processRepository() {
        if repoType == .github {
            guard !githubURL.isEmpty, !accessToken.isEmpty else {
                showError("URL and Access Token are required.")
                return
            }
        } else {
            guard !localPath.isEmpty else {
                showError("Local repository path is required.")
                return
            }
        }
        
        fetchTask?.cancel()
        
        isLoading = true
        errorMessage = nil
        fileTree = nil
        currentRepository = nil
        verboseLogs.removeAll()
        
        if repoType == .github {
            let service = GitHubService(token: accessToken)
            self.githubService = service
            
            fetchTask = Task(priority: .userInitiated) {
                do {
                    log("Fetching repository metadata...")
                    let repository = try await service.fetchRepository(url: githubURL)
                    if Task.isCancelled { return }
                    
                    await MainActor.run {
                        self.currentRepository = repository
                    }
                    
                    log("Building file tree structure...")
                    let rootNode = try await service.buildFileTree(owner: repository.owner.login, repo: repository.name, includeVirtualEnvironments: includeVirtualEnvironments)
                    if Task.isCancelled { return }

                    log("Estimating token counts...")
                    estimateTokenCounts(for: rootNode)

                    tokenService.sortNodesByTokenCount(rootNode)
                    
                    log("Structure built. Updating UI...")
                    await MainActor.run {
                        self.fileTree = rootNode
                        self.isLoading = false
                        self.selectedTab = 1
                        self.addToRecents(self.githubURL)
                        self.isCurrentOutputBookmarked = false
                    }
                    
                } catch {
                    if !Task.isCancelled {
                        showError("Failed to process repository: \(error.localizedDescription)")
                    }
                    await MainActor.run {
                        self.isLoading = false
                    }
                }
            }
        } else {
            fetchTask = Task(priority: .userInitiated) {
                do {
                    log("Processing local repository...")
                    
                    let localRepoName = URL(fileURLWithPath: localPath).lastPathComponent
                    let mockRepo = Repository(
                        id: 0,
                        name: localRepoName,
                        fullName: localRepoName,
                        description: "Local repository",
                        htmlUrl: "file:
                        defaultBranch: "main",
                        size: 0,
                        language: nil,
                        owner: Repository.Owner(login: "local")
                    )
                    
                    await MainActor.run {
                        self.currentRepository = mockRepo
                    }
                    
                    log("Building local file tree...")
                    let rootNode = try await buildLocalFileTree(path: localPath)
                    if Task.isCancelled { return }
                    
                    log("Processing complete. Updating UI...")
                    DispatchQueue.main.async {
                        self.fileTree = rootNode
                        self.isLoading = false
                        self.selectedTab = 1
                        self.addToRecents(self.localPath)
                        self.isCurrentOutputBookmarked = false
                    }
                    
                } catch {
                    if !Task.isCancelled {
                        showError("Failed to process local repository: \(error.localizedDescription)")
                    }
                    await MainActor.run {
                        self.isLoading = false
                    }
                }
            }
        }
    }
    
    private func estimateTokenCounts(for node: FileNode) {
        if node.isDirectory {
            var estimatedTokens = 0
            for child in node.children {
                estimateTokenCounts(for: child)
                estimatedTokens += child.totalTokenCount
            }
            node.tokenCount = estimatedTokens
            node.totalTokenCount = estimatedTokens
        } else {
            let estimated = max(1, Int(ceil(Double(node.size) / 4.0)))
            node.tokenCount = estimated
            node.totalTokenCount = estimated
        }
    }

    func generateOutput() {
        guard let repository = currentRepository, let fileTree = fileTree else {
            showError("Cannot generate output. Missing repository data.")
            return
        }
        
        isGeneratingOutput = true
        generatedOutput = ""
        log("Starting optimized output generation...")
        
        generateTask?.cancel()
        
        generateTask = Task {
            await Task.yield()
            
            var outputParts: [String] = []
            
            await MainActor.run {
                self.log("Building header and collecting files...")
            }
            
            let treeString = fileTree.generateTreeString()
            let header = """
            Repository: \(repository.fullName)
            Description: \(repository.description ?? "No description")
            Generated at: \(Date())
            
            File Tree:
            \(treeString)
            
            Repository Contents:
            
            """
            outputParts.append(header)
            
            var filesToProcess: [FileNode] = []
            func collectFiles(_ node: FileNode) {
                if node.isDirectory {
                    node.children.forEach(collectFiles)
                } else if node.isIncluded {
                    filesToProcess.append(node)
                }
            }
            collectFiles(fileTree)
            
            await MainActor.run {
                self.log("Fetching content for \(filesToProcess.count) files...")
            }
            
            let startTime = Date()
            
            if repoType == .github {
                await processGitHubFiles(filesToProcess, repository: repository, outputParts: &outputParts)
            } else {
                await processLocalFiles(filesToProcess, outputParts: &outputParts)
            }
            
            let duration = Date().timeIntervalSince(startTime)
            await MainActor.run {
                self.log("Content fetching completed in \(String(format: "%.2f", duration)) seconds")
            }
            
            if Task.isCancelled {
                await MainActor.run {
                    self.log("Output generation cancelled.")
                    self.isGeneratingOutput = false
                }
                return
            }

            await MainActor.run {
                self.log("Generation complete.")
                self.generatedOutput = outputParts.joined(separator: "\n")
                self.isGeneratingOutput = false
                self.selectedTab = 2
                self.checkCurrentOutputBookmarkStatus()
            }
        }
    }
    
    func cancelProcessing() {
        fetchTask?.cancel()
        isLoading = false
        log("Processing cancelled by user.")
    }
    
    func cancelGenerateOutput() {
        generateTask?.cancel()
        isGeneratingOutput = false
        log("Output generation cancelled by user.")
    }
    
    
    private func countFiles(_ node: FileNode) -> Int {
        var count = 0
        if node.isDirectory {
            for child in node.children {
                count += countFiles(child)
            }
        } else {
            count = 1
        }
        return count
    }
    

    
    private func log(_ message: String) {
        print(message)
        verboseLogs.append("[\(Date().formatted(date: .omitted, time: .standard))] \(message)")
    }
    
    private func buildLocalFileTree(path: String) async throws -> FileNode {
        let url = URL(fileURLWithPath: path)
        let rootNode = FileNode(name: url.lastPathComponent, path: path, type: .directory)
        
        var visitedPaths = Set<String>()
        try await processLocalDirectory(url: url, node: rootNode, visitedPaths: &visitedPaths, depth: 0)
        
        estimateTokenCounts(for: rootNode)
        
        return rootNode
    }
    
    private func processLocalDirectory(url: URL, node: FileNode, visitedPaths: inout Set<String>, depth: Int) async throws {
        guard depth < 50 else { 
            log("⚠️ Max recursion depth reached for: \(url.path)")
            return 
        }
        
        guard !Task.isCancelled else { return }
        
        let canonicalPath = url.resolvingSymlinksInPath().path
        guard !visitedPaths.contains(canonicalPath) else {
            log("⚠️ Symlink loop detected, skipping: \(url.path)")
            return
        }
        visitedPaths.insert(canonicalPath)
        
        let fileManager = FileManager.default
        
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: url, 
                includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .isSymbolicLinkKey], 
                options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
            )
            
            for itemURL in contents {
                guard !Task.isCancelled else { return }
                
                let resourceValues = try itemURL.resourceValues(forKeys: [
                    .isDirectoryKey, 
                    .fileSizeKey, 
                    .isSymbolicLinkKey
                ])
                
                let isDirectory = resourceValues.isDirectory ?? false
                let isSymlink = resourceValues.isSymbolicLink ?? false
                let fileSize = resourceValues.fileSize ?? 0
                let fileName = itemURL.lastPathComponent
                
                if shouldSkipPath(fileName, isDirectory: isDirectory) {
                    log("⏭️ Skipping: \(fileName)")
                    continue
                }
                
                let fileType: FileNode.FileType = isSymlink ? .symlink : (isDirectory ? .directory : .file)
                let childNode = FileNode(name: fileName, path: itemURL.path, type: fileType, size: fileSize)
                node.children.append(childNode)
                
                if isDirectory && !isSymlink {
                    try await processLocalDirectory(url: itemURL, node: childNode, visitedPaths: &visitedPaths, depth: depth + 1)
                } else if !isDirectory {
                    let estimatedTokens = max(1, Int(ceil(Double(fileSize) / 4.0)))
                    childNode.tokenCount = estimatedTokens
                    childNode.totalTokenCount = estimatedTokens
                }
                
                if depth == 0 && node.children.count % 100 == 0 {
                    await Task.yield()
                    log("📁 Processed \(node.children.count) items in root directory...")
                }
            }
        } catch {
            log("⚠️ Error reading directory \(url.path): \(error.localizedDescription)")
        }
        
        visitedPaths.remove(canonicalPath)
    }
    
    private func shouldSkipPath(_ name: String, isDirectory: Bool) -> Bool {
        let lowerName = name.lowercased()
        
        let skipDirs = [
            "node_modules", ".git", ".svn", ".hg", ".bzr",
            "build", "dist", "target", "bin", "obj",
            ".gradle", ".maven", ".cargo", ".tox",
            "venv", ".venv", "env", ".env", "__pycache__",
            ".pytest_cache", ".mypy_cache", ".coverage",
            "vendor", "deps", "packages", ".nuget",
            ".vs", ".vscode", ".idea", ".eclipse",
            "Pods", "DerivedData", ".xcode",
            "tmp", "temp", "cache", ".cache",
            "logs", "log", ".DS_Store"
        ]
        
        if isDirectory && skipDirs.contains(lowerName) {
            return true
        }
        
        let skipExtensions = [
            ".exe", ".dll", ".so", ".dylib", ".a", ".lib",
            ".zip", ".tar", ".gz", ".rar", ".7z",
            ".jpg", ".jpeg", ".png", ".gif", ".bmp", ".ico",
            ".mp4", ".avi", ".mov", ".mkv", ".wmv",
            ".mp3", ".wav", ".flac", ".ogg",
            ".pdf", ".doc", ".docx", ".xls", ".xlsx", ".ppt", ".pptx",
            ".sqlite", ".db", ".mdb",
            ".min.js", ".min.css"
        ]
        
        return skipExtensions.contains { lowerName.hasSuffix($0) }
    }
    
    private func processGitHubFiles(_ filesToProcess: [FileNode], repository: Repository, outputParts: inout [String]) async {
        guard let githubService = self.githubService else { return }
        
        var processedFileContents = [(path: String, content: String)](repeating: ("", ""), count: filesToProcess.count)
        
        await withTaskGroup(of: (Int, String, String).self) { group in
            for (index, node) in filesToProcess.enumerated() {
                group.addTask {
                    do {
                        let contentResponse = try await githubService.fetchFileContent(owner: repository.owner.login, repo: repository.name, path: node.path)
                        let fileContent = contentResponse.decodedContent ?? "
                        return (index, node.path, fileContent)
                    } catch {
                        return (index, node.path, "
                    }
                }
            }
            
            for await (index, path, content) in group {
                if Task.isCancelled { break }
                processedFileContents[index] = (path, content)
            }
        }
        
        for (path, content) in processedFileContents {
            let fileSection = """
            ---
            File: \(path)
            ---
            \(content)
            
            """
            outputParts.append(fileSection)
        }
    }
    
    private func processLocalFiles(_ filesToProcess: [FileNode], outputParts: inout [String]) async {
        for (index, node) in filesToProcess.enumerated() {
            if Task.isCancelled { break }
            
            if index % 10 == 0 {
                await MainActor.run {
                    self.log("Processing local file \(index + 1)/\(filesToProcess.count): \(node.name)")
                }
            }
            
            let content: String
            if let existingContent = node.content {
                content = existingContent
            } else {
                content = await loadLocalFileContent(path: node.path, maxSize: 10_000_000)
                
                let tokenCount = tokenService.countTokens(in: content)
                await MainActor.run {
                    node.content = content
                    node.tokenCount = tokenCount
                    node.totalTokenCount = tokenCount
                }
            }
            
            let fileSection = """
            ---
            File: \(node.path)
            ---
            \(content)
            
            """
            outputParts.append(fileSection)
        }
    }
    
    private func loadLocalFileContent(path: String, maxSize: Int) async -> String {
        return await Task.detached {
            do {
                let url = URL(fileURLWithPath: path)
                
                let attributes = try FileManager.default.attributesOfItem(atPath: path)
                if let fileSize = attributes[.size] as? Int64, fileSize > maxSize {
                    return "
                }
                
                let data = try Data(contentsOf: url)
                if data.isEmpty {
                    return "
                }
                
                let printableCount = data.filter { char in
                    return char >= 32 && char <= 126 || char == 9 || char == 10 || char == 13
                }.count
                
                if Double(printableCount) / Double(data.count) < 0.95 {
                    return "
                }
                
                return String(data: data, encoding: .utf8) ?? "
                
            } catch {
                return "
            }
        }.value
    }
    
    func showError(_ message: String) {
        errorMessage = message
        log("ERROR: \(message)")
    }
    
    func removeOutputBookmark(_ output: SavedOutput) {
        savedOutputs.removeAll { $0.id == output.id }
        persistenceService.saveSavedOutputs(savedOutputs)
    }
    
    
    func loadRecentRepository(_ repoPath: String) {
        if repoPath.hasPrefix("http") {
            githubURL = repoPath
            repoType = .github
        } else {
            localPath = repoPath
            repoType = .local
        }
        selectedTab = 0
    }
    
    func addBookmark(_ repoName: String) {
        if !bookmarkedRepositories.contains(repoName) {
            bookmarkedRepositories.append(repoName)
            persistenceService.saveBookmarks(bookmarkedRepositories)
        }
    }
    
    func removeBookmark(_ repoName: String) {
        bookmarkedRepositories.removeAll { $0 == repoName }
        persistenceService.saveBookmarks(bookmarkedRepositories)
    }
    
    func loadBookmarkedRepository(_ repoName: String) {
        githubURL = "https:
        repoType = .github
        selectedTab = 0
    }
    
    func saveCurrentOutput() {
        guard let repository = currentRepository, !generatedOutput.isEmpty else { return }
        
        let fileCount = countSelectedFiles(fileTree)
        let tokenCount = calculateTotalTokens(fileTree)
        
        let savedOutput = SavedOutput(
            name: repository.fullName,
            content: generatedOutput,
            fileCount: fileCount,
            tokenCount: tokenCount,
            createdAt: Date()
        )
        
        savedOutputs.append(savedOutput)
        persistenceService.saveSavedOutputs(savedOutputs)
        log("Output saved: \(repository.fullName)")
    }
    
    func toggleCurrentOutputBookmark() {
        guard let repository = currentRepository, !generatedOutput.isEmpty else { return }
        
        if isCurrentOutputBookmarked {
            savedOutputs.removeAll { $0.name == repository.fullName }
            isCurrentOutputBookmarked = false
            log("Output bookmark removed: \(repository.fullName)")
        } else {
            let fileCount = countSelectedFiles(fileTree)
            let tokenCount = calculateTotalTokens(fileTree)
            
            let savedOutput = SavedOutput(
                name: repository.fullName,
                content: generatedOutput,
                fileCount: fileCount,
                tokenCount: tokenCount,
                createdAt: Date()
            )
            
            savedOutputs.append(savedOutput)
            isCurrentOutputBookmarked = true
            newBookmarksCount += 1
            log("Output bookmarked: \(repository.fullName)")
        }
        
        persistenceService.saveSavedOutputs(savedOutputs)
    }
    
    func checkCurrentOutputBookmarkStatus() {
        guard let repository = currentRepository else {
            isCurrentOutputBookmarked = false
            return
        }
        
        isCurrentOutputBookmarked = savedOutputs.contains { $0.name == repository.fullName }
    }
    
    func resetNewBookmarksCount() {
        newBookmarksCount = 0
    }
    
    func loadSavedOutput(_ savedOutput: SavedOutput) {
        generatedOutput = savedOutput.content
        selectedTab = 2
    }
    
    func deleteSavedOutput(_ savedOutput: SavedOutput) {
        savedOutputs.removeAll { $0.id == savedOutput.id }
        persistenceService.saveSavedOutputs(savedOutputs)
    }
    
    private func countSelectedFiles(_ node: FileNode?) -> Int {
        guard let node = node else { return 0 }
        var count = 0
        if node.isDirectory {
            for child in node.children {
                count += countSelectedFiles(child)
            }
        } else if node.isIncluded {
            count = 1
        }
        return count
    }
    
    private func calculateTotalTokens(_ node: FileNode?) -> Int {
        guard let node = node else { return 0 }
        var total = 0
        if node.isDirectory {
            for child in node.children {
                total += calculateTotalTokens(child)
            }
        } else if node.isIncluded {
            total += node.tokenCount
        }
        return total
    }
    
    private func addToRecents(_ repoPath: String) {
        recentRepositories.removeAll { $0.path == repoPath }
        let newRecent = RecentRepository(path: repoPath, type: repoType == .github ? .github : .local)
        recentRepositories.insert(newRecent, at: 0)
        
        if recentRepositories.count > 10 {
            recentRepositories.removeLast()
        }
        
        persistenceService.saveRecents(recentRepositories)
    }
    
    func deleteRecentRepository(_ repo: RecentRepository) {
        recentRepositories.removeAll { $0.id == repo.id }
        persistenceService.saveRecents(recentRepositories)
    }
}