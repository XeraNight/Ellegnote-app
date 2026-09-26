//
//  LegalComplianceView.swift
//  Encore
//
//  Created for App Store & GDPR Compliance.
//

import SwiftUI

public struct LegalComplianceView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: LegalTab = .privacy

    public enum LegalTab: String, CaseIterable, Identifiable {
        case privacy = "Súkromie (GDPR)"
        case terms = "Podmienky & EULA"
        case disclaimer = "Zodpovednosť"
        case audioKsis = "Hudba & SZTŠ"

        public var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .privacy: return "hand.raised.fill"
            case .terms: return "doc.text.fill"
            case .disclaimer: return "cross.case.fill"
            case .audioKsis: return "music.note.list"
            }
        }
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                ElleganceToolBackground()
                
                VStack(spacing: 0) {
                    // Segmented Selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(LegalTab.allCases) { tab in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                        selectedTab = tab
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: tab.icon)
                                            .font(.system(size: 11, weight: .bold))
                                        Text(tab.rawValue)
                                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        selectedTab == tab
                                            ? Color.gold500.opacity(0.2)
                                            : Color.white.opacity(0.04)
                                    )
                                    .foregroundColor(selectedTab == tab ? .gold400 : .white.opacity(0.6))
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(
                                                selectedTab == tab ? Color.gold400.opacity(0.5) : Color.white.opacity(0.08),
                                                lineWidth: 1
                                            )
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    
                    Divider().background(Color.gold500.opacity(0.2))

                    // Content ScrollView
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            switch selectedTab {
                            case .privacy:
                                privacyPolicyContent
                            case .terms:
                                termsAndEulaContent
                            case .disclaimer:
                                disclaimerContent
                            case .audioKsis:
                                audioAndKsisContent
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Právne informácie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zavrieť") {
                        dismiss()
                    }
                    .foregroundColor(.gold400)
                    .font(.system(size: 14, weight: .semibold))
                }
            }
        }
    }

    // MARK: - 1. Privacy Policy (GDPR)
    private var privacyPolicyContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerBadge(title: "Zásady ochrany osobných údajov", icon: "lock.shield.fill")
            
            legalSection(
                title: "1. Prevádzkovateľ a správca osobných údajov",
                body: "Prevádzkovateľom aplikácie Encore a správcom osobných údajov je autor aplikácie. Kontakt pre uplatnenie práv dotknutých osôb v zmysle GDPR: jakub.encoreapp@gmail.com."
            )
            
            legalSection(
                title: "2. Aké údaje spracúvame a prečo",
                body: """
                • Registračné údaje: Meno/Prezývka, e-mailová adresa (získané priamo alebo cez Google Sign-In / Sign in with Apple). Právny základ: Plnenie zmluvy o poskytovaní služby.
                • Tanečné materiály: Zoznam zostáv, choreografií, vlastné poznámky a nahrávky figúr. Tieto dáta sú privátne pre váš účet.
                • Tréningové videá a analýza držania tela: Videá slúžia výhradne na orientačnú biomechanickú analýzu pre váš tréning. Neslúžia na biometrickú identifikáciu osoby. Sú primárne uložené na vašom zariadení.
                • Súťažné dáta: Výsledky zo systému ksis.eu, ktoré si používateľ sám importuje pre prehľad o svojom postupe.
                """
            )
            
            legalSection(
                title: "3. Doba uchovávania a zmazanie",
                body: "Vaše údaje uchovávame len po dobu aktívneho využívania aplikácie. Kedykoľvek môžete v sekcii Profil využiť tlačidlo „Zmazať účet a osobné dáta“. Týmto dôjde k trvalému a neodvratnému vymazaniu všetkých údajov zo serverov a zrušeniu autorizácie."
            )
            
            legalSection(
                title: "4. Vaše práva podľa GDPR",
                body: """
                Ako dotknutá osoba máte právo na:
                • Prístup k osobným údajom a informácie o ich spracúvaní,
                • Opravu nesprávnych alebo neúplných údajov,
                • Vymazanie (právo „na zabudnutie“) priamo v aplikácii,
                • Prenosnosť údajov (funkcia exportu zostáv do JSON formátu priamo v Profile),
                • Podanie sťažnosti na Úrad na ochranu osobných údajov SR.
                """
            )
            
            legalSection(
                title: "5. Tretie strany a infraštruktúra",
                body: "Dáta sú bezpečne ukladané v databáze Supabase s platnou zmluvou o spracovaní údajov (DPA) a servermi umiestnenými v Európskej únii. Žiadne osobné údaje nepredávame reklamným sieťam ani nesledujeme používateľov naprieč inými aplikáciami (App Tracking Transparency = No Tracking)."
            )
        }
    }

    // MARK: - 2. Terms of Service & EULA
    private var termsAndEulaContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerBadge(title: "Podmienky používania & EULA", icon: "doc.plaintext.fill")

            legalSection(
                title: "1. Prijatie podmienok",
                body: "Používaním aplikácie Encore súhlasíte s týmito zmluvnými podmienkami (EULA). Ak s nimi nesúhlasíte, aplikáciu nepoužívajte."
            )

            legalSection(
                title: "2. Pravidlá používateľského obsahu (UGC)",
                body: """
                Aplikácia Encore uplatňuje politiku nulovej tolerancie voči nevhodnému obsahu:
                • Je prísne zakázané nahrávať, synchronizovať alebo zdieľať cez QR kód obsah, ktorý je urážlivý, nezákonný, hanlivý, obťažujúci alebo porušuje autorské práva tretích strán.
                • Zdieľanie zostáv s tanečným partnerom alebo priateľom je určené výhradne na legálne športové a tréningové účely.
                • Porušenie týchto pravidiel má za následok okamžité zablokovanie účtu a vymazanie synchronizovaných zostáv.
                """
            )

            legalSection(
                title: "3. Duševné vlastníctvo a vlastníctvo choreografií",
                body: "Všetky vaše choreografie, tanečné zostavy, videozáznamy a poznámky zostávajú vo vašom výlučnom vlastníctve. Poskytovateľovi aplikácie udeľujete iba technickú licenciu nevyhnutnú na ich uloženie a zobrazenie na vašich zariadeniach."
            )

            legalSection(
                title: "4. Predplatné a In-App platby",
                body: "Pokiaľ aplikácia ponúka platené funkcie alebo predplatné na iOS zariadeniach, platby sú spracovávané výhradne prostredníctvom Apple In-App Purchase (StoreKit) v súlade s pravidlami spoločnosti Apple. Správu predplatného a žiadosti o vrátenie peňazí je možné vykonávať cez nastavenia Apple ID."
            )

            legalSection(
                title: "5. Vekové obmedzenie a ochrana mladistvých (GDPR)",
                body: "Aplikácia Encore je určená pre tanečníkov všetkých vekových kategórií vrátane juniorov a mládeže. Používatelia mladší ako 16 rokov môžu aplikáciu používať a zakladať si účet výhradne so súhlasom svojho zákonného zástupcu (rodiča) v súlade s článkom 8 nariadenia GDPR a Zákonom č. 18/2018 Z. z. o ochranne osobných údajov."
            )
        }
    }

    // MARK: - 3. Disclaimers
    private var disclaimerContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerBadge(title: "Vyhlásenie o vylúčení zodpovednosti", icon: "cross.case.fill")

            legalSection(
                title: "1. Zdravotné a tréningové vyhlásenie",
                body: """
                Aplikácia Encore je asistenčný nástroj pre tanečníkov a trénerov. 
                • Analýza držania tela, biomechanické odporúčania a tréningové záznamy majú výhradne orientačný a edukatívny charakter.
                • Aplikácia nenahrádza odborné vedenie certifikovaného trénera, fyzioterapeuta ani lekára.
                • Tréning a fyzické cvičenie vykonávate na vlastné riziko. Prevádzkovateľ nenesie zodpovednosť za akékoľvek zranenia, úrazy alebo poškodenia zdravia vzniknuté v súvislosti s tréningom podľa aplikácie.
                """
            )

            legalSection(
                title: "2. Presnosť súťažných dát",
                body: "Dáta o bodoch a finálových umiestneniach zo systému ksis.eu majú informatívny charakter. Jediným oficiálnym a právne záväzným zdrojom súťažných výsledkov je Slovenský zväz tanečného športu (SZTŠ)."
            )
        }
    }

    // MARK: - 4. Audio & KSIS Fair Use
    private var audioAndKsisContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerBadge(title: "Hudba, Médiá & KSIS Dáta", icon: "music.note.list")

            legalSection(
                title: "1. Zvukové nahrávky a metronóm",
                body: """
                • Modul Metronóm nevyužíva žiadne chránené zvukové vzorky tretích strán — všetky rytmické signály sú generované algoritmicky v reálnom čase matematickou syntézou zvukovej vlny.
                • Modul Music Speed Trainer slúži ako prehrávač pre vlastné zvukové súbory používateľa. Aplikácia neobsahuje žiadne chránené hudobné diela. Používateľ zodpovedá za to, že k nahrávkam, ktoré si do aplikácie importuje, disponuje príslušnými právami.
                """
            )

            legalSection(
                title: "2. Záznamy zo seminárov a videá idolov",
                body: "Pri nahrávaní tréningových seminárov alebo importovaní vzorových videí používateľ zodpovedá za získanie súhlasu dotknutých osôb v zmysle autorského zákona a ochrany osobnosti. Tieto záznamy slúžia len na súkromné študijné účely používateľa."
            )

            legalSection(
                title: "3. Informácia o systéme KSIS",
                body: "Názov KSIS a výsledkové listiny sú majetkom ich príslušných prevádzkovateľov. Aplikácia Encore využíva výhradne verejne publikované zoznamy a rešpektuje technické limity serverov prostredníctvom riadeného obmedzenia počtu požiadaviek (rate limiting)."
            )
        }
    }

    // MARK: - Helpers
    private func headerBadge(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.gold400)
            Text(title)
                .font(.system(size: 14, weight: .black, design: .serif))
                .foregroundColor(.gold400)
        }
        .padding(.vertical, 4)
    }

    private func legalSection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
            
            Text(body)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.white.opacity(0.8))
                .lineSpacing(3)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.04))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Xcode Canvas Preview
#Preview("LegalComplianceView") {
    LegalComplianceView()
        .preferredColorScheme(.dark)
}
