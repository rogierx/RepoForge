import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = MainViewModel()
    
    var body: some View {
        HSplitView {
            SidebarView(viewModel: viewModel)
                .frame(width: 50)
            
            DetailView(viewModel: viewModel)
                .frame(minWidth: 750)
        }
        .frame(minWidth: 800, minHeight: 500)
        .background(Color.white)
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
    @State private var showingSettings = false
    
    var body: some View {
        ZStack {
            Color.clear
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                VStack(spacing: 20) {
                    Button(action: {
                        viewModel.activePage = .main
                    }) {
                        Image(systemName: "house")
                            .font(.system(size: 16))
                            .foregroundColor(viewModel.activePage == .main ? .black : .secondary)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        viewModel.activePage = .recents
                    }) {
                        Image(systemName: "clock")
                            .font(.system(size: 16))
                            .foregroundColor(viewModel.activePage == .recents ? .black : .secondary)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        viewModel.activePage = .bookmarks
                        viewModel.resetNewBookmarksCount()
                    }) {
                        ZStack {
                            Image(systemName: "bookmark")
                                .font(.system(size: 16))
                                .foregroundColor(viewModel.activePage == .bookmarks ? .black : .secondary)
                            
                            if viewModel.newBookmarksCount > 0 {
                                Text("\(viewModel.newBookmarksCount)")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(minWidth: 12, minHeight: 12)
                                    .background(Circle().fill(Color.red))
                                    .offset(x: 8, y: -8)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 20)
                
                Spacer()
                
                VStack(spacing: 16) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showingSettings) {
                        SettingsView()
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .background(Color.clear)
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
    
    var body: some View {
        VStack(spacing: 0) {
            if [.main, .fileTree, .output].contains(viewModel.activePage) {
                HStack(spacing: 0) {
                    Spacer()
                    
                    TabButton(title: "Main", isSelected: viewModel.activePage == .main) {
                        viewModel.activePage = .main
                    }
                    TabButton(title: "File Tree", isSelected: viewModel.activePage == .fileTree) {
                        viewModel.activePage = .fileTree
                    }
                    TabButton(title: "Output", isSelected: viewModel.activePage == .output) {
                        viewModel.activePage = .output
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.white)
            }
            
            switch viewModel.activePage {
            case .main:
                MainInputView(viewModel: viewModel)
            case .fileTree:
                FileTreeMainView(viewModel: viewModel)
            case .output:
                OutputMainView(viewModel: viewModel)
            case .recents:
                RecentsPageView(viewModel: viewModel)
            case .bookmarks:
                BookmarksPageView(viewModel: viewModel)
            }
            
            Spacer()
            
            FooterView()
        }
        .onChange(of: viewModel.selectedTab) { newValue in
            if newValue == 1 {
                viewModel.activePage = .fileTree
            }
            else if newValue == 2 {
                viewModel.activePage = .output
            }
        }
        .onChange(of: viewModel.isGeneratingOutput) { isGenerating in
            if !isGenerating && !viewModel.generatedOutput.isEmpty {
                viewModel.activePage = .output
                viewModel.checkCurrentOutputBookmarkStatus()
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
        VStack(spacing: 32) {
            AppLogoView(size: 128)
            
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Picker("", selection: $viewModel.repoType) {
                        ForEach(MainViewModel.RepoType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    
                    if viewModel.repoType == .github {
                        VStack(spacing: 12) {
                            TextField("GitHub Repository URL", text: $viewModel.githubURL)
                                .textFieldStyle(.roundedBorder)
                            
                            SecureField("Personal Access Token (optional for public repos)", text: $viewModel.accessToken)
                                .textFieldStyle(.roundedBorder)
                        }
                    } else {
                        HStack {
                            TextField("Local Repository Path", text: $viewModel.localPath)
                                .textFieldStyle(.roundedBorder)
                            
                            Button("Browse") {
                                let panel = NSOpenPanel()
                                panel.allowsMultipleSelection = false
                                panel.canChooseDirectories = true
                                panel.canChooseFiles = false
                                if panel.runModal() == .OK {
                                    viewModel.localPath = panel.url?.path ?? ""
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    
                    HStack(spacing: 20) {
                        Toggle("Include VENV", isOn: $viewModel.includeVirtualEnvironments)
                        
                        if viewModel.repoType == .github {
                            Toggle("Save URL and Token", isOn: $viewModel.saveURL)
                        } else {
                            Toggle("Save Path", isOn: $viewModel.saveURL)
                        }
                    }
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                    )
            )
            .frame(maxWidth: 500)
            
            Button(action: {
                viewModel.processRepository()
            }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                    Text(viewModel.isLoading ? "Processing..." : "Process Repository")
                        .font(.system(size: 14, weight: .medium))
                }
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.isLoading)
        }
        .padding(40)
    }
}


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
            HStack {
                Button(action: {
                    if viewModel.isGeneratingOutput {
                        viewModel.cancelGenerateOutput()
                    } else {
                        viewModel.generateOutput()
                    }
                }) {
                    HStack(spacing: 4) {
                        if viewModel.isGeneratingOutput {
                            ProgressView()
                                .scaleEffect(0.5)
                                .progressViewStyle(CircularProgressViewStyle(tint: .primary))
                        }
                        Text(viewModel.isGeneratingOutput ? "Generating..." : "Generate Output")
                            .font(.system(size: 12, weight: .medium))
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(viewModel.fileTree == nil)
                
                Spacer()
                
                HStack(spacing: 12) {
                    if let fileTree = viewModel.fileTree {
                        TokenCountsView(fileTree: fileTree)
                    }
                    
                    ExcludeOptionsView()
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(.controlBackgroundColor))
            
            Divider()
            
            if let fileTree = viewModel.fileTree {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        FileTreeNodeView(node: fileTree, level: 0)
                    }
                    .padding(.horizontal, 20)
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
                HStack(spacing: 0) {
                    ForEach(0..<level, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 16)
                    }
                }
                
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
                        .foregroundColor(.secondary)
                } else {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 12, height: 12)
                    
                    Image(systemName: "doc.text")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Text(node.name)
                    .font(.system(size: 13))
                    .lineLimit(1)
                
                Spacer()
                
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
                    
                    Toggle("", isOn: Binding(
                        get: { node.isIncluded },
                        set: { newValue in
                            node.updateInclusion(isIncluded: newValue, includeChildren: true)
                        }
                    ))
                    .toggleStyle(.checkbox)
                    .scaleEffect(0.8)
                }
            }
            .padding(.vertical, 2)
            .contentShape(Rectangle())
            
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
    
    private func showSavePanel() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.plainText, .item]
        savePanel.nameFieldStringValue = "repository_output"
        savePanel.allowsOtherFileTypes = true
        savePanel.canCreateDirectories = true
        
        let response = savePanel.runModal()
        if response == .OK, let url = savePanel.url {
            var finalURL = url
            
            if finalURL.pathExtension.isEmpty {
                finalURL = finalURL.appendingPathExtension("txt")
            }
            
            do {
                try viewModel.generatedOutput.write(to: finalURL, atomically: true, encoding: .utf8)
            } catch {
                viewModel.showError("Failed to save file: \(error.localizedDescription)")
            }
        }
    }
    
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
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Generated Output")
                                .font(.headline)
                            
                            Spacer()
                            
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
                                    viewModel.toggleCurrentOutputBookmark()
                                }) {
                                    Image(systemName: viewModel.isCurrentOutputBookmarked ? "bookmark.fill" : "bookmark")
                                        .font(.system(size: 12))
                                        .foregroundColor(viewModel.isCurrentOutputBookmarked ? .black : .primary)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                
                                Button(action: {
                                    showSavePanel()
                                }) {
                                    Image(systemName: "arrow.down.circle")
                                        .font(.system(size: 12))
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                        
                        HStack(spacing: 16) {
                            Label("182,894", systemImage: "number")
                            Label("187", systemImage: "doc")
                            Label(viewModel.currentRepository?.name ?? "Repository", systemImage: "folder")
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
                
                ScrollView {
                    Text(viewModel.generatedOutput)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .padding(20)
                }
                .scrollIndicators(.visible)
            } else {
                VStack {
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
    @ObservedObject var fileTree: FileNode
    @State private var updateTrigger = 0
    
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
        if !node.isIncluded {
            return 0
        }
        
        var total = 0
        if node.isDirectory {
            for child in node.children {
                total += calculateSelectedTokens(child)
            }
        } else {
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
        .id(updateTrigger)
        .onReceive(fileTree.objectWillChange) { _ in
            DispatchQueue.main.async {
                updateTrigger += 1
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("FileNodeChanged"))) { _ in
            DispatchQueue.main.async {
                updateTrigger += 1
            }
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
            HStack(spacing: 6) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 13))
                Text("Exclude")
                    .font(.system(size: 13, weight: .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .buttonStyle(.borderless)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                )
        )
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
                if let url = URL(string: "https:
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

struct BookmarksView: View {
    @ObservedObject var viewModel: MainViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bookmarks")
                .font(.headline)
            
            Text("Repository Bookmarks")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if viewModel.bookmarkedRepositories.isEmpty {
                Text("No bookmarked repositories")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(viewModel.bookmarkedRepositories, id: \.self) { repo in
                    HStack {
                        Button(action: {
                            viewModel.loadBookmarkedRepository(repo)
                        }) {
                            HStack {
                                Image(systemName: "bookmark.fill")
                                    .foregroundColor(.orange)
                                Text(repo)
                                    .font(.system(size: 13))
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            viewModel.removeBookmark(repo)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .font(.system(size: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            if let currentRepo = viewModel.currentRepository {
                Button("Bookmark Current Repository") {
                    viewModel.addBookmark(currentRepo.fullName)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            Divider()
            
            Text("Output Bookmarks")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if viewModel.savedOutputs.isEmpty {
                Text("No saved outputs")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(viewModel.savedOutputs, id: \.id) { output in
                    HStack {
                        Button(action: {
                            viewModel.loadSavedOutput(output)
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(output.name)
                                    .font(.system(size: 13, weight: .medium))
                                Text("\(output.fileCount) files • \(output.tokenCount) tokens")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        Button(action: {
                            viewModel.deleteSavedOutput(output)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .font(.system(size: 12))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 4)
                }
            }
            
            if !viewModel.generatedOutput.isEmpty {
                Button("Save Current Output") {
                    viewModel.saveCurrentOutput()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(16)
        .frame(width: 360)
    }
}



struct SettingsView: View {
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Group {
                if let appIcon = NSImage(contentsOfFile: "appicon.png") ?? NSImage(named: "appicon") {
                    Image(nsImage: appIcon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .cornerRadius(20)
                } else {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "app")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                        )
                }
            }
            
            VStack(alignment: .center, spacing: 12) {
                Text("Settings")
                    .font(.headline)
                
                Text("Convert repositories to LLM-ready text format")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 8) {
                    Button("Clear All Data") {
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Visit GitHub") {
                        if let url = URL(string: "https:
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(16)
        .frame(width: 280, height: 320)
    }
}

struct RecentsPageView: View {
    @ObservedObject var viewModel: MainViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 24) {
                RecentsASCIIView()
                    .padding(.top, 80)
                
                if viewModel.recentRepositories.isEmpty {
                    Text("No recents yet")
                        .font(.system(.body))
                        .foregroundColor(.secondary)
                } else {
                    VStack(spacing: 16) {
                        ForEach(viewModel.recentRepositories.prefix(5), id: \.self) { repo in
                            RecentRepoCard(repo: repo, viewModel: viewModel)
                        }
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                            )
                    )
                    .frame(maxWidth: 500)
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct BookmarksPageView: View {
    @ObservedObject var viewModel: MainViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 24) {
                BookmarksASCIIView()
                    .padding(.top, 80)
                
                if viewModel.savedOutputs.isEmpty {
                    Text("No bookmarks yet")
                        .font(.system(.body))
                        .foregroundColor(.secondary)
                } else {
                    VStack(spacing: 16) {
                        ForEach(viewModel.savedOutputs.prefix(5)) { output in
                            BookmarkCard(output: output, viewModel: viewModel)
                        }
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                            )
                    )
                    .frame(maxWidth: 500)
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct RecentRepoCard: View {
    let repo: RecentRepository
    @ObservedObject var viewModel: MainViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(repo.path)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)
                
                Text("\(repo.type.rawValue) Repository")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button("Use") {
                    if repo.type == .github {
                        viewModel.githubURL = repo.path
                        viewModel.repoType = .github
                    } else {
                        viewModel.localPath = repo.path
                        viewModel.repoType = .local
                    }
                    viewModel.activePage = .main
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button(action: {
                    viewModel.deleteRecentRepository(repo)
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .foregroundColor(.red)
            }
        }
        .padding(16)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct BookmarkCard: View {
    let output: SavedOutput
    @ObservedObject var viewModel: MainViewModel
    @State private var isLoading = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(output.name)
                        .font(.system(size: 14, weight: .medium))
                        .lineLimit(1)
                    
                    Text(output.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button(action: {
                        Task {
                            await loadOutput()
                        }
                    }) {
                        HStack(spacing: 4) {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.6)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .primary))
                            }
                            Text("View")
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(isLoading)
                    
                    Button(action: {
                        viewModel.removeOutputBookmark(output)
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .foregroundColor(.red)
                }
            }
            
            HStack(spacing: 16) {
                Label("\(output.tokenCount.formatted())", systemImage: "number")
                Label("\(output.fileCount)", systemImage: "doc")
            }
            .font(.system(size: 11))
            .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    @MainActor
    private func loadOutput() async {
        isLoading = true
        
        viewModel.activePage = .output
        
        try? await Task.sleep(nanoseconds: 10_000_000)
        
        viewModel.generatedOutput = output.content
        
        isLoading = false
    }
}
