import SwiftUI
import CoreImage.CIFilterBuiltins

// MARK: - Luxury Encore Member Card (Italian Carmine Leather & Metallic 3D Gold)
struct EncoreMemberCardView: View {
    var name: String
    var club: String
    var userId: String
    var qrURL: String? = nil
    var allowInteractiveTilt: Bool = true
    var showActionButtons: Bool = true
    
    @State private var isFlipped = false
    @State private var flipRotation: Double = 0
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    @State private var showShareSheet = false
    @State private var renderedCardImage: UIImage? = nil
    
    @ObservedObject private var walletManager = AppleWalletPassManager.shared
    
    // Custom Carmine & Wine Leather Palette
    private let leatherDeepCarmine = Color(red: 0.52, green: 0.05, blue: 0.11) // #850D1C
    private let leatherWineCenter  = Color(red: 0.35, green: 0.02, blue: 0.07) // #590512
    private let leatherDarkShade   = Color(red: 0.20, green: 0.01, blue: 0.04) // #33030A
    
    private var targetQRString: String {
        qrURL ?? FriendManager.shared.buildMemberCardURL()
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // MARK: - Interactive 3D Card Surface
            ZStack {
                // Front Face (Rotates 0° -> 180°, visible at 0°..90°)
                cardFrontView
                    .opacity(flipRotation <= 90 ? 1 : 0)
                    .rotation3DEffect(
                        .degrees(flipRotation),
                        axis: (x: 0, y: 1, z: 0),
                        perspective: 0.55
                    )
                    .accessibilityHidden(isFlipped)
                
                // Back Face (Rotates -180° -> 0°, visible at 90°..180°)
                // When flipRotation is 180°, (180 - 180) = 0° towards user -> Left-to-right text is NOT mirrored!
                cardBackView
                    .opacity(flipRotation > 90 ? 1 : 0)
                    .rotation3DEffect(
                        .degrees(flipRotation - 180),
                        axis: (x: 0, y: 1, z: 0),
                        perspective: 0.55
                    )
                    .accessibilityHidden(!isFlipped)
            }
            .frame(maxWidth: 360)
            .aspectRatio(1.72, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(red: 0.95, green: 0.82, blue: 0.50).opacity(0.55),
                                Color(red: 0.60, green: 0.42, blue: 0.16).opacity(0.25),
                                Color(red: 0.95, green: 0.82, blue: 0.50).opacity(0.45)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.0
                    )
            )
            .shadow(color: Color.black.opacity(0.75), radius: 20, x: 0, y: 10)
            .shadow(color: leatherDeepCarmine.opacity(0.35), radius: 26, x: 0, y: 12)
            // Interactive 3D Tilt Parallax on Finger Drag
            .rotation3DEffect(
                .degrees(allowInteractiveTilt ? Double(dragOffset.width / 14) : 0),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.6
            )
            .rotation3DEffect(
                .degrees(allowInteractiveTilt ? Double(-dragOffset.height / 14) : 0),
                axis: (x: 1, y: 0, z: 0),
                perspective: 0.6
            )
            .gesture(
                DragGesture()
                    .onChanged { value in
                        guard allowInteractiveTilt else { return }
                        isDragging = true
                        dragOffset = value.translation
                    }
                    .onEnded { _ in
                        guard allowInteractiveTilt else { return }
                        isDragging = false
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                            dragOffset = .zero
                        }
                    }
            )
            .onTapGesture(count: 2) {
                toggleFlip()
            }
            
            // MARK: - Action Buttons Below Card
            if showActionButtons {
                VStack(spacing: 12) {
                    // Apple Wallet Button or Already in Wallet Status
                    if walletManager.isPassInWallet {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(Color.gold400)
                            Text("Karta je v Apple Peňaženke")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.obsidian800)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.gold500.opacity(0.4), lineWidth: 1)
                        )
                    } else {
                        Button {
                            HapticFeedback.medium()
                            Task {
                                await walletManager.addCardToAppleWallet(
                                    userId: userId,
                                    name: name,
                                    club: club
                                )
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "wallet.pass.fill")
                                    .font(.system(size: 16, weight: .bold))
                                Text(walletManager.isLoadingPass ? "Pripravujem lístok..." : "Pridať do Apple Peňaženky")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 0.98, green: 0.88, blue: 0.60), Color(red: 0.83, green: 0.68, blue: 0.28)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: Color(red: 0.83, green: 0.68, blue: 0.28).opacity(0.35), radius: 10, y: 3)
                        }
                        .buttonStyle(.plain)
                        .disabled(walletManager.isLoadingPass)
                    }
                    
                    // Flip & Share Secondary Controls
                    HStack(spacing: 10) {
                        Button {
                            toggleFlip()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 12, weight: .bold))
                                Text(isFlipped ? "Predná strana" : "Zadná strana")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundColor(Color.gold300)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.obsidian800)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gold500.opacity(0.3), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            shareCardImage()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 12, weight: .bold))
                                Text("Zdieľať kartu")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundColor(Color.gold300)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.obsidian800)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gold500.opacity(0.3), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: 360)
            }
        }
        // Apple Wallet Informative Alert Dialog
        .alert(isPresented: $walletManager.showErrorAlert) {
            Alert(
                title: Text(walletManager.alertTitle),
                message: Text(walletManager.alertMessage),
                primaryButton: .default(Text("Otvoriť webovú kartu")) {
                    if let url = walletManager.fallbackURL {
                        UIApplication.shared.open(url)
                    }
                },
                secondaryButton: .cancel(Text("Rozumiem"))
            )
        }
    }
    
    // MARK: - Toggle 3D Flip
    private func toggleFlip() {
        withAnimation(.spring(response: 0.65, dampingFraction: 0.82)) {
            isFlipped.toggle()
            flipRotation = isFlipped ? 180 : 0
        }
        HapticFeedback.light()
    }
    
    // MARK: - Card Front View (Luxury Matte Red Leather & Metallic Gold)
    private var cardFrontView: some View {
        ZStack {
            // 1. Handcrafted Red Leather Base Surface with Saddle Stitching
            LeatherCardSurface(isFront: true)
            
            // 2. Card Content Layers
            VStack {
                // Top Row: QR Code in Top Right Corner
                HStack(alignment: .top) {
                    Spacer()
                    
                    if let qrImage = QRGenerator.generateQRCode(from: targetQRString) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.white)
                                .frame(width: 58, height: 58)
                            
                            Image(uiImage: qrImage)
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 52, height: 52)
                            
                            // Center tiny Encore seal
                            Circle()
                                .fill(leatherDeepCarmine)
                                .frame(width: 10, height: 10)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 1)
                                )
                        }
                        .padding(16)
                        .shadow(color: Color.black.opacity(0.45), radius: 6, x: 0, y: 3)
                    }
                }
                
                Spacer()
                
                // Bottom Row: Calligraphic cursive name in Gilded Embossed Gold
                HStack {
                    Spacer()
                    
                    Text(name.isEmpty ? "Jakub Kalina" : name)
                        .font(calligraphicFont)
                        .foregroundColor(Color(red: 0.96, green: 0.85, blue: 0.50))
                        .shadow(color: Color.black.opacity(0.85), radius: 3, x: 1, y: 1.5)
                        .shadow(color: Color(red: 0.92, green: 0.78, blue: 0.38).opacity(0.4), radius: 6)
                        .padding(.trailing, 20)
                        .padding(.bottom, 16)
                }
            }
            
            // 3. Center Metallic 3D Gold Logo (Machined Brass / Embossed Metal)
            metallicGoldEmblem
        }
    }
    
    // MARK: - Metallic 3D Gold Emblem (Physical Cast Metal on Leather)
    private var metallicGoldEmblem: some View {
        ZStack {
            // A. Embossed Leather Stamping Shadow (Deep deboss indentation in the leather)
            Image("EncoreLogo")
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: 66, height: 66)
                .foregroundColor(Color.black.opacity(0.80))
                .blur(radius: 1.8)
                .offset(x: 1.2, y: 2.2)
            
            // B. Specular Metal Bevel Chamfer Highlight (Top-left light edge)
            Image("EncoreLogo")
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: 66, height: 66)
                .foregroundStyle(Color(red: 1.0, green: 0.98, blue: 0.90).opacity(0.90))
                .offset(x: -0.9, y: -0.9)
            
            // C. Multi-Stop Specular Brushed Gold Body
            Image("EncoreLogo")
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: 66, height: 66)
                .foregroundStyle(
                    LinearGradient(
                        stops: [
                            .init(color: Color(red: 1.00, green: 0.96, blue: 0.82), location: 0.00), // Specular Crest
                            .init(color: Color(red: 0.92, green: 0.78, blue: 0.38), location: 0.20), // 24K Polished Gold
                            .init(color: Color(red: 0.65, green: 0.46, blue: 0.14), location: 0.46), // Deep Bronze Shadow
                            .init(color: Color(red: 0.98, green: 0.91, blue: 0.66), location: 0.68), // Specular Reflection
                            .init(color: Color(red: 0.86, green: 0.69, blue: 0.30), location: 0.86), // Warm Gold
                            .init(color: Color(red: 0.52, green: 0.36, blue: 0.10), location: 1.00)  // Edge Rim Shadow
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.black.opacity(0.55), radius: 4, x: 0, y: 2)
            
            // D. Soft Ambient Metallic Radiance
            Image("EncoreLogo")
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: 66, height: 66)
                .foregroundStyle(Color(red: 0.95, green: 0.82, blue: 0.40).opacity(0.20))
                .blur(radius: 6)
        }
    }
    
    // MARK: - Card Back View (Matte Leather & Normal Left-to-Right Orientation)
    private var cardBackView: some View {
        ZStack {
            // 1. Leather Surface
            LeatherCardSurface(isFront: false)
            
            // 2. Information Layout (Normal Left-to-Right Reading)
            VStack(alignment: .leading, spacing: 12) {
                // Header Row
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ENCORE DANCE PASS")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .tracking(1.4)
                            .foregroundColor(Color(red: 0.96, green: 0.85, blue: 0.50))
                        Text("Ballroom & Latin Excellence")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(Color.white.opacity(0.65))
                    }
                    Spacer()
                    Image("EncoreLogo")
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 1.0, green: 0.92, blue: 0.70), Color(red: 0.85, green: 0.68, blue: 0.28)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                Divider().background(Color.gold500.opacity(0.35))
                
                // Dancer Details
                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TANEČNÍK")
                            .font(.system(size: 8, weight: .bold))
                            .tracking(0.8)
                            .foregroundColor(Color(red: 0.90, green: 0.78, blue: 0.45).opacity(0.8))
                        Text(name.isEmpty ? "Jakub Kalina" : name)
                            .font(.system(size: 14, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("KLUB")
                            .font(.system(size: 8, weight: .bold))
                            .tracking(0.8)
                            .foregroundColor(Color(red: 0.90, green: 0.78, blue: 0.45).opacity(0.8))
                        Text(club.isEmpty ? "Individuálny" : club)
                            .font(.system(size: 14, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                }
                
                Spacer()
                
                // Bottom Pass Code / Member UID & Invite Code
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        let code = UserProfileStore.shared.currentInviteCode
                        let displayCode = code.isEmpty ? String(userId.prefix(8)).uppercased() : code
                        Text("POZVÁNKA KÓD: \(displayCode)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(red: 0.96, green: 0.85, blue: 0.50))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.40))
                            .cornerRadius(4)
                        
                        Text("UID: \(userId.prefix(8).uppercased())")
                            .font(.system(size: 8, weight: .medium, design: .monospaced))
                            .foregroundColor(Color.white.opacity(0.45))
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 5) {
                        Circle().fill(Color(red: 0.95, green: 0.82, blue: 0.45)).frame(width: 5, height: 5)
                        Text(walletManager.isPassInWallet ? "V APPLE PEŇAŽENKE" : "WALLET READY")
                            .font(.system(size: 8, weight: .heavy))
                            .foregroundColor(Color(red: 0.95, green: 0.82, blue: 0.45))
                    }
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Calligraphic Font
    private var calligraphicFont: Font {
        if let _ = UIFont(name: "SnellRoundhand-Bold", size: 23) {
            return Font.custom("SnellRoundhand-Bold", size: 23)
        } else if let _ = UIFont(name: "SnellRoundhand", size: 23) {
            return Font.custom("SnellRoundhand", size: 23)
        } else if let _ = UIFont(name: "Zapfino", size: 18) {
            return Font.custom("Zapfino", size: 18)
        }
        return Font.system(size: 21, weight: .medium, design: .serif).italic()
    }
    
    // MARK: - Share Card Helper
    private func shareCardImage() {
        let cardToRender = isFlipped ? AnyView(cardBackView) : AnyView(cardFrontView)
        let renderer = ImageRenderer(content: cardToRender.frame(width: 360, height: 210).clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous)))
        renderer.scale = 3.0
        if let image = renderer.uiImage {
            let av = UIActivityViewController(activityItems: [image, targetQRString], applicationActivities: nil)
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let root = scene.windows.first?.rootViewController {
                root.present(av, animated: true)
            }
        }
    }
}

// MARK: - Luxury Handcrafted Leather Surface with Saddle Stitching
struct LeatherCardSurface: View {
    var isFront: Bool = true
    
    // Italian Leather Palette
    private let leatherDeepCarmine = Color(red: 0.52, green: 0.05, blue: 0.11) // #850D1C
    private let leatherWineCenter  = Color(red: 0.35, green: 0.02, blue: 0.07) // #590512
    private let leatherDarkShade   = Color(red: 0.20, green: 0.01, blue: 0.04) // #33030A
    
    var body: some View {
        ZStack {
            // 1. Base Rich Matte Leather Gradient (No plastic shine)
            LinearGradient(
                stops: [
                    .init(color: leatherDeepCarmine, location: 0.0),
                    .init(color: leatherWineCenter, location: 0.48),
                    .init(color: leatherDarkShade, location: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // 2. Leather Vignette (Darkened edges for volume & depth)
            RadialGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.38)
                ],
                center: .center,
                startRadius: 70,
                endRadius: 230
            )
            
            // 3. Procedural Micro-Pebbled Leather Grain (Tactile matte texture)
            Canvas { context, size in
                let spacing: CGFloat = 3.6
                var y: CGFloat = 1.0
                var row = 0
                while y < size.height {
                    let offsetX = (row % 2 == 0) ? 0.0 : spacing / 2.0
                    var x: CGFloat = 1.0 + offsetX
                    while x < size.width {
                        let hash = sin(x * 12.9898 + y * 78.233) * 43758.5453
                        let rand = hash - floor(hash)
                        
                        // Pebble shadow indent
                        let cellRect = CGRect(x: x, y: y, width: 1.6, height: 1.6)
                        let shadowColor = Color.black.opacity(0.12 + rand * 0.10)
                        context.fill(Path(ellipseIn: cellRect), with: .color(shadowColor))
                        
                        // Pebble matte apex highlight
                        if rand > 0.48 {
                            let hlRect = CGRect(x: x - 0.3, y: y - 0.3, width: 0.85, height: 0.85)
                            let hlColor = Color(red: 1.0, green: 0.85, blue: 0.80).opacity(0.035 + rand * 0.035)
                            context.fill(Path(ellipseIn: hlRect), with: .color(hlColor))
                        }
                        
                        x += spacing
                    }
                    y += spacing
                    row += 1
                }
            }
            .opacity(0.85)
            .allowsHitTesting(false)
            
            // 4. Perimeter Leather Crease Groove
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(Color.black.opacity(0.35), lineWidth: 0.8)
                .padding(6)
            
            // 5. Handcrafted Saddle Stitching (Dashed Waxed Thread with debossed groove)
            ZStack {
                // Thread indent shadow (groove in the leather)
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(
                        Color.black.opacity(0.50),
                        style: StrokeStyle(lineWidth: 1.2, lineCap: .round, dash: [4.0, 3.5], dashPhase: 0)
                    )
                    .offset(x: 0.3, y: 0.6)
                
                // Waxed Gold-Bronze Thread
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(red: 0.88, green: 0.74, blue: 0.42).opacity(0.70),
                                Color(red: 0.70, green: 0.52, blue: 0.22).opacity(0.55),
                                Color(red: 0.92, green: 0.80, blue: 0.50).opacity(0.75)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 1.1, lineCap: .round, dash: [4.0, 3.5], dashPhase: 0)
                    )
            }
            .padding(10)
        }
    }
}
