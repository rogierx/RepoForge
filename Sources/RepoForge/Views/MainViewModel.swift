//
//  MainViewModel.swift
//  RepoForge
//
//  Created by Rogier on 2025-07-18.
//

import Foundation
import SwiftUI
import Combine

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
        
        try await processLocalDirectory(url: url, node: rootNode)
        return rootNode
    }
    
    private func processLocalDirectory(url: URL, node: FileNode) async throws {
        let fileManager = FileManager.default
        let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])
        
        for itemURL in contents {
            let resourceValues = try itemURL.resourceValues(forKeys: [.isDirectoryKey])
            let isDirectory = resourceValues.isDirectory ?? false
            
            let fileType: FileNode.FileType = isDirectory ? .directory : .file
            let childNode = FileNode(name: itemURL.lastPathComponent, path: itemURL.path, type: fileType)
            node.children.append(childNode)
            
            if isDirectory {
                try await processLocalDirectory(url: itemURL, node: childNode)
            } else {
                // Read file content and count tokens
                if let content = try? String(contentsOf: itemURL) {
                    childNode.content = content
                    let tokenCount = tokenService.countTokens(in: content)
                    childNode.addTokens(tokenCount)
                }
            }
        }
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
        for node in filesToProcess {
            if Task.isCancelled { break }
            
            let content = node.content ?? {
                if let loadedContent = try? String(contentsOfFile: node.path) {
                    return loadedContent
                } else {
                    return "// Error loading local file content"
                }
            }()
            
            let fileSection = """
            ---
            File: \(node.path)
            ---
            \(content)
            
            """
            outputParts.append(fileSection)
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        log("ERROR: \(message)")
    }
} 