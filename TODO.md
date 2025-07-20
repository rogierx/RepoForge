# RepoForge Swift - TODO List

## Current Status
✅ **COMPLETED:**
- Swift Package Manager project initialized
- Basic directory structure created  
- Comprehensive project documentation written
- Package.swift configured with macOS 13+ target

⚠️ **CURRENT ISSUE:**
- Swift compiler enforcing strict macOS version availability checks
- SwiftUI features require different minimum versions (10.15, 11.0, 12.0, 13.0)
- Need to either add @available attributes or create simpler initial version

## Phase 1: Foundation - IMMEDIATE NEXT STEPS

### 🎯 **HIGH PRIORITY - START HERE**

#### 1. Fix Version Compatibility Issues  
- [ ] **Option A**: Add @available macOS 13.0 attributes to all SwiftUI code
- [ ] **Option B**: Create simpler command-line version first, then upgrade to SwiftUI
- [ ] **Option C**: Use AppKit instead of SwiftUI for broader compatibility
- [ ] Test compilation and basic app launch

#### 2. Package Configuration & Dependencies
- [x] Updated `Package.swift` with macOS 13.0+ target
- [ ] Add any tokenizer library dependencies  
- [ ] Research Swift tokenizer options (tiktoken-swift, GPTEncoder, etc.)

#### 3. Basic App Structure 
- [x] Created `Sources/RepoForge/App.swift` - main app entry point
- [x] Created `Sources/RepoForge/ContentView.swift` - main interface (needs version fixes)
- [ ] Fix version compatibility issues
- [ ] Test basic app compilation and launch

#### 4. Core Data Models
- [ ] `Sources/RepoForge/Models/Repository.swift` - repo data structure
- [ ] `Sources/RepoForge/Models/FileNode.swift` - file tree structure  
- [ ] `Sources/RepoForge/Models/GitHubAPI.swift` - API response models
- [ ] Basic model validation and testing

#### 5. GitHub Service Foundation
- [ ] `Sources/RepoForge/Services/GitHubService.swift` - API client
- [ ] Basic URL validation
- [ ] Authentication header setup
- [ ] Simple repository metadata fetching
- [ ] Test with a small public repository

## Alternative Approach: Command Line First

If SwiftUI version issues persist, consider building a command-line version first:

### CLI Version Benefits:
- No macOS version compatibility issues
- Faster development and testing
- Core logic development without UI complexity
- Can upgrade to SwiftUI later

### CLI Implementation:
```swift
// main.swift
import Foundation

@main
struct RepoForge {
    static func main() async throws {
        print("RepoForge - GitHub Repository Processor")
        // Command line argument parsing
        // GitHub API integration
        // Token counting
        // Output generation
    }
}
```

## Phase 2: Core Features (After Phase 1)

### GitHub Integration
- [ ] Recursive directory fetching
- [ ] Progress tracking
- [ ] Error handling and retries
- [ ] Rate limiting respect

### Token Counting
- [ ] Research Swift tokenizer libraries:
  - **tiktoken-swift**: Swift port of OpenAI's tiktoken
  - **GPTEncoder**: Pure Swift implementation
  - **Custom implementation**: Based on cl100k_base encoding
- [ ] Implement cl100k_base compatible counting
- [ ] Real-time token analysis
- [ ] File and directory token summaries

### Content Processing
- [ ] Gemini 2.5 Pro output formatting
- [ ] File tree generation with token counts
- [ ] Content combination and export
- [ ] Copy to clipboard functionality (macOS only)

## Phase 3: Native macOS Features (SwiftUI Version)

### UI Polish
- [ ] Resolve macOS version compatibility
- [ ] SF Symbols integration throughout
- [ ] Native macOS styling
- [ ] Sidebar navigation
- [ ] Settings panel

### Data Persistence  
- [ ] Keychain integration for tokens
- [ ] Repository history
- [ ] User preferences storage
- [ ] Bookmarking system

## Phase 4: Advanced Features

### Performance
- [ ] Intelligent caching
- [ ] Parallel processing
- [ ] Memory optimization
- [ ] Background processing

### Distribution
- [ ] App bundle creation
- [ ] Code signing
- [ ] Notarization
- [ ] Installer package

---

## Development Commands

```bash
# Build and test
swift build
swift run

# Package resolution
swift package resolve
swift package update

# Clean build
swift package clean
```

## Key Files from Electron Prototype

Reference these files for implementation patterns:
- `main.js` - GitHub API integration logic (lines 1-180: GitHub API, recursive fetching)
- `renderer.js` - UI state management and token counting (lines 200-400: token calculation logic)
- `index.html` - Interface structure and styling
- `.cursorrules` - Project preferences and requirements

## Tokenizer Research

### Swift Tokenizer Options:
1. **tiktoken-swift**: Direct port of OpenAI's tiktoken library
2. **GPTEncoder**: Pure Swift BPE implementation
3. **Custom cl100k_base**: Implement encoding manually
4. **Bridge to Python**: Use PyObjC to call tiktoken directly

---

**NEXT ACTION:** 
1. **Fix version compatibility** by adding @available attributes OR
2. **Create CLI version first** for faster development OR  
3. **Use AppKit** instead of SwiftUI for simpler compatibility

**RECOMMENDED**: Start with CLI version to get core functionality working, then upgrade to SwiftUI! 