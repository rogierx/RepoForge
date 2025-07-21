import Foundation


class FileTypeCategories: @unchecked Sendable {
    static let shared = FileTypeCategories()
    
    enum Category: String, CaseIterable {
        case code, text, document, image, audio, video, archive, other
    }
    
    private let categoryMapping: [String: Category] = [
        "swift": .code, "java": .code, "py": .code, "js": .code, "html": .code,
        "css": .code, "php": .code, "rb": .code, "cpp": .code, "h": .code,
        "c": .code, "cs": .code, "go": .code, "rs": .code, "ts": .code, "kt": .code,
        "txt": .text, "md": .text, "json": .text, "xml": .text, "yml": .text,
        "yaml": .text, "csv": .text, "log": .text, "rtf": .text,
        "pdf": .document, "doc": .document, "docx": .document,
        "xls": .document, "xlsx": .document, "ppt": .document, "pptx": .document,
        "png": .image, "jpg": .image, "jpeg": .image, "gif": .image, "bmp": .image,
        "tiff": .image, "svg": .image,
        "mp3": .audio, "wav": .audio, "aac": .audio, "flac": .audio,
        "mp4": .video, "mov": .video, "avi": .video, "mkv": .video,
        "zip": .archive, "rar": .archive, "7z": .archive, "tar": .archive, "gz": .archive
    ]
    
    private init() {}
    
    func category(for fileName: String) -> Category {
        let fileExtension = (fileName as NSString).pathExtension.lowercased()
        return categoryMapping[fileExtension] ?? .other
    }
    

} 