import XCTest
@testable import RepoForge

final class RepoForgeTests: XCTestCase {
    func testTokenCounting() throws {
        let tokenService = TokenCountingService()
        let count = tokenService.countTokens(in: "Hello, world!")
        XCTAssertGreaterThan(count, 0)
        XCTAssertLessThan(count, 10) // Should be around 3-4 tokens
    }
    
    func testFileNodeCreation() throws {
        let fileNode = FileNode(name: "test.swift", path: "test.swift", type: .file)
        XCTAssertEqual(fileNode.name, "test.swift")
        XCTAssertEqual(fileNode.type, .file)
        XCTAssertTrue(fileNode.isIncluded)
    }
    
    func testGitHubURLParsing() throws {
        let url = GitHubURL(urlString: "https://github.com/owner/repo")
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.owner, "owner")
        XCTAssertEqual(url?.repository, "repo")
    }
} 