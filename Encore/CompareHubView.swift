import SwiftUI
import SwiftData

// MARK: - Compare Hub View (Reference vs My Performance)
struct CompareHubView: View {
    @Binding var pathA: String?
    @Binding var pathB: String?
    @Binding var isPresented: Bool
    
    @Query(sort: \VideoMediaEntry.createdAt, order: .reverse) private var allVideos: [VideoMediaEntry]
    @Query(sort: \InstantNote.createdAt, order: .reverse) private var allNotes: [InstantNote]
    @Query(sort: \Dance.name) private var allDances: [Dance]
    
    @State private var showDirectComparison: Bool = false
    @State private var activeSlotForPicker: Int? = nil // 1 for A, 2 for B
    
    var body: some View {
        ZStack {
            EllegancePageBackground()
            
            GeometryReader { geo in
                let autoSidePadding = max(geo.size.width * 0.08, 20)
                
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // Header description
                        VStack(spacing: 6) {
                            Text("⚔️ Dual Porovnávač")
                                .font(.system(size: 22, weight: .bold, design: .serif))
                                .foregroundColor(.white)
                            
                            Text("Porovnanie referenčného vzoru (Idol) s vašim vlastným tancom so synchronizovaným posunom času a zrkadlením.")
                                .font(.system(size: 12))
                                .foregroundColor(Color.white.opacity(0.6))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 16)
                        
                        // Slots Selection (A vs B)
                        HStack(spacing: 12) {
                            // Slot A (My Take)
                            compareSlotCard(
                                slotNumber: 1,
                                title: "MOJE VIDEO (A)",
                                path: pathA,
                                roleName: "Vlastný pokus",
                                accentColor: Color.latinCrimson,
                                onSelect: { activeSlotForPicker = 1 },
                                onClear: { pathA = nil }
                            )
                            
                            // Slot B (Reference Idol)
                            compareSlotCard(
                                slotNumber: 2,
                                title: "VZOR / IDOL (B)",
                                path: pathB,
                                roleName: "Referencia",
                                accentColor: Color.syncEmerald,
                                onSelect: { activeSlotForPicker = 2 },
                                onClear: { pathB = nil }
                            )
                        }
                        
                        // Launch Dual Player Button
                        Button {
                            showDirectComparison = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "play.fill")
                                Text("Spustiť porovnávanie")
                            }
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color.obsidian900)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(colors: [Color.gold500, Color.gold400], startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(Capsule())
                            .shadow(color: Color.gold500.opacity(0.35), radius: 10)
                        }
                    }
                    .padding(.horizontal, autoSidePadding)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zavrieť") { isPresented = false }
                        .foregroundColor(Color.gold400)
                }
            }
            .fullScreenCover(isPresented: $showDirectComparison) {
                DualVideoComparisonView(
                    pathA: $pathA,
                    pathB: $pathB
                )
            }
            .sheet(isPresented: Binding(
                get: { activeSlotForPicker != nil },
                set: { if !$0 { activeSlotForPicker = nil } }
            )) {
                if let slot = activeSlotForPicker {
                    UniversalMediaPickerSheet(
                        slotTitle: slot == 1 ? DualSlot.a.rawValue : DualSlot.b.rawValue,
                        currentPath: slot == 1 ? pathA : pathB,
                        onSelectMedia: { path in
                            if slot == 1 {
                                pathA = path
                            } else {
                                pathB = path
                            }
                            activeSlotForPicker = nil
                        },
                        onClearMedia: {
                            if slot == 1 {
                                pathA = nil
                            } else {
                                pathB = nil
                            }
                            activeSlotForPicker = nil
                        }
                    )
                }
            }
        }
    }
    
    private func compareSlotCard(slotNumber: Int, title: String, path: String?, roleName: String, accentColor: Color, onSelect: @escaping () -> Void, onClear: @escaping () -> Void) -> some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.system(size: 11, weight: .black))
                .foregroundColor(accentColor)
            
            if let path = path {
                if MediaResolver.isImagePath(path: path), let img = MediaResolver.resolveImage(path: path) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 120)
                        .clipped()
                        .cornerRadius(12)
                } else if MediaResolver.isImagePath(path: path) {
                    MediaThumbnailView(path: path, placeholderIcon: "photo", cornerRadius: 12)
                        .frame(height: 120)
                } else {
                    LoopingVideoPlayer(videoPath: path, rate: 1.0)
                        .frame(height: 120)
                        .cornerRadius(12)
                }
                
                HStack(spacing: 8) {
                    Button(action: onSelect) {
                        Text("Zmeniť")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color.gold400)
                    }
                    
                    Text("•")
                        .foregroundColor(Color.white.opacity(0.3))
                    
                    Button(action: onClear) {
                        Text("Odobrať")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color.latinCrimson)
                    }
                }
            } else {
                Button(action: onSelect) {
                    VStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(accentColor)
                        
                        Text("Zvoliť video / foto")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(roleName)
                            .font(.system(size: 10))
                            .foregroundColor(Color.white.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .background(Color.themeCard.opacity(0.7))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(accentColor.opacity(0.35), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .luxurySmokedCard(cornerRadius: 16, accentColor: accentColor)
    }
}
