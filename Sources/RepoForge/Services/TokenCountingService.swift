import Foundation

class TokenCountingService: @unchecked Sendable {
    
    func countTokens(in text: String) -> Int {
        guard !text.isEmpty else { return 0 }
        
        let characterCount = text.count
        return max(1, Int(ceil(Double(characterCount) / 4.0)))
    }
    
    func updateTokenCounts(for node: FileNode) {
        if node.isDirectory {
            var directoryTokenCount = 0
            for child in node.children {
                updateTokenCounts(for: child)
                directoryTokenCount += child.totalTokenCount
            }
            node.tokenCount = directoryTokenCount
            node.totalTokenCount = directoryTokenCount
        } else if let content = node.content {
            let tokens = countTokens(in: content)
            node.tokenCount = tokens
            node.totalTokenCount = tokens
        }
    }

    func sortNodesByTokenCount(_ node: FileNode) {
        if node.isDirectory {
            for child in node.children {
                sortNodesByTokenCount(child)
            }
            node.children.sort { $0.totalTokenCount > $1.totalTokenCount }
        }
    }
    
    func calculateStatistics(for rootNode: FileNode) -> ProcessingStatistics {
        var totalFiles = 0
        var includedFiles = 0
        var totalTokens = 0
        var includedTokens = 0
        var largestFile: (path: String, tokens: Int)?

        func traverse(_ node: FileNode) {
            if node.isDirectory {
                node.children.forEach(traverse)
            } else {
                totalFiles += 1
                totalTokens += node.tokenCount
                
                if node.isIncluded {
                    includedFiles += 1
                    includedTokens += node.tokenCount
                    
                    if let largest = largestFile, node.tokenCount > largest.tokens {
                        largestFile = (node.path, node.tokenCount)
                    } else if largestFile == nil {
                        largestFile = (node.path, node.tokenCount)
                    }
                }
            }
        }
        
        traverse(rootNode)
        
        return ProcessingStatistics(
            totalFiles: totalFiles,
            includedFiles: includedFiles,
            totalTokens: totalTokens,
            includedTokens: includedTokens,
            largestFile: largestFile
        )
    }
    
    func formatTokenCount(_ count: Int) -> String {
        if count < 1000 {
            return "\(count)"
        } else if count < 1_000_000 {
            return String(format: "%.1fk", Double(count) / 1000.0)
        } else {
            return String(format: "%.1fM", Double(count) / 1_000_000.0)
        }
    }
}

struct ProcessingStatistics {
    let totalFiles: Int
    let includedFiles: Int
    let totalTokens: Int
    let includedTokens: Int
    let largestFile: (path: String, tokens: Int)?
} 