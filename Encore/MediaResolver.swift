import Foundation
import UIKit
import ImageIO
import AVFoundation
import CoreGraphics
import SwiftUI

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
    
    /// Overí, či cesta reprezentuje obrázok (podľa prípony)
    public static func isImagePath(path: String) -> Bool {
        let ext = (path as NSString).pathExtension.lowercased()
        return ["jpg", "jpeg", "png", "heic", "heif", "webp", "gif"].contains(ext)
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
    
    /// Získa náhľad pre video alebo fotku z pamäťovej keše (alebo okamžite dekóduje statický obrázok)
    @MainActor
    public static func resolveThumbnail(path: String, maxPixelSize: CGFloat = 400) -> UIImage? {
        let cacheKey = "thumb_\(path)_\(Int(maxPixelSize))" as NSString
        if let cached = imageCache.object(forKey: cacheKey) {
            return cached
        }
        
        if isImagePath(path: path) {
            if let img = resolveImage(path: path, maxPixelSize: maxPixelSize) {
                imageCache.setObject(img, forKey: cacheKey)
                return img
            }
        }
        return nil
    }
    
    /// Asynchrónne získa náhľad pre video alebo fotku (cez moderné AVAssetImageGenerator API bez blokovania UI)
    @MainActor
    public static func resolveThumbnailAsync(path: String, maxPixelSize: CGFloat = 400) async -> UIImage? {
        let cacheKey = "thumb_\(path)_\(Int(maxPixelSize))" as NSString
        if let cached = imageCache.object(forKey: cacheKey) {
            return cached
        }
        
        if isImagePath(path: path) {
            if let img = resolveImage(path: path, maxPixelSize: maxPixelSize) {
                imageCache.setObject(img, forKey: cacheKey)
                return img
            }
            return nil
        }
        
        // Extrakcia náhľadu z videa cez moderné AVAssetImageGenerator API
        guard let videoURL = resolveVideoURL(path: path) else { return nil }
        let asset = AVURLAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: maxPixelSize, height: maxPixelSize)
        
        let time = CMTime(seconds: 0.1, preferredTimescale: 600)
        do {
            let (cgImage, _) = try await generator.image(at: time)
            let thumb = UIImage(cgImage: cgImage)
            imageCache.setObject(thumb, forKey: cacheKey)
            return thumb
        } catch {
            return nil
        }
    }
    
    /// Hardvérovo akcelerovaný dekóder obrázkov (CGImageSource / ImageIO bez preťaženia RAM)
    @MainActor
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
            .appendingPathComponent("encore-media")
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

// MARK: - Reusable Media Thumbnail View
public struct MediaThumbnailView: View {
    public let path: String?
    public var placeholderIcon: String
    public var cornerRadius: CGFloat
    
    @State private var thumbnail: UIImage? = nil
    
    public init(path: String?, placeholderIcon: String = "film", cornerRadius: CGFloat = 10) {
        self.path = path
        self.placeholderIcon = placeholderIcon
        self.cornerRadius = cornerRadius
    }
    
    public init(filePath: String?, placeholderIcon: String = "film", cornerRadius: CGFloat = 10) {
        self.path = filePath
        self.placeholderIcon = placeholderIcon
        self.cornerRadius = cornerRadius
    }
    
    public var body: some View {
        ZStack {
            Color.obsidian800
            
            if let thumb = thumbnail {
                Image(uiImage: thumb)
                    .resizable()
                    .scaledToFill()
            } else {
                VStack(spacing: 4) {
                    Image(systemName: placeholderIcon)
                        .font(.system(size: 24))
                        .foregroundColor(Color.white.opacity(0.35))
                }
            }
            
            // Format icon indicator (Video vs Photo)
            if let path = path, !path.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: MediaResolver.isImagePath(path: path) ? "photo.fill" : "play.fill")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color.black.opacity(0.65))
                            .clipShape(Circle())
                    }
                    .padding(6)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .onAppear {
            loadThumb()
        }
        .onChange(of: path) { _, _ in
            loadThumb()
        }
    }
    
    private func loadThumb() {
        guard let path = path, !path.isEmpty else {
            thumbnail = nil
            return
        }
        if let cached = MediaResolver.resolveThumbnail(path: path) {
            self.thumbnail = cached
            return
        }
        Task {
            let thumb = await MediaResolver.resolveThumbnailAsync(path: path)
            self.thumbnail = thumb
        }
    }
}

