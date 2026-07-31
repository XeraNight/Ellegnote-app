import Foundation
import UIKit

struct MediaResolver {
    
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
        let localURL = MediaStorageManager.url(for: path)
        if let uiImage = UIImage(contentsOfFile: localURL.path) {
            return uiImage
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
        URLSession.shared.downloadTask(with: url) { tempLocalURL, response, error in
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
}
