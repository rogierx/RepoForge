import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = MainViewModel()
    
    var body: some View {
        NavigationSplitView {
            SidebarView(viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 250, ideal: 280, max: 350)
        } detail: {
            DetailView(viewModel: viewModel)
                .navigationTitle("")
        }
        .navigationTitle("")
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil), actions: {
            Button("OK", role: .cancel) {
                viewModel.errorMessage = nil
            }
        }, message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred.")
        })
    }
}

struct SidebarView: View {
    @ObservedObject var viewModel: MainViewModel
    
    var body: some View {
        ZStack {
            // Glass background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(NSColor.controlBackgroundColor).opacity(0.9),
                    Color(NSColor.windowBackgroundColor).opacity(0.7)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Main content
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        // Recent section
                        RecentSection()
                        
                        // Bookmarks section
                        BookmarksSection()
                        
                        // Output Bookmarks section
                        OutputBookmarksSection()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                }
                .scrollIndicators(.never)
                
                Spacer()
                
                // Settings button in sidebar with glass effect
                HStack {
                    Button(action: {}) {
                        HStack(spacing: 6) {
                            Image(systemName: "gearshape")
                                .font(.system(size: 12))
                            Text("Settings")
                                .font(.system(size: 12))
                        }
                    }
                    .buttonStyle(GlassButtonStyle())
                    .controlSize(.small)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
    }
}

struct RecentSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "clock")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Text("Recent")
                    .font(.system(size: 13, weight: .medium))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                RecentItemView(name: "RechtGPT-V2", date: "20-07-25")
            }
            .padding(.leading, 16)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct RecentItemView: View {
    let name: String
    let date: String
    
    var body: some View {
        HStack {
            Text(name)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer()
            Text(date)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(4)
    }
}

struct BookmarksSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "bookmark")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Text("Bookmarks")
                    .font(.system(size: 13, weight: .medium))
                Spacer()
                Button(action: {}) {
                    Image(systemName: "plus")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            Text("No bookmarks yet")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .padding(.leading, 16)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct OutputBookmarksSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Text("Output Bookmarks")
                    .font(.system(size: 13, weight: .medium))
            }
            
            Text("No saved outputs")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .padding(.leading, 16)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct DetailView: View {
    @ObservedObject var viewModel: MainViewModel
    @State private var selectedDetailTab = "Main"
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content
            switch selectedDetailTab {
            case "Main":
                MainInputView(viewModel: viewModel)
            case "File Tree":
                FileTreeMainView(viewModel: viewModel)
            case "Output":
                OutputMainView(viewModel: viewModel)
            default:
                MainInputView(viewModel: viewModel)
            }
            
            Spacer()
            
            // Footer
            FooterView()
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                // Tab buttons in the center of toolbar
                HStack(spacing: 0) {
                    TabButton(title: "Main", isSelected: selectedDetailTab == "Main") {
                        selectedDetailTab = "Main"
                    }
                    TabButton(title: "File Tree", isSelected: selectedDetailTab == "File Tree") {
                        selectedDetailTab = "File Tree"
                    }
                    TabButton(title: "Output", isSelected: selectedDetailTab == "Output") {
                        selectedDetailTab = "Output"
                    }
                }
            }
            

        }
        .onChange(of: viewModel.selectedTab) { newValue in
            // Auto-switch to File Tree when processing completes
            if newValue == 1 {
                selectedDetailTab = "File Tree"
            }
        }
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isSelected ? .primary : .secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? Color(.selectedControlColor) : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }
}

struct MainInputView: View {
    @ObservedObject var viewModel: MainViewModel
    
    var body: some View {
        ZStack {
            // Background gradient for glassmorphism
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemBackground).opacity(0.8),
                    Color(.controlBackgroundColor).opacity(0.6)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                AppLogoView(size: 128)
                
                // Glass effect container for main form
                VStack(spacing: 24) {
                    // Repo type picker with glass effect
                    VStack(spacing: 16) {
                        Picker("", selection: $viewModel.repoType) {
                            ForEach(MainViewModel.RepoType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        
                        // Conditional fields based on repo type
                        if viewModel.repoType == .github {
                            VStack(spacing: 12) {
                                TextField("GitHub Repository URL", text: $viewModel.githubURL)
                                    .textFieldStyle(GlassTextFieldStyle())
                                
                                SecureField("Personal Access Token", text: $viewModel.accessToken)
                                    .textFieldStyle(GlassTextFieldStyle())
                            }
                        } else {
                            HStack {
                                TextField("Local Repository Path", text: $viewModel.localPath)
                                    .textFieldStyle(GlassTextFieldStyle())
                                
                                Button("Browse") {
                                    let panel = NSOpenPanel()
                                    panel.allowsMultipleSelection = false
                                    panel.canChooseDirectories = true
                                    panel.canChooseFiles = false
                                    if panel.runModal() == .OK {
                                        viewModel.localPath = panel.url?.path ?? ""
                                    }
                                }
                                .buttonStyle(GlassButtonStyle())
                            }
                        }
                        
                        HStack(spacing: 20) {
                            Toggle("Include VENV", isOn: $viewModel.includeVirtualEnvironments)
                                .toggleStyle(GlassToggleStyle())
                            
                            if viewModel.repoType == .github {
                                Toggle("Save URL and Token", isOn: $viewModel.saveURL)
                                    .toggleStyle(GlassToggleStyle())
                            } else {
                                Toggle("Save Path", isOn: $viewModel.saveURL)
                                    .toggleStyle(GlassToggleStyle())
                            }
                        }
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.1))
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .blur(radius: 0.5)
                )
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                .frame(maxWidth: 500)
                
                // Process button with glass effect
                if viewModel.isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Processing...")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.1))
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                            )
                    )
                } else {
                    Button("Process Repository") {
                        viewModel.processRepository()
                    }
                    .buttonStyle(GlassPrimaryButtonStyle())
                }
                
                // Verbose logs with glass effect
                if !viewModel.verboseLogs.isEmpty {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(viewModel.verboseLogs, id: \.self) { log in
                                Text(log)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(16)
                    }
                    .frame(height: 150)
                    .frame(maxWidth: 500)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.05))
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .scrollIndicators(.never)
                }
            }
            .padding(40)
        }
    }
}

// MARK: - Glass Styles

struct GlassTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.08))
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}

struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(configuration.isPressed ? 0.15 : 0.1))
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct GlassPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(configuration.isPressed ? 0.7 : 0.8),
                                Color.blue.opacity(configuration.isPressed ? 0.5 : 0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
            )
            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct GlassToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
                .font(.system(size: 14, weight: .medium))
            
            Spacer()
            
            RoundedRectangle(cornerRadius: 12)
                .fill(configuration.isOn ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(configuration.isOn ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1)
                )
                .frame(width: 44, height: 24)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        .frame(width: 18, height: 18)
                        .offset(x: configuration.isOn ? 8 : -8)
                        .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
                )
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
    }
}

struct FileTreeMainView: View {
    @ObservedObject var viewModel: MainViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Top controls
            HStack {
                if viewModel.isGeneratingOutput {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Generating Output...")
                        Button("Cancel") {
                            viewModel.cancelGenerateOutput()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                } else {
                    Button("Generate Output") {
                        viewModel.generateOutput()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.fileTree == nil)
                }
                
                Spacer()
                
                // Token counts
                if let fileTree = viewModel.fileTree {
                    TokenCountsView(fileTree: fileTree)
                }
                
                ExcludeOptionsView()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(.controlBackgroundColor))
            
            Divider()
            
            // File tree content
            if let fileTree = viewModel.fileTree {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        FileTreeNodeView(node: fileTree, level: 0)
                    }
                    .padding(.leading, 20)
                    .padding(.vertical, 12)
                }
                .scrollIndicators(.never)
            } else {
                VStack {
                    Image(systemName: "folder.tree")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No repository loaded")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Process a repository to see its file structure")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

struct FileTreeNodeView: View {
    @ObservedObject var node: FileNode
    let level: Int
    @State private var isExpanded: Bool
    
    init(node: FileNode, level: Int) {
        self.node = node
        self.level = level
        // Main folder (level 0) should be expanded, all others collapsed
        self._isExpanded = State(initialValue: level == 0)
    }
    
    private func calculateFolderTokens(_ node: FileNode) -> Int {
        var total = 0
        for child in node.children {
            if child.isDirectory {
                total += calculateFolderTokens(child)
            } else {
                total += child.tokenCount
            }
        }
        return total
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                // Indentation
                HStack(spacing: 0) {
                    ForEach(0..<level, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 16)
                    }
                }
                
                // Folder arrow or file icon
                if node.isDirectory {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 12, height: 12)
                    }
                    .buttonStyle(.plain)
                    
                    Image(systemName: isExpanded ? "folder.fill" : "folder")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                } else {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 12, height: 12)
                    
                    Image(systemName: "doc.text")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                // File/folder name
                Text(node.name)
                    .font(.system(size: 13))
                    .lineLimit(1)
                
                Spacer()
                
                // Token count and checkbox
                HStack(spacing: 8) {
                    if node.isDirectory {
                        let folderTokens = calculateFolderTokens(node)
                        if folderTokens > 0 {
                            Text("\(folderTokens)")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    } else if node.tokenCount > 0 {
                        Text("\(node.tokenCount)")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    Toggle("", isOn: $node.isIncluded)
                        .toggleStyle(.checkbox)
                        .scaleEffect(0.8)
                }
            }
            .padding(.vertical, 2)
            .contentShape(Rectangle())
            
            // Children (if expanded)
            if isExpanded && node.isDirectory {
                ForEach(node.children, id: \.id) { child in
                    FileTreeNodeView(node: child, level: level + 1)
                }
            }
        }
    }
}

struct OutputMainView: View {
    @ObservedObject var viewModel: MainViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isGeneratingOutput {
                VStack {
                    ProgressView("Generating Output...")
                    Text("This may take a moment...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if !viewModel.generatedOutput.isEmpty {
                // Output header with stats
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Generated Output")
                                .font(.headline)
                            
                            Spacer()
                            
                            // Export options with icons
                            HStack(spacing: 8) {
                                Button(action: {
                                    let pasteboard = NSPasteboard.general
                                    pasteboard.clearContents()
                                    pasteboard.setString(viewModel.generatedOutput, forType: .string)
                                }) {
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 12))
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                
                                Button(action: {
                                    // TODO: Implement bookmark
                                }) {
                                    Image(systemName: "bookmark")
                                        .font(.system(size: 12))
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                
                                Menu {
                                    Button("Save as .txt") {
                                        // TODO: Implement save as txt
                                    }
                                    Button("Save as .md") {
                                        // TODO: Implement save as md
                                    }
                                } label: {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 12))
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .menuStyle(.borderlessButton)
                            }
                        }
                        
                        HStack(spacing: 16) {
                            Label("182,894", systemImage: "number")
                            Label("187", systemImage: "doc")
                            Label("RechtGPT-V2", systemImage: "folder")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(.controlBackgroundColor))
                
                Divider()
                
                // Output content
                ScrollView {
                    Text(viewModel.generatedOutput)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .padding(20)
                }
                .scrollIndicators(.visible)
            } else {
                VStack {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No output generated")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Process a repository and generate output to see it here")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

struct TokenCountsView: View {
    let fileTree: FileNode
    
    private var totalTokens: Int {
        calculateTotalTokens(fileTree)
    }
    
    private var selectedTokens: Int {
        calculateSelectedTokens(fileTree)
    }
    
    private func calculateTotalTokens(_ node: FileNode) -> Int {
        var total = 0
        if node.isDirectory {
            for child in node.children {
                total += calculateTotalTokens(child)
            }
        } else {
            total += node.tokenCount
        }
        return total
    }
    
    private func calculateSelectedTokens(_ node: FileNode) -> Int {
        var total = 0
        if node.isDirectory {
            for child in node.children {
                total += calculateSelectedTokens(child)
            }
        } else if node.isIncluded {
            total += node.tokenCount
        }
        return total
    }
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("Total: \(totalTokens.formatted())")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
            Text("Selected: \(selectedTokens.formatted())")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.primary)
        }
    }
}

struct ExcludeOptionsView: View {
    @State private var excludeNodeModules = true
    @State private var excludeVenv = true
    @State private var excludeBuildDirs = true
    @State private var excludeGit = true
    @State private var excludeDSStore = true
    @State private var showingPopover = false
    
    var body: some View {
        Button(action: {
            showingPopover.toggle()
        }) {
            HStack(spacing: 4) {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.system(size: 12))
                Text("Exclude")
                    .font(.system(size: 13))
            }
        }
        .buttonStyle(.bordered)
        .popover(isPresented: $showingPopover) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Exclude Options")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("node_modules/", isOn: $excludeNodeModules)
                    Toggle(".venv/, venv/", isOn: $excludeVenv)
                    Toggle("build/, dist/, target/", isOn: $excludeBuildDirs)
                    Toggle(".git/, .svn/", isOn: $excludeGit)
                    Toggle(".DS_Store, Thumbs.db", isOn: $excludeDSStore)
                }
                .toggleStyle(.checkbox)
                
                Divider()
                
                HStack {
                    Button("Select All") {
                        excludeNodeModules = true
                        excludeVenv = true
                        excludeBuildDirs = true
                        excludeGit = true
                        excludeDSStore = true
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                    
                    Spacer()
                    
                    Button("Select None") {
                        excludeNodeModules = false
                        excludeVenv = false
                        excludeBuildDirs = false
                        excludeGit = false
                        excludeDSStore = false
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                }
            }
            .padding(16)
            .frame(width: 220)
        }
    }
}

struct FooterView: View {
    var body: some View {
        HStack {
            Spacer()
            
            Button(action: {
                if let url = URL(string: "https://github.com/rogierx") {
                    NSWorkspace.shared.open(url)
                }
            }) {
                HStack(spacing: 4) {
                    Text("made by")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text("rogierx")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.controlBackgroundColor))
    }
}
