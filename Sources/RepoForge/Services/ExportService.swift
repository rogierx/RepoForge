import Foundation

// MARK: - Export Service for Multiple Output Formats
class ExportService: ObservableObject {
    
    // MARK: - Export Formats
    enum ExportFormat: String, CaseIterable, Identifiable {
        case plainText = "Plain Text"
        case markdown = "Markdown"
        case json = "JSON"
        case xml = "XML"
        case yaml = "YAML"
        case csv = "CSV"
        case html = "HTML"
        case customTemplate = "Custom Template"
        
        var id: String { rawValue }
        
        var fileExtension: String {
            switch self {
            case .plainText: return "txt"
            case .markdown: return "md"
            case .json: return "json"
            case .xml: return "xml"
            case .yaml: return "yaml"
            case .csv: return "csv"
            case .html: return "html"
            case .customTemplate: return "txt"
            }
        }
        
        var mimeType: String {
            switch self {
            case .plainText: return "text/plain"
            case .markdown: return "text/markdown"
            case .json: return "application/json"
            case .xml: return "application/xml"
            case .yaml: return "text/yaml"
            case .csv: return "text/csv"
            case .html: return "text/html"
            case .customTemplate: return "text/plain"
            }
        }
        
        var icon: String {
            switch self {
            case .plainText: return "doc.text"
            case .markdown: return "doc.richtext"
            case .json: return "curlybraces"
            case .xml: return "chevron.left.forwardslash.chevron.right"
            case .yaml: return "list.bullet.indent"
            case .csv: return "tablecells"
            case .html: return "globe"
            case .customTemplate: return "wand.and.stars"
            }
        }
    }
    
    // MARK: - Export Methods
    func exportRepository(
        repository: Repository,
        files: [FileNode],
        format: ExportFormat,
        includeMetadata: Bool = true,
        customTemplate: String? = nil
    ) -> String {
        switch format {
        case .plainText:
            return exportAsPlainText(repository: repository, files: files, includeMetadata: includeMetadata)
        case .markdown:
            return exportAsMarkdown(repository: repository, files: files, includeMetadata: includeMetadata)
        case .json:
            return exportAsJSON(repository: repository, files: files, includeMetadata: includeMetadata)
        case .xml:
            return exportAsXML(repository: repository, files: files, includeMetadata: includeMetadata)
        case .yaml:
            return exportAsYAML(repository: repository, files: files, includeMetadata: includeMetadata)
        case .csv:
            return exportAsCSV(repository: repository, files: files, includeMetadata: includeMetadata)
        case .html:
            return exportAsHTML(repository: repository, files: files, includeMetadata: includeMetadata)
        case .customTemplate:
            return exportWithCustomTemplate(repository: repository, files: files, template: customTemplate ?? defaultTemplate, includeMetadata: includeMetadata)
        }
    }
    
    // MARK: - Plain Text Export (Original Format)
    private func exportAsPlainText(repository: Repository, files: [FileNode], includeMetadata: Bool) -> String {
        var output = ""
        
        if includeMetadata {
            output += generateMetadataHeader(repository: repository, files: files)
            output += "\n"
        }
        
        output += generateFileTree(files: files)
        output += "\n"
        output += generateFileContents(files: files)
        
        return output
    }
    
    // MARK: - Markdown Export
    private func exportAsMarkdown(repository: Repository, files: [FileNode], includeMetadata: Bool) -> String {
        var output = ""
        
        if includeMetadata {
            output += "# \(repository.name)\n\n"
            output += "**Repository**: [\(repository.name)](\(repository.htmlUrl))\n"
            output += "**Owner**: \(repository.owner.login)\n"
            if let description = repository.description {
                output += "**Description**: \(description)\n"
            }
            output += "**Generated**: \(formattedDate())\n\n"
            
            // Statistics
            let stats = generateStatistics(files: files)
            output += "## Repository Statistics\n\n"
            output += "| Metric | Value |\n"
            output += "|--------|-------|\n"
            for (key, value) in stats {
                output += "| \(key) | \(value) |\n"
            }
            output += "\n"
        }
        
        output += "## File Structure\n\n"
        output += "```\n"
        output += generateFileTree(files: files)
        output += "```\n\n"
        
        output += "## File Contents\n\n"
        output += generateMarkdownFileContents(files: files)
        
        return output
    }
    
    // MARK: - JSON Export
    private func exportAsJSON(repository: Repository, files: [FileNode], includeMetadata: Bool) -> String {
        let jsonData = RepositoryExport(
            repository: repository,
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            statistics: includeMetadata ? generateStatistics(files: files) : [:],
            fileTree: generateJSONFileTree(files: files),
            files: generateJSONFiles(files: files)
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let jsonData = try encoder.encode(jsonData)
            return String(data: jsonData, encoding: .utf8) ?? "Error encoding JSON"
        } catch {
            return "Error: \(error.localizedDescription)"
        }
    }
    
    // MARK: - XML Export
    private func exportAsXML(repository: Repository, files: [FileNode], includeMetadata: Bool) -> String {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        xml += "<repository>\n"
        
        if includeMetadata {
            xml += "  <metadata>\n"
            xml += "    <name>\(xmlEscape(repository.name))</name>\n"
            xml += "    <url>\(xmlEscape(repository.htmlUrl))</url>\n"
            xml += "    <owner>\(xmlEscape(repository.owner.login))</owner>\n"
            if let description = repository.description {
                xml += "    <description>\(xmlEscape(description))</description>\n"
            }
            xml += "    <generated>\(formattedDate())</generated>\n"
            xml += "  </metadata>\n"
        }
        
        xml += "  <files>\n"
        xml += generateXMLFiles(files: files, indent: "    ")
        xml += "  </files>\n"
        xml += "</repository>"
        
        return xml
    }
    
    // MARK: - YAML Export
    private func exportAsYAML(repository: Repository, files: [FileNode], includeMetadata: Bool) -> String {
        var yaml = ""
        
        if includeMetadata {
            yaml += "repository:\n"
            yaml += "  name: \"\(repository.name)\"\n"
            yaml += "  url: \"\(repository.htmlUrl)\"\n"
            yaml += "  owner: \"\(repository.owner.login)\"\n"
            if let description = repository.description {
                yaml += "  description: \"\(description)\"\n"
            }
            yaml += "  generated: \"\(formattedDate())\"\n\n"
        }
        
        yaml += "files:\n"
        yaml += generateYAMLFiles(files: files, indent: "  ")
        
        return yaml
    }
    
    // MARK: - CSV Export
    private func exportAsCSV(repository: Repository, files: [FileNode], includeMetadata: Bool) -> String {
        var csv = "File Path,File Name,Type,Category,Size (Bytes),Token Count,Content\n"
        
        func processNode(_ node: FileNode, path: String = "") {
            let fullPath = path.isEmpty ? node.name : "\(path)/\(node.name)"
            let type = node.isDirectory ? "Directory" : "File"
            let content = node.content?.replacingOccurrences(of: "\"", with: "\"\"") ?? ""
            
            csv += "\"\(fullPath)\",\"\(node.name)\",\"\(type)\",\"\(node.category.rawValue)\",\(node.size),\(node.tokenCount),\"\(content)\"\n"
            
            if node.isDirectory {
                for child in node.children.filter(\.isIncluded) {
                    processNode(child, path: fullPath)
                }
            }
        }
        
        for file in files.filter(\.isIncluded) {
            processNode(file)
        }
        
        return csv
    }
    
    // MARK: - HTML Export
    private func exportAsHTML(repository: Repository, files: [FileNode], includeMetadata: Bool) -> String {
        var html = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>\(repository.name) - Repository Export</title>
            <style>
                body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; margin: 0; padding: 20px; }
                .container { max-width: 1200px; margin: 0 auto; }
                .header { border-bottom: 2px solid #e1e5e9; padding-bottom: 20px; margin-bottom: 30px; }
                .file-tree { background: #f6f8fa; padding: 20px; border-radius: 8px; margin: 20px 0; }
                .file-content { border: 1px solid #e1e5e9; border-radius: 8px; margin: 20px 0; }
                .file-header { background: #f6f8fa; padding: 10px 20px; border-bottom: 1px solid #e1e5e9; font-weight: bold; }
                .file-body { padding: 20px; }
                pre { background: #f6f8fa; padding: 15px; border-radius: 5px; overflow-x: auto; }
                code { background: #f6f8fa; padding: 2px 5px; border-radius: 3px; }
                .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin: 20px 0; }
                .stat { background: #f6f8fa; padding: 15px; border-radius: 8px; text-align: center; }
                .category-source { color: #0969da; }
                .category-config { color: #bf8700; }
                .category-documentation { color: #1a7f37; }
                .category-assets { color: #8250df; }
                .category-data { color: #cf222e; }
                .category-tests { color: #d1242f; }
                .category-build { color: #656d76; }
            </style>
        </head>
        <body>
            <div class="container">
        """
        
        if includeMetadata {
            html += """
                <div class="header">
                    <h1>\(repository.name)</h1>
                    <p><strong>Repository:</strong> <a href="\(repository.htmlUrl)">\(repository.htmlUrl)</a></p>
                    <p><strong>Owner:</strong> \(repository.owner.login)</p>
            """
            if let description = repository.description {
                html += "<p><strong>Description:</strong> \(htmlEscape(description))</p>"
            }
            html += "<p><strong>Generated:</strong> \(formattedDate())</p>"
            
            let stats = generateStatistics(files: files)
            html += "<div class=\"stats\">"
            for (key, value) in stats {
                html += "<div class=\"stat\"><strong>\(key)</strong><br>\(value)</div>"
            }
            html += "</div></div>"
        }
        
        html += "<div class=\"file-tree\"><h2>File Structure</h2><pre>\(htmlEscape(generateFileTree(files: files)))</pre></div>"
        
        html += generateHTMLFileContents(files: files)
        
        html += """
            </div>
        </body>
        </html>
        """
        
        return html
    }
    
    // MARK: - Custom Template Export
    private func exportWithCustomTemplate(repository: Repository, files: [FileNode], template: String, includeMetadata: Bool) -> String {
        var output = template
        
        // Replace template variables
        output = output.replacingOccurrences(of: "{{REPO_NAME}}", with: repository.name)
        output = output.replacingOccurrences(of: "{{REPO_URL}}", with: repository.htmlUrl)
        output = output.replacingOccurrences(of: "{{REPO_OWNER}}", with: repository.owner.login)
        output = output.replacingOccurrences(of: "{{REPO_DESCRIPTION}}", with: repository.description ?? "")
        output = output.replacingOccurrences(of: "{{GENERATED_DATE}}", with: formattedDate())
        output = output.replacingOccurrences(of: "{{FILE_TREE}}", with: generateFileTree(files: files))
        output = output.replacingOccurrences(of: "{{FILE_CONTENTS}}", with: generateFileContents(files: files))
        
        let stats = generateStatistics(files: files)
        for (key, value) in stats {
            output = output.replacingOccurrences(of: "{{\(key.uppercased().replacingOccurrences(of: " ", with: "_"))}}", with: value)
        }
        
        return output
    }
    
    // MARK: - Helper Methods
    private func generateMetadataHeader(repository: Repository, files: [FileNode]) -> String {
        var header = "Repository: \(repository.name)\n"
        header += "URL: \(repository.htmlUrl)\n"
        header += "Owner: \(repository.owner.login)\n"
        if let description = repository.description {
            header += "Description: \(description)\n"
        }
        header += "Generated: \(formattedDate())\n"
        
        let stats = generateStatistics(files: files)
        header += "\nRepository Statistics:\n"
        for (key, value) in stats {
            header += "- \(key): \(value)\n"
        }
        
        return header
    }
    
    private func generateStatistics(files: [FileNode]) -> [String: String] {
        var stats: [String: String] = [:]
        var totalFiles = 0
        var totalTokens = 0
        var categoryCounts: [FileTypeCategories.Category: Int] = [:]
        
        func processNode(_ node: FileNode) {
            if node.isDirectory {
                node.children.filter(\.isIncluded).forEach(processNode)
            } else if node.isIncluded {
                totalFiles += 1
                totalTokens += node.tokenCount
                categoryCounts[node.category, default: 0] += 1
            }
        }
        
        files.filter(\.isIncluded).forEach(processNode)
        
        stats["Total Files"] = "\(totalFiles)"
        stats["Total Tokens"] = "\(totalTokens)"
        
        for category in FileTypeCategories.Category.allCases {
            if let count = categoryCounts[category], count > 0 {
                stats["\(category.rawValue) Files"] = "\(count)"
            }
        }
        
        return stats
    }
    
    private func generateFileTree(files: [FileNode]) -> String {
        var tree = ""
        for file in files.filter(\.isIncluded) {
            tree += file.generateTreeString()
        }
        return tree
    }
    
    private func generateFileContents(files: [FileNode]) -> String {
        var content = ""
        
        func processNode(_ node: FileNode) {
            if node.isDirectory {
                node.children.filter(\.isIncluded).forEach(processNode)
            } else if node.isIncluded, let fileContent = node.content {
                content += "---\nFile: \(node.path)\n---\n\(fileContent)\n\n"
            }
        }
        
        files.filter(\.isIncluded).forEach(processNode)
        return content
    }
    
    private func generateMarkdownFileContents(files: [FileNode]) -> String {
        var content = ""
        
        func processNode(_ node: FileNode) {
            if node.isDirectory {
                node.children.filter(\.isIncluded).forEach(processNode)
            } else if node.isIncluded, let fileContent = node.content {
                let language = detectLanguage(from: node.name)
                content += "### \(node.path)\n\n"
                content += "```\(language)\n\(fileContent)\n```\n\n"
            }
        }
        
        files.filter(\.isIncluded).forEach(processNode)
        return content
    }
    
    private func generateHTMLFileContents(files: [FileNode]) -> String {
        var content = ""
        
        func processNode(_ node: FileNode) {
            if node.isDirectory {
                node.children.filter(\.isIncluded).forEach(processNode)
            } else if node.isIncluded, let fileContent = node.content {
                let categoryClass = "category-\(node.category.rawValue.lowercased().replacingOccurrences(of: " ", with: "-").replacingOccurrences(of: "&", with: ""))"
                content += """
                <div class="file-content">
                    <div class="file-header \(categoryClass)">\(htmlEscape(node.path)) (\(node.category.rawValue))</div>
                    <div class="file-body"><pre><code>\(htmlEscape(fileContent))</code></pre></div>
                </div>
                """
            }
        }
        
        files.filter(\.isIncluded).forEach(processNode)
        return content
    }
    
    private func generateJSONFileTree(files: [FileNode]) -> [JSONFileNode] {
        return files.filter(\.isIncluded).map { JSONFileNode(from: $0) }
    }
    
    private func generateJSONFiles(files: [FileNode]) -> [JSONFile] {
        var jsonFiles: [JSONFile] = []
        
        func processNode(_ node: FileNode) {
            if node.isDirectory {
                node.children.filter(\.isIncluded).forEach(processNode)
            } else if node.isIncluded {
                jsonFiles.append(JSONFile(from: node))
            }
        }
        
        files.filter(\.isIncluded).forEach(processNode)
        return jsonFiles
    }
    
    private func generateXMLFiles(files: [FileNode], indent: String) -> String {
        var xml = ""
        
        for file in files.filter(\.isIncluded) {
            if file.isDirectory {
                xml += "\(indent)<directory name=\"\(xmlEscape(file.name))\" path=\"\(xmlEscape(file.path))\">\n"
                xml += generateXMLFiles(files: file.children, indent: indent + "  ")
                xml += "\(indent)</directory>\n"
            } else {
                xml += "\(indent)<file name=\"\(xmlEscape(file.name))\" path=\"\(xmlEscape(file.path))\" category=\"\(xmlEscape(file.category.rawValue))\" tokens=\"\(file.tokenCount)\">\n"
                if let content = file.content {
                    xml += "\(indent)  <content><![CDATA[\(content)]]></content>\n"
                }
                xml += "\(indent)</file>\n"
            }
        }
        
        return xml
    }
    
    private func generateYAMLFiles(files: [FileNode], indent: String) -> String {
        var yaml = ""
        
        for file in files.filter(\.isIncluded) {
            if file.isDirectory {
                yaml += "\(indent)- name: \"\(file.name)\"\n"
                yaml += "\(indent)  type: directory\n"
                yaml += "\(indent)  path: \"\(file.path)\"\n"
                yaml += "\(indent)  children:\n"
                yaml += generateYAMLFiles(files: file.children, indent: indent + "    ")
            } else {
                yaml += "\(indent)- name: \"\(file.name)\"\n"
                yaml += "\(indent)  type: file\n"
                yaml += "\(indent)  path: \"\(file.path)\"\n"
                yaml += "\(indent)  category: \"\(file.category.rawValue)\"\n"
                yaml += "\(indent)  tokens: \(file.tokenCount)\n"
                if let content = file.content {
                    let escapedContent = content.replacingOccurrences(of: "\"", with: "\\\"")
                    yaml += "\(indent)  content: \"\(escapedContent)\"\n"
                }
            }
        }
        
        return yaml
    }
    
    private func detectLanguage(from fileName: String) -> String {
        let ext = (fileName as NSString).pathExtension.lowercased()
        
        switch ext {
        case "swift": return "swift"
        case "py": return "python"
        case "js": return "javascript"
        case "ts": return "typescript"
        case "jsx": return "jsx"
        case "tsx": return "tsx"
        case "java": return "java"
        case "kt": return "kotlin"
        case "go": return "go"
        case "rs": return "rust"
        case "cpp", "cc", "cxx": return "cpp"
        case "c": return "c"
        case "h", "hpp": return "c"
        case "cs": return "csharp"
        case "php": return "php"
        case "rb": return "ruby"
        case "scala": return "scala"
        case "clj": return "clojure"
        case "elm": return "elm"
        case "dart": return "dart"
        case "vue": return "vue"
        case "svelte": return "svelte"
        case "json": return "json"
        case "xml": return "xml"
        case "yml", "yaml": return "yaml"
        case "toml": return "toml"
        case "css": return "css"
        case "scss": return "scss"
        case "sass": return "sass"
        case "less": return "less"
        case "html": return "html"
        case "md": return "markdown"
        case "sql": return "sql"
        case "sh", "bash": return "bash"
        case "zsh": return "zsh"
        case "fish": return "fish"
        case "ps1": return "powershell"
        default: return ""
        }
    }
    
    private func xmlEscape(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
    
    private func htmlEscape(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
    
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .medium
        return formatter.string(from: Date())
    }
    
    private let defaultTemplate = """
    Repository: {{REPO_NAME}}
    URL: {{REPO_URL}}
    Owner: {{REPO_OWNER}}
    Description: {{REPO_DESCRIPTION}}
    Generated: {{GENERATED_DATE}}
    
    Total Files: {{TOTAL_FILES}}
    Total Tokens: {{TOTAL_TOKENS}}
    
    File Structure:
    {{FILE_TREE}}
    
    File Contents:
    {{FILE_CONTENTS}}
    """
}

// MARK: - JSON Export Models
struct RepositoryExport: Codable {
    let repository: Repository
    let generatedAt: String
    let statistics: [String: String]
    let fileTree: [JSONFileNode]
    let files: [JSONFile]
}

struct JSONFileNode: Codable {
    let name: String
    let path: String
    let type: String
    let category: String
    let tokenCount: Int
    let children: [JSONFileNode]?
    
    init(from fileNode: FileNode) {
        self.name = fileNode.name
        self.path = fileNode.path
        self.type = fileNode.isDirectory ? "directory" : "file"
        self.category = fileNode.category.rawValue
        self.tokenCount = fileNode.totalTokenCount
        self.children = fileNode.isDirectory ? fileNode.children.filter(\.isIncluded).map { JSONFileNode(from: $0) } : nil
    }
}

struct JSONFile: Codable {
    let name: String
    let path: String
    let category: String
    let size: Int
    let tokenCount: Int
    let content: String?
    
    init(from fileNode: FileNode) {
        self.name = fileNode.name
        self.path = fileNode.path
        self.category = fileNode.category.rawValue
        self.size = fileNode.size
        self.tokenCount = fileNode.tokenCount
        self.content = fileNode.content
    }
} 