import Foundation
import UIKit
import ImageIO
import AVFoundation
import CoreGraphics

public struct MediaResolver {
    private static let downloadLock = NSLock()
    private static var activeDownloads = Set<URL>()
    
    // In-memory hardware thumbnail cache (max 150 items, 50MB budget)
    private static let imageCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 150
        cache.totalCostLimit = 50 * 1024 * 1024
        return cache
    }()
    
    /// Vráti cestu k lokálnemu adresáru dokumentov aplikácie
    public static func getDocumentsDirectory() -> URL {
        MediaStorageManager.documentsDirectory
    }
    
    /// Rozhodne, či je video dostupné lokálne. Ak nie, vráti online stream URL zo Supabase a spustí sťahovanie na pozadí.
    public static func resolveVideoURL(path: String) -> URL? {
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
    
    /// Hardvérovo akcelerovaný dekóder obrázkov (CGImageSource / ImageIO bez preťaženia RAM)
    public static func resolveImage(path: String, maxPixelSize: CGFloat = 1200) -> UIImage? {
        let cacheKey = "\(path)_\(Int(maxPixelSize))" as NSString
        if let cached = imageCache.object(forKey: cacheKey) {
            return cached
        }
        
        let localURL = MediaStorageManager.url(for: path)
        guard MediaStorageManager.fileExists(path) else {
            // Asynchrónne stiahneme z cloudu ak chýba
            if let publicURL = getPublicStorageURL(for: path) {
                downloadFileToCache(from: publicURL, destination: localURL)
            }
            return nil
        }
        
        // Hardvérové dekódovanie priamo z disku do požadovaného rozlíšenia
        guard let source = CGImageSourceCreateWithURL(localURL as CFURL, nil) else {
            return nil
        }
        
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]
        
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }
        
        let image = UIImage(cgImage: cgImage)
        let memoryCost = cgImage.bytesPerRow * cgImage.height
        imageCache.setObject(image, forKey: cacheKey, cost: memoryCost)
        return image
    }
    
    /// Vytvorí verejnú URL pre stiahnutie alebo streamovanie súboru zo Supabase Storage
    public static func getPublicStorageURL(for fileName: String) -> URL? {
        return SupabaseConfig.url
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
            
            do {
                if FileManager.default.fileExists(atPath: destination.path) {
                    try? FileManager.default.removeItem(at: destination)
                }
                try FileManager.default.copyItem(at: tempURL, to: destination)
                print("Successfully cached media file locally: \(destination.lastPathComponent)")
                
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("MediaCacheDidUpdate"), object: nil)
                }
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
