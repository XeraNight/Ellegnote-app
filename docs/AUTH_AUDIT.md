# Encore: audit registrácie, prihlásenia a účtu (iOS + Supabase)

> Dátum auditu: 5. 10. 2026. Rozsah: `AuthManager`, `AuthSheetView`, `PasswordSheets`, `EncoreApp` (deep linky), `SubscriptionManager` (ban), `UserProfileStore`, `KeychainHelper`, edge funkcia `send-email`, produkčná databáza Supabase (projekt `iukblwlttvrcdclmlyxu`: tabuľky, RLS, triggery, funkcie, FK, advisory).
> Čo nebolo možné overiť: nastavenia v Supabase Dashboarde (Authentication → Providers, SMTP, rate limity, potvrdzovanie e-mailov, CAPTCHA, Site URL). Tie cez nástroje nevidím, treba ich skontrolovať ručne (sekcia „Dashboard kontrola“).
> Zoznam všetkých situácií je v `MOZNE_CHYBY.md` (kategória VII).

## Stav po opravách (6. 10. 2026)

| Vrstva | Stav |
|---|---|
| Kód v appke | Hotový, build prechádza, 11 jednotkových testov prešlo (`EncoreTests`: pravidlá hesla, kontrola e-mailu, preklad chýb). |
| SQL migrácia `20261006_auth_account_lifecycle.sql` | Napísaná, **nespustená** (živú databázu som nemohol overiť, pripojenie cez nástroj vypadlo). |
| `20261006_enable_email_confirmation.sql` | Napísaná, **nespúšťať**, kým nie je hotový Dashboard a SMTP. |
| Edge funkcie `delete-account`, `send-email` | Napísané a typovo skontrolované (`deno check`), **nenasadené**. |
| Dashboard (potvrdenie e-mailu, SMTP, šablóny, heslo 8+, OTP 10 min, Site URL) | **Nie je urobené**, robí ho majiteľ projektu. |
| Overené v simulátore | Nové prihlasovacie obrazovky, kód z e-mailu, zmazanie účtu a ban **neboli otestované naživo**. |

Skóre: **živý systém teraz ~4/10** (appka lepšia, server rovnaký), **po nasadení všetkého ~8/10**. Do 10/10 chýba: Apple Developer účet (Sign in with Apple, odvolanie Apple tokenu pri zmazaní), CAPTCHA, plán Pro (kontrola uniknutých hesiel), vlastný SMTP s overenou doménou, 2FA alebo passkeys, test na reálnom iPhone podľa celej matice v `MOZNE_CHYBY.md`.

Poradie nasadenia: 1) `20261005_hardening_function_grants.sql`, 2) `20261006_auth_account_lifecycle.sql`, 3) nasadiť `delete-account`, 4) Dashboard (SMTP, šablóny s `{{ .Token }}`, Confirm email ON, heslo 8+), 5) až potom `20261006_enable_email_confirmation.sql`, 6) otestovať maticu.

## Celkové skóre: 3 / 10

Na verejný launch to **nie je pripravené**. Základný scenár (e-mail + heslo, obnova relácie, Face ID nad existujúcou reláciou) funguje a je pomerne dobre ošetrený. Zlyháva všetko okolo: životný cyklus účtu (zmazanie nefunguje), bezpečnosť registrácie (žiadne overenie e-mailu), oddelenie dát medzi účtami na jednom zariadení a vynucovanie banov.

| Oblasť | Skóre | Prečo |
|---|---|---|
| Základný tok (prihlásenie, registrácia, obnova relácie) | 6/10 | Relácia žije v Keychain cez SDK (PKCE, rotácia refresh tokenov), pri chybe siete sa nikdy neodhlási, Apple nonce je správne. Chýba Return-kľúč, zobrazenie hesla a odolné spracovanie chýb. |
| Bezpečnosť účtu | 3/10 | Auto-potvrdenie všetkých e-mailov, heslo min. 6 znakov, vypnutá kontrola uniknutých hesiel, žiadna CAPTCHA, ban iba v UI. |
| Životný cyklus účtu (odhlásenie, zmena účtu, zmazanie) | 1/10 | **`delete_user_account` v databáze neexistuje**, lokálne dáta sa pri odhlásení nemažú, ostatné zariadenia sa nikdy neodhlásia. |
| Spracovanie chýb a lokalizácia | 4/10 | Chyby sa rozpoznávajú podľa anglických textov, na slovenskom iPhone zlyháva rozpoznanie sieťových chýb. |
| UX voči veľkým aplikáciám | 4/10 | Chýba zobrazenie hesla, Return-kľúč, „poslať potvrdenie znova“, pokročilá obnova, jasné stavy. |
| Databázová strana (RLS, funkcie) | 6/10 | RLS zapnuté všade, dobrý `is_app_owner`, chránené citlivé stĺpce. Ale zmazanie, ban, voľne upraviteľné `dancer_code`/`invite_code` a nenasadená, no nebezpečná `send-email`. |
| Odolnosť voči zneužitiu (rate limit, boti, spam) | 2/10 | Žiadna CAPTCHA, nič nebráni masovým registráciám. |

## Porovnanie s tým, čo je štandard

Porovnané s požiadavkami App Review (4.8, 5.1.1(v), 5.1.1(i)), odporúčaniami Supabase pre produkciu a OWASP MASVS (autentifikácia, session). Konkrétne aplikácie neopisujem, len bežnú prax veľkých aplikácií.

| Čo je bežné u veľkých aplikácií | Encore |
|---|---|
| Overenie e-mailu pred plným účtom | ❌ Trigger `on_auth_user_created_auto_confirm` potvrdí všetko automaticky. |
| Zmazanie účtu v aplikácii, ktoré naozaj zmaže dáta (povinné pre App Store) | ❌ Funkcia v DB neexistuje. Appka potichu zlyhá a tvári sa, že účet je zmazaný. |
| Odvolanie tokenu Sign in with Apple pri zmazaní | ➖ Chýba. |
| Čistý stav po odhlásení (žiadne cudzie dáta na zariadení) | ❌ SwiftData a médiá ostávajú. |
| Zobraziť / skryť heslo, Return posúva pole a odosiela | ➖ Chýba. |
| Heslo min. 8 znakov, kontrola uniknutých hesiel | ❌ 6 znakov, kontrola vypnutá. |
| Ochrana proti botom (CAPTCHA / App Attest) | ➖ Chýba. |
| Odhlásenie ostatných zariadení po zmene hesla | ❌ Nerobí sa. |
| Banovanie účtu na serveri | ❌ Len stav v UI, JWT ostáva platný. |
| Vlastný SMTP (doručiteľnosť, SPF/DKIM) | ❓ Neoverené, pripravená je Resend funkcia. |
| Kontrola veku / súhlas rodiča (pri mladých používateľoch) | ➖ Chýba (tanečníci sú často mladší ako 16). |
| Passkeys / 2FA | ➖ Voliteľné, až po launchu. |

## Blokery pred akýmkoľvek launchom (P0)

1. **Zmazanie účtu nefunguje.** `AuthManager.deleteAccount` volá RPC `delete_user_account`, ktorá v databáze nie je. Chyba sa len zaloguje, appka sa odhlási a účet zostane. Pri tom mazaní by navyše zlyhala FK `routines.user_id` (NO ACTION), a tiež `user_entitlements.granted_by` a `connections.initiated_by`. Videá v úložisku (`encore-media/{user_id}/…`) by ostali. Porušuje App Store 5.1.1(v) a GDPR čl. 17. **Oprava:** edge funkcia so service rolou (zmaže storage, dáta, auth používateľa, odvolá Apple token), FK na CASCADE alebo explicitné mazanie, appka nesmie tvrdiť „zmazané“, kým server nepotvrdí.
2. **Žiadne overenie e-mailu + prepojenie účtov = pre-hijacking.** Útočník zaregistruje cudzí e-mail (automaticky potvrdený), obeť sa neskôr prihlási cez Google/Apple s tým istým e-mailom, identity sa spoja a útočník pozná heslo. **Oprava:** vypnúť auto-confirm trigger a zapnúť potvrdzovanie e-mailov (po zapnutí SMTP), aspoň pred verejným launchom.
3. **Cudzie dáta po zmene účtu na jednom zariadení.** Pri odhlásení sa nemaže SwiftData ani lokálne médiá. Ďalší používateľ vidí zostavy a poznámky predchádzajúceho a pri úprave ich nahrá pod svojím účtom. **Oprava:** viazať lokálne dáta na `user_id` a pri zmene účtu ich vymazať alebo odpojiť.
4. **Ban je len kozmetika.** Kontrola stavu beží v appke, pri chybe siete zlyhá „otvorene“ a RLS stav neberie do úvahy. **Oprava:** `banned_until` na `auth.users` cez admin API (edge funkcia) + kontrola v RLS.
5. **Edge funkcia `send-email` (zatiaľ nenasadená) je spamový reléový server.** Prihlásený používateľ môže poslať ľubovoľný HTML e-mail komukoľvek z tvojej domény; `partnerName` a `customMessage` sú vložené do HTML bez escapovania; bez limitu. **Nenasadzovať**, kým nebude: povolený len typ pozvánky, adresát zo zoznamu partnerov, escapovanie, limit na používateľa.

## Vysoká priorita (P1)

- Heslo min. 8 znakov (klient aj server), zapnúť kontrolu uniknutých hesiel (Dashboard, môže vyžadovať plán Pro).
- CAPTCHA (Turnstile) alebo App Attest na registráciu, rate limity v Dashboarde.
- Spracovanie chýb podľa `AuthError.errorCode` a `URLError.code`, nie podľa anglických textov (na slovenskom iPhone je `localizedDescription` po slovensky a rozpoznanie zlyhá).
- Po zmene alebo obnove hesla odhlásiť ostatné zariadenia (`signOut(scope: .others)`).
- Po preinštalovaní appky Keychain prežije, takže používateľ ostane prihlásený bez dát. Pri prvom štarte po inštalácii (príznak v UserDefaults) odhlásiť.
- Obnova hesla: odkaz otvorený na inom zariadení (PKCE) vyhlási nezrozumiteľnú chybu; heuristika `isRecoveryLink` (hodina od žiadosti) zamení potvrdzovací odkaz za obnovu.
- Google: prezentácia z root kontroléra nefunguje, keď je prihlásenie otvorené ako sheet; záložný tok cez Safari vráti úspech bez prihlásenia.
- Veková brána / súhlas rodiča a zápis do privacy manifestu (overiť obsah `PrivacyInfo.xcprivacy`).
- Zrušiť zbytočné opakované volania pri každom návrate do appky (`applySession` spúšťa 4+ požiadavky).

## Stredná a nízka (P2)

Zobrazenie hesla, Return-kľúč a `submitLabel`, „poslať potvrdenie znova“, zmena e-mailu v appke, odpojenie od profilu pri chybe sieťového zápisu pri registrácii, validácia dĺžky mena, uzamknutie stĺpcov `profiles` (`dancer_code`, `invite_code`, `email`), duplicitný unikátny index `invite_code`, Google nonce, `canUseBiometricLogin` počíta Keychain v tele pohľadu, Dynamic Type a VoiceOver na prihlasovacej obrazovke, skryť tlačidlo Apple, kým nie je Developer účet.

## Dashboard kontrola (musíš skontrolovať ručne)

Authentication → URL Configuration: Site URL nesmie byť `127.0.0.1`, v Redirect URLs musí byť `encore://auth-callback`. Providers → Email: Confirm email, minimálna dĺžka hesla, Leaked password protection. SMTP: vlastný (Resend), inak je limit vstavaného odosielania veľmi nízky. Rate Limits: e-maily, prihlásenia. Attack Protection: CAPTCHA. Google provider: Client ID zhodný s `GIDClientID` v `Info.plist`. Apple provider: až po Developer účte.

## Poradie opráv (na zajtra)

1. **Databáza (SQL najprv ukázať):** `delete_user_account` + FK + storage, `banned_until`, uzamknutie `profiles`, duplicitný index, vyčistenie `invite_tokens`. Spustiť `20261005_hardening_function_grants.sql`.
2. **Appka:** oprava zmazania účtu (volanie edge funkcie, čakanie na server, čistenie lokálnych dát), čistenie pri zmene účtu a preinštalovaní, spracovanie chýb podľa kódov, odhlásenie ostatných zariadení.
3. **Registrácia:** heslo 8+, CAPTCHA, zapnutie potvrdzovania e-mailu a odstránenie auto-confirm triggera (po SMTP).
4. **UX:** zobrazenie hesla, Return-kľúč, resend, jasné hlášky.
5. **Testovacia matica:** prejsť všetky riadky v `MOZNE_CHYBY.md` kategória VII a zapísať výsledok (✅/❌) pri každom.
