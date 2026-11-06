# Plan: self-contained explanations mapped to question codes

Prepared on 2026-09-19. This document proposes the implementation; it does not create or approve the explanation corpus.

## 1. Recommended approach

Build a **versioned, offline explanation corpus** alongside the existing question bank. Resolve citations against authoritative sources, extract the relevant provisions deterministically, and write a short Spanish explanation that applies those provisions to each question. Retain the original citation and supporting evidence separately. Use human review before publishing an explanation; an LLM may draft prose, but must not decide which legal source or historical version is authoritative.

Use **BOE structured XML first**, structured HTML second, and PDF extraction only where necessary. Extend the same pipeline with source adapters for EU legislation, international agreements, technical guides, and doctrinal material. Generate both:

- `docs/question_explanations.md`: our readable document, grouped by section and indexed by question code, containing the explanation itself.
- `packages/pm_questions_bank/assets/explanations/pm_260326.json`: a machine-readable map keyed by question code, ready for optional app integration.

Both outputs come from the same reviewed records. Neither requires the reader or application to retrieve another document to understand the explanation.

This offers the best balance for this repository: reliable source retrieval, reusable evidence across related questions, explicit handling of outdated answers, useful study explanations, and reproducible releases without runtime network or model dependencies.

## 2. What the repository actually contains

Inspection of `packages/pm_questions_bank/assets/pm_260326_json/*.json` produced:

| Section | Questions |
| --- | ---: |
| 1A | 453 |
| 1B | 542 |
| 1C | 421 |
| 1D | 341 |
| 1E | 1,118 |
| 1F | 633 |
| 1G | 662 |
| 1H | 305 |
| **Total** | **4,475** |

All 4,475 codes are unique in this snapshot. There are **1,627 distinct raw `norma` strings** and **944 questions with `doctrinalReference`**. These are inventory counts, not counts of distinct laws or automatically resolvable citations. The doctrinal count is not a complete classification of nonlegal sources.

Relevant existing components:

- [`Question`](packages/pm_questions_bank/lib/src/models/question.dart) already exposes `code`, `prompt`, `answers`, `correctOption`, `norma`, and optional `doctrinalReference`. Its JSON schema rejects additional properties.
- [`QuestionTxtParser`](packages/pm_questions_bank/lib/src/parsers/question_txt_parser.dart) preserves the source fields, including doctrinal references.
- [`compile_question_assets.dart`](packages/pm_questions_bank/tools/compile_question_assets.dart) regenerates the JSON from the package's TXT assets.
- [`QuestionBankLoader`](packages/pm_questions_bank/lib/src/loaders/question_bank_loader.dart) loads the packaged question assets; [`load_questions.dart`](pm_app/lib/src/questions/load_questions.dart) delegates to it.
- Questions also exist under root-level `pm_260326/`. The new pipeline should consume the package's compiled JSON and hash its inputs, avoiding a second independently maintained question import.

Consequently, do not put authored explanations directly into the generated question JSON or overwrite `norma`. A separate map avoids compiler overwrites and does not require changing the question schema to deliver the requested document.

The source mix matters. Examples in the actual bank include:

| Source/reference shape | Example | Required treatment |
| --- | --- | --- |
| Spanish legislation | `RD 1211/1990, art. 6` | Resolve instrument, version, article, and relevant paragraph |
| Several provisions | `Código Civil, art. 1543; Código Civil, art. 1583` | Preserve both references and assess their combined support |
| Annex/table | `RD 2822/1998, Anexo IX.2` | Preserve headings, units, categories, and exceptions |
| EU legislation | `Reglamento Comunitario (CE) 561/2006, art. 8` | EUR-Lex identity and dated Spanish text |
| Agreement | `Acuerdo ADR, 1.4.3.1.1` | Identify edition and nested provision |
| Vague instrument alias | `RD Plan General de Contabilidad., Tercera parte` | Curated alias plus a non-article selector |
| Technical guide | European cargo-securing guide | Publisher, edition, section/page, and reuse conditions |
| Doctrinal reference | Accounting and business textbooks; `INCOTERMS 2020` | Accessible evidence or independently authored, reviewed explanation |

## 3. Define “flattened” precisely

The main deliverable is a **self-contained explanation of why the answer is correct**, not just a resolved URL or an entire pasted article.

Each approved explanation should:

1. State the relevant rule or concept in Spanish.
2. Apply it to the question's facts and identify the correct answer by its meaning.
3. Include necessary conditions, exclusions, thresholds, units, and definitions.
4. Explain any cross-reference needed to understand that reasoning in place.
5. Stand on its own without phrases such as “según el artículo anterior” or “en los casos previstos en dicha ley.”

Keep citations as provenance below the explanation. “Non-referential” describes the explanatory prose; it does not mean removing traceability.

Maintain two distinct fields: `explanationEs` for our authored explanation and `evidence` for faithfully extracted source passages. A copied article can itself contain unresolved references, and its text alone may not explain the particular answer. Never edit a quotation to make it appear that the source said our interpretation.

Aim for roughly 60–150 words where useful, without imposing a minimum on simple questions or truncating complex conditions. Calculation questions need assumptions, formula, substituted values, units, and rounding. Explain distractors only when that improves understanding. Avoid “B is correct” as the whole explanation: the app supports answer shuffling.

## 4. Verified BOE feasibility and an important real conflict

The supplied [BOE page](https://www.boe.es/buscar/act.php?id=BOE-A-1990-24442#a6.) exposes Article 6 directly in HTML. Its document-level latest update is 10 June 2026; that does not mean every article changed on that date.

BOE documents endpoints for full text, an index, and individual blocks. Use the index to discover block IDs rather than deriving anchors from article numbers. [BOE API documentation](https://www.boe.es/datosabiertos/api/api.php)

```text
GET https://www.boe.es/datosabiertos/api/legislacion-consolidada/id/BOE-A-1990-24442/texto/indice
GET https://www.boe.es/datosabiertos/api/legislacion-consolidada/id/BOE-A-1990-24442/texto
GET https://www.boe.es/datosabiertos/api/legislacion-consolidada/id/BOE-A-1990-24442/texto/bloque/a6.
Accept: application/xml
```

The block request was successfully checked with `curl`. It returned `bloque id="a6."` containing two `version` elements, with publication/effectiveness dates of 1990-10-08/1990-10-28 and 2019-02-20/2019-02-21. Amendment notes are separate from the operative paragraphs. This verifies the proposed extraction route for this example, not universal coverage of all sources. [Article 6 XML](https://www.boe.es/datosabiertos/api/legislacion-consolidada/id/BOE-A-1990-24442/texto/bloque/a6.)

Eight bank questions have the exact citation `RD 1211/1990, art. 6`. They need different explanations. In particular, `1A03027` and `1A03097` select requesting a report/opinion about freight charges. That function appears in the historical wording and is absent from the current article. This is a **candidate bank/source conflict**, not proof that no other rule could support the answer. Investigate before publishing; do not quietly select an old text because it matches the key. [Historical and current Article 6](https://www.boe.es/datosabiertos/api/legislacion-consolidada/id/BOE-A-1990-24442/texto/bloque/a6.)

### Worked example: `1A03021`

The bank asks whether a transport arbitration board can decide a labor matter concerning a transport company. Its official answer is `B`, “No, no es posible.” A suitable draft explanation is:

> Las Juntas Arbitrales del Transporte no pueden resolver conflictos laborales, aunque afecten a una empresa transportista o estén relacionados con un servicio de transporte. Su competencia se refiere a determinadas controversias mercantiles sobre contratos de transporte y actividades auxiliares. Por eso, la respuesta correcta es que no pueden decidir sobre esa materia laboral.

Support: Article 6.1(a), including its express exclusion of labor disputes. This is authored explanatory prose, not a quotation or a completed editorial approval. [Supporting provision](https://www.boe.es/buscar/act.php?id=BOE-A-1990-24442#a6.)

For `1A01001`, the same article helps explain why an industrial-property rental dispute falls outside those transport-contract functions. Establishing the positive procedural route to recover rent may require additional evidence. Label additional supporting sources separately from the bank's original citation.

## 5. Date and version policy

Use a **bank-specific explanation release with an explicit legal cutoff**, and retain historical evidence where needed. Never let “latest available today” silently redefine a previously released explanation.

The folder name `pm_260326` suggests a date but does not prove the bank's publication date or legal cutoff. Phase 1 must look for publisher metadata. Until verified, record the bank date as unknown; use a declared research cutoff, initially 2026-09-19, and disclose that it is our research policy rather than the publisher's intended date.

Record separately:

- Bank identity, input hashes, and verified publication/cutoff date if available.
- Our research cutoff and retrieval timestamp.
- Instrument-level update date.
- Selected provision's publication date, effective date, version identifier, and evidence hash.
- Any applicability/transitional qualification and the review date.

For straightforward provisions, select the version effective at the chosen cutoff. Effective date alone is insufficient where delayed application, transitional arrangements, territorial scope, or special cases matter; route those cases to review. Do not infer a complete validity interval solely from the next publication date.

When the official answer and selected source disagree, preserve the official question and answer unchanged, set `answer_source_conflict`, record both sides, and investigate. A deliberately historical explanation must be explicitly labeled with its historical scope. Corrections to the question bank should be a separate reviewed change. A conflicted record must not appear as an ordinary approved explanation of current rules.

## 6. Pipeline design

```text
Existing question JSON + input manifest
  -> inventory and reference classification
  -> reviewed source registry and parsed provision selectors
  -> cached authoritative source snapshots
  -> version selection and structured extraction
  -> question-specific evidence and dependency resolution
  -> draft Spanish explanation
  -> editorial review and automated validation
  -> JSON map + Markdown document + coverage report
```

### A. Inventory and normalize references

Process every question once. Preserve the raw strings and parse a separate structured representation. Recognize instrument type/number/year, article, paragraph, letter, annex, table, edition, and multiple references. Handle `art.`, `Art.`, missing spaces, `bis`, ranges, and numbered agreement clauses. Avoid splitting blindly on commas: titles and author names contain them.

Build a small reviewed source registry with stable IDs, canonical titles, aliases, publisher URLs, source type, language, edition/version policy, and reuse metadata. Explicitly map `RD 1211/1990` to `BOE-A-1990-24442`. Resolve unfamiliar instruments through authoritative search and title/date/type verification; never trust the first fuzzy search result.

Store manual corrections as overrides with reasons, rather than silently “fixing” the input. Unresolved or ambiguous references enter an exception queue. Count exact raw references, normalized references, instruments, and provisions separately.

### B. Retrieve and cache sources

| Source | Preferred retrieval | Fallback |
| --- | --- | --- |
| BOE consolidated legislation | XML API, discovered blocks and versions | Structured BOE HTML; then the matching dated PDF |
| EU legislation | Spanish EUR-Lex text identified by CELEX/ELI and selected date | Official PDF of the same version |
| ADR, ATP, CMR, TIR | Relevant official publisher/treaty source with verified edition and applicability | Official PDF plus reviewed extraction |
| Public technical guides | Publisher's accessible structured text | Publisher PDF, with tables checked visually |
| Commercial/doctrinal material | Lawfully accessible edition or independently verified alternative source | Original authored explanation with review, or an explicit unavailable status |

EUR-Lex uses CELEX identifiers, and its consolidated texts are documentation aids. Version identity must be stored explicitly. [CELEX documentation](https://eur-lex.europa.eu/content/help/eurlex-content/celex-number.html?locale=en), [EUR-Lex consolidation explanation](https://eur-lex.europa.eu/EN/legal-content/glossary/consolidation.html)

Fetch once per source/version and reuse it across questions. Use a disk cache, response hashes, timeouts, bounded concurrency, retry/backoff, and resumable jobs. Record redirects and actual content types; an HTML error page is not a successful XML fetch. Treat 404s as unresolved source failures rather than empty provisions. Follow the publisher's access constraints.

Retain raw bytes plus normalized text and extraction-tool versions. Small fixtures and manifests belong in Git; large permitted snapshots can live in an immutable artifact archive referenced by checksum. Do not commit commercial source material without redistribution rights. A live URL alone is insufficient for reproducibility.

### C. Extract the right provision

Parse XML/HTML structurally. Identify the article body, nested paragraphs, letters, tables, headings, and notes. Exclude navigation, tables of contents, and amendment commentary from operative text while preserving commentary as version metadata.

Do not assume every article has its own block: grouped repealed articles, annexes, and unusual numbering need explicit handling. First retain the entire selected provision for context; then select the smallest evidence passage sufficient for the question, including relevant exceptions and definitions.

For PDFs, try the text layer before OCR. Remove repeating headers/footers conservatively and preserve table relationships, decimal separators, mathematical notation, and units. Inspect rendered pages for multi-column layouts, tables, scans, and suspect text. A low-confidence OCR result cannot pass automatically.

### D. Resolve necessary cross-references

Represent dependencies as versioned provision-to-provision edges. Follow references only when they affect the answer: definitions, scope, exceptions, thresholds, and procedures needed for this question. Resolve relative expressions such as “apartado anterior” in their original context.

Track visited nodes to detect cycles. Start with operational limits of three dependency levels and twenty supporting provisions per question. These are review triggers, not permission to truncate meaning: exceeding a limit creates `needs_review` until a reviewer supplies a sufficient explanation.

Record why a reference was expanded or considered unnecessary. Retain all material qualifications in the final prose. A successful extraction is not automatically a successful flattening.

### E. Author the explanation

For simple cases, a reviewed template or human author may be enough. For varied prose, use a constrained LLM drafting step receiving the question, all answer choices, the official answer, selected evidence, temporal metadata, and resolved dependencies.

Require structured output: draft explanation, claim-to-evidence links, unresolved issues, and potential answer conflicts. The model must be able to abstain. Do not ask it to justify the answer key at all costs. Treat retrieved text as data, not as instructions to the drafting system.

Record model/prompt versions and the evidence/input hashes. Cache accepted drafts. Live generation is not reproducible; the committed reviewed record becomes the reproducible input to publication. A model confidence score or a second model's agreement is not editorial approval.

For nonlegal questions, author a supported explanation of the actual concept or calculation. A bibliographic reference does not guarantee a freely accessible paragraph exists. Disclose substitute evidence and leave unavailable material unresolved rather than fabricating quotations or claiming to have consulted an inaccessible book.

### F. Review and publish

The reviewer should see the question and options, official answer, raw citation, selected source version, exact evidence, dependency notes, draft, and automated findings together. Review shared source mappings once, but check the application to each question separately.

Record reviewer, timestamp, evidence hashes, and rationale for manual overrides. Any material source, question, or explanation change invalidates the associated approval. Review all first-release explanations; batch identical evidence where useful without assuming identical reasoning.

Publish deterministically from reviewed records. Generate unresolved entries and a separate work queue with reasons; never hide missing coverage by omitting question codes.

## 7. Data model and repository layout

Use a normalized authoring store to avoid duplicating large source passages, and a flattened publication map so consumers obtain each explanation directly by code.

Proposed additions, not existing files:

```text
QUESTION_EXPLANATIONS_PLAN.md
tools/explanations/
  bin/                         # inventory, fetch, extract, draft, validate, export
  lib/                         # reference parsing and source adapters
  test/fixtures/               # small permitted snapshots, no live-network tests
data/explanations/
  sources.json                 # canonical source registry and aliases
  references.json              # parsed citations and reviewed overrides
  manifest.json                # bank hashes, cutoff policy, source snapshot IDs
  records/1A.json               # authored records, partitioned by bank section
  records/1B.json               # ... through 1H
  schemas/                     # versioned record and release schemas
docs/
  question_explanations.md      # generated readable document
  question_explanations_coverage.md
packages/pm_questions_bank/assets/explanations/
  pm_260326.json                # generated application map
```

Prefer a Dart command-line package for orchestration and validation, fitting the existing repository. Pin XML/HTML parsing dependencies during implementation. Introduce a small Python PDF/OCR helper only if the pilot demonstrates the need; do not add a second general-purpose pipeline immediately. Begin with files and ordinary CI, not a database service, crawler platform, or vector store.

### Publication contract

The release envelope contains `schemaVersion`, `bankId`, a bank manifest hash, `legalAsOf`, date-policy explanation, source/release manifest identifiers, and `questions` keyed by code. Use strings for codes and dates. Release timestamps must be fixed metadata, not fresh values inserted during every rebuild.

Each question record contains:

| Field | Purpose |
| --- | --- |
| `questionHash` | Detect changed prompt, choices, answer, or citations under an unchanged code |
| `originalNorma`, `originalDoctrinalReference` | Preserve bank provenance |
| `officialCorrectOption`, `officialCorrectAnswerText` | Preserve the official key and its meaning |
| `status` | `unresolved`, `draft`, `needs_review`, `approved`, `conflict`, or `stale` |
| `issueCodes` | Structured reasons such as `ambiguous_reference`, `source_unavailable`, `version_unknown`, `dependency_limit`, `answer_source_conflict` |
| `explanationEs` | Approved self-contained text; null in public output for unapproved records |
| `evidence` | Source identity, exact passage/locator, URL, selected version, dates, snapshot hash, attribution, and whether cited by the bank or added by us |
| `claimEvidence` | Internal links from assertions to supporting evidence |
| `review` | Reviewer, time, approval scope, and content/evidence hashes |

Draft text lives in the authoring records. The public map must not accidentally treat it as approved. Evidence excerpts should be included inline where permitted; restricted material can retain locators and accessible substitute evidence. The explanation itself remains readable without following those locators.

The readable document should contain a version/date note, a code index, section headings, and an entry for every code with its prompt, official answer text, status, explanation, and source/version attribution. Use the same status semantics as JSON. A code present with `explanationEs: null` counts as accounted for, not explained.

## 8. Quality gates and acceptance criteria

### Automated checks

- Every bank code appears exactly once; no orphan records or duplicate keys. For this snapshot, expected count is 4,475.
- Validate schemas, stable sorting, input hashes, and section/code consistency.
- Every approved record has nonempty Spanish prose, approved review hashes, resolvable evidence identifiers, and selected version metadata or an explicit reviewed nonlegal edition policy.
- Check that extracted passages match the pinned source after documented whitespace normalization. Test normalization so it does not change numbers, negations, or units.
- Fail publication of approved records with unresolved material dependencies, unknown required dates, stale approvals, or answer conflicts.
- Lint for unresolved references and letter-only reasoning; treat findings as review prompts because wording heuristics cannot prove semantic completeness.
- Rebuilding from the same reviewed records and snapshots produces identical JSON and Markdown. Regenerating question JSON does not overwrite explanations.
- Ordinary validation and document generation run offline. Network refresh is a separate command/job.

### Meaningful test fixtures

Cover the Article 6 historical/current distinction and the eight actual questions, semicolon-separated citations, annex tables, `bis` numbering, grouped repealed articles, ambiguous instrument names, missing sources, future effective dates, relative cross-references, and cycles. Add an example where the bank answer is not supported and assert that the system blocks approval rather than inventing justification. Test a code whose question changes between releases and invalidates its explanation.

For PDF/OCR adapters, use a small fixture containing table units or exclusions whose loss would change the answer. For app integration, test missing/stale records and shuffled options. Avoid broad UI changes for the document-only milestone.

### Editorial checklist

For every approved explanation, verify that it answers the actual question, supports the correct answer without circular reasoning, preserves necessary qualifications, uses the intended time/edition, and can be understood without opening a source. Distinguish source statements from our inference. A qualified subject reviewer handles ambiguous legal or technical interpretation.

### Coverage and completion

Report total questions, resolved citations, extracted evidence, drafts, approved explanations, conflicts, stale records, and unavailable sources by section and source family. Also report source-mapping precision and drafting/review time on the pilot. Never use retrieval success as a proxy for explanation correctness.

The first useful release may cover a reviewed subset, with every remaining code visibly accounted for. The **full requested corpus is complete only when every question has an approved self-contained explanation**, or a documented scope decision has excluded it. An unresolved placeholder is useful operationally but is not a completed explanation. Conflicts require an explicit editorial disposition before claiming full completion.

## 9. Implementation phases

| Phase | Work and concrete output | Exit condition |
| --- | --- | --- |
| 1. Inventory and policies | Reproducible counts, source classification, verified bank metadata where obtainable, date policy, schema, prioritized source registry | Every question classified or explicitly queued; no assumed publisher cutoff |
| 2. BOE vertical slice | Resolve RD 1211/1990; fetch and pin Article 6 versions; create evidence and explanations for its eight questions | Correct non-conflict examples reviewed; report/opinion questions explicitly investigated and classified |
| 3. Representative pilot | About 100 questions across all eight sections, including EU rules, agreements, tables, calculations, doctrine, and multi-source cases | Precision, failure categories, review minutes, source availability, and draft cost measured; supported examples have no known factual defects |
| 4. Expand source coverage | Prioritize frequently used instruments, then other source families; draft and review in resumable batches | Every code has an authoring record; backlog and genuine unavailable sources are quantified |
| 5. Publish corpus | Generate the Markdown document, JSON map, attribution, and coverage report from approved records | Offline validation passes; unresolved coverage visible; full coverage claimed only under the criteria above |
| 6. Optional application integration | Add `QuestionExplanation` and separate loader; register assets; display reviewed explanation after answering | Offline loading works, answer shuffling is safe, and absent/stale explanations have a clear fallback |
| 7. Maintenance | Scheduled source checks, bank-import comparisons, affected-question review, release snapshots | Demonstrate one source update invalidates and rebuilds only affected explanations |

The document and JSON corpus are the primary scope. App integration is a subsequent choice, not a dependency for delivering the document.

Prioritization can exploit repetition: exact first-comma prefixes include 207 questions for Ley 15/2009, 205 for Ley 16/1987, 182 for RD Legislativo 1/2010, and 165 for RD 1211/1990. These are useful workload indicators, not a parsed coverage guarantee: multi-source citations and aliases still need normalization.

### Effort and cost planning

Engineering is likely smaller than editorial work. As an initial planning range, allow 2–4 working days for inventory/schema/the BOE slice, 3–7 for the representative pilot and first exporters, and 1–3 further weeks for adapters and full-batch tooling. These estimates assume one engineer, accessible sources, and reviewer availability; recalibrate after the pilot.

Reviewing 4,475 entries at an assumed average of 2–5 minutes takes approximately **149–373 reviewer hours**, before difficult-source research. Measure actual times rather than assuming model drafting eliminates this cost. Review shared evidence in batches and reuse approved explanations only when the question's reasoning and qualifiers genuinely match.

Track source-fetch count, storage, tokens per draft, model costs at the chosen provider's then-current prices, retry rates, reviewer minutes, and rework. Cache by evidence/question/prompt hashes and start with a limited pilot budget. No paid model service is required for the deterministic extraction or document-generation stages.

## 10. Alternatives and their tradeoffs

| Approach | Advantages | Disadvantages | Assessment |
| --- | --- | --- | --- |
| Fully manual document or spreadsheet | Easy to start; strong editorial control; handles unusual sources | Thousands of lookups; inconsistent structure; duplicate evidence; difficult updates and reproducibility | Good for pilot authoring and exceptions; weak as the sole long-term process |
| Copy entire articles into a code map | Deterministic after citation resolution; avoids model prose; quick legal-text baseline | References remain nested; long or irrelevant text; no application to the question; nonlegal sources still unresolved | Useful evidence milestone, insufficient as the final flattened explanation |
| PDF-first extraction/OCR | Works across many publishers and preserves page locators | Layout/OCR errors, especially numbers and tables; harder version selection; more cleanup and compute | Necessary fallback; avoid making it the BOE default |
| HTML scraping only | Readable, accessible, easier than PDFs; handles sites without APIs | Site layout changes; navigation/notes contamination; weaker structural guarantees | Second choice after an official structured endpoint |
| One-shot LLM over citations/questions | Fast initial prose and broad apparent coverage | Invented law, version errors, rationalized wrong keys, opaque evidence, costly review | Reject as a publishing method |
| Whole-document LLM extraction and drafting | Less parser development for unusual documents; can interpret layouts | Missed exceptions, context limits, repeated processing cost, unstable locators | Candidate helper for exceptional sources, with extraction verification |
| RAG/vector search across all legal PDFs | Flexible semantic discovery when citations are vague | Adds indexing infrastructure; retrieval can miss exact provisions or versions; does not solve approval or offline corpus ownership | Defer; exact citation lookup is better suited to the current bank |
| Live retrieval/generation when answering | Can consult fresh sources; avoids bundling every explanation initially | Network latency, outages, recurring costs, inconsistent answers, poor offline behavior, silent legal changes | Poor fit for this deliverable and the current asset-based app |
| Commercial legal-content service | Potentially curated normalization, editorial metadata, and historical coverage | Fees, licensing/export limits, vendor dependence, uncertain coverage of technical/doctrinal sources | Evaluate only if the pilot identifies gaps worth the cost |
| **Structured retrieval + reviewed explanations + static exports** | **Auditable, question-specific, reproducible, offline, and incrementally maintainable** | **Requires source adapters and sustained human review; full automation is unrealistic** | **Recommended** |

A spreadsheet can be an editing interface later, but reviewed structured records should remain the publication source of truth. A database or review web app becomes justified only if concurrent editorial work makes file-based review cumbersome.

## 11. Updates, provenance, and reuse

Keep bank releases immutable. For a new bank, compare question content hashes as well as codes: a reused code is not proof that the question is unchanged. Carry forward approval only when the question, explanation, evidence, and temporal scope remain compatible.

Check referenced sources periodically and before each explanation release. BOE's API documents update-date filters for discovery; changed-source discovery should trigger provision-level comparison, not automatic replacement of explanations. [BOE API documentation](https://www.boe.es/datosabiertos/api/api.php)

Maintain a reverse dependency index from source/version/provision to questions. Changes to a transitive supporting provision must also invalidate affected records. Keep the existing release available until its successor passes review, with the original release date/cutoff visible. New drafts and refresh failures should not overwrite the last reviewed artifact. Export an impact report and preserve the reason for every change.

BOE's reuse terms require appropriate attribution, preserved update metadata, identification of adaptations, and an informative-status notice for reused consolidated text. Use the prescribed attribution for derived material, “Basado en datos de la Agencia Estatal Boletín Oficial del Estado,” with a BOE link. Keep original excerpts and our explanation visibly distinct. Check other publishers individually, especially textbooks, standards, and commercial guides; do not assume BOE's terms apply elsewhere. [BOE reuse terms](https://www.boe.es/informacion/aviso_legal/index.php)

The initial implementation should therefore start with the **eight Article 6 questions**, prove version-aware extraction and conflict handling, then expand through the representative pilot. That sequence validates the hardest assumptions before committing to drafting all 4,475 explanations.
