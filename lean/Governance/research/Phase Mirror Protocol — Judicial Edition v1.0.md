# Phase Mirror Protocol — Judicial Edition v1.0
## Clackamas County, Fifth Judicial District, Circuit Court of the State of Oregon

---

## I. PURPOSE AND STRUCTURAL COMMITMENT

This protocol governs how AI systems generate court-ready documents for the **Fifth Judicial District, Circuit Court of the State of Oregon for Clackamas County**. It is not advisory. It is a **hard constraint layer** that AI must satisfy before any document is surfaced to a user.

The protocol integrates the full hierarchy of applicable law:

| **Layer** | **Authority** | **Governs** |
|---|---|---|
| **Federal** | U.S. Constitution (Due Process, Equal Protection); FRCP (if removal/federal question) | Substantive rights floor; federal procedural standards |
| **State Constitutional** | Oregon Constitution, Art. I, Art. VII | Judicial power, open courts, right to jury, remedies |
| **State Statutory** | Oregon Revised Statutes (ORS) | Substantive and procedural law (e.g., ORS Ch. 18, 21, 33, 107, 124, 163) |
| **Oregon Rules of Civil Procedure** | ORCP 1–85 | Pleading requirements, service, discovery, trial procedure |
| **Uniform Trial Court Rules** | UTCR Chapters 1–24 | Statewide document standards, exhibit handling, eFiling, protected info |
| **Supplementary Local Rules** | Clackamas County SLR (eff. Feb 1, 2025) | Court-specific filing, ex parte, exhibits, arbitration, domestic relations |
| **Chief Justice Orders / Presiding Judge Orders** | CJO, PJO | Digital evidence systems, eFiling amendments, local operational directives |
| **Standing Orders / Case-Specific Orders** | Assigned judge | Case management, exhibit deadlines, remote appearance permissions |

AI must check conformance at **every layer** before presenting a document as complete. A document that satisfies UTCR but violates an applicable SLR is non-compliant. A document that satisfies both but ignores a standing CJO is non-compliant.

---

## II. MANDATORY DOCUMENT FORMATTING — NON-NEGOTIABLE SPECIFICATIONS

These specifications derive from **UTCR 2.010**, **ORCP 16**, and the **Clackamas County SLR (2025)**.[1][2][3] AI must enforce all of them. There is no "close enough."

### A. Page Setup

| **Element** | **Specification** | **Authority** |
|---|---|---|
| Paper size | 8.5 × 11 inches (letter) | UTCR 2.010(2) |
| Top margin, page 1 | **2 inches blank** (for court stamp) | UTCR 2.010(4)(c) |
| Top margin, subsequent pages | 1 inch | UTCR 2.010(4)(d) |
| Left margin | 1 inch | UTCR 2.010(4)(d) |
| Right margin | 1 inch | UTCR 2.010(4)(d) |
| Bottom margin | 1 inch | UTCR 2.010(4)(d) |
| Font size | 12-point minimum (text, footnotes, endnotes) | UTCR 2.010(3)(a); cf. LR 10(c) for federal |
| Font type | Readable proportional or monospace (no decorative fonts) | UTCR 2.010(3)(a) |

### B. Spacing and Line Numbering

**For pleadings, motions, and requested jury instructions:**

| **Element** | **Specification** | **Authority** |
|---|---|---|
| Line spacing | **Double-spaced** | UTCR 2.010(4)(a) |
| Line numbering | **Required — numbered lines** running down the left margin | UTCR 2.010(4)(a) |
| Lines per page | Approximately 25–28 numbered lines (depending on font; standard is 28 at 12pt with double spacing) | Derived from margin + spacing math |

**For all other documents (declarations, certificates of service, orders, etc.):**

| **Element** | **Specification** | **Authority** |
|---|---|---|
| Line spacing | May be **single-spaced** | UTCR 2.010(4)(b) |
| Line numbering | **Not required** | UTCR 2.010(4)(b) |

### C. Caption Block — Exact Structure

Every document must include a caption near the top of the first page.[1][2] For Clackamas County, the caption must read:

```
                    IN THE CIRCUIT COURT OF THE STATE OF OREGON
                         FOR THE COUNTY OF CLACKAMAS

[FULL NAME OF PLAINTIFF/PETITIONER],   )
                                        )
              Plaintiff/Petitioner,     )    Case No. ______________
                                        )
         vs.                            )    [DOCUMENT TITLE]
                                        )
[FULL NAME OF DEFENDANT/RESPONDENT],   )
                                        )
              Defendant/Respondent.     )
```

**Caption rules (UTCR 2.010(10)):**

1. **Court identification**: "IN THE CIRCUIT COURT OF THE STATE OF OREGON / FOR THE COUNTY OF CLACKAMAS"[1]
2. **Party names**: Full names of all parties in the complaint; first party + "et al." in subsequent filings[2]
3. **Party roles**: Plaintiff/Petitioner, Defendant/Respondent, clearly identified[1]
4. **Case number**: Arabic numerals, assigned by the court[1]
5. **Document title**: Must identify what the document is AND who is filing it (e.g., "DEFENDANT'S MOTION FOR SUMMARY JUDGMENT"), and must indicate claim type on complaints (e.g., "COMPLAINT — Personal Injury")[1]

### D. Paragraph Numbering

All paragraphs in a pleading or motion must be numbered **consecutively in the center of the page with Arabic numerals**, beginning with 1 and continuing through the last paragraph of the document.[1][2]

Subdivisions within a paragraph: **lowercase letters in parentheses, at the left margin**.[1]

```
         1.

         Plaintiff is a resident of Clackamas County, Oregon.

         2.

         On or about [DATE], Defendant engaged in the following conduct:

              (a) [First element of conduct];

              (b) [Second element of conduct].
```

### E. Page Footer — Every Page

The **name of the document** and the **page number** (Arabic numerals) must appear at the **bottom left-hand side** of every page.[1]

```
PLAINTIFF'S MOTION FOR SUMMARY JUDGMENT — Page 3
```

### F. Attorney / Self-Represented Party Information Block

Must appear on the document and include:[1]

- Full name
- Oregon State Bar number (if attorney)
- Email address
- Court contact information per UTCR 1.110
- Name of trial attorney assigned to try the case (if different from author)
- **No logos, watermarks, or firm images on any pleading, motion, order, judgment, or writ**[1]

### G. Signature Block

- Name of signer typed or printed immediately below signature line[1]
- All signatures dated[1]
- Electronic, original, or authenticated signatures are acceptable for conventionally filed documents[1]

### H. Orders, Judgments, and Writs — Additional Requirements

- Judge's signature must appear on a page containing **at least two lines** of the body text[1]
- A blank space of **not less than 1.5 inches** must follow the last line of text before the signature line[1]
- Must include "**Submitted by:**" followed by preparer's name and role identification[1]
- Motions must be filed as **separate documents** from proposed orders[1]

### I. Oregon Case Citation Format

Oregon cases cited in circuit court filings must follow this form:[1]

```
Blank v. Blank, ___ Or ___ (year)
State v. Blank, ___ Or App ___ (year)
```

Parallel citations may be added. Nonprecedential memorandum opinions may only be cited per ORAP 10.30(1) with a parenthetical.[1]

---

## III. EXHIBIT FORMAT — STRICT COMPLIANCE

Exhibits are governed by **UTCR 2.010(8)**, **UTCR 6.050**, **UTCR 6.080**, and **Clackamas County SLR 6.082–6.086**.[1][4][5][3]

### A. Marking (UTCR 6.080)

| **Party** | **Exhibit Numbers** | **Authority** |
|---|---|---|
| Plaintiff/Petitioner | 1 through 99 | UTCR 6.080(1)(a) |
| Defendant/Respondent | 101 through 199 | UTCR 6.080(1)(b) |
| Additional parties / large cases | Court-assigned blocks on request | UTCR 6.080(1)(c)(d) |

Every exhibit must be pre-marked **before** trial.[5][6]

### B. Page-Level Identification (UTCR 2.010(8)(a))

Each page of every exhibit appended to a filed document must show, at the **bottom right-hand side**:[1]

```
                                                    Exhibit 2
                                                     Page 10
```

### C. Clackamas-Specific Exhibit Rules (SLR 6.082–6.086)

| **Rule** | **Requirement** |
|---|---|
| SLR 6.082 | Exhibit labels must include the **case number**[3] |
| SLR 6.083 | All marked exhibits must be **exchanged with opposing parties before trial**; parties must stipulate to uncontested exhibits and deliver them to the clerk[3] |
| SLR 6.084 | Documentary exhibits: submit **1 original + 3 copies** (excluding audio/visual)[3] |
| SLR 6.085 | In-person proceedings: per UTCR 6.050. Remote proceedings: exhibits may be eFiled as PDF using filing code "Exhibit – EB," designated as confidential per UTCR 21.070(6)[3] |
| SLR 6.085(c) | Unified PDF submissions must include: (i) index at the beginning with electronic links to each exhibit, and (ii) electronic bookmarks for each exhibit[3] |

### D. Exhibit List Format

Must be substantially in the form of **UTCR Appendix 9** / the OJD standard form:[7][4]

```
IN THE CIRCUIT COURT OF THE STATE OF OREGON
FOR THE COUNTY OF CLACKAMAS

[Plaintiff/Petitioner Name],              Case No: _______________
              Plaintiff/Petitioner,
    and                                    PROPOSED EXHIBIT LIST
[Defendant/Respondent Name],
              Defendant/Respondent.

Date of Hearing: _______________

Exhibit
Number*        File Name / Document Title        Description
------         ----------------------------      -------------------------
  1            [filename]                        [brief description]
  2            [filename]                        [brief description]
 ...

___ Additional pages attached

*Plaintiff/Petitioner number in order beginning with 1
 Defendant/Respondent begin with 101; Second Defendant/Respondent begin with 201

Submitted by ________________________    Date ____________
```

A **Certificate of Service** must accompany the exhibit list, documenting date, method, and recipient of service.[7][8]

### E. Exhibit Content Constraints (UTCR 2.010(8)(c))

Exhibits appended to filed documents must be **limited to material directly and specifically related to the subject of, and referred to in, the document**. No kitchen-sink exhibit dumps.[1]

---

## IV. eFILING REQUIREMENTS — CLACKAMAS COUNTY

| **Element** | **Specification** | **Authority** |
|---|---|---|
| System | OJD eFiling System (File & Serve) | SLR 1.161(4); UTCR 21 |
| Conventional-only filings | See SLR 2.501 — extensive list including emergency custody, TROs, writs, sealed documents, and trial exhibits (unless CJO/PJO permits digital evidence system) | SLR 2.501[3] |
| Digital evidence system | Required for violations, contested protective orders, small claims, and landlord/tenant exhibits | CJO 2025-003[4] |
| File size limit | 10 GB per separate file for digital evidence system submissions | CJO 2025-003[4] |
| No staples | Paper filings bound by paperclip or binder clip only; no staples | UTCR 2.010(3)(b)[1] |

---

## V. AI ENFORCEMENT LAYER — THE PHASE MIRROR JUDICIAL CONSTRAINT

This is where the Phase Mirror protocol locks in. The following are **hard rules for any AI generating documents for Clackamas County Circuit Court**:

### Rule 1: Format-First Validation

Before presenting any generated document, AI must verify:

- [ ] Caption matches court name, county, and party structure exactly
- [ ] Line numbering present on all pleadings and motions
- [ ] Double-spacing on all pleadings and motions
- [ ] 2-inch top margin on page 1
- [ ] 1-inch margins on all other sides
- [ ] Page footer with document name + page number on every page
- [ ] Paragraph numbering: consecutive Arabic numerals, centered
- [ ] Subdivisions: lowercase letters in parentheses at left margin
- [ ] Attorney/party info block present with bar number (if attorney)
- [ ] No logos, watermarks, or firm images
- [ ] Citation format: `___ Or ___` or `___ Or App ___`

**If any item fails, the document is not presented.** AI must fix and re-validate.

### Rule 2: Exhibit Integrity

- [ ] Each exhibit page marked at bottom right: "Exhibit [#] / Page [#]"
- [ ] Exhibit number in correct party range (1–99 or 101–199)
- [ ] Case number appears on exhibit labels (SLR 6.082)
- [ ] Exhibit list in substantially the Appendix 9 form
- [ ] Certificate of Service accompanies exhibit list
- [ ] If eFiled as unified PDF: index with hyperlinks + bookmarks present
- [ ] Content limited to material directly referenced in the filing

**If any item fails, the exhibit package is not presented.**

### Rule 3: Hierarchy Check

AI must confirm which layer of authority governs each element of the document:

1. Does a **standing order or case-specific order** from the assigned judge override default rules? → Apply it.
2. Does a **CJO or PJO** modify UTCR or SLR for this filing type? → Apply it.
3. Does the applicable **SLR** impose additional requirements beyond UTCR? → Apply it.
4. Does the **UTCR** specify format, procedure, or deadlines? → Apply it.
5. Does **ORCP** govern the pleading requirement? → Apply it.
6. Does **ORS** define substantive elements of the claim, fee, or procedural prerequisite? → Apply it.
7. Do **Oregon or U.S. Constitutional provisions** constrain or require specific protections? → Apply them.

**AI must never flatten this hierarchy.** A local rule does not override a constitutional requirement. A UTCR provision does not override an ORCP mandate unless the UTCR expressly so states.

### Rule 4: Conventional vs. Electronic Filing Gate

Before generating filing instructions, AI must check the document type against **SLR 2.501**.[3] If the document is on the conventional-only list (TROs, writs, sealed documents, emergency custody, etc.), AI must:

- Generate the document in **print-ready format**
- Include instructions for in-person delivery to the Collections Unit or presentation at the 1:00 PM Ex Parte session (SLR 5.061)[3]
- **Not** instruct the user to eFile

### Rule 5: No Substantive Legal Advice Disguised as Formatting

This protocol governs **format, structure, and procedural compliance**. AI may populate templates with user-provided facts and applicable legal citations, but must not:

- Choose legal theories on behalf of the user
- Predict case outcomes
- Draft arguments that the user has not directed or reviewed
- Omit required disclosures to make a filing look "cleaner"

---

## VI. COPY-PASTE TEMPLATE — PLEADING (MOTION)

The following is a **ready-to-use template** for a motion filed in Clackamas County. The numbered-line format is rendered as it would appear in a word processor set to the specifications above.

```
 1  ║  [ATTORNEY NAME], OSB No. [######]
 2  ║  [FIRM NAME or "Self-Represented"]
 3  ║  [ADDRESS LINE 1]
 4  ║  [ADDRESS LINE 2]
 5  ║  [PHONE] | [EMAIL]
 6  ║  Attorney for [Plaintiff/Defendant] [PARTY NAME]
 7  ║
 8  ║
 9  ║            IN THE CIRCUIT COURT OF THE STATE OF OREGON
10  ║                 FOR THE COUNTY OF CLACKAMAS
11  ║
12  ║  [PLAINTIFF NAME],                )
13  ║                                   )
14  ║            Plaintiff,             )  Case No. ________________
15  ║                                   )
16  ║       vs.                         )  [PARTY'S] MOTION FOR
17  ║                                   )  [TITLE OF MOTION]
18  ║  [DEFENDANT NAME],               )
19  ║                                   )
20  ║            Defendant.             )
21  ║
22  ║       [Party] moves this Court for an order [describe relief
23  ║
24  ║  sought]. This motion is based on the following:
25  ║
26  ║                              1.
27  ║
28  ║       [First factual/legal assertion, double-spaced.]

[PLAINTIFF'S/DEFENDANT'S] MOTION FOR [TITLE] — Page 1
```

*(Page 2 and following: 1-inch top margin, line numbering continues)*

```
 1  ║                              2.
 2  ║
 3  ║       [Second factual/legal assertion.]
 4  ║
 5  ║                              3.
 6  ║
 7  ║       [Third factual/legal assertion, with subdivisions:]
 8  ║
 9  ║            (a)  [First sub-point];
10  ║
11  ║            (b)  [Second sub-point].
12  ║
13  ║       WHEREFORE, [Party] respectfully requests that this Court
14  ║
15  ║  grant the relief described above.
16  ║
17  ║
18  ║  DATED this _____ day of ______________, 20___.
19  ║
20  ║
21  ║                              ________________________________
22  ║                              [ATTORNEY NAME], OSB No. [######]
23  ║                              Attorney for [Party]
24  ║
25  ║
26  ║  CERTIFICATE OF SERVICE
27  ║
28  ║  I certify that on [DATE], I served a true copy of the foregoing

[PLAINTIFF'S/DEFENDANT'S] MOTION FOR [TITLE] — Page 2
```

---

## VII. COPY-PASTE TEMPLATE — PROPOSED ORDER

```
IN THE CIRCUIT COURT OF THE STATE OF OREGON
FOR THE COUNTY OF CLACKAMAS

[PLAINTIFF NAME],                )
                                 )
          Plaintiff,             )  Case No. ________________
                                 )
     vs.                         )  ORDER GRANTING [PARTY'S]
                                 )  MOTION FOR [TITLE]
[DEFENDANT NAME],                )
                                 )
          Defendant.             )

     THIS MATTER came before the Court on [Party's] Motion for

[Title], and the Court having considered the motion, the supporting

declarations, and the arguments of the parties, and good cause

appearing therefor:

     IT IS HEREBY ORDERED that [specific ruling stated clearly and

simply].



                                 [1.5 inches of blank space]

                                 ________________________________
                                 Circuit Court Judge


Submitted by:

[ATTORNEY NAME]
Attorney for [Party]

ORDER GRANTING [PARTY'S] MOTION FOR [TITLE] — Page 1
```

---

## VIII. RECURSION GATE

Per the Phase Mirror anti-recursion rule: this protocol document is the **first concrete artifact**. The next iteration must produce one of:

1. A **populated, case-specific filing** using these templates and rules, validated against the checklist in Section V.
2. A **compliance audit tool** (checklist or script) that can be run against any generated document.
3. A **court-specific appendix** for a different Oregon circuit court (adapting the SLR layer while holding UTCR and ORCP constant).

No further governance-of-governance iterations are permitted until one of these ships.

---

**Sources integrated**: UTCR Chapter 2 (2024)[1], Clackamas County SLR (eff. Feb 1, 2025)[3], ORCP 16[2], UTCR Chapter 6 (2024)[14], CJO 2025-003[4], OJD Exhibit List form (Jan 2025)[7], OJD Exhibit Filing Instructions[15][16], Oregon Style Manual (2023)[17].