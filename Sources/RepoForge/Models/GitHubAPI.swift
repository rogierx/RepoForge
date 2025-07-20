import Foundation

// MARK: - Core API Models

struct Repository: Codable, Identifiable {
    let id: Int
    let name: String
    let fullName: String
    let description: String?
    let htmlUrl: String
    let defaultBranch: String
    let size: Int
    let language: String?
    let owner: Owner
    
    struct Owner: Codable {
        let login: String
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, size, language, owner
        case fullName = "full_name"
        case htmlUrl = "html_url"
        case defaultBranch = "default_branch"
    }
}

struct RepositoryContent: Codable {
    let name: String
    let path: String
    let type: ContentType
    let size: Int
    let downloadUrl: String?
    let content: String?
    let encoding: String?
    
    enum ContentType: String, Codable {
        case file, dir
    }
    
    enum CodingKeys: String, CodingKey {
        case name, path, type, size, content, encoding
        case downloadUrl = "download_url"
    }
}

struct GitTree: Codable {
    let tree: [GitTreeEntry]
}

struct GitTreeEntry: Codable {
    let path: String
    let type: String
    let size: Int?
}

// MARK: - API Error Handling

struct GitHubAPIError: Error, Codable {
    let message: String
    let documentation_url: String?
    
    // Adding statusCode to be able to handle it, but it's not in the JSON response.
    var statusCode: Int?
}

// MARK: - API Configuration & Rate Limiting

struct GitHubAPIConfig {
    let token: String
    let baseURL = "https://api.github.com"
}

struct GitHubRateLimit: Codable {
    let limit: Int
    let remaining: Int
    let reset: Int
    let used: Int
}

// MARK: - URL Parsing Utility

struct GitHubURL {
    let owner: String
    let repo: String
    
    var fullName: String {
        return "\(owner)/\(repo)"
    }
    
    init?(urlString: String) {
        let pattern = #"github\.com/([^/]+)/([^/]+)"#
        let regex = try? NSRegularExpression(pattern: pattern)
        
        if let match = regex?.firstMatch(in: urlString, range: NSRange(urlString.startIndex..., in: urlString)) {
            if let ownerRange = Range(match.range(at: 1), in: urlString),
               let repoRange = Range(match.range(at: 2), in: urlString) {
                self.owner = String(urlString[ownerRange])
                self.repo = String(urlString[repoRange]).replacingOccurrences(of: ".git", with: "")
                return
            }
        }
        return nil
    }
} 