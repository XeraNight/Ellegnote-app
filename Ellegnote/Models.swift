import Foundation
import SwiftData

@Model
final class Dance {
    @Attribute(.unique) var id: UUID
    var name: String
    var category: String // "Standard" or "Latin"
    var tempo: String
    var info: String
    var imagePath: String?
    var videoPath: String?
    
    init(id: UUID = UUID(), name: String, category: String, tempo: String, info: String, imagePath: String? = nil, videoPath: String? = nil) {
        self.id = id
        self.name = name
        self.category = category
        self.tempo = tempo
        self.info = info
        self.imagePath = imagePath
        self.videoPath = videoPath
    }
}

@Model
final class FigureLibraryItem {
    @Attribute(.unique) var id: UUID
    var name: String
    var danceName: String
    var rhythm: String
    var techniqueNotes: String
    var imagePath: String?
    var videoPath: String?
    var isCustom: Bool
    
    init(id: UUID = UUID(), name: String, danceName: String, rhythm: String, techniqueNotes: String = "", imagePath: String? = nil, videoPath: String? = nil, isCustom: Bool = false) {
        self.id = id
        self.name = name
        self.danceName = danceName
        self.rhythm = rhythm
        self.techniqueNotes = techniqueNotes
        self.imagePath = imagePath
        self.videoPath = videoPath
        self.isCustom = isCustom
    }
}

@Model
final class Routine {
    @Attribute(.unique) var id: UUID
    var name: String
    var danceName: String
    var danceCategory: String // "Standard" or "Latin"
    var createdAt: Date
    var updatedAt: Date
    var lastModifiedBy: String?
    
    @Relationship(deleteRule: .cascade, inverse: \CanvasNode.routine)
    var canvasNodes: [CanvasNode] = []
    
    init(id: UUID = UUID(), name: String, danceName: String, danceCategory: String, createdAt: Date = Date(), updatedAt: Date = Date(), lastModifiedBy: String? = nil) {
        self.id = id
        self.name = name
        self.danceName = danceName
        self.danceCategory = danceCategory
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastModifiedBy = lastModifiedBy
    }
}

@Model
final class CanvasNode {
    @Attribute(.unique) var id: UUID
    var x: Double
    var y: Double
    var figureName: String
    var rhythm: String
    var notes: String
    var videoPath: String? // Local file name in app sandbox
    var orderIndex: Int
    var transitionNotes: String
    
    var routine: Routine?
    
    init(id: UUID = UUID(), x: Double, y: Double, figureName: String, rhythm: String = "", notes: String = "", videoPath: String? = nil, orderIndex: Int = 0, transitionNotes: String = "") {
        self.id = id
        self.x = x
        self.y = y
        self.figureName = figureName
        self.rhythm = rhythm
        self.notes = notes
        self.videoPath = videoPath
        self.orderIndex = orderIndex
        self.transitionNotes = transitionNotes
    }
}

// MARK: - Figures Database Seeding Extension
extension FigureLibraryItem {
    static func seedDefaultFigures(in context: ModelContext) {
        let figuresData: [String: [(String, String)]] = [
            "Waltz": [
                ("Closed Changes", "1, 2, 3"),
                ("Natural Turn", "1, 2, 3"),
                ("Reverse Turn", "1, 2, 3"),
                ("Whisk", "1, 2, 3"),
                ("Chasse from PP", "1, 2 a 3"),
                ("Natural Spin Turn", "1, 2, 3, 4, 5, 6"),
                ("Reverse Corte", "1, 2, 3"),
                ("Outside Spin", "1, 2, 3"),
                ("Double Reverse Spin", "1, 2, a3"),
                ("Weave from PP", "1, 2, 3, 4, 5, 6")
            ],
            "Tango": [
                ("Progressive Side Step", "Quick, Quick"),
                ("Rock Turn", "Slow, Quick, Quick, Slow"),
                ("Open Promenade", "Slow, Quick, Quick, Slow"),
                ("Back Corte", "Slow, Quick, Quick, Slow"),
                ("Progressive Link", "Quick, Quick"),
                ("Closed Promenade", "Slow, Quick, Quick, Slow"),
                ("Four Step", "Quick, Quick, Quick, Quick"),
                ("Fallaway Promenade", "Slow, Quick, Quick, Slow"),
                ("Outside Swivel", "Slow, Quick"),
                ("Five Step", "Quick, Quick, Quick, Quick, Slow")
            ],
            "Viennese Waltz": [
                ("Natural Turn", "1, 2, 3"),
                ("Reverse Turn", "1, 2, 3"),
                ("Forward Change (Nat to Rev)", "1, 2, 3"),
                ("Forward Change (Rev to Nat)", "1, 2, 3"),
                ("Backward Change (Nat to Rev)", "1, 2, 3"),
                ("Backward Change (Rev to Nat)", "1, 2, 3"),
                ("Reverse Fleckerl", "1, 2, 3"),
                ("Contra Check", "1, 2, 3"),
                ("Natural Fleckerl", "1, 2, 3"),
                ("Left Foot Closed Change", "1, 2, 3")
            ],
            "Slowfoxtrot": [
                ("Feather Step", "Slow, Quick, Quick"),
                ("Three Step", "Slow, Quick, Quick"),
                ("Natural Turn", "Slow, Quick, Quick"),
                ("Reverse Turn so zakončením Feather Finish", "Slow, Quick, Quick, Slow, Quick, Quick"),
                ("Closed Impetus", "Slow, Quick, Quick"),
                ("Change of Direction", "Slow, Slow"),
                ("Open Telemark", "Slow, Quick, Quick"),
                ("Hover Feather", "Slow, Quick, Quick"),
                ("Natural Weave", "Slow, Quick, Quick, Quick, Quick, Quick, Quick"),
                ("Reverse Wave", "Slow, Quick, Quick, Slow, Quick, Quick")
            ],
            "Quickstep": [
                ("Quarter Turn to Right", "Slow, Quick, Quick, Slow"),
                ("Progressive Chasse", "Slow, Quick, Quick, Slow"),
                ("Forward Lock Step", "Slow, Quick, Quick, Slow"),
                ("Backward Lock Step", "Slow, Quick, Quick, Slow"),
                ("Natural Spin Turn", "Slow, Quick, Quick, Slow, Slow, Slow"),
                ("Chasse Reverse Turn", "Slow, Quick, Quick, Slow"),
                ("Change of Direction", "Slow, Slow"),
                ("Double Reverse Spin", "Slow, Slow, a-Slow"),
                ("Zig-Zag", "Slow, Slow, Quick, Quick, Slow"),
                ("Running Right Turn", "Slow, Quick, Quick, Slow, Slow, Slow, Quick, Quick, Slow")
            ],
            "Samba": [
                ("Basic Steps (Natural & Reverse)", "1 a 2"),
                ("Samba Whisks", "1 a 2"),
                ("Samba Walks in Promenade", "1 a 2"),
                ("Stationary Samba Walks", "1 a 2"),
                ("Bota Fogos", "1 a 2"),
                ("Voltas", "1 a 2 a 3 a 4"),
                ("Shadow Bota Fogos", "1 a 2"),
                ("Cortaca", "1 a 2 a 3 a 4"),
                ("Closed Rocks", "1 a 2"),
                ("Cruzados Walks", "1 a 2")
            ],
            "Cha-Cha-Cha": [
                ("Basic Movement (Closed & Open)", "2, 3, 4 a 1"),
                ("New York", "2, 3, 4 a 1"),
                ("Spot Turns", "2, 3, 4 a 1"),
                ("Hand to Hand", "2, 3, 4 a 1"),
                ("Three Cha-Chas", "2, 3, 4 a 1, 2, 3, 4 a 1"),
                ("Underarm Turns", "2, 3, 4 a 1"),
                ("Shoulder to Shoulder", "2, 3, 4 a 1"),
                ("Hockey Stick", "2, 3, 4 a 1"),
                ("Alemana", "2, 3, 4 a 1"),
                ("Natural Top", "2, 3, 4 a 1")
            ],
            "Rumba": [
                ("Basic Movement", "2, 3, 4, 1"),
                ("New York", "2, 3, 4, 1"),
                ("Spot Turns", "2, 3, 4, 1"),
                ("Hand to Hand", "2, 3, 4, 1"),
                ("Underarm Turns", "2, 3, 4, 1"),
                ("Cucaracha", "2, 3, 4, 1"),
                ("Shoulder to Shoulder", "2, 3, 4, 1"),
                ("Hockey Stick", "2, 3, 4, 1"),
                ("Alemana", "2, 3, 4, 1"),
                ("Opening Out to Right and Left", "2, 3, 4, 1")
            ],
            "Paso Doble": [
                ("Basic Movement", "1, 2, 3, 4, 5, 6, 7, 8"),
                ("Sur Place", "1, 2, 3, 4, 5, 6, 7, 8"),
                ("Chasses to Right and Left", "1, 2, 3, 4, 5, 6, 7, 8"),
                ("Promenade Link", "1, 2, 3, 4, 5, 6, 7, 8"),
                ("Deplacement", "1, 2, 3, 4, 5, 6, 7, 8"),
                ("Ecart", "1, 2, 3, 4, 5, 6, 7, 8"),
                ("Separation", "1, 2, 3, 4, 5, 6, 7, 8"),
                ("Fallaway Reverse Turn", "1, 2, 3, 4, 5, 6, 7, 8"),
                ("Huit", "1, 2, 3, 4, 5, 6, 7, 8"),
                ("La Passe", "1, 2, 3, 4, 5, 6, 7, 8")
            ],
            "Jive": [
                ("Basic In Place", "1, 2, 3 a 4, 5 a 6"),
                ("Fallaway Rock", "1, 2, 3 a 4, 5 a 6"),
                ("Change of Places Right to Left", "1, 2, 3 a 4, 5 a 6"),
                ("Change of Places Left to Right", "1, 2, 3 a 4, 5 a 6"),
                ("Link", "1, 2, 3 a 4, 5 a 6"),
                ("American Spin", "1, 2, 3 a 4, 5 a 6"),
                ("Stop and Go", "1, 2, 3 a 4, 5 a 6"),
                ("Mooch", "1, 2, 3 a 4, 5 a 6"),
                ("Whip", "1, 2, 3 a 4, 5 a 6"),
                ("Windmill", "1, 2, 3 a 4, 5 a 6")
            ]
        ]
        
        for (danceName, figures) in figuresData {
            for fig in figures {
                let name = fig.0
                let descriptor = FetchDescriptor<FigureLibraryItem>(
                    predicate: #Predicate { $0.name == name && $0.danceName == danceName }
                )
                if let existing = try? context.fetch(descriptor), !existing.isEmpty {
                    continue
                }
                
                let item = FigureLibraryItem(
                    name: fig.0,
                    danceName: danceName,
                    rhythm: fig.1,
                    isCustom: false
                )
                context.insert(item)
            }
        }
        try? context.save()
    }
}

@Model
final class InstantNote {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var text: String
    var videoPath: String?
    var imagePath: String?
    
    init(id: UUID = UUID(), createdAt: Date = Date(), text: String = "", videoPath: String? = nil, imagePath: String? = nil) {
        self.id = id
        self.createdAt = createdAt
        self.text = text
        self.videoPath = videoPath
        self.imagePath = imagePath
    }
}

import UIKit
extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
