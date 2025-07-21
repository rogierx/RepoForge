//
//  MainViewModel.swift
//  RepoForge
//
//  Created by Rogier on 2025-07-18.
//

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

@MainActor
class MainViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
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
    @Published var verboseLogs: [String] = []
    
    // MARK: - Sidebar Features
    @Published var recentRepositories: [String] = []
    @Published var bookmarkedRepositories: [String] = []
    @Published var savedOutputs: [SavedOutput] = []
    
    // MARK: - Services
    
    private var githubService: GitHubService?
    let tokenService = TokenCountingService()
    private let outputService: OutputService
    private let persistenceService = PersistenceService()
    
    // MARK: - Private State
    
    private var fetchTask: Task<Void, Never>?
    private var generateTask: Task<Void, Never>?
    
    // MARK: - Init & Setup
    
    init() {
        self.outputService = OutputService(tokenService: self.tokenService)
        loadPersistedData()
    }
    
    private func loadPersistedData() {
        self.githubURL = persistenceService.retrieveGitHubURL() ?? ""
        self.accessToken = persistenceService.retrieveGitHubToken() ?? ""
        if !githubURL.isEmpty { self.saveURL = true }
        if !accessToken.isEmpty { self.saveToken = true }
        
        // Load sidebar data
        self.recentRepositories = persistenceService.loadRecents()
        self.bookmarkedRepositories = persistenceService.loadBookmarks()
        self.savedOutputs = persistenceService.loadSavedOutputs()
    }
    
    // MARK: - Core Logic
    
    func processRepository() {
        // Validate based on repo type
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
        
        // Cancel any existing task.
        fetchTask?.cancel()
        
        // Reset state for a new run.
        isLoading = true
        errorMessage = nil
        fileTree = nil
        currentRepository = nil
        verboseLogs.removeAll()
        
        if repoType == .github {
            // GitHub repository processing
            let service = GitHubService(token: accessToken)
            self.githubService = service
            
            // Start the fully asynchronous processing pipeline.
            fetchTask = Task(priority: .userInitiated) {
                do {
                    // --- PHASE 1: Build Structure (Fast) ---
                    log("Fetching repository metadata...")
                    let repository = try await service.fetchRepository(url: githubURL)
                    if Task.isCancelled { return }
                    
                    await MainActor.run {
                        self.currentRepository = repository
                    }
                    
                    log("Building file tree structure...")
                    // This now ONLY builds the node hierarchy, without content. It will be very fast.
                    let rootNode = try await service.buildFileTree(owner: repository.owner.login, repo: repository.name, includeVirtualEnvironments: includeVirtualEnvironments)
                    if Task.isCancelled { return }

                    // OPTIONAL: Estimate tokens based on file size for a preliminary view.
                    log("Estimating token counts...")
                    estimateTokenCounts(for: rootNode)

                    // Sort the tree based on initial estimates
                    tokenService.sortNodesByTokenCount(rootNode)
                    
                    log("Structure built. Updating UI...")
                    await MainActor.run {
                        self.fileTree = rootNode
                        self.isLoading = false // Stop loading indicator HERE
                        self.selectedTab = 1   // Switch to the file tree view
                        self.addToRecents(self.githubURL) // Add to recents
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
            // Local repository processing
            fetchTask = Task(priority: .userInitiated) {
                do {
                    log("Processing local repository...")
                    
                    // Create a mock repository for local processing
                    let localRepoName = URL(fileURLWithPath: localPath).lastPathComponent
                    let mockRepo = Repository(
                        id: 0,
                        name: localRepoName,
                        fullName: localRepoName,
                        description: "Local repository",
                        htmlUrl: "file://\(localPath)",
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
                        self.addToRecents(self.localPath) // Add to recents
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
    
    // New helper method to give users a rough idea of token counts without fetching content.
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
            // A common heuristic: ~4 characters per token.
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
        
        // Immediately update UI to show generating state
        isGeneratingOutput = true
        generatedOutput = ""
        log("Starting optimized output generation...")
        
        // Cancel any existing generation task
        generateTask?.cancel()
        
        generateTask = Task {
            // Yield immediately to allow UI update
            await Task.yield()
            
            var outputParts: [String] = []
            
            await MainActor.run {
                self.log("Building header and collecting files...")
            }
            
            // 1. Generate Header (moved to background)
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
            
            // 2. Collect all file nodes to be included
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
            
            // 3. Process files based on repo type
            if repoType == .github {
                // GitHub repository processing with concurrent content fetching
                await processGitHubFiles(filesToProcess, repository: repository, outputParts: &outputParts)
            } else {
                // Local repository processing
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

            // 4. Assemble the final output
            await MainActor.run {
                self.log("Generation complete.")
                self.generatedOutput = outputParts.joined(separator: "\n")
                self.isGeneratingOutput = false
                self.selectedTab = 2 // Switch to output view
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
    
    // MARK: - UI Helpers
    
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
        
        // Use visited paths to prevent infinite loops from symlinks
        var visitedPaths = Set<String>()
        try await processLocalDirectory(url: url, node: rootNode, visitedPaths: &visitedPaths, depth: 0)
        
        // Estimate token counts without loading content
        estimateTokenCounts(for: rootNode)
        
        return rootNode
    }
    
    private func processLocalDirectory(url: URL, node: FileNode, visitedPaths: inout Set<String>, depth: Int) async throws {
        // Safety checks
        guard depth < 50 else { 
            log("⚠️ Max recursion depth reached for: \(url.path)")
            return 
        }
        
        guard !Task.isCancelled else { return }
        
        // Prevent infinite loops from symlinks
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
                
                // Skip dangerous directories and files
                if shouldSkipPath(fileName, isDirectory: isDirectory) {
                    log("⏭️ Skipping: \(fileName)")
                    continue
                }
                
                let fileType: FileNode.FileType = isSymlink ? .symlink : (isDirectory ? .directory : .file)
                let childNode = FileNode(name: fileName, path: itemURL.path, type: fileType, size: fileSize)
                node.children.append(childNode)
                
                if isDirectory && !isSymlink {
                    // Only recurse into real directories, not symlinks
                    try await processLocalDirectory(url: itemURL, node: childNode, visitedPaths: &visitedPaths, depth: depth + 1)
                } else if !isDirectory {
                    // DON'T load content here - do it lazily during output generation
                    // Just estimate tokens based on file size
                    let estimatedTokens = max(1, Int(ceil(Double(fileSize) / 4.0)))
                    childNode.tokenCount = estimatedTokens
                    childNode.totalTokenCount = estimatedTokens
                }
                
                // Yield control periodically to prevent UI freezing
                if depth == 0 && node.children.count % 100 == 0 {
                    await Task.yield()
                    log("📁 Processed \(node.children.count) items in root directory...")
                }
            }
        } catch {
            log("⚠️ Error reading directory \(url.path): \(error.localizedDescription)")
        }
        
        // Remove from visited paths when exiting (for sibling directories)
        visitedPaths.remove(canonicalPath)
    }
    
    private func shouldSkipPath(_ name: String, isDirectory: Bool) -> Bool {
        let lowerName = name.lowercased()
        
        // Skip common problematic directories
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
        
        // Skip large binary files and problematic files
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
                        let fileContent = contentResponse.decodedContent ?? "// Failed to decode content"
                        return (index, node.path, fileContent)
                    } catch {
                        return (index, node.path, "// Error loading content: \(error.localizedDescription)")
                    }
                }
            }
            
            for await (index, path, content) in group {
                if Task.isCancelled { break }
                processedFileContents[index] = (path, content)
            }
        }
        
        // Add file contents to output
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
            
            // Update progress
            if index % 10 == 0 {
                await MainActor.run {
                    self.log("Processing local file \(index + 1)/\(filesToProcess.count): \(node.name)")
                }
            }
            
            // Load content lazily - only when generating output
            let content: String
            if let existingContent = node.content {
                content = existingContent
            } else {
                // Safely load file content with size limits
                content = await loadLocalFileContent(path: node.path, maxSize: 10_000_000) // 10MB limit
                
                // Count tokens and update node
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
                
                // Check file size first
                let attributes = try FileManager.default.attributesOfItem(atPath: path)
                if let fileSize = attributes[.size] as? Int64, fileSize > maxSize {
                    return "// File too large (\(fileSize) bytes) - skipped for performance"
                }
                
                // Check if file is likely binary
                let data = try Data(contentsOf: url)
                if data.isEmpty {
                    return "// Empty file"
                }
                
                // Simple binary check - if more than 5% non-printable chars, treat as binary
                let printableCount = data.filter { char in
                    return char >= 32 && char <= 126 || char == 9 || char == 10 || char == 13
                }.count
                
                if Double(printableCount) / Double(data.count) < 0.95 {
                    return "// Binary file - content not included"
                }
                
                return String(data: data, encoding: .utf8) ?? "// Could not decode file as UTF-8"
                
            } catch {
                return "// Error loading file: \(error.localizedDescription)"
            }
        }.value
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        log("ERROR: \(message)")
    }
    
    // MARK: - Sidebar Functionality
    
    func loadRecentRepository(_ repoPath: String) {
        if repoPath.hasPrefix("http") {
            // GitHub URL
            githubURL = repoPath
            repoType = .github
        } else {
            // Local path
            localPath = repoPath
            repoType = .local
        }
        selectedTab = 0 // Switch to Main tab
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
        githubURL = "https://github.com/\(repoName)"
        repoType = .github
        selectedTab = 0 // Switch to Main tab
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
    
    func loadSavedOutput(_ savedOutput: SavedOutput) {
        generatedOutput = savedOutput.content
        selectedTab = 2 // Switch to Output tab
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
        // Remove if already exists and add to front
        recentRepositories.removeAll { $0 == repoPath }
        recentRepositories.insert(repoPath, at: 0)
        
        // Keep only last 10 items
        if recentRepositories.count > 10 {
            recentRepositories = Array(recentRepositories.prefix(10))
        }
        
        persistenceService.saveRecents(recentRepositories)
    }
} 