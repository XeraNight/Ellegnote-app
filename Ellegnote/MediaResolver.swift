import Foundation
import UIKit

struct MediaResolver {
    private static let downloadLock = NSLock()
    private static var activeDownloads = Set<URL>()
    private static let imageCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 120
        cache.totalCostLimit = 60 * 1024 * 1024
        return cache
    }()
    
    /// Vráti cestu k lokálnemu adresáru dokumentov aplikácie
    static func getDocumentsDirectory() -> URL {
        MediaStorageManager.documentsDirectory
    }
    
    /// Rozhodne, či je video dostupné lokálne. Ak nie, vráti online stream URL zo Supabase a spustí sťahovanie na pozadí.
    static func resolveVideoURL(path: String) -> URL? {
        let localURL = MediaStorageManager.url(for: path)
        if MediaStorageManager.fileExists(path) {
            return localURL
        }
        
        // Ak neexistuje lokálne, streamujeme online zo Supabase Storage a ukladáme do lokálnej cache
        if let publicURL = getPublicStorageURL(for: path) {
            downloadFileToCache(from: publicURL, destination: localURL)
            return publicURL
        }
        
        return nil
    }
    
    /// Pokúsi sa získať obrázok z lokálneho disku. Ak chýba, asynchrónne ho stiahne pre budúce zobrazenia.
    static func resolveImage(path: String) -> UIImage? {
        let cacheKey = path as NSString
        if let cached = imageCache.object(forKey: cacheKey) {
            return cached
        }
        
        let localURL = MediaStorageManager.url(for: path)
        if let uiImage = UIImage(contentsOfFile: localURL.path) {
            let prepared = uiImage.preparingForEllegnotePreview()
            imageCache.setObject(prepared, forKey: cacheKey, cost: prepared.ellegnoteMemoryCost)
            return prepared
        }
        
        // Ak neexistuje lokálne, spustíme sťahovanie z online úložiska
        if let publicURL = getPublicStorageURL(for: path) {
            downloadFileToCache(from: publicURL, destination: localURL)
        }
        
        return nil
    }
    
    /// Vytvorí verejnú URL pre stiahnutie alebo streamovanie súboru zo Supabase Storage
    static func getPublicStorageURL(for fileName: String) -> URL? {
        guard let baseURL = SupabaseConfig.url else { return nil }
        
        // Cesta pre verejné objekty v Supabase: baseURL/storage/v1/object/public/ellegnote-media/fileName
        return baseURL
            .appendingPathComponent("storage/v1/object/public")
            .appendingPathComponent("ellegnote-media")
            .appendingPathComponent(fileName)
    }
    
    /// Stiahne súbor z online úložiska na pozadí a uloží ho do lokálnej pamäte zariadenia
    private static func downloadFileToCache(from url: URL, destination: URL) {
        guard markDownloadStarted(for: destination) else { return }
        
        URLSession.shared.downloadTask(with: url) { tempLocalURL, response, error in
            defer { markDownloadFinished(for: destination) }
            
            guard let tempURL = tempLocalURL, error == nil else {
                print("Failed to download media file: \(String(describing: error))")
                return
            }
            
            // Bezpečne skopírujeme stiahnutý súbor z dočasného priečinka do cieľového dokumentového priečinka
            do {
                if FileManager.default.fileExists(atPath: destination.path) {
                    try? FileManager.default.removeItem(at: destination)
                }
                try FileManager.default.copyItem(at: tempURL, to: destination)
                print("Successfully cached media file locally: \(destination.lastPathComponent)")
                
                // Vyvoláme NotificationCenter udalosť na osvieženie UI (najmä pre fotky)
                NotificationCenter.default.post(name: NSNotification.Name("MediaCacheDidUpdate"), object: nil)
            } catch {
                print("Failed to save downloaded file to local cache: \(error)")
            }
        }.resume()
    }
    
    private static func markDownloadStarted(for destination: URL) -> Bool {
        downloadLock.lock()
        defer { downloadLock.unlock() }
        
        guard !activeDownloads.contains(destination) else { return false }
        activeDownloads.insert(destination)
        return true
    }
    
    private static func markDownloadFinished(for destination: URL) {
        downloadLock.lock()
        activeDownloads.remove(destination)
        downloadLock.unlock()
    }
}

private extension UIImage {
    var ellegnoteMemoryCost: Int {
        guard let cgImage else { return 1 }
        return cgImage.bytesPerRow * cgImage.height
    }
    
    func preparingForEllegnotePreview(maxPixel: CGFloat = 1400) -> UIImage {
        let longestSide = max(size.width, size.height)
        guard longestSide > maxPixel else {
            return preparingForDisplay() ?? self
        }
        
        let scaleRatio = maxPixel / longestSide
        let targetSize = CGSize(
            width: max(1, floor(size.width * scaleRatio)),
            height: max(1, floor(size.height * scaleRatio))
        )
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        let resized = renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return resized.preparingForDisplay() ?? resized
    }
}
