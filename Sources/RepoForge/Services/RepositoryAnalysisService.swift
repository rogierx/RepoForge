import Foundation
import RegexBuilder

// MARK: - Repository Analysis Service
class RepositoryAnalysisService: ObservableObject {
    
    // MARK: - Analysis Result Models
    struct AnalysisResult {
        let overview: RepositoryOverview
        let complexity: ComplexityAnalysis
        let dependencies: DependencyAnalysis
        let codeQuality: CodeQualityAnalysis
        let fileAnalysis: FileAnalysis
        let insights: [Insight]
        let recommendations: [Recommendation]
    }
    
    struct RepositoryOverview {
        let totalFiles: Int
        let totalLines: Int
        let totalTokens: Int
        let fileTypeBreakdown: [FileTypeCategories.Category: Int]
        let languageBreakdown: [String: Int]
        let largestFiles: [FileMetric]
        let directoryStructureDepth: Int
    }
    
    struct ComplexityAnalysis {
        let averageFileSize: Double
        let complexityScore: Double
        let cyclomaticComplexity: Int
        let nestingDepth: Int
        let functionCount: Int
        let classCount: Int
        let importCount: Int
        let duplicateCodeRatio: Double
    }
    
    struct DependencyAnalysis {
        let externalDependencies: [Dependency]
        let internalDependencies: [String: [String]]
        let dependencyGraph: DependencyGraph
        let circularDependencies: [CircularDependency]
        let unusedDependencies: [String]
        let outdatedDependencies: [String]
    }
    
    struct CodeQualityAnalysis {
        let qualityScore: Double
        let documentation: DocumentationMetrics
        let testCoverage: TestCoverageMetrics
        let codeSmells: [CodeSmell]
        let securityIssues: [SecurityIssue]
        let maintainabilityIndex: Double
    }
    
    struct FileAnalysis {
        let duplicateFiles: [DuplicateFile]
        let emptyFiles: [String]
        let binaryFiles: [String]
        let largeFiles: [FileMetric]
        let unusedFiles: [String]
        let configFiles: [ConfigFile]
    }
    
    struct Insight {
        let type: InsightType
        let title: String
        let description: String
        let severity: Severity
        let affectedFiles: [String]
    }
    
    struct Recommendation {
        let category: RecommendationCategory
        let title: String
        let description: String
        let priority: Priority
        let estimatedImpact: Impact
        let actionItems: [String]
    }
    
    // MARK: - Supporting Models
    struct FileMetric {
        let path: String
        let name: String
        let size: Int
        let lines: Int
        let tokens: Int
        let complexity: Double
    }
    
    struct Dependency {
        let name: String
        let version: String?
        let type: DependencyType
        let source: String
        let isRequired: Bool
    }
    
    struct DependencyGraph {
        let nodes: [String]
        let edges: [(from: String, to: String)]
        let depth: Int
        let clusters: [[String]]
    }
    
    struct CircularDependency {
        let files: [String]
        let severity: Severity
    }
    
    struct DocumentationMetrics {
        let coverage: Double
        let readmeQuality: Double
        let codeComments: Double
        let apiDocumentation: Double
    }
    
    struct TestCoverageMetrics {
        let percentage: Double
        let testFiles: Int
        let totalTestable: Int
        let missingTests: [String]
    }
    
    struct CodeSmell {
        let type: CodeSmellType
        let file: String
        let line: Int?
        let description: String
        let severity: Severity
    }
    
    struct SecurityIssue {
        let type: SecurityIssueType
        let file: String
        let line: Int?
        let description: String
        let severity: Severity
        let cwe: String?
    }
    
    struct DuplicateFile {
        let files: [String]
        let similarity: Double
    }
    
    struct ConfigFile {
        let path: String
        let type: ConfigType
        let isValid: Bool
        let issues: [String]
    }
    
    // MARK: - Enums
    enum InsightType: String, CaseIterable {
        case performance = "Performance"
        case maintainability = "Maintainability"
        case security = "Security"
        case documentation = "Documentation"
        case testing = "Testing"
        case dependencies = "Dependencies"
        case architecture = "Architecture"
    }
    
    enum RecommendationCategory: String, CaseIterable {
        case codeQuality = "Code Quality"
        case performance = "Performance"
        case security = "Security"
        case maintainability = "Maintainability"
        case testing = "Testing"
        case documentation = "Documentation"
        case dependencies = "Dependencies"
    }
    
    enum Severity: String, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
        
        var color: String {
            switch self {
            case .low: return "green"
            case .medium: return "yellow"
            case .high: return "orange"
            case .critical: return "red"
            }
        }
    }
    
    enum Priority: String, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case urgent = "Urgent"
    }
    
    enum Impact: String, CaseIterable {
        case minimal = "Minimal"
        case moderate = "Moderate"
        case significant = "Significant"
        case major = "Major"
    }
    
    enum DependencyType: String, CaseIterable {
        case production = "Production"
        case development = "Development"
        case peer = "Peer"
        case optional = "Optional"
    }
    
    enum CodeSmellType: String, CaseIterable {
        case longMethod = "Long Method"
        case largeClass = "Large Class"
        case duplicatedCode = "Duplicated Code"
        case longParameterList = "Long Parameter List"
        case godClass = "God Class"
        case deadCode = "Dead Code"
        case magicNumbers = "Magic Numbers"
        case complexCondition = "Complex Condition"
    }
    
    enum SecurityIssueType: String, CaseIterable {
        case hardcodedCredentials = "Hardcoded Credentials"
        case sqlInjection = "SQL Injection"
        case xss = "Cross-Site Scripting"
        case pathTraversal = "Path Traversal"
        case weakCrypto = "Weak Cryptography"
        case insecureConfig = "Insecure Configuration"
        case unvalidatedInput = "Unvalidated Input"
    }
    
    enum ConfigType: String, CaseIterable {
        case packageManager = "Package Manager"
        case buildSystem = "Build System"
        case cicd = "CI/CD"
        case environment = "Environment"
        case docker = "Docker"
        case ide = "IDE"
        case git = "Git"
    }
    
    // MARK: - Analysis Methods
    func analyzeRepository(files: [FileNode]) async -> AnalysisResult {
        let overview = analyzeOverview(files: files)
        let complexity = analyzeComplexity(files: files)
        let dependencies = analyzeDependencies(files: files)
        let codeQuality = analyzeCodeQuality(files: files)
        let fileAnalysis = analyzeFiles(files: files)
        let insights = generateInsights(overview: overview, complexity: complexity, dependencies: dependencies, codeQuality: codeQuality, fileAnalysis: fileAnalysis)
        let recommendations = generateRecommendations(insights: insights, overview: overview, complexity: complexity)
        
        return AnalysisResult(
            overview: overview,
            complexity: complexity,
            dependencies: dependencies,
            codeQuality: codeQuality,
            fileAnalysis: fileAnalysis,
            insights: insights,
            recommendations: recommendations
        )
    }
    
    // MARK: - Overview Analysis
    private func analyzeOverview(files: [FileNode]) -> RepositoryOverview {
        var totalFiles = 0
        var totalLines = 0
        var totalTokens = 0
        var fileTypeBreakdown: [FileTypeCategories.Category: Int] = [:]
        var languageBreakdown: [String: Int] = [:]
        var allFiles: [FileMetric] = []
        var maxDepth = 0
        
        func processNode(_ node: FileNode, depth: Int = 0) {
            maxDepth = max(maxDepth, depth)
            
            if node.isDirectory {
                node.children.filter(\.isIncluded).forEach { processNode($0, depth: depth + 1) }
            } else if node.isIncluded {
                totalFiles += 1
                totalTokens += node.tokenCount
                
                fileTypeBreakdown[node.category, default: 0] += 1
                
                let language = detectLanguage(from: node.name)
                if !language.isEmpty {
                    languageBreakdown[language, default: 0] += 1
                }
                
                let lineCount = node.content?.components(separatedBy: .newlines).count ?? 0
                totalLines += lineCount
                
                allFiles.append(FileMetric(
                    path: node.path,
                    name: node.name,
                    size: node.size,
                    lines: lineCount,
                    tokens: node.tokenCount,
                    complexity: calculateFileComplexity(content: node.content ?? "")
                ))
            }
        }
        
        files.filter(\.isIncluded).forEach { processNode($0) }
        
        let largestFiles = Array(allFiles.sorted { $0.size > $1.size }.prefix(10))
        
        return RepositoryOverview(
            totalFiles: totalFiles,
            totalLines: totalLines,
            totalTokens: totalTokens,
            fileTypeBreakdown: fileTypeBreakdown,
            languageBreakdown: languageBreakdown,
            largestFiles: largestFiles,
            directoryStructureDepth: maxDepth
        )
    }
    
    // MARK: - Complexity Analysis
    private func analyzeComplexity(files: [FileNode]) -> ComplexityAnalysis {
        var totalSize = 0
        var totalFiles = 0
        var totalComplexity = 0.0
        var cyclomaticComplexity = 0
        var maxNestingDepth = 0
        var functionCount = 0
        var classCount = 0
        var importCount = 0
        var duplicateLines = 0
        var totalLines = 0
        
        func processNode(_ node: FileNode) {
            if node.isDirectory {
                node.children.filter(\.isIncluded).forEach(processNode)
            } else if node.isIncluded, let content = node.content {
                totalSize += node.size
                totalFiles += 1
                
                let lines = content.components(separatedBy: .newlines)
                totalLines += lines.count
                
                let fileComplexity = calculateFileComplexity(content: content)
                totalComplexity += fileComplexity
                
                cyclomaticComplexity += calculateCyclomaticComplexity(content: content)
                maxNestingDepth = max(maxNestingDepth, calculateNestingDepth(content: content))
                functionCount += countFunctions(content: content)
                classCount += countClasses(content: content)
                importCount += countImports(content: content)
                duplicateLines += findDuplicateLines(lines: lines)
            }
        }
        
        files.filter(\.isIncluded).forEach(processNode)
        
        let averageFileSize = totalFiles > 0 ? Double(totalSize) / Double(totalFiles) : 0
        let complexityScore = totalFiles > 0 ? totalComplexity / Double(totalFiles) : 0
        let duplicateCodeRatio = totalLines > 0 ? Double(duplicateLines) / Double(totalLines) : 0
        
        return ComplexityAnalysis(
            averageFileSize: averageFileSize,
            complexityScore: complexityScore,
            cyclomaticComplexity: cyclomaticComplexity,
            nestingDepth: maxNestingDepth,
            functionCount: functionCount,
            classCount: classCount,
            importCount: importCount,
            duplicateCodeRatio: duplicateCodeRatio
        )
    }
    
    // MARK: - Dependency Analysis
    private func analyzeDependencies(files: [FileNode]) -> DependencyAnalysis {
        var externalDependencies: [Dependency] = []
        var internalDependencies: [String: [String]] = [:]
        var configFiles: [FileNode] = []
        
        func processNode(_ node: FileNode) {
            if node.isDirectory {
                node.children.filter(\.isIncluded).forEach(processNode)
            } else if node.isIncluded {
                // Collect configuration files
                if isConfigurationFile(node.name) {
                    configFiles.append(node)
                }
                
                // Analyze imports/includes
                if let content = node.content {
                    let imports = extractImports(from: content, language: detectLanguage(from: node.name))
                    internalDependencies[node.path] = imports
                }
            }
        }
        
        files.filter(\.isIncluded).forEach(processNode)
        
        // Parse external dependencies from config files
        for configFile in configFiles {
            if let content = configFile.content {
                externalDependencies.append(contentsOf: parseExternalDependencies(from: content, fileName: configFile.name))
            }
        }
        
        let dependencyGraph = buildDependencyGraph(internalDependencies: internalDependencies)
        let circularDependencies = findCircularDependencies(graph: dependencyGraph)
        
        return DependencyAnalysis(
            externalDependencies: externalDependencies,
            internalDependencies: internalDependencies,
            dependencyGraph: dependencyGraph,
            circularDependencies: circularDependencies,
            unusedDependencies: [], // Would require more sophisticated analysis
            outdatedDependencies: [] // Would require external API calls
        )
    }
    
    // MARK: - Code Quality Analysis
    private func analyzeCodeQuality(files: [FileNode]) -> CodeQualityAnalysis {
        let documentation = analyzeDocumentation(files: files)
        let testCoverage = analyzeTestCoverage(files: files)
        let codeSmells = findCodeSmells(files: files)
        let securityIssues = findSecurityIssues(files: files)
        
        // Calculate overall quality score
        let docScore = documentation.coverage * 0.25
        let testScore = testCoverage.percentage * 0.25
        let smellPenalty = min(Double(codeSmells.count) * 0.05, 0.3)
        let securityPenalty = min(Double(securityIssues.count) * 0.1, 0.4)
        
        let qualityScore = max(0, (docScore + testScore + 0.5) - smellPenalty - securityPenalty)
        let maintainabilityIndex = calculateMaintainabilityIndex(files: files)
        
        return CodeQualityAnalysis(
            qualityScore: qualityScore,
            documentation: documentation,
            testCoverage: testCoverage,
            codeSmells: codeSmells,
            securityIssues: securityIssues,
            maintainabilityIndex: maintainabilityIndex
        )
    }
    
    // MARK: - File Analysis
    private func analyzeFiles(files: [FileNode]) -> FileAnalysis {
        var allFiles: [FileNode] = []
        var duplicateFiles: [DuplicateFile] = []
        var emptyFiles: [String] = []
        var binaryFiles: [String] = []
        var largeFiles: [FileMetric] = []
        var configFiles: [ConfigFile] = []
        
        func collectFiles(_ node: FileNode) {
            if node.isDirectory {
                node.children.filter(\.isIncluded).forEach(collectFiles)
            } else if node.isIncluded {
                allFiles.append(node)
                
                if let content = node.content {
                    if content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        emptyFiles.append(node.path)
                    }
                    
                    if isBinaryContent(content) {
                        binaryFiles.append(node.path)
                    }
                    
                    let lineCount = content.components(separatedBy: .newlines).count
                    if lineCount > 1000 {
                        largeFiles.append(FileMetric(
                            path: node.path,
                            name: node.name,
                            size: node.size,
                            lines: lineCount,
                            tokens: node.tokenCount,
                            complexity: calculateFileComplexity(content: content)
                        ))
                    }
                }
                
                if isConfigurationFile(node.name) {
                    configFiles.append(ConfigFile(
                        path: node.path,
                        type: getConfigType(node.name),
                        isValid: validateConfigFile(node.content ?? "", fileName: node.name),
                        issues: []
                    ))
                }
            }
        }
        
        files.filter(\.isIncluded).forEach(collectFiles)
        
        // Find duplicate files
        duplicateFiles = findDuplicateFiles(allFiles)
        
        return FileAnalysis(
            duplicateFiles: duplicateFiles,
            emptyFiles: emptyFiles,
            binaryFiles: binaryFiles,
            largeFiles: largeFiles.sorted { $0.lines > $1.lines },
            unusedFiles: [], // Would require more sophisticated analysis
            configFiles: configFiles
        )
    }
    
    // MARK: - Helper Methods for Analysis
    private func detectLanguage(from fileName: String) -> String {
        let ext = (fileName as NSString).pathExtension.lowercased()
        
        switch ext {
        case "swift": return "Swift"
        case "py": return "Python"
        case "js": return "JavaScript"
        case "ts": return "TypeScript"
        case "java": return "Java"
        case "kt": return "Kotlin"
        case "go": return "Go"
        case "rs": return "Rust"
        case "cpp", "cc", "cxx": return "C++"
        case "c": return "C"
        case "cs": return "C#"
        case "php": return "PHP"
        case "rb": return "Ruby"
        case "scala": return "Scala"
        case "dart": return "Dart"
        default: return ""
        }
    }
    
    private func calculateFileComplexity(content: String) -> Double {
        let lines = content.components(separatedBy: .newlines)
        let nonEmptyLines = lines.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        // Basic complexity based on control flow keywords
        let complexityKeywords = ["if", "else", "while", "for", "switch", "case", "catch", "try"]
        let complexityCount = complexityKeywords.reduce(0) { count, keyword in
            count + content.components(separatedBy: keyword).count - 1
        }
        
        return Double(complexityCount) + Double(nonEmptyLines.count) * 0.1
    }
    
    private func calculateCyclomaticComplexity(content: String) -> Int {
        let patterns = ["if", "else if", "while", "for", "case", "catch", "&&", "||"]
        return patterns.reduce(1) { complexity, pattern in
            complexity + (content.components(separatedBy: pattern).count - 1)
        }
    }
    
    private func calculateNestingDepth(content: String) -> Int {
        var maxDepth = 0
        var currentDepth = 0
        
        for char in content {
            if char == "{" {
                currentDepth += 1
                maxDepth = max(maxDepth, currentDepth)
            } else if char == "}" {
                currentDepth = max(0, currentDepth - 1)
            }
        }
        
        return maxDepth
    }
    
    private func countFunctions(content: String) -> Int {
        let patterns = ["func ", "function ", "def ", "public ", "private ", "protected "]
        return patterns.reduce(0) { count, pattern in
            count + (content.components(separatedBy: pattern).count - 1)
        }
    }
    
    private func countClasses(content: String) -> Int {
        let patterns = ["class ", "struct ", "interface ", "enum "]
        return patterns.reduce(0) { count, pattern in
            count + (content.components(separatedBy: pattern).count - 1)
        }
    }
    
    private func countImports(content: String) -> Int {
        let patterns = ["import ", "#include ", "require(", "from "]
        return patterns.reduce(0) { count, pattern in
            count + (content.components(separatedBy: pattern).count - 1)
        }
    }
    
    private func findDuplicateLines(lines: [String]) -> Int {
        let lineSet = Set(lines.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
        return lines.count - lineSet.count
    }
    
    private func isConfigurationFile(_ fileName: String) -> Bool {
        let configPatterns = ["package.json", "Gemfile", "requirements.txt", "pom.xml", "build.gradle", "Dockerfile", "docker-compose", ".env", "config"]
        return configPatterns.contains { fileName.lowercased().contains($0.lowercased()) }
    }
    
    private func extractImports(from content: String, language: String) -> [String] {
        var imports: [String] = []
        let lines = content.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            switch language {
            case "Swift":
                if trimmedLine.hasPrefix("import ") {
                    imports.append(String(trimmedLine.dropFirst(7)))
                }
            case "Python":
                if trimmedLine.hasPrefix("import ") || trimmedLine.hasPrefix("from ") {
                    imports.append(trimmedLine)
                }
            case "JavaScript", "TypeScript":
                if trimmedLine.hasPrefix("import ") || trimmedLine.contains("require(") {
                    imports.append(trimmedLine)
                }
            default:
                break
            }
        }
        
        return imports
    }
    
    private func parseExternalDependencies(from content: String, fileName: String) -> [Dependency] {
        var dependencies: [Dependency] = []
        
        if fileName == "package.json" {
            // Parse JSON dependencies (simplified)
            if let data = content.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                
                if let deps = json["dependencies"] as? [String: String] {
                    for (name, version) in deps {
                        dependencies.append(Dependency(
                            name: name,
                            version: version,
                            type: .production,
                            source: fileName,
                            isRequired: true
                        ))
                    }
                }
                
                if let devDeps = json["devDependencies"] as? [String: String] {
                    for (name, version) in devDeps {
                        dependencies.append(Dependency(
                            name: name,
                            version: version,
                            type: .development,
                            source: fileName,
                            isRequired: false
                        ))
                    }
                }
            }
        }
        
        return dependencies
    }
    
    private func buildDependencyGraph(internalDependencies: [String: [String]]) -> DependencyGraph {
        let nodes = Array(internalDependencies.keys)
        var edges: [(String, String)] = []
        
        for (from, imports) in internalDependencies {
            for importedFile in imports {
                if nodes.contains(importedFile) {
                    edges.append((from, importedFile))
                }
            }
        }
        
        return DependencyGraph(
            nodes: nodes,
            edges: edges,
            depth: calculateGraphDepth(nodes: nodes, edges: edges),
            clusters: findClusters(nodes: nodes, edges: edges)
        )
    }
    
    private func findCircularDependencies(graph: DependencyGraph) -> [CircularDependency] {
        // Simplified circular dependency detection
        var visited: Set<String> = []
        var recursionStack: Set<String> = []
        var circularDeps: [CircularDependency] = []
        
        func dfs(_ node: String, path: [String]) {
            if recursionStack.contains(node) {
                let cycleStart = path.firstIndex(of: node) ?? 0
                let cycle = Array(path[cycleStart...])
                circularDeps.append(CircularDependency(
                    files: cycle,
                    severity: cycle.count > 3 ? .high : .medium
                ))
                return
            }
            
            if visited.contains(node) { return }
            
            visited.insert(node)
            recursionStack.insert(node)
            
            let neighbors = graph.edges.filter { $0.from == node }.map { $0.to }
            for neighbor in neighbors {
                dfs(neighbor, path: path + [neighbor])
            }
            
            recursionStack.remove(node)
        }
        
        for node in graph.nodes {
            if !visited.contains(node) {
                dfs(node, path: [node])
            }
        }
        
        return circularDeps
    }
    
    private func analyzeDocumentation(files: [FileNode]) -> DocumentationMetrics {
        var totalFiles = 0
        var documentedFiles = 0
        var hasReadme = false
        var commentLines = 0
        var totalLines = 0
        
        func processNode(_ node: FileNode) {
            if node.isDirectory {
                node.children.filter(\.isIncluded).forEach(processNode)
            } else if node.isIncluded {
                if node.name.lowercased().contains("readme") {
                    hasReadme = true
                }
                
                if node.category == .code, let content = node.content {
                    totalFiles += 1
                    let lines = content.components(separatedBy: .newlines)
                    totalLines += lines.count
                    
                    let comments = lines.filter { line in
                        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                        return trimmed.hasPrefix("//") || trimmed.hasPrefix("/*") || trimmed.hasPrefix("*") || trimmed.hasPrefix("#")
                    }
                    
                    commentLines += comments.count
                    
                    if !comments.isEmpty {
                        documentedFiles += 1
                    }
                }
            }
        }
        
        files.filter(\.isIncluded).forEach(processNode)
        
        let coverage = totalFiles > 0 ? Double(documentedFiles) / Double(totalFiles) : 0
        let readmeQuality = hasReadme ? 1.0 : 0.0
        let codeComments = totalLines > 0 ? Double(commentLines) / Double(totalLines) : 0
        
        return DocumentationMetrics(
            coverage: coverage,
            readmeQuality: readmeQuality,
            codeComments: codeComments,
            apiDocumentation: 0.5 // Placeholder
        )
    }
    
    private func analyzeTestCoverage(files: [FileNode]) -> TestCoverageMetrics {
        var testFiles = 0
        var sourceFiles = 0
        var missingTests: [String] = []
        
        func processNode(_ node: FileNode) {
            if node.isDirectory {
                node.children.filter(\.isIncluded).forEach(processNode)
            } else if node.isIncluded {
                if node.category == .other { // Assuming tests are categorized as 'other' for now
                    testFiles += 1
                } else if node.category == .code {
                    sourceFiles += 1
                    
                }
            }
        }
        
        files.filter(\.isIncluded).forEach(processNode)
        
        let percentage = sourceFiles > 0 ? Double(testFiles) / Double(sourceFiles) : 0
        
        return TestCoverageMetrics(
            percentage: min(percentage, 1.0),
            testFiles: testFiles,
            totalTestable: sourceFiles,
            missingTests: missingTests
        )
    }
    
    private func findCodeSmells(files: [FileNode]) -> [CodeSmell] {
        var codeSmells: [CodeSmell] = []
        
        func processNode(_ node: FileNode) {
            if node.isDirectory {
                node.children.filter(\.isIncluded).forEach(processNode)
            } else if node.isIncluded, let content = node.content {
                let lines = content.components(separatedBy: .newlines)
                
                // Long file
                if lines.count > 1000 {
                    codeSmells.append(CodeSmell(
                        type: .largeClass,
                        file: node.path,
                        line: nil,
                        description: "File has \(lines.count) lines, consider breaking it down",
                        severity: lines.count > 2000 ? .high : .medium
                    ))
                }
                
                // Long methods (simplified detection)
                var currentFunction = ""
                var functionLineCount = 0
                
                for (index, line) in lines.enumerated() {
                    let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if trimmed.contains("func ") || trimmed.contains("function ") || trimmed.contains("def ") {
                        currentFunction = trimmed
                        functionLineCount = 1
                    } else if !currentFunction.isEmpty {
                        functionLineCount += 1
                        
                        if trimmed == "}" && functionLineCount > 50 {
                            codeSmells.append(CodeSmell(
                                type: .longMethod,
                                file: node.path,
                                line: index + 1,
                                description: "Method '\(currentFunction)' has \(functionLineCount) lines",
                                severity: functionLineCount > 100 ? .high : .medium
                            ))
                            currentFunction = ""
                        }
                    }
                }
                
                // Magic numbers
                let numberPattern = "\\b\\d{3,}\\b"
                if let regex = try? NSRegularExpression(pattern: numberPattern) {
                    let matches = regex.matches(in: content, range: NSRange(content.startIndex..., in: content))
                    if matches.count > 5 {
                        codeSmells.append(CodeSmell(
                            type: .magicNumbers,
                            file: node.path,
                            line: nil,
                            description: "Found \(matches.count) potential magic numbers",
                            severity: .low
                        ))
                    }
                }
            }
        }
        
        files.filter(\.isIncluded).forEach(processNode)
        return codeSmells
    }
    
    private func findSecurityIssues(files: [FileNode]) -> [SecurityIssue] {
        var securityIssues: [SecurityIssue] = []
        
        func processNode(_ node: FileNode) {
            if node.isDirectory {
                node.children.filter(\.isIncluded).forEach(processNode)
            } else if node.isIncluded, let content = node.content {
                let lowercased = content.lowercased()
                
                // Hardcoded credentials
                let credentialPatterns = ["password", "api_key", "secret", "token"]
                for pattern in credentialPatterns {
                    if lowercased.contains("\(pattern) = ") || lowercased.contains("\(pattern):") {
                        securityIssues.append(SecurityIssue(
                            type: .hardcodedCredentials,
                            file: node.path,
                            line: nil,
                            description: "Potential hardcoded credential: \(pattern)",
                            severity: .high,
                            cwe: "CWE-798"
                        ))
                    }
                }
                
                // SQL Injection
                if lowercased.contains("select ") && (lowercased.contains("+ ") || lowercased.contains("concat")) {
                    securityIssues.append(SecurityIssue(
                        type: .sqlInjection,
                        file: node.path,
                        line: nil,
                        description: "Potential SQL injection vulnerability",
                        severity: .critical,
                        cwe: "CWE-89"
                    ))
                }
                
                // Weak crypto
                let weakCryptoPatterns = ["md5", "sha1", "des", "rc4"]
                for pattern in weakCryptoPatterns {
                    if lowercased.contains(pattern) {
                        securityIssues.append(SecurityIssue(
                            type: .weakCrypto,
                            file: node.path,
                            line: nil,
                            description: "Weak cryptographic algorithm: \(pattern)",
                            severity: .medium,
                            cwe: "CWE-327"
                        ))
                    }
                }
            }
        }
        
        files.filter(\.isIncluded).forEach(processNode)
        return securityIssues
    }
    
    private func calculateMaintainabilityIndex(files: [FileNode]) -> Double {
        var totalComplexity = 0.0
        var totalFiles = 0
        
        func processNode(_ node: FileNode) {
            if node.isDirectory {
                node.children.filter(\.isIncluded).forEach(processNode)
            } else if node.isIncluded, let content = node.content {
                totalFiles += 1
                totalComplexity += calculateFileComplexity(content: content)
            }
        }
        
        files.filter(\.isIncluded).forEach(processNode)
        
        let averageComplexity = totalFiles > 0 ? totalComplexity / Double(totalFiles) : 0
        return max(0, 100 - (averageComplexity * 2)) // Simplified maintainability index
    }
    
    private func findDuplicateFiles(_ files: [FileNode]) -> [DuplicateFile] {
        var duplicates: [DuplicateFile] = []
        
        for i in 0..<files.count {
            for j in i+1..<files.count {
                if let content1 = files[i].content, let content2 = files[j].content {
                    let similarity = calculateSimilarity(content1: content1, content2: content2)
                    if similarity > 0.8 {
                        duplicates.append(DuplicateFile(
                            files: [files[i].path, files[j].path],
                            similarity: similarity
                        ))
                    }
                }
            }
        }
        
        return duplicates
    }
    
    private func calculateSimilarity(content1: String, content2: String) -> Double {
        let lines1 = Set(content1.components(separatedBy: .newlines))
        let lines2 = Set(content2.components(separatedBy: .newlines))
        
        let intersection = lines1.intersection(lines2)
        let union = lines1.union(lines2)
        
        return union.isEmpty ? 0 : Double(intersection.count) / Double(union.count)
    }
    
    private func isBinaryContent(_ content: String) -> Bool {
        // Simple heuristic: if content contains null bytes or high percentage of non-printable characters
        let nonPrintableCount = content.unicodeScalars.filter { $0.value > 127 || $0.value < 32 }.count
        return Double(nonPrintableCount) / Double(content.count) > 0.3
    }
    
    private func getConfigType(_ fileName: String) -> ConfigType {
        let name = fileName.lowercased()
        
        if name.contains("package.json") || name.contains("gemfile") || name.contains("requirements") {
            return .packageManager
        } else if name.contains("makefile") || name.contains("build") || name.contains("cmake") {
            return .buildSystem
        } else if name.contains("docker") {
            return .docker
        } else if name.contains(".github") || name.contains("ci") || name.contains("travis") {
            return .cicd
        } else if name.contains("env") {
            return .environment
        } else if name.contains("git") {
            return .git
        } else {
            return .ide
        }
    }
    
    private func validateConfigFile(_ content: String, fileName: String) -> Bool {
        // Basic validation - check if it's valid JSON/YAML
        if fileName.hasSuffix(".json") {
            return (try? JSONSerialization.jsonObject(with: content.data(using: .utf8) ?? Data())) != nil
        }
        return !content.isEmpty // Simplified validation
    }
    
    private func calculateGraphDepth(nodes: [String], edges: [(String, String)]) -> Int {
        // Simplified depth calculation
        var inDegree: [String: Int] = [:]
        
        for node in nodes {
            inDegree[node] = 0
        }
        
        for edge in edges {
            inDegree[edge.1, default: 0] += 1
        }
        
        var queue = nodes.filter { inDegree[$0] == 0 }
        var depth = 0
        
        while !queue.isEmpty {
            depth += 1
            let levelSize = queue.count
            
            for _ in 0..<levelSize {
                let current = queue.removeFirst()
                let neighbors = edges.filter { $0.0 == current }.map { $0.1 }
                
                for neighbor in neighbors {
                    inDegree[neighbor]! -= 1
                    if inDegree[neighbor]! == 0 {
                        queue.append(neighbor)
                    }
                }
            }
        }
        
        return depth
    }
    
    private func findClusters(nodes: [String], edges: [(String, String)]) -> [[String]] {
        // Simplified clustering - just return all nodes as one cluster
        return [nodes]
    }
    
    // MARK: - Insight and Recommendation Generation
    private func generateInsights(overview: RepositoryOverview, complexity: ComplexityAnalysis, dependencies: DependencyAnalysis, codeQuality: CodeQualityAnalysis, fileAnalysis: FileAnalysis) -> [Insight] {
        var insights: [Insight] = []
        
        // Performance insights
        if complexity.averageFileSize > 50000 {
            insights.append(Insight(
                type: .performance,
                title: "Large Average File Size",
                description: "Files are averaging \(Int(complexity.averageFileSize)) bytes, which may impact compilation and loading times",
                severity: .medium,
                affectedFiles: overview.largestFiles.map { $0.path }
            ))
        }
        
        // Maintainability insights
        if complexity.complexityScore > 50 {
            insights.append(Insight(
                type: .maintainability,
                title: "High Code Complexity",
                description: "Code complexity score of \(Int(complexity.complexityScore)) suggests the codebase may be difficult to maintain",
                severity: .high,
                affectedFiles: []
            ))
        }
        
        // Security insights
        if !codeQuality.securityIssues.isEmpty {
            insights.append(Insight(
                type: .security,
                title: "Security Issues Detected",
                description: "Found \(codeQuality.securityIssues.count) potential security issues that should be addressed",
                severity: .high,
                affectedFiles: codeQuality.securityIssues.map { $0.file }
            ))
        }
        
        // Documentation insights
        if codeQuality.documentation.coverage < 0.5 {
            insights.append(Insight(
                type: .documentation,
                title: "Low Documentation Coverage",
                description: "Only \(Int(codeQuality.documentation.coverage * 100))% of files have documentation",
                severity: .medium,
                affectedFiles: []
            ))
        }
        
        // Testing insights
        if codeQuality.testCoverage.percentage < 0.5 {
            insights.append(Insight(
                type: .testing,
                title: "Insufficient Test Coverage",
                description: "Test coverage is only \(Int(codeQuality.testCoverage.percentage * 100))%",
                severity: .medium,
                affectedFiles: codeQuality.testCoverage.missingTests
            ))
        }
        
        // Dependencies insights
        if !dependencies.circularDependencies.isEmpty {
            insights.append(Insight(
                type: .dependencies,
                title: "Circular Dependencies Detected",
                description: "Found \(dependencies.circularDependencies.count) circular dependencies that could cause issues",
                severity: .high,
                affectedFiles: dependencies.circularDependencies.flatMap { $0.files }
            ))
        }
        
        return insights
    }
    
    private func generateRecommendations(insights: [Insight], overview: RepositoryOverview, complexity: ComplexityAnalysis) -> [Recommendation] {
        var recommendations: [Recommendation] = []
        
        // Code quality recommendations
        if complexity.duplicateCodeRatio > 0.2 {
            recommendations.append(Recommendation(
                category: .codeQuality,
                title: "Reduce Code Duplication",
                description: "High code duplication (\(Int(complexity.duplicateCodeRatio * 100))%) detected. Consider extracting common functionality into shared modules or functions.",
                priority: .medium,
                estimatedImpact: .significant,
                actionItems: [
                    "Identify duplicated code blocks",
                    "Extract common functionality into utility functions",
                    "Create shared modules for repeated patterns",
                    "Set up code analysis tools to prevent future duplication"
                ]
            ))
        }
        
        // Performance recommendations
        if overview.largestFiles.count > 5 {
            recommendations.append(Recommendation(
                category: .performance,
                title: "Break Down Large Files",
                description: "Several large files detected that may impact performance and maintainability.",
                priority: .medium,
                estimatedImpact: .moderate,
                actionItems: [
                    "Split large files into smaller, focused modules",
                    "Extract classes/functions into separate files",
                    "Consider using lazy loading for heavy components",
                    "Implement modular architecture patterns"
                ]
            ))
        }
        
        // Security recommendations
        let securityInsights = insights.filter { $0.type == .security }
        if !securityInsights.isEmpty {
            recommendations.append(Recommendation(
                category: .security,
                title: "Address Security Vulnerabilities",
                description: "Multiple security issues detected that require immediate attention.",
                priority: .high,
                estimatedImpact: .major,
                actionItems: [
                    "Review and remove hardcoded credentials",
                    "Implement proper input validation",
                    "Use secure cryptographic algorithms",
                    "Set up automated security scanning",
                    "Conduct security code review"
                ]
            ))
        }
        
        // Testing recommendations
        let testingInsights = insights.filter { $0.type == .testing }
        if !testingInsights.isEmpty {
            recommendations.append(Recommendation(
                category: .testing,
                title: "Improve Test Coverage",
                description: "Low test coverage detected. Improving tests will increase code reliability and make refactoring safer.",
                priority: .medium,
                estimatedImpact: .significant,
                actionItems: [
                    "Write unit tests for core functionality",
                    "Add integration tests for critical workflows",
                    "Set up automated testing in CI/CD",
                    "Establish minimum test coverage requirements",
                    "Use test-driven development for new features"
                ]
            ))
        }
        
        // Documentation recommendations
        let docInsights = insights.filter { $0.type == .documentation }
        if !docInsights.isEmpty {
            recommendations.append(Recommendation(
                category: .documentation,
                title: "Enhance Documentation",
                description: "Poor documentation coverage makes the codebase harder to understand and maintain.",
                priority: .low,
                estimatedImpact: .moderate,
                actionItems: [
                    "Add README files for each major module",
                    "Document public APIs and interfaces",
                    "Include code comments for complex logic",
                    "Create developer setup guides",
                    "Maintain up-to-date technical documentation"
                ]
            ))
        }
        
        return recommendations
    }
} 