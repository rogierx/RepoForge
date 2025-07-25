import Foundation

class PersistenceService: ObservableObject {
    private let userDefaults = UserDefaults.standard
    
    
    func storeGitHubToken(_ token: String) {
        userDefaults.set(token, forKey: "github-token")
    }
    
    func retrieveGitHubToken() -> String? {
        return userDefaults.string(forKey: "github-token")
    }
    
    func deleteGitHubToken() {
        userDefaults.removeObject(forKey: "github-token")
    }
    
    func storeGitHubURL(_ url: String) {
        userDefaults.set(url, forKey: "github-url")
    }
    
    func retrieveGitHubURL() -> String? {
        return userDefaults.string(forKey: "github-url")
    }
    
    func deleteGitHubURL() {
        userDefaults.removeObject(forKey: "github-url")
    }
    
    
    func storeRecentRepository(_ repo: RecentRepository) {
        var recentRepos = getRecentRepositories()
        
        recentRepos.removeAll { $0.path == repo.path }
        
        recentRepos.insert(repo, at: 0)
        
        recentRepos = Array(recentRepos.prefix(10))
        
        do {
            let data = try JSONEncoder().encode(recentRepos)
            userDefaults.set(data, forKey: "recentRepositories")
        } catch {
            print("Failed to store recent repository: \(error)")
        }
    }
    
    func getRecentRepositories() -> [RecentRepository] {
        guard let data = userDefaults.data(forKey: "recentRepositories") else {
            return []
        }
        
        do {
            return try JSONDecoder().decode([RecentRepository].self, from: data)
        } catch {
            print("Failed to decode recent repositories: \(error)")
            return []
        }
    }
    
    func storeBookmark(_ bookmark: Bookmark) {
        var bookmarks = getBookmarks()
        
        bookmarks.removeAll { $0.fullName == bookmark.fullName }
        
        bookmarks.append(bookmark)
        
        bookmarks.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        
        do {
            let data = try JSONEncoder().encode(bookmarks)
            userDefaults.set(data, forKey: "bookmarks")
        } catch {
            print("Failed to store bookmark: \(error)")
        }
    }
    
    func getBookmarks() -> [Bookmark] {
        guard let data = userDefaults.data(forKey: "bookmarks") else {
            return []
        }
        
        do {
            return try JSONDecoder().decode([Bookmark].self, from: data)
        } catch {
            print("Failed to decode bookmarks: \(error)")
            return []
        }
    }
    
    func removeBookmark(fullName: String) {
        var bookmarks = getBookmarks()
        bookmarks.removeAll { $0.fullName == fullName }
        
        do {
            let data = try JSONEncoder().encode(bookmarks)
            userDefaults.set(data, forKey: "bookmarks")
        } catch {
            print("Failed to remove bookmark: \(error)")
        }
    }
    
    
    func storeOutputBookmark(_ bookmark: OutputBookmark) {
        var bookmarks = getOutputBookmarks()
        
        bookmarks.removeAll { $0.repositoryName == bookmark.repositoryName && Calendar.current.isDate($0.createdAt, equalTo: bookmark.createdAt, toGranularity: .minute) }
        
        bookmarks.insert(bookmark, at: 0)
        
        bookmarks = Array(bookmarks.prefix(20))
        
        do {
            let data = try JSONEncoder().encode(bookmarks)
            userDefaults.set(data, forKey: "outputBookmarks")
        } catch {
            print("Failed to store output bookmark: \(error)")
        }
    }
    
    func getOutputBookmarks() -> [OutputBookmark] {
        guard let data = userDefaults.data(forKey: "outputBookmarks") else {
            return []
        }
        
        do {
            return try JSONDecoder().decode([OutputBookmark].self, from: data)
        } catch {
            print("Failed to load output bookmarks: \(error)")
            return []
        }
    }
    
    func removeOutputBookmark(_ bookmark: OutputBookmark) {
        var bookmarks = getOutputBookmarks()
        bookmarks.removeAll { $0.id == bookmark.id }
        
        do {
            let data = try JSONEncoder().encode(bookmarks)
            userDefaults.set(data, forKey: "outputBookmarks")
        } catch {
            print("Failed to remove output bookmark: \(error)")
        }
    }
    
    
    func getExcludePatterns() -> [String] {
        return userDefaults.stringArray(forKey: "excludePatterns") ?? [
            ".git", ".DS_Store", "node_modules", ".venv", "__pycache__",
            ".pytest_cache", ".tox", "venv", "env", ".env", "dist",
            "build", ".build", "target", ".target", "Pods", "DerivedData"
        ]
    }
    
    func setExcludePatterns(_ patterns: [String]) {
        userDefaults.set(patterns, forKey: "excludePatterns")
    }
    
    func getMaxTokensPerFile() -> Int {
        let value = userDefaults.integer(forKey: "maxTokensPerFile")
        return value > 0 ? value : 50000
    }
    
    func setMaxTokensPerFile(_ maxTokens: Int) {
        userDefaults.set(maxTokens, forKey: "maxTokensPerFile")
    }
    
    func getShouldAutoExcludeLargeFiles() -> Bool {
        return userDefaults.bool(forKey: "autoExcludeLargeFiles")
    }
    
    func setShouldAutoExcludeLargeFiles(_ should: Bool) {
        userDefaults.set(should, forKey: "autoExcludeLargeFiles")
    }
    
    
    func saveRecents(_ recents: [RecentRepository]) {
        if let data = try? JSONEncoder().encode(recents) {
            userDefaults.set(data, forKey: "recent-repositories")
        }
    }
    
    func loadRecents() -> [RecentRepository] {
        guard let data = userDefaults.data(forKey: "recent-repositories"),
              let recents = try? JSONDecoder().decode([RecentRepository].self, from: data) else {
            return []
        }
        return recents
    }
    
    func saveBookmarks(_ bookmarks: [String]) {
        userDefaults.set(bookmarks, forKey: "bookmarked-repositories")
    }
    
    func loadBookmarks() -> [String] {
        return userDefaults.array(forKey: "bookmarked-repositories") as? [String] ?? []
    }
    
    func saveSavedOutputs(_ outputs: [SavedOutput]) {
        if let data = try? JSONEncoder().encode(outputs) {
            userDefaults.set(data, forKey: "saved-outputs")
        }
    }
    
    func loadSavedOutputs() -> [SavedOutput] {
        guard let data = userDefaults.data(forKey: "saved-outputs"),
              let outputs = try? JSONDecoder().decode([SavedOutput].self, from: data) else {
            return []
        }
        return outputs
    }
}

struct Bookmark: Codable, Identifiable {
    let id = UUID()
    let name: String
    let fullName: String
    let url: String
    let description: String?
    let language: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case name, fullName, url, description, language, createdAt
    }
}

enum PersistenceError: Error, LocalizedError {
    case keychainError(String)
    case encodingError(String)
    case decodingError(String)
    
    var errorDescription: String? {
        switch self {
        case .keychainError(let message):
            return "Keychain error: \(message)"
        case .encodingError(let message):
            return "Encoding error: \(message)"
        case .decodingError(let message):
            return "Decoding error: \(message)"
        }
    }
} 