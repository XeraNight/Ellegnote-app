import SwiftUI
import SwiftData
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

// MARK: - Import a shared routine (QR or pasted code)
enum RoutineShareImportError: LocalizedError {
    case unreadable, tooManyFigures, invalidContent

    var errorDescription: String? {
        switch self {
        case .unreadable: return "Nepodarilo sa naimportovať zostavu."
        case .tooManyFigures: return "QR kód obsahuje príliš veľa figúr (max. 200)."
        case .invalidContent: return "QR kód obsahuje neplatné dáta."
        }
    }
}

enum RoutineShareImporter {
    /// Creates the routine (or updates it when the same routine was imported before) and returns its name.
    @MainActor
    static func importRoutine(fromCode rawCode: String, into context: ModelContext) throws -> String {
        let trimmed = rawCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = trimmed.data(using: .utf8),
              let payload = try? JSONDecoder().decode(QRSharePayload.self, from: data) else {
            throw RoutineShareImportError.unreadable
        }
        guard payload.nodes.count <= 200 else { throw RoutineShareImportError.tooManyFigures }
        guard payload.n.count <= 120, payload.d.count <= 80 else { throw RoutineShareImportError.invalidContent }

        let routineId = payload.id.flatMap(UUID.init(uuidString:)) ?? UUID()
        let existing = try? context.fetch(FetchDescriptor<Routine>(predicate: #Predicate { $0.id == routineId })).first
        let routine: Routine
        if let existing {
            routine = existing
            routine.name = payload.n
            routine.danceName = payload.d
            routine.danceCategory = payload.c
            routine.updatedAt = Date()
        } else {
            routine = Routine(id: routineId, name: payload.n, danceName: payload.d, danceCategory: payload.c)
            context.insert(routine)
        }

        for raw in payload.nodes {
            let nodeId = raw.id.flatMap(UUID.init(uuidString:)) ?? UUID()
            if let node = routine.canvasNodes.first(where: { $0.id == nodeId }) {
                node.x = raw.x
                node.y = raw.y
                node.figureName = raw.f
                node.rhythm = raw.r ?? ""
                node.notes = raw.n ?? ""
                node.orderIndex = raw.o
                node.transitionNotes = raw.t ?? ""
            } else {
                let node = CanvasNode(
                    id: nodeId, x: raw.x, y: raw.y, figureName: raw.f, rhythm: raw.r ?? "",
                    notes: raw.n ?? "", orderIndex: raw.o, transitionNotes: raw.t ?? ""
                )
                node.routine = routine
                context.insert(node)
            }
        }

        do {
            try context.save()
        } catch {
            throw RoutineShareImportError.unreadable
        }
        SupabaseSyncManager.shared.syncRoutineOnBackground(routine)
        return payload.n
    }
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
    
    /// Runs off the main thread. Returns nil when the text does not fit into a QR code
    /// (about 2.9 kB with the lowest error correction).
    nonisolated static func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "L"
        
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
