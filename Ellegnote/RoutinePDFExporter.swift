import SwiftUI
import PDFKit
import CoreImage.CIFilterBuiltins
import UniformTypeIdentifiers

// MARK: - Routine PDF Exporter
final class RoutinePDFExporter {
    static func renderPDF(for routine: Routine) -> Data {
        let pageWidth: Double = 595.2  // Standard A4
        let pageHeight: Double = 841.8
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        let pdfData = renderer.pdfData { context in
            context.beginPage()
            let ctx = context.cgContext
            
            // 1. Header Background Banner
            let headerRect = CGRect(x: 36, y: 36, width: pageWidth - 72, height: 70)
            ctx.setFillColor(UIColor.black.cgColor)
            ctx.fill(headerRect)
            
            // Gold Border around banner
            ctx.setStrokeColor(UIColor(Color.amberGold).cgColor)
            ctx.setLineWidth(2.0)
            ctx.stroke(headerRect)
            
            // Header Text
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18, weight: .black),
                .foregroundColor: UIColor.white
            ]
            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .bold),
                .foregroundColor: UIColor(Color.amberGold)
            ]
            
            let titleStr = routine.name.uppercased()
            titleStr.draw(at: CGPoint(x: 48, y: 48), withAttributes: titleAttributes)
            
            let subtitleStr = "TANEC: \(routine.danceName.uppercased()) • KATEGÓRIA: \(routine.danceCategory.uppercased()) • ELLEGNOTE"
            subtitleStr.draw(at: CGPoint(x: 48, y: 76), withAttributes: subtitleAttributes)
            
            // 2. Table Column Headers
            var currentY: Double = 126
            let tableX: Double = 36
            let colOrderWidth: Double = 32
            let colNameWidth: Double = 160
            let colRhythmWidth: Double = 80
            let colNotesWidth: Double = pageWidth - 72 - colOrderWidth - colNameWidth - colRhythmWidth
            
            // Draw Table Header Bar
            let thRect = CGRect(x: tableX, y: currentY, width: pageWidth - 72, height: 24)
            ctx.setFillColor(UIColor(white: 0.92, alpha: 1.0).cgColor)
            ctx.fill(thRect)
            
            let thAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9, weight: .black),
                .foregroundColor: UIColor.black
            ]
            
            "#".draw(at: CGPoint(x: tableX + 8, y: currentY + 6), withAttributes: thAttributes)
            "NÁZOV FIGÚRY".draw(at: CGPoint(x: tableX + colOrderWidth + 8, y: currentY + 6), withAttributes: thAttributes)
            "RYTMUS".draw(at: CGPoint(x: tableX + colOrderWidth + colNameWidth + 8, y: currentY + 6), withAttributes: thAttributes)
            "TECHNICKÉ POZNÁMKY & SMER".draw(at: CGPoint(x: tableX + colOrderWidth + colNameWidth + colRhythmWidth + 8, y: currentY + 6), withAttributes: thAttributes)
            
            currentY += 28
            
            // 3. Render Figures Rows
            let sortedNodes = routine.canvasNodes.sorted(by: { $0.orderIndex < $1.orderIndex })
            
            let cellFont = UIFont.systemFont(ofSize: 10, weight: .regular)
            let cellBoldFont = UIFont.systemFont(ofSize: 10, weight: .bold)
            let cellTextAttr: [NSAttributedString.Key: Any] = [.font: cellFont, .foregroundColor: UIColor.black]
            let cellBoldAttr: [NSAttributedString.Key: Any] = [.font: cellBoldFont, .foregroundColor: UIColor.black]
            let cellRhythmAttr: [NSAttributedString.Key: Any] = [.font: UIFont.monospacedSystemFont(ofSize: 10, weight: .bold), .foregroundColor: UIColor(Color.amberGold)]
            
            for (idx, node) in sortedNodes.enumerated() {
                let rowHeight: Double = 32
                
                // Row background zebra striping
                if idx % 2 == 0 {
                    let rowRect = CGRect(x: tableX, y: currentY, width: pageWidth - 72, height: rowHeight)
                    ctx.setFillColor(UIColor(white: 0.97, alpha: 1.0).cgColor)
                    ctx.fill(rowRect)
                }
                
                // Row Bottom Border Line
                ctx.setStrokeColor(UIColor(white: 0.85, alpha: 1.0).cgColor)
                ctx.setLineWidth(0.5)
                ctx.move(to: CGPoint(x: tableX, y: currentY + rowHeight))
                ctx.addLine(to: CGPoint(x: tableX + pageWidth - 72, y: currentY + rowHeight))
                ctx.strokePath()
                
                // Text columns
                "\(node.orderIndex).".draw(at: CGPoint(x: tableX + 8, y: currentY + 8), withAttributes: cellBoldAttr)
                node.figureName.draw(at: CGPoint(x: tableX + colOrderWidth + 8, y: currentY + 8), withAttributes: cellBoldAttr)
                
                let rhythmText = node.rhythm.isEmpty ? "-" : node.rhythm
                rhythmText.draw(at: CGPoint(x: tableX + colOrderWidth + colNameWidth + 8, y: currentY + 8), withAttributes: cellRhythmAttr)
                
                let notesText = node.notes.isEmpty ? (node.transitionNotes.isEmpty ? "-" : node.transitionNotes) : node.notes
                let notesRect = CGRect(x: tableX + colOrderWidth + colNameWidth + colRhythmWidth + 8, y: currentY + 8, width: colNotesWidth - 12, height: 20)
                notesText.draw(in: notesRect, withAttributes: cellTextAttr)
                
                currentY += rowHeight
                
                // Page overflow guard
                if currentY > pageHeight - 160 {
                    context.beginPage()
                    currentY = 36
                }
            }
            
            // 4. Footer & QR Code
            let footerY = pageHeight - 90
            let footerRect = CGRect(x: 36, y: footerY, width: pageWidth - 72, height: 54)
            ctx.setFillColor(UIColor.black.cgColor)
            ctx.fill(footerRect)
            
            let footerText = "Vygenerované aplikáciou Ellegnote • Oficiálny súťažný hárok choreografie"
            let footerAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9, weight: .bold),
                .foregroundColor: UIColor.white.withAlphaComponent(0.8)
            ]
            footerText.draw(at: CGPoint(x: 48, y: footerY + 20), withAttributes: footerAttr)
            
            // Generate Small QR Code
            if let qr = generateQRCode(from: "ellegnote://routine/\(routine.id.uuidString)") {
                qr.draw(in: CGRect(x: pageWidth - 76, y: footerY + 7, width: 40, height: 40))
            }
        }
        
        return pdfData
    }
    
    private static func generateQRCode(from string: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        guard let data = string.data(using: .utf8) else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        
        if let ciImage = filter.outputImage {
            let transform = CGAffineTransform(scaleX: 5, y: 5)
            let scaledImage = ciImage.transformed(by: transform)
            let context = CIContext()
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        return nil
    }
}

// MARK: - Routine PDF Preview Sheet
struct RoutinePDFPreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    let routine: Routine
    
    @State private var pdfData: Data? = nil
    
    init(routine: Routine) {
        self.routine = routine
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color.themeBg.ignoresSafeArea()
                
                if let data = pdfData {
                    PDFKitRepresentedView(data: data)
                        .ignoresSafeArea(edges: .bottom)
                } else {
                    ProgressView("Generujem PDF...")
                        .tint(.themeAccent)
                }
            }
            .navigationTitle("PDF Choreografia")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Zavrieť") { dismiss() }
                        .foregroundColor(.themeDark)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if let data = pdfData {
                        ShareLink(
                            item: PDFExportFile(data: data, filename: "\(routine.name)_\(routine.danceName).pdf"),
                            preview: SharePreview("\(routine.name) (PDF)", image: Image(systemName: "doc.text.fill"))
                        ) {
                            HStack(spacing: 4) {
                                Image(systemName: "square.and.arrow.up")
                                Text("Zdieľať")
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.themeAccent)
                        }
                    }
                }
            }
        }
        .onAppear {
            DispatchQueue.global(qos: .userInitiated).async {
                let data = RoutinePDFExporter.renderPDF(for: routine)
                DispatchQueue.main.async {
                    self.pdfData = data
                }
            }
        }
    }
}

// MARK: - PDFKit Represented View
struct PDFKitRepresentedView: UIViewRepresentable {
    let data: Data
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.document = PDFDocument(data: data)
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = PDFDocument(data: data)
    }
}

// MARK: - PDF Transferable File
struct PDFExportFile: Transferable {
    let data: Data
    let filename: String
    
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .pdf) { item in
            item.data
        }
        .suggestedFileName { item in
            item.filename
        }
    }
}
