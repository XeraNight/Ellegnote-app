import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRSharePayload: Codable {
    let id: String? // routine ID (optional for backward compatibility)
    let n: String // name
    let d: String // danceName
    let c: String // danceCategory
    let nodes: [QRShareNode]
}

struct QRShareNode: Codable {
    let id: String? // node ID (optional for backward compatibility)
    let x: Double
    let y: Double
    let f: String // figureName
    let r: String? // rhythm (optional for backward compatibility)
    let n: String? // notes (optional for backward compatibility)
    let o: Int    // orderIndex
    let t: String? // transitionNotes (optional for backward compatibility)
}

struct QRGenerator {
    static func generatePayload(from routine: Routine) -> String? {
        let shareNodes = routine.canvasNodes.map { node in
            QRShareNode(
                id: node.id.uuidString,
                x: node.x,
                y: node.y,
                f: node.figureName,
                r: node.rhythm,
                n: node.notes,
                o: node.orderIndex,
                t: node.transitionNotes
            )
        }
        let payload = QRSharePayload(
            id: routine.id.uuidString,
            n: routine.name,
            d: routine.danceName,
            c: routine.danceCategory,
            nodes: shareNodes
        )
        guard let data = try? JSONEncoder().encode(payload),
              let jsonString = String(data: data, encoding: .utf8) else {
            return nil
        }
        return jsonString
    }
    
    static func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        
        guard let outputImage = filter.outputImage else { return nil }
        
        // Upscale the QR image (it's naturally small/pixelated)
        let scaleX = 300.0 / outputImage.extent.size.width
        let scaleY = 300.0 / outputImage.extent.size.height
        let transformedImage = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        if let cgImage = context.createCGImage(transformedImage, from: transformedImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        return nil
    }
}
