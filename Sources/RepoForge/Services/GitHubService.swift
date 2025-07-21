
import Foundation

@MainActor
class GitHubService: ObservableObject {
    @Published var isLoading = false
    @Published var progress = 0.0
    @Published var currentStatus = ""
    @Published var rateLimit: GitHubRateLimit?
    
    private let config: GitHubAPIConfig
    private let session: URLSession
    private let gitIgnoreService = GitIgnoreService()
    
    init(token: String) {
        self.config = GitHubAPIConfig(token: token)
        
        let configuration = URLSessionConfiguration.default
        configuration.httpMaximumConnectionsPerHost = 8
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 120
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil
        
        self.session = URLSession(configuration: configuration)
    }
    
    func fetchRepository(url: String) async throws -> Repository {
        guard let githubURL = GitHubURL(urlString: url) else {
            throw GitHubAPIError(message: "Invalid GitHub URL format", documentation_url: nil, statusCode: 422)
        }
        
        currentStatus = "Loading repository information..."
        let endpoint = "\(config.baseURL)/repos/\(githubURL.fullName)"
        return try await performRequest(endpoint: endpoint, type: Repository.self)
    }
    
    func buildFileTree(owner: String, repo: String, includeVirtualEnvironments: Bool) async throws -> FileNode {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                Task {
                    do {
                        let rootNode = try await self.buildStructure(owner: owner, repo: repo, includeVirtualEnvironments: includeVirtualEnvironments)
                        continuation.resume(returning: rootNode)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }

    private func buildStructure(owner: String, repo: String, includeVirtualEnvironments: Bool) async throws -> FileNode {
        await MainActor.run { currentStatus = "Fetching repository tree..." }
        
        
        do {
            let gitTree = try await fetchRepositoryTree(owner: owner, repo: repo)
            await MainActor.run { currentStatus = "Processing \(gitTree.tree.count) items..." }
            return self.buildTreeFromGitTree(gitTree: gitTree, repo: repo, includeVirtualEnvironments: includeVirtualEnvironments)
        } catch {
            await MainActor.run { currentStatus = "Fallback: Using Contents API..." }
            return try await buildTreeFromContentsAPI(owner: owner, repo: repo, includeVirtualEnvironments: includeVirtualEnvironments)
        }
    }
    
    private func loadGitIgnoreFile(owner: String, repo: String) async {
        do {
            let gitIgnoreContent = try await fetchFileContent(owner: owner, repo: repo, path: ".gitignore")
            if let content = gitIgnoreContent.content, let encoding = gitIgnoreContent.encoding {
                let decodedContent: String
                if encoding == "base64", let data = Data(base64Encoded: content.replacingOccurrences(of: "\n", with: "")) {
                    decodedContent = String(data: data, encoding: .utf8) ?? ""
                } else {
                    decodedContent = content
                }
                gitIgnoreService.parseGitIgnore(content: decodedContent)
                await MainActor.run { currentStatus = "Loaded .gitignore with \(gitIgnoreService.getActivePatterns().count) patterns" }
            }
        } catch {
            await MainActor.run { currentStatus = "No .gitignore file found, using default filtering" }
        }
    }
    
    private func buildTreeFromGitTree(gitTree: GitTree, repo: String, includeVirtualEnvironments: Bool) -> FileNode {
        let root = FileNode(name: repo, path: "", type: .directory)
        var pathToNode: [String: FileNode] = ["": root]
        
        let sortedItems = gitTree.tree.sorted { $0.path.count < $1.path.count }
        
        
        for item in sortedItems {
            let fileName = URL(fileURLWithPath: item.path).lastPathComponent
            let isDirectory = item.type != "blob"
            
            let shouldInclude = !FileNode.shouldExcludeByDefault(
                path: item.path,
                name: fileName,
                includeVirtualEnvironments: includeVirtualEnvironments
            )
            
            if !shouldInclude {
                continue
            }
            
            let node = FileNode(
                name: fileName,
                path: item.path,
                type: isDirectory ? .directory : .file,
                size: item.size ?? 0
            )
            
            node.isIncluded = shouldInclude
            
            let parentPath = String(item.path.split(separator: "/").dropLast().joined(separator: "/"))
            if let parent = pathToNode[parentPath] {
                parent.addChild(node)
            }
            pathToNode[item.path] = node
        }
        
        return root
    }
    
    private func buildTreeFromContentsAPI(owner: String, repo: String, includeVirtualEnvironments: Bool) async throws -> FileNode {
        let root = FileNode(name: repo, path: "", type: .directory)
        try await buildContentsRecursive(owner: owner, repo: repo, path: "", parentNode: root, includeVirtualEnvironments: includeVirtualEnvironments, depth: 0)
        return root
    }
    
    private func buildContentsRecursive(owner: String, repo: String, path: String, parentNode: FileNode, includeVirtualEnvironments: Bool, depth: Int) async throws {
        guard depth < 10 else { return }
        
        let contents = try await fetchContents(owner: owner, repo: repo, path: path)
        
        for item in contents {
            let node = FileNode(
                name: item.name,
                path: item.path,
                type: item.type.rawValue == "file" ? .file : .directory,
                size: item.size
            )
            node.updateInclusionBasedOnSettings(includeVirtualEnvironments: includeVirtualEnvironments)
            parentNode.addChild(node)
            
            if item.type.rawValue == "dir" {
                try await buildContentsRecursive(owner: owner, repo: repo, path: item.path, parentNode: node, includeVirtualEnvironments: includeVirtualEnvironments, depth: depth + 1)
            }
        }
    }
    
    func loadContent(for fileNode: FileNode, owner: String, repo: String) async {
        guard fileNode.type == .file, fileNode.content == nil else { return }
        
        if fileNode.size > 2_000_000 {
            fileNode.content = "
            return
        }
        
        do {
            let content = try await fetchFileContent(owner: owner, repo: repo, path: fileNode.path)
            if let fileContent = content.content, let encoding = content.encoding {
                if encoding == "base64", let data = Data(base64Encoded: fileContent.replacingOccurrences(of: "\n", with: "")) {
                    fileNode.content = String(data: data, encoding: .utf8) ?? "
                } else {
                    fileNode.content = fileContent
                }
            } else {
                fileNode.content = "
            }
        } catch {
            fileNode.content = "
        }
    }
    
    
    private func fetchContents(owner: String, repo: String, path: String) async throws -> [RepositoryContent] {
        let endpoint = "\(config.baseURL)/repos/\(owner)/\(repo)/contents/\(path)"
        return try await performRequest(endpoint: endpoint, type: [RepositoryContent].self)
    }
    
    private func fetchRepositoryTree(owner: String, repo: String, branch: String = "main") async throws -> GitTree {
        let endpoint = "\(config.baseURL)/repos/\(owner)/\(repo)/git/trees/\(branch)?recursive=1"
        return try await performRequest(endpoint: endpoint, type: GitTree.self)
    }
    
    func fetchFileContent(owner: String, repo: String, path: String) async throws -> RepositoryContent {
        let endpoint = "\(config.baseURL)/repos/\(owner)/\(repo)/contents/\(path)"
        return try await performRequest(endpoint: endpoint, type: RepositoryContent.self)
    }
    
    private func performRequest<T: Decodable>(endpoint: String, type: T.Type) async throws -> T {
        guard let url = URL(string: endpoint) else {
            throw GitHubAPIError(message: "Invalid URL", documentation_url: nil, statusCode: 400)
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(config.token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubAPIError(message: "Invalid response from server", documentation_url: nil, statusCode: 500)
        }
        
        if let xRateLimit = httpResponse.value(forHTTPHeaderField: "X-RateLimit-Limit"),
           let xRateLimitRemaining = httpResponse.value(forHTTPHeaderField: "X-RateLimit-Remaining"),
           let xRateLimitReset = httpResponse.value(forHTTPHeaderField: "X-RateLimit-Reset"),
           let limit = Int(xRateLimit),
           let remaining = Int(xRateLimitRemaining),
           let reset = Int(xRateLimitReset) {
            
            DispatchQueue.main.async {
                self.rateLimit = GitHubRateLimit(limit: limit, remaining: remaining, reset: reset, used: limit - remaining)
            }
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            var error = try? JSONDecoder().decode(GitHubAPIError.self, from: data)
            error?.statusCode = httpResponse.statusCode
            throw error ?? GitHubAPIError(message: "An unknown error occurred", documentation_url: nil, statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

private struct GitHubErrorResponse: Codable {
    let message: String
    let documentation_url: String?
}

private func formatBytes(_ bytes: Int) -> String {
    let formatter = ByteCountFormatter()
    formatter.countStyle = .file
    return formatter.string(fromByteCount: Int64(bytes))
} 