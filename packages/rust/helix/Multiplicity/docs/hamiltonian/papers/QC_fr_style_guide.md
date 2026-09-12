**[FACT] [VELOCITY=PROCEED] [AUTHORITY=CUSTODIAN] [FORM=RECOMMEND]**

### **Quebec French Legal-Technical Style Guidelines for RFC 0001 v4**
*(Formal, durable, and enforcement-compliant)*

---

## **1. Core Principles**
### **1.1 Register**
- **Formal Canadian French (Quebec)**:
  - Use **standardized legal-technical terminology** (e.g., *Office québécois de la langue française* [OQLF] and *Commission d’accès à l’information* [CAI] references).
  - Avoid slang, colloquialisms, or European French terms (e.g., "courriel" instead of "e-mail", "magasinage" instead of "shopping").
  - Maintain **consistency** with Quebec government and legal documents (e.g., *Loi 25*, *Code civil du Québec*).

- **Plain Language**:
  - Prefer **clear, concise phrasing** (e.g., "Le système doit valider les entrées" instead of "Il est impératif que le système procède à la validation des entrées").
  - Use **active voice** (e.g., "Le dépositaire ratifie la commande" instead of "La commande est ratifiée par le dépositaire").

### **1.2 Terminology Durability**
- **Avoid Ephemeral Terms**:
  - Use **time-tested terminology** (e.g., "traitement" for "processing", "données" for "data").
  - Avoid trendy or overly technical jargon (e.g., "blockchain" → "chaîne de blocs" is acceptable, but prefer "registre immuable" for broader understanding).

- **Quebec-Specific Terms**:
  - Use **authentic Quebec French terms** where they exist (e.g., "pourriel" for "spam", "clavardage" for "chat").
  - For IT/legal terms without direct Quebec French equivalents, use **OQLF-approved borrowings** (e.g., "logiciel" for "software", "nuage" for "cloud").

---

## **2. Enforcement Semantics: Canonical English Preservation**
### **2.1 When to Preserve English**
**Preserve English terms in the following contexts**:
1. **Metadata and Code**:
   - JSON/YAML keys, API parameters, and enforcement logic must remain in English to ensure **interoperability and canonical enforcement**.
   - Example:
     ```json
     {
       "form_en": "EXECUTE",  // Canonical enforcement term
       "form_fr": "EXÉCUTER"  // Localized display term
     }
     ```

2. **Technical Specifications**:
   - Terms that are **universally recognized in IT/legal contexts** and lack standardized French equivalents (e.g., "SHA256", "API", "GICD").
   - Example:
     > "Le système génère un reçu SHA256 ancré dans la chaîne de blocs Bitcoin."

3. **Enforcement Logic**:
   - **Velocity signals** (`PROCEED`, `PAUSE`, `ESCALATE`, `STOP`) and **form types** (`FACT`, `HYPOTHESIS`, `EXECUTE`) must remain in English to ensure **consistent ratification logic**.
   - Example:
     > "La vitesse `ESCALATE` suspend l’exécution et transfère le contrôle à une autorité supérieure (`CUSTODIAN`)."

4. **Acronyms**:
   - Preserve acronyms in their original form (e.g., "ITAR", "CPCSC", "GICD") but provide a **French expansion on first use**.
   - Example:
     > "Conformément aux exigences du *Controlled Goods Program* (CGP, Programme des marchandises contrôlées)..."

---

### **2.2 When to Translate to French**
**Translate to French in the following contexts**:
1. **User-Facing Content**:
   - All **documentation, error messages, and UI elements** must be in Quebec French.
   - Example:
     > "Erreur : La commande `EXÉCUTER` nécessite une ratification du dépositaire."

2. **Legal/Compliance Terms**:
   - Terms with **established French equivalents** in Quebec law (e.g., "consentement" for "consent", "renseignements personnels" for "personal information").
   - Example:
     > "Conformément à la *Loi 25*, les renseignements personnels doivent être protégés."

3. **Governance and Policy**:
   - **Authority roles** (`CUSTODIAN` → `DÉPOSITAIRE`, `POLICY` → `POLITIQUE`) and **high-level concepts** must be translated for clarity.
   - Example:
     > "Le dépositaire (`CUSTODIAN`) est responsable de la ratification des commandes `EXÉCUTER`."

4. **Natural Language Utterances**:
   - User inputs (e.g., chat messages, voice commands) should be processed in the user’s language, but **enforcement metadata must remain in English**.
   - Example:
     > **User Input (French)**: "Transférer les données techniques à [REDACTED]."
     > **Metadata**:
     > ```json
     > {
     >   "utterance": "Transférer les données techniques à [REDACTED].",
     >   "form_en": "EXECUTE",
     >   "form_fr": "EXÉCUTER",
     >   "velocity_en": "ESCALATE"
     > }
     > ```

---

## **3. Specific Terminology Guidelines**
### **3.1 Enforcement and Governance Terms**
| English Term       | Quebec French Term       | Notes                                  | Enforcement Context          |
|--------------------|--------------------------|----------------------------------------|------------------------------|
| **Form**           | **Forme**                |                                        | Translate in docs, preserve in code. |
| **Velocity**       | **Vitesse**              |                                        | Translate in docs, preserve in code. |
| **Authority**      | **Autorité**             |                                        | Translate in docs, preserve in code. |
| **FACT**           | **FAIT**                 |                                        | Preserve in enforcement logic. |
| **HYPOTHESIS**     | **HYPOTHÈSE**            |                                        | Preserve in enforcement logic. |
| **ASSUMPTION**     | **HYPOTHÈSE DE TRAVAIL** | Avoid "présomption" (legal ambiguity). | Preserve in enforcement logic. |
| **QUESTION**       | **QUESTION**             |                                        | Preserve in enforcement logic. |
| **RECOMMEND**      | **RECOMMANDATION**       |                                        | Preserve in enforcement logic. |
| **EXECUTE**        | **EXÉCUTER**             |                                        | Preserve in enforcement logic. |
| **PROCEED**        | **PROCÉDER**             |                                        | Preserve in enforcement logic. |
| **PAUSE**          | **PAUSE**                | Tech-friendly term.                    | Preserve in enforcement logic. |
| **ESCALATE**       | **ESCALADER**            |                                        | Preserve in enforcement logic. |
| **STOP**           | **ARRÊT**                |                                        | Preserve in enforcement logic. |
| **CUSTODIAN**      | **DÉPOSITAIRE**          | Aligns with *Loi 25*.                  | Translate in docs, preserve in code. |
| **POLICY**         | **POLITIQUE**            |                                        | Translate in docs, preserve in code. |
| **ADVISORY**       | **CONSULTATIF**          |                                        | Translate in docs, preserve in code. |
| **Ratification**   | **Ratification**         |                                        | Translate in docs.            |
| **GICD Scan**      | **Analyse GICD**         | *Gouvernance, Intégrité, Coûts, Délégation* | Translate in docs, preserve acronym. |
| **Mandatory Collapse** | **Effondrement Obligatoire** |                                | Translate in docs.            |

---

### **3.2 Legal and Compliance Terms**
| English Term               | Quebec French Term               | Notes                                  |
|----------------------------|----------------------------------|----------------------------------------|
| **Personal Information**   | **Renseignements personnels**    | *Loi 25* term.                         |
| **Consent**                | **Consentement**                 |                                        |
| **Audit Trail**            | **Piste de vérification**        |                                        |
| **Data Residency**         | **Résidence des données**        |                                        |
| **Controlled Goods**       | **Marchandises contrôlées**      | *Programme des marchandises contrôlées (CGP)*. |
| **ITAR**                   | **ITAR**                         | Preserve acronym, expand on first use. |
| **CPCSC**                  | **CGP**                          | *Programme des marchandises contrôlées*. |

---

## **4. Example Translations**
### **4.1 Enforcement Logic (Preserve English)**
**Original (English)**:
```json
{
  "utterance": "Transfer controlled
