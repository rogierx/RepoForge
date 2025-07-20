import Foundation

class OutputService: @unchecked Sendable {
    private let tokenService: TokenCountingService
    
    init(tokenService: TokenCountingService) {
        self.tokenService = tokenService
    }
    
    // STREAMING: Generate output on-demand without loading all content into memory
    func generateOutputStreaming(
        for repository: Repository,
        fileTree: FileNode,
        githubService: GitHubService,
        progressHandler: @Sendable @escaping (Double, String) async -> Void
    ) async -> String {
        
        await progressHandler(0.05, "[STREAM] Starting streaming generation...")
        
        // Build header immediately
        let headerStart = Date()
        let statistics = tokenService.calculateStatistics(for: fileTree)
        var output = generateHeader(repository: repository, statistics: statistics)
        output.append("\n")
        let headerTime = Date().timeIntervalSince(headerStart)
        await progressHandler(0.1, "[PERF] Header generated in \(String(format: "%.3f", headerTime * 1000))ms")
        
        // Generate file tree structure
        let treeStart = Date()
        output.append("File Tree Structure:\n")
        output.append(fileTree.generateTreeString())
        output.append("\n")
        let treeTime = Date().timeIntervalSince(treeStart)
        await progressHandler(0.15, "[PERF] Tree generated in \(String(format: "%.3f", treeTime * 1000))ms")
        
        // STREAMING: Collect file references (no content yet)
        await progressHandler(0.2, "[STREAM] Collecting file references...")
        let collectStart = Date()
        
        var fileRefs: [(node: FileNode, estimatedTokens: Int)] = []
        collectFileReferences(fileTree, into: &fileRefs)
        
        // Sort by estimated token count
        fileRefs.sort { $0.estimatedTokens > $1.estimatedTokens }
        
        let collectTime = Date().timeIntervalSince(collectStart)
        await progressHandler(0.25, "[PERF] Collected \(fileRefs.count) file refs in \(String(format: "%.3f", collectTime * 1000))ms")
        
        // STREAMING: Generate content section by section
        output.append("Repository Contents:\n\n")
        let totalFiles = fileRefs.count
        
        await progressHandler(0.3, "[STREAM] Processing files with lazy loading...")
        
        let processStart = Date()
        var processedFiles = 0
        
        // Process files one by one with content loading on-demand
        for (index, fileRef) in fileRefs.enumerated() {
            let fileNode = fileRef.node
            
            // Load content on-demand only if not already loaded
            if fileNode.content == nil {
                await progressHandler(0.3 + (0.6 * Double(index) / Double(totalFiles)), "[LOADING] Loading content for \(fileNode.path)")
                await githubService.loadContent(
                    for: fileNode,
                    owner: repository.owner.login,
                    repo: repository.name
                )
            }
            
            // Generate section for this file
            let section = generateFileSection(
                path: fileNode.path,
                content: fileNode.content ?? "// Content not available",
                tokens: fileNode.tokenCount,
                index: index + 1,
                total: totalFiles
            )
            
            output.append(section)
            output.append("\n\n")
            
            processedFiles += 1
            
            // Update progress more frequently for responsiveness
            if processedFiles % 5 == 0 || processedFiles == totalFiles {
                let progress = 0.3 + (0.65 * Double(processedFiles) / Double(totalFiles))
                await progressHandler(progress, "[STREAM] Processed \(processedFiles)/\(totalFiles) files")
            }
            
            // Check for cancellation
            if Task.isCancelled {
                await progressHandler(1.0, "[CANCELLED] Output generation cancelled")
                return "// Output generation was cancelled"
            }
            
            // Yield control frequently to prevent UI blocking
            await Task.yield()
        }
        
        let processTime = Date().timeIntervalSince(processStart)
        await progressHandler(0.98, "[PERF] Streaming generation completed in \(String(format: "%.3f", processTime * 1000))ms")
        
        await progressHandler(1.0, "[COMPLETE] Output ready (\(output.count) chars)")
        
        return output
    }
    
    // LIGHTWEIGHT: Collect file references without loading content
    private func collectFileReferences(_ node: FileNode, into refs: inout [(node: FileNode, estimatedTokens: Int)]) {
        if node.isDirectory {
            for child in node.children where child.isIncluded {
                collectFileReferences(child, into: &refs)
            }
        } else if node.isIncluded {
            let estimatedTokens = node.tokenCount > 0 ? node.tokenCount : max(1, node.size / 4)
            refs.append((node: node, estimatedTokens: estimatedTokens))
        }
    }
    
    // FAST: Generate file section without heavy processing
    private func generateFileSection(path: String, content: String, tokens: Int, index: Int, total: Int) -> String {
        return """
        ---
        File: \(path) (Tokens: \(tokens), File: \(index)/\(total))
        ---
        \(content)
        """
    }
    
    // LIGHTWEIGHT: Generate header with pre-calculated statistics
    private func generateHeader(repository: Repository, statistics: ProcessingStatistics) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        return """
        Repository: \(repository.fullName)
        Description: \(repository.description ?? "No description available")
        Default Branch: \(repository.defaultBranch)
        Language: \(repository.language ?? "Mixed")
        Total Files: \(statistics.totalFiles)
        Total Tokens: \(statistics.totalTokens)
        Generated: \(formatter.string(from: Date()))
        """
    }
    
    // OPTIMIZED: Estimate output size without loading content
    private func estimateOutputSize(_ fileTree: FileNode) -> Int {
        var totalFiles = 0
        var estimatedSize = 0
        
        func estimate(_ node: FileNode) {
            if node.isDirectory {
                node.children.filter(\.isIncluded).forEach(estimate)
            } else if node.isIncluded {
                totalFiles += 1
                estimatedSize += node.size + 200 // Add overhead for formatting
            }
        }
        
        estimate(fileTree)
        return estimatedSize + (totalFiles * 100) + 10000 // Buffer for headers and formatting
    }
} 