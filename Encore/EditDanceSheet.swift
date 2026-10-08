import SwiftUI
import SwiftData
import PhotosUI

// MARK: - Edit Dance Details Sheet

struct EditDanceSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var dance: Dance
    
    @State private var nameText = ""
    @State private var tempoText = ""
    @State private var infoText = ""
    @State private var playbackRate: Float = 1.0
    
    @State private var showCamera = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                EllegancePageBackground()
                
                GeometryReader { geo in
                    let autoSidePadding = max(geo.size.width * 0.08, 20)
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            
                            VStack(alignment: .leading, spacing: 14) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Názov tanca")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(Color.white.opacity(0.6))
                                    TextField("Názov", text: $nameText)
                                        .padding()
                                        .background(Color.themeCard)
                                        .cornerRadius(10)
                                        .foregroundColor(.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                        )
                                }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Tempo")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(Color.white.opacity(0.6))
                                    TextField("Tempo (napr. 28t/m)", text: $tempoText)
                                        .padding()
                                        .background(Color.themeCard)
                                        .cornerRadius(10)
                                        .foregroundColor(.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                        )
                                }
                            }
                            
                            // Image section
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Ilustračná fotografia tanca")
                                    .font(.system(size: 14, weight: .bold, design: .serif))
                                    .foregroundColor(.white)
                                
                                if let imagePath = dance.imagePath,
                                   let uiImage = MediaResolver.resolveImage(path: imagePath) {
                                    
                                    VStack(spacing: 12) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(maxHeight: 200)
                                            .cornerRadius(16)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                            )
                                        
                                        Button(action: deletePhoto) {
                                            HStack {
                                                Image(systemName: "trash")
                                                Text("Odstrániť fotku")
                                            }
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(Color.latinRed)
                                        }
                                    }
                                } else {
                                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                        HStack {
                                            Image(systemName: "photo.badge.plus")
                                            Text("Vybrať fotku z galérie")
                                        }
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 80)
                                        .background(Color.themeCard)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            
                            // Video section
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Všeobecné tréningové video")
                                    .font(.system(size: 14, weight: .bold, design: .serif))
                                    .foregroundColor(.white)
                                
                                if let videoPath = dance.videoPath {
                                    VStack(spacing: 12) {
                                        LoopingVideoPlayer(videoPath: videoPath, rate: playbackRate)
                                            .frame(height: 200)
                                            .cornerRadius(16)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                            )
                                        
                                        HStack(spacing: 12) {
                                            Text("Rýchlosť:")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(Color.white.opacity(0.6))
                                            
                                            ForEach([0.5, 0.75, 1.0, 1.5], id: \.self) { speed in
                                                Button(action: { playbackRate = Float(speed) }) {
                                                    Text(String(format: "%.2fx", speed))
                                                        .font(.system(size: 11, weight: .black))
                                                        .foregroundColor(playbackRate == Float(speed) ? .black : .white)
                                                        .padding(.horizontal, 10)
                                                        .padding(.vertical, 6)
                                                        .background(playbackRate == Float(speed) ? Color.gold400 : Color.themeCard)
                                                        .cornerRadius(8)
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 8)
                                                                .stroke(playbackRate == Float(speed) ? Color.clear : Color.white.opacity(0.1), lineWidth: 1)
                                                        )
                                                }
                                                .buttonStyle(.plain)
                                            }
                                            
                                            Spacer()
                                            
                                            Button(action: deleteVideo) {
                                                Image(systemName: "trash.circle.fill")
                                                    .font(.system(size: 22))
                                                    .foregroundColor(Color.latinRed)
                                            }
                                        }
                                    }
                                } else {
                                    Button(action: { showCamera = true }) {
                                        HStack {
                                            Image(systemName: "video.badge.plus.fill")
                                            Text("Nahrať tréningové video")
                                        }
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 80)
                                        .background(Color.themeCard)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            
                            // Text description
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Popis tanca / Charakteristika")
                                    .font(.system(size: 14, weight: .bold, design: .serif))
                                    .foregroundColor(.white)
                                
                                TextEditor(text: $infoText)
                                    .scrollContentBackground(.hidden)
                                    .frame(height: 120)
                                    .padding(8)
                                    .background(Color.themeCard)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, autoSidePadding)
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Upraviť \(dance.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zrušiť") { dismiss() }
                        .foregroundColor(Color.white.opacity(0.7))
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Uložiť") {
                        saveChanges()
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color.gold400)
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Hotovo") {
                        UIApplication.shared.endEditing()
                    }
                    .foregroundColor(Color.gold400)
                }
            }
            .onAppear {
                nameText = dance.name
                tempoText = dance.tempo
                infoText = dance.info
            }
            .fullScreenCover(isPresented: $showCamera) {
                DanceCameraView { localPath in
                    dance.videoPath = localPath
                    try? modelContext.save()
                    showCamera = false
                }
                .ignoresSafeArea()
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        if let filename = try? MediaStorageManager.store(data: data, prefix: "dance_img", fileExtension: "jpg") {
                            await MainActor.run {
                                MediaStorageManager.removeFile(named: dance.imagePath)
                                dance.imagePath = filename
                                try? modelContext.save()
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func saveChanges() {
        dance.name = nameText
        dance.tempo = tempoText
        dance.info = infoText
        try? modelContext.save()
    }
    
    private func deletePhoto() {
        if let path = dance.imagePath {
            MediaStorageManager.removeFile(named: path)
        }
        dance.imagePath = nil
        try? modelContext.save()
    }
    
    private func deleteVideo() {
        if let path = dance.videoPath {
            MediaStorageManager.removeFile(named: path)
        }
        dance.videoPath = nil
        try? modelContext.save()
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
