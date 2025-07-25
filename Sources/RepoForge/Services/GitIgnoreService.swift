import Foundation


class GitIgnoreService: @unchecked Sendable {
    private var patterns: [GitIgnorePattern] = []
    private var globalPatterns: [GitIgnorePattern] = []
    
    struct GitIgnorePattern {
        let pattern: String
        let isNegation: Bool
        let isDirectory: Bool
        let isGlobal: Bool
        
        init(line: String, isGlobal: Bool = false) {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            self.isGlobal = isGlobal
            self.isNegation = trimmedLine.hasPrefix("!")
            
            let patternWithoutNegation = isNegation ? String(trimmedLine.dropFirst()) : trimmedLine
            self.isDirectory = patternWithoutNegation.hasSuffix("/")
            
            self.pattern = isDirectory ? String(patternWithoutNegation.dropLast()) : patternWithoutNegation
        }
    }
    
    init() {
        loadGlobalPatterns()
    }
    
    private func loadGlobalPatterns() {
        let globalIgnorePatterns = [
            ".DS_Store",
            "Thumbs.db",
            "*.log",
            "*.tmp",
            "*.temp",
            "*.cache",
            "*.swp",
            "*.swo",
            "*~",
            ".git/",
            ".svn/",
            ".hg/",
            "node_modules/",
            "__pycache__/",
            "*.pyc",
            "*.pyo",
            ".pytest_cache/",
            ".coverage",
            ".nyc_output/",
            "coverage/",
            ".sass-cache/",
            ".nuxt/",
            ".next/",
            "build/",
            "dist/",
            "target/",
            "bin/",
            "obj/",
            ".vscode/",
            ".idea/",
            "vendor/",
            "Pods/",
            "DerivedData/",
            ".build/",
            "Package.resolved"
        ]
        
        globalPatterns = globalIgnorePatterns.map { GitIgnorePattern(line: $0, isGlobal: true) }
    }
    
    func parseGitIgnore(content: String) {
        patterns = []
        
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmedLine.isEmpty || trimmedLine.hasPrefix("#") {
                continue
            }
            
            patterns.append(GitIgnorePattern(line: trimmedLine))
        }
    }
    
    func shouldIgnore(path: String, isDirectory: Bool) -> Bool {
        if matchesAnyPattern(path: path, isDirectory: isDirectory, patterns: globalPatterns) {
            return true
        }
        
        return matchesAnyPattern(path: path, isDirectory: isDirectory, patterns: patterns)
    }
    
    private func matchesAnyPattern(path: String, isDirectory: Bool, patterns: [GitIgnorePattern]) -> Bool {
        var isIgnored = false
        
        for pattern in patterns {
            if matchesPattern(path: path, isDirectory: isDirectory, pattern: pattern) {
                if pattern.isNegation {
                    isIgnored = false
                } else {
                    isIgnored = true
                }
            }
        }
        
        return isIgnored
    }
    
    private func matchesPattern(path: String, isDirectory: Bool, pattern: GitIgnorePattern) -> Bool {
        if pattern.isDirectory && !isDirectory {
            return false
        }
        
        let pathComponents = path.split(separator: "/").map(String.init)
        let fileName = pathComponents.last ?? path
        
        if pattern.pattern.contains("*") {
            return matchesWildcardPattern(string: fileName, pattern: pattern.pattern) ||
                   matchesWildcardPattern(string: path, pattern: pattern.pattern)
        }
        
        if pattern.pattern == fileName || pattern.pattern == path {
            return true
        }
        
        if pattern.isDirectory {
            return pathComponents.contains(pattern.pattern)
        }
        
        return path.hasSuffix(pattern.pattern) || fileName == pattern.pattern
    }
    
    private func matchesWildcardPattern(string: String, pattern: String) -> Bool {
        
        if pattern == "*" {
            return true
        }
        
        if pattern.hasPrefix("*.") {
            let fileExtension = String(pattern.dropFirst(2))
            return string.hasSuffix("." + fileExtension)
        }
        
        if pattern.hasSuffix("*") {
            let prefix = String(pattern.dropLast())
            return string.hasPrefix(prefix)
        }
        
        if pattern.contains("*") {
            let parts = pattern.split(separator: "*").map(String.init)
            var lastIndex = string.startIndex
            
            for part in parts {
                guard let range = string.range(of: part, range: lastIndex..<string.endIndex) else {
                    return false
                }
                lastIndex = range.upperBound
            }
            return true
        }
        
        return string == pattern
    }
    
    func isAllowedFile(path: String, fileName: String, isDirectory: Bool, fileSize: Int) -> Bool {
        if shouldIgnore(path: path, isDirectory: isDirectory) {
            return false
        }
        
        return !FileNode.shouldExcludeByDefault(path: path, name: fileName, includeVirtualEnvironments: true)
    }
    
    func getFilteringStats(for files: [String]) -> (ignored: Int, allowed: Int) {
        var ignored = 0
        var allowed = 0
        
        for file in files {
            let isDirectory = file.hasSuffix("/")
            
            if shouldIgnore(path: file, isDirectory: isDirectory) {
                ignored += 1
            } else {
                allowed += 1
            }
        }
        
        return (ignored: ignored, allowed: allowed)
    }
    
    func getActivePatterns() -> [String] {
        return patterns.map { pattern in
            var result = pattern.pattern
            if pattern.isNegation { result = "!" + result }
            if pattern.isDirectory { result += "/" }
            if pattern.isGlobal { result += " (global)" }
            return result
        }
    }
} 