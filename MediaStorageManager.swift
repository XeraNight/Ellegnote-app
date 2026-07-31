import Foundation

enum MediaStorageManager {
    static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    static func url(for filename: String) -> URL {
        documentsDirectory.appendingPathComponent(filename)
    }
    
    static func fileExists(_ filename: String?) -> Bool {
        guard let filename else { return false }
        return FileManager.default.fileExists(atPath: url(for: filename).path)
    }
    
    static func removeFile(named filename: String?) {
        guard let filename else { return }
        try? FileManager.default.removeItem(at: url(for: filename))
    }
    
    static func store(data: Data, prefix: String, fileExtension: String) throws -> String {
        let filename = "\(prefix)_\(UUID().uuidString).\(fileExtension)"
        try data.write(to: url(for: filename), options: .atomic)
        return filename
    }
    
    static func copyIntoDocuments(from sourceURL: URL, fileExtension: String) throws -> String {
        let filename = "\(UUID().uuidString).\(fileExtension)"
        let destinationURL = url(for: filename)
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }
        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
        return filename
    }
    
    static func totalSize(for filenames: [String]) -> Int64 {
        filenames.reduce(0) { total, filename in
            let fileURL = url(for: filename)
            let size = (try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? NSNumber)?.int64Value ?? 0
            return total + size
        }
    }
}
