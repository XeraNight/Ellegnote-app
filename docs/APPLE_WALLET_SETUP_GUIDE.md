# 🎟️ Apple Wallet (.pkpass) – Oficiálny Návod na Aktiváciu

Tento dokument slúži ako kompletný sprievodca aktiváciou oficiálnych kariet Apple Peňaženky (**Apple Wallet**) pre aplikáciu **Encore**, akonáhle si aktivuješ platený **Apple Developer Program** (99 $ / cca 99 € ročne na [developer.apple.com/programs/enroll](https://developer.apple.com/programs/enroll)).

---

## 📌 Základné Parametre Projektu
- **Názov aplikácie**: Encore Dance
- **Bundle ID**: `com.jakub.encore`
- **Apple Team ID**: `2MD5BS4DLM`
- **Pass Type ID**: `pass.com.jakub.encore`
- **Doména**: `https://encore-app.vercel.app`

---

## 🚀 Postup Krok za Krokom (po zakúpení Developer účtu)

### Krok 1: Registrácia Pass Type ID
1. Otvor v prehliadači: **[Apple Developer – Identifiers](https://developer.apple.com/account/resources/identifiers/list/passTypeId)**
2. Klikni na modré **`+`** (Register a new identifier).
3. Zvoľ možnosť **Pass Type IDs** a klikni na **Continue**.
4. Vyplň:
   - **Description**: `Encore Member Pass`
   - **Identifier**: `pass.com.jakub.encore`
5. Klikni na **Continue** a potom **Register**.

---

### Krok 2: Žiadosť o certifikát (CSR) na Macu
1. Na Macu otvor systémovú aplikáciu **Kľúčenka** (*Keychain Access*).
2. V hornom menu klikni na:
   **Kľúčenka** ➔ **Sprievodca certifikáciou** ➔ **Požiadať o certifikát od certifikačnej autority...** (*Request a Certificate From a Certificate Authority...*).
3. Vyplň:
   - **E-mailová adresa používateľa**: Tvoj Apple ID e-mail.
   - **Bežný názov (Common Name)**: `Encore Pass Signing`.
   - **Požiadavka je**: Zaklikni **Uložené na disk** (*Saved to disk*).
4. Klikni na **Pokračovať** a ulož súbor na **Plochu** ako `CertificateSigningRequest.certSigningRequest`.

---

### Krok 3: Vygenerovanie a stiahnutie certifikátu
1. Otvor: **[Apple Developer – Certificates](https://developer.apple.com/account/resources/certificates/add)**
2. V sekcii *Services* zvoľ **Pass Type ID Certificate** a klikni na **Continue**.
3. V rozbaľovacom zozname vyber: `pass.com.jakub.encore`.
4. Nahraj súbor `CertificateSigningRequest.certSigningRequest` z Plochy a klikni na **Continue**.
5. Klikni na **Download** – stiahne sa súbor **`pass.cer`**.

---

### Krok 4: Export do `pass.p12` z Kľúčenky
1. Dvakrát klikni na stiahnutý súbor **`pass.cer`** – automaticky sa pridá do Kľúčenky.
2. V Kľúčenke v ľavom paneli zvoľ **Moje certifikáty** (*My Certificates*).
3. Nájdi položku **`Pass Type ID: pass.com.jakub.encore`**.
4. Klikni na ňu pravým tlačidlom mysle (alebo dvoma prstami na touchpade) a vyber **Exportovať „Pass Type ID: pass.com.jakub.encore“...**.
5. Ulož súbor na **Plochu** ako **`pass.p12`** (Formát: *Výmena osobných informácií (.p12)*).
   *(Heslo môžeš nechať prázdne alebo zadať krátke heslo – zapamätaj si ho).*

---

### Krok 5: Spustenie pripraveného automatického skriptu
Otvor terminál a v koreňovom priečinku projektu spusti:

```bash
./scripts/setup-apple-pass-certs.sh ~/Desktop/pass.p12
```

Tento skript:
1. Pomocou OpenSSL rozdelí `pass.p12` na verejný certifikát a privátny kľúč.
2. Stiahne Apple WWDR G4 certifikát.
3. Všetko zakóduje do Base64 a zapíše do lokálneho `web/.env.local`.
4. Vypíše hotové hodnoty pre Vercel Dashboard.

---

### Krok 6: Vloženie premenných do Vercelu
Vo Vercel Dashboard (**Project Settings ➔ Environment Variables**) pridaj:
- `APPLE_PASS_TYPE_IDENTIFIER` = `pass.com.jakub.encore`
- `APPLE_TEAM_IDENTIFIER` = `2MD5BS4DLM`
- `APPLE_WWDR_CERT_BASE64` = *(hodnota zo skriptu)*
- `APPLE_PASS_CERT_BASE64` = *(hodnota zo skriptu)*
- `APPLE_PASS_KEY_BASE64` = *(hodnota zo skriptu)*

---

### Hotovo!
Akonáhle sú tieto premenné vo Verceli, endpoint `https://encore-app.vercel.app/api/wallet/pass` začne okamžite vracať platné `.pkpass` karty priamo do systémovej Apple Peňaženky.
