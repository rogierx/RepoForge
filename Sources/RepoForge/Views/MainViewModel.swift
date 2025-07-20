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
        guard !githubURL.isEmpty, !accessToken.isEmpty else {
            showError("URL and Access Token are required.")
            return
        }
        
        // Cancel any existing task.
        fetchTask?.cancel()
        
        // Reset state for a new run.
        isLoading = true
        errorMessage = nil
        fileTree = nil
        currentRepository = nil
        verboseLogs.removeAll()
        
        // Add ASCII banner
        let asciiBanner = """
        ██████╗ ███████╗██████╗  ██████╗ ███████╗ ██████╗ ██████╗  ██████╗ ███████╗
        ██╔══██╗██╔════╝██╔══██╗██╔═══██╗██╔════╝██╔═══██╗██╔══██╗██╔════╝ ██╔════╝
        ██████╔╝█████╗  ██████╔╝██║   ██║█████╗  ██║   ██║██████╔╝██║  ███╗█████╗  
        ██╔══██╗██╔══╝  ██╔═══╝ ██║   ██║██╔══╝  ██║   ██║██╔══██╗██║   ██║██╔══╝  
        ██║  ██║███████╗██║     ╚██████╔╝██║     ╚██████╔╝██║  ██║╚██████╔╝███████╗
        ╚═╝  ╚═╝╚══════╝╚═╝      ╚═════╝ ╚═╝      ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝
        """
        log(asciiBanner)
        log("")
        
        let service = GitHubService(token: accessToken)
        self.githubService = service
        
        // Start the fully asynchronous processing pipeline.
        fetchTask = Task(priority: .userInitiated) {
            do {
                // 1. Fetch repository metadata.
                log("Fetching repository metadata...")
                let repository = try await service.fetchRepository(url: githubURL)
                if Task.isCancelled { return }
                
                // Set the repository on the main thread.
                await MainActor.run {
                    self.currentRepository = repository
                }
                
                // 2. Build file tree structure in the background.
                log("Building file tree structure...")
                let rootNode = try await service.buildFileTree(owner: repository.owner.login, repo: repository.name, includeVirtualEnvironments: includeVirtualEnvironments)
                if Task.isCancelled { return }
                
                // 3. Load content and count tokens in the background.
                log("Loading content and calculating token counts...")
                await loadContentAndCountTokens(for: rootNode, service: service)
                if Task.isCancelled { return }
                
                // 4. Sort the tree by token count.
                log("Sorting file tree by token count...")
                tokenService.sortNodesByTokenCount(rootNode)
                if Task.isCancelled { return }
                
                // 5. Update the UI once with the final, processed data.
                log("Processing complete. Updating UI...")
                DispatchQueue.main.async {
                    self.fileTree = rootNode
                    self.isLoading = false
                    self.selectedTab = 1
                }
                
            } catch {
                if !Task.isCancelled {
                    showError("Failed to process repository: \(error.localizedDescription)")
                }
                isLoading = false
            }
        }
    }
    
    private func loadContentAndCountTokens(for node: FileNode, service: GitHubService) async {
        guard let repo = self.currentRepository else { return }
        
        await withTaskGroup(of: Void.self) { group in
            func traverse(node: FileNode) {
                if node.isDirectory {
                    for child in node.children {
                        traverse(node: child)
                    }
                } else {
                    group.addTask {
                        await service.loadContent(for: node, owner: repo.owner.login, repo: repo.name)
                        if let content = node.content {
                            let tokenCount = self.tokenService.countTokens(in: content)
                            node.addTokens(tokenCount)
                        }
                    }
                }
            }
            traverse(node: node)
        }
    }

    func generateOutput() {
        guard let repository = currentRepository,
              let fileTree = fileTree else {
            showError("No repository data available to generate output")
            return
        }
        
        log("Starting simple output generation...")
        isGeneratingOutput = true
        generatedOutput = ""
        
        // Cancel any existing generation task
        generateTask?.cancel()
        
        generateTask = Task {
            await MainActor.run {
                self.log("Generating simplified output...")
            }
            
            // Create a very simple output to avoid freezing
            let output = """
            Repository: \(repository.fullName)
            Description: \(repository.description ?? "No description")
            Generated at: \(Date())
            
            File Tree:
            \(fileTree.generateTreeString())
            
            Status: Output generation working! 
            Files in repository: \(countFiles(fileTree))
            """
            
            // Yield control to prevent blocking
            await Task.yield()
            
            await MainActor.run {
                self.log("Output generated successfully, length: \(output.count)")
                self.generatedOutput = output
                self.isGeneratingOutput = false
                self.log("Output generation completed!")
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
    
    private func showError(_ message: String) {
        errorMessage = message
        log("ERROR: \(message)")
    }
} 