import Foundation

struct OutputBookmark: Codable, Identifiable {
    let id: UUID
    let repositoryName: String
    let repositoryUrl: String
    let tokenCount: Int
    let fileCount: Int
    let createdAt: Date
    let output: String
    
    var shortOutput: String {
        String(output.prefix(200)) + (output.count > 200 ? "..." : "")
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
} 