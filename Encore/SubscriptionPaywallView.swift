import SwiftUI
import StoreKit

// MARK: - Subscription Paywall View (StoreKit 2 Luxury Modal)
public struct SubscriptionPaywallView: View {
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var isAnnual: Bool = true
    @State private var selectedTier: SubscriptionTier = .plus
    @State private var errorMessage: String? = nil
    @State private var showLegalSheet: Bool = false
    
    public init(initialTier: SubscriptionTier = .plus) {
        _selectedTier = State(initialValue: initialTier == .free ? .plus : initialTier)
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                EllegancePageBackground()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // 1. Luxury Header Hero
                        headerSection
                        
                        // 2. Billing Period Selector (Monthly vs Annual with -30% discount)
                        billingPeriodPicker
                        
                        // 3. Tiers Comparison Cards
                        tierCardsSection
                        
                        // 4. Feature Highlights for Selected Tier
                        featuresListSection
                        
                        // 5. Action Button (Subscribe or Manage)
                        purchaseButtonSection
                        
                        // 6. Restore Purchases & Legal Disclaimers (Required by Apple Review)
                        appleComplianceFooter
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Členstvo Encore")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .sheet(isPresented: $showLegalSheet) {
                LegalComplianceView()
            }
            .task {
                await subscriptionManager.loadProducts()
            }
        }
    }
    
    // MARK: - 1. Header Hero
    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [LuxuryTheme.gold500.opacity(0.35), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 50
                        )
                    )
                    .frame(width: 90, height: 90)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [LuxuryTheme.gold300, LuxuryTheme.gold500],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: LuxuryTheme.gold500.opacity(0.5), radius: 12, x: 0, y: 4)
            }
            
            Text("Posuňte svoj tanec na vrchol")
                .font(.system(size: 24, weight: .heavy))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text("Vyberte si úroveň, ktorá zodpovedá vašim športovým cieľom — od tanečného páru až po trénerské štúdio.")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)
        }
    }
    
    // MARK: - 2. Billing Period Picker
    private var billingPeriodPicker: some View {
        HStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3)) { isAnnual = false }
            } label: {
                Text("Mesačne")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(!isAnnual ? LuxuryTheme.obsidian900 : .white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(!isAnnual ? LuxuryTheme.gold400 : Color.clear)
                    .cornerRadius(10)
            }
            
            Button {
                withAnimation(.spring(response: 0.3)) { isAnnual = true }
            } label: {
                HStack(spacing: 6) {
                    Text("Ročne")
                        .font(.system(size: 14, weight: .bold))
                    
                    Text("UŠETRÍTE 30%")
                        .font(.system(size: 9, weight: .black))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(LuxuryTheme.obsidian900.opacity(0.6))
                        .foregroundColor(LuxuryTheme.gold300)
                        .cornerRadius(6)
                }
                .foregroundColor(isAnnual ? LuxuryTheme.obsidian900 : .white.opacity(0.7))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isAnnual ? LuxuryTheme.gold400 : Color.clear)
                .cornerRadius(10)
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.08))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(LuxuryTheme.gold500.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - 3. Tier Cards Section
    private var tierCardsSection: some View {
        HStack(spacing: 12) {
            tierCard(tier: .plus)
            tierCard(tier: .studio)
        }
    }
    
    private func tierCard(tier: SubscriptionTier) -> some View {
        let isSelected = selectedTier == tier
        let price = isAnnual ? tier.annualPriceFormatted : tier.monthlyPriceFormatted
        let period = isAnnual ? "/ rok" : "/ mesiac"
        
        return Button {
            withAnimation(.spring(response: 0.3)) {
                selectedTier = tier
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: tier.iconName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isSelected ? LuxuryTheme.gold400 : .white.opacity(0.6))
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(LuxuryTheme.gold400)
                    }
                }
                
                Text(tier.rawValue)
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundColor(.white)
                
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(price)
                        .font(.system(size: 20, weight: .black))
                        .foregroundColor(LuxuryTheme.gold300)
                    Text(period)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Text(tier == .plus ? "Pre tanečníkov & páry" : "Pre trénerov & kluby")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.65))
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? LuxuryTheme.obsidian800 : Color.white.opacity(0.04))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? LuxuryTheme.gold400 : Color.white.opacity(0.12), lineWidth: isSelected ? 1.8 : 1)
            )
            .shadow(color: isSelected ? LuxuryTheme.gold500.opacity(0.2) : .clear, radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - 4. Features List Section
    private var featuresListSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(selectedTier == .plus ? "VÝHODY ENCORE PLUS:" : "VÝHODY ENCORE STUDIO:")
                .font(.system(size: 11, weight: .black))
                .foregroundColor(LuxuryTheme.gold400)
                .tracking(1.2)
            
            if selectedTier == .plus {
                featureRow(icon: "trophy.fill", title: "Sledovanie vlastných KSIS bodov", subtitle: "Automatický výpočet postupových bodov z ksis.eu a finálových umiestnení")
                featureRow(icon: "arrow.triangle.2.circlepath", title: "Zdieľanie s partnerom v cloude", subtitle: "Spoločná synchronizácia zostáv a poznámok naživo")
                featureRow(icon: "folder.fill.badge.plus", title: "Neobmedzené choreografie", subtitle: "Žiadny limit 2 zostáv, archivácia všetkých tancov STT a LAT")
                featureRow(icon: "waveform.path", title: "Biomechanická analýza držania tela", subtitle: "Detekcia tanečného rámu a sklonu ramien")
            } else {
                featureRow(icon: "checkmark.seal.fill", title: "Všetko z balíka Plus", subtitle: "Všetky funkcie pre neobmedzenú tvorbu choreografií a vlastných bodov")
                featureRow(icon: "person.3.sequence.fill", title: "Sledovanie bodov iných párov (Roster)", subtitle: "Majte prehľad o postupoch a výsledkoch svojich zverencov a priateľov")
                featureRow(icon: "building.2.crop.circle.fill", title: "Trénerský manažment žiakov", subtitle: "Priraďovanie figúr a revízia choreografií pre celý tanečný klub")
                featureRow(icon: "bell.badge.fill", title: "KSIS Notifikácie a alerty", subtitle: "Upozornenia na nové výsledky a postupové zmeny vašich párov")
                featureRow(icon: "star.shield.fill", title: "Prioritná technická podpora", subtitle: "Priamy kontakt na vývojársky tím Encore")
            }
        }
        .padding(18)
        .background(LuxuryTheme.obsidian800.opacity(0.85))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(LuxuryTheme.gold500.opacity(0.25), lineWidth: 1)
        )
    }
    
    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(LuxuryTheme.gold500.opacity(0.18))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(LuxuryTheme.gold400)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.65))
            }
            
            Spacer()
        }
    }
    
    // MARK: - 5. Purchase Button Section
    private var purchaseButtonSection: some View {
        VStack(spacing: 10) {
            if subscriptionManager.isAppOwner {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .foregroundColor(LuxuryTheme.gold300)
                    Text("Prihlásený ako Majiteľ aplikácie (God Mode aktívny)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(LuxuryTheme.gold300)
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(LuxuryTheme.gold500.opacity(0.15))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(LuxuryTheme.gold500.opacity(0.4), lineWidth: 1))
            } else if subscriptionManager.currentTier == selectedTier {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Tento plán máte aktuálne aktívny")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(14)
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.15))
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.green.opacity(0.4), lineWidth: 1))
            } else {
                Button {
                    executePurchase()
                } label: {
                    HStack(spacing: 8) {
                        if subscriptionManager.isPurchasing {
                            ProgressView().tint(LuxuryTheme.obsidian900)
                        }
                        Text(subscriptionManager.isPurchasing ? "Prebieha nákup..." : "Aktivovať \(selectedTier.rawValue)")
                    }
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundColor(LuxuryTheme.obsidian900)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [LuxuryTheme.gold500, LuxuryTheme.gold400],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: LuxuryTheme.gold500.opacity(0.4), radius: 12, x: 0, y: 4)
                }
                .disabled(subscriptionManager.isPurchasing)
            }
            
            if let err = errorMessage {
                Text(err)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.latinCrimson)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - 6. Apple Compliance Footer (Restore & Legal Links)
    private var appleComplianceFooter: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    errorMessage = nil
                    await subscriptionManager.restorePurchases()
                }
            } label: {
                Text("Obnoviť predchádzajúce nákupy")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(LuxuryTheme.gold300)
            }
            
            Text("Predplatné sa automaticky obnovuje, pokiaľ nie je zrušené aspoň 24 hodín pred koncom aktuálneho fakturačného obdobia. Spravovať predplatné a automatické obnovenie môžete kedykoľvek vo svojom Apple ID účte v Nastaveniach.")
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(.white.opacity(0.45))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)
            
            HStack(spacing: 16) {
                Button {
                    showLegalSheet = true
                } label: {
                    Text("Podmienky používania (EULA)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .underline()
                }
                
                Text("•").foregroundColor(.white.opacity(0.3))
                
                Button {
                    showLegalSheet = true
                } label: {
                    Text("Ochrana súkromia")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .underline()
                }
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Purchase Action
    private func executePurchase() {
        errorMessage = nil
        let targetId: String
        switch (selectedTier, isAnnual) {
        case (.plus, true): targetId = SubscriptionManager.ProductID.plusAnnual
        case (.plus, false): targetId = SubscriptionManager.ProductID.plusMonthly
        case (.studio, true): targetId = SubscriptionManager.ProductID.studioAnnual
        case (.studio, false): targetId = SubscriptionManager.ProductID.studioMonthly
        default: targetId = SubscriptionManager.ProductID.plusMonthly
        }
        
        guard let product = subscriptionManager.availableProducts.first(where: { $0.id == targetId }) else {
            // Product not yet loaded or running in simulator without StoreKit configuration
            errorMessage = "Produkt sa pripravuje v App Store Connect. V prípade otázok kontaktujte podporu."
            return
        }
        
        Task {
            do {
                let success = try await subscriptionManager.purchase(product: product)
                if success {
                    dismiss()
                }
            } catch {
                errorMessage = "Nákup nebolo možné dokončiť: \(error.localizedDescription)"
            }
        }
    }
}
