# Tool & Skill Orchestration

This file governs how `teach` uses other skills and MCP tools that may be available in the environment (document readers, Docling, Mermaid, Jupyter, Anki, grounded-citations, arXiv, Socrates, or others not listed here). Read it whenever a session might benefit from one of these, and before wiring a new integration into a workspace.

**The core rule: `teach` is the orchestrator, not a peer.** External skills and tools provide specialized capabilities on request. They do not take ownership of exam strategy, syllabus structure, learning-state tracking, lesson sequencing, weak-area identification, or the decision of what to study next — that responsibility stays with `teach` regardless of which tools are installed.

## Contents

- [Delegation table](#delegation-table)
- [Delegation principles](#delegation-principles)
- [Source hierarchy](#source-hierarchy)
- [Capability fallback](#capability-fallback)
- [Document reading (PDF / DOCX / PPTX / XLSX)](#document-reading-pdf--docx--pptx--xlsx)
- [Docling MCP](#docling-mcp)
- [Mermaid diagrams](#mermaid-diagrams)
- [Jupyter notebooks](#jupyter-notebooks)
- [Anki MCP](#anki-mcp)
- [External research and grounded citations](#external-research-and-grounded-citations)
- [arXiv](#arxiv)
- [Socratic mode](#socratic-mode)

## Delegation table

| Need | Preferred capability |
|---|---|
| Read a normal, machine-readable PDF | `pdf` skill |
| Read a DOCX | `docx` skill |
| Read a PPTX | `pptx` skill |
| Read an XLSX | `xlsx` skill |
| Scanned, multi-column, or layout-sensitive document; poor text extraction; OCR | Docling MCP |
| A diagram or visual model would clarify a concept | Mermaid |
| Numerical, statistical, or dataset-based calculation or verification | Jupyter notebook (`opencode-jupyter` kernel when registered) |
| Persistent spaced-repetition flashcards | Anki MCP |
| Verifying or citing something genuinely outside the provided materials | `grounded-citations` |
| Retrieving an academic paper referenced by the materials | `arxiv` |
| Guided, no-answers-given practice; oral-exam rehearsal | `socrates` |

## Delegation principles

1. Use a tool only because the task actually needs it — not because it happens to be available.
2. Prefer the simplest tool that reliably solves the task.
3. Don't run the same material through multiple extraction or verification systems without a concrete reason to think the first pass was insufficient.
4. Anything a tool extracts, calculates, or generates still has to be integrated into the study model by `teach` — into `SYLLABUS.md`, `GLOSSARY.md`, a lesson, a learning record, wherever it belongs. A tool's output sitting unintegrated in a notebook or a card deck doesn't count as done.
5. A tool answers its own narrow question ("what's in this document," "what does this compute to," "is this diagram accurate") — it does not decide what the student should know or study next. That stays with `teach`.

## Source hierarchy

When deciding what's authoritative for exam preparation, apply this order. Higher tiers override lower ones:

1. The student's own official course/exam materials, as logged in `SOURCES.md`.
2. The student's own supplementary materials.
3. Information derived directly from tier 1–2 materials via a tool (document-reading skills, Docling, a Jupyter calculation grounded in the student's own data). This still counts as coming from the materials — it's the same source, just processed — so it does not need the "background" flag that genuinely external knowledge gets.
4. External authoritative sources, only when the External Research policy below permits them, and always flagged.
5. General model knowledge, used minimally per the Source of Truth section in `SKILL.md`, and always flagged.

Never let a lower tier silently override a higher one — including quietly "correcting" the student's materials using outside knowledge. If materials look wrong, say so; don't fix them in place.

## Capability fallback

Not every workspace will have every tool installed. Before relying on an optional integration, check whether it's actually available this session.

- If it's missing, fall back to the best available alternative and keep going — don't stall the session or repeatedly nag the student to install something optional mid-lesson.
- Missing `pdf`/`docx`/`pptx`/`xlsx` skill, Docling available → use Docling.
- Missing Docling → use the ordinary document-reading skill; if extraction still looks broken (garbled text, missing tables), say so plainly rather than teaching from bad extraction. Before treating Docling as missing, note that it can look unavailable simply because it's still starting up — see [Docling MCP](#docling-mcp) for the two common causes and what to check before falling back.
- Missing Jupyter → solve the calculation directly and note that it wasn't programmatically verified.
- Missing Anki → keep memorization targets inside the workspace (`GLOSSARY.md`, a lesson's flashcard widget) instead.
- Missing `grounded-citations` or `arxiv` → treat that as another reason to lean on the provided materials rather than reaching further outside them.
- Missing `socrates` → run Socratic-style questioning yourself (ask before telling) rather than treating the mode as unavailable.

## Document reading (PDF / DOCX / PPTX / XLSX)

When source materials arrive in one of these formats, use the matching document-reading skill to extract them:

- PDF → `pdf`
- DOCX → `docx`
- PPTX → `pptx`
- XLSX → `xlsx`

These skills answer "what is inside this document" — not "what should the student know about this topic." Extract with them, then run the result through the normal `SOURCES.md` → `SYLLABUS.md` pipeline described in `SKILL.md`. Don't treat a document skill's output as already being a lesson or a syllabus entry; it's raw material for one.

## Docling MCP

Treat Docling as a fallback and enhancement, not a default first pass. Reach for it when:

- the PDF is scanned or needs OCR,
- it has complex or multi-column tables,
- the ordinary `pdf` skill's extraction looks incomplete, garbled, or loses layout that carries meaning (e.g. a diagram-heavy slide, a form).

For an ordinary machine-readable PDF, try the `pdf` skill first. Don't run the same document through both extraction paths unless the first one gave you reason to distrust it — that wastes context and can produce two slightly different versions of the same material.

### Docling MCP: setup and known failure modes

`docling-mcp` (the typical way Docling shows up as an MCP server, often launched via `uvx`) has two startup quirks that look like the tool being broken when it isn't. Knowing them avoids wrongly concluding Docling is unavailable and falling back to a worse extraction than necessary:

- **Wrong conversion mode.** The server defaults to `remote` mode, which expects a `DOCLING_MCP_SERVICE_URL` pointing at a hosted conversion service. In a workspace that only has Docling installed locally, remote mode has nothing to call and every conversion fails with something like `DOCLING_MCP_SERVICE_URL is not set but DOCLING_MCP_CONVERSION_MODE=remote`. If the environment doesn't document a remote endpoint, set `DOCLING_MCP_CONVERSION_MODE=local` so it runs against the local Docling install instead.
- **Slow cold start.** The first launch in a fresh environment can install a large dependency set and load Docling's models before it responds — several minutes, not seconds. If the calling client (an agent runtime, an MCP host) applies a shorter startup timeout, it can report the server as unavailable or failed even though it's still finishing setup. A second launch after that first one, with the environment already warm, typically starts in well under a minute. If Docling reports as unavailable right after being newly configured, that's a reason to retry once after giving it time to finish its first boot, not to immediately conclude it's broken and fall back.

If tools still don't appear after a retry and there's a way to invoke the server directly (a small script or CLI that speaks its protocol) that's a faster way to confirm whether the server itself works before assuming a client-side integration problem — and, in a pinch, is itself a usable path to get a batch of documents converted while the client-side issue gets sorted out. Either way, whatever Docling produces still goes through the normal extraction → `SOURCES.md` → `SYLLABUS.md` pipeline; a workaround for reaching the tool doesn't change what happens with its output.

## Mermaid diagrams

Generate a diagram when a concept would genuinely be clearer as one — not as decoration. Good candidates: processes, sequences, timelines, dependencies, state transitions, hierarchies, system architectures, cause-and-effect chains. This applies inside lessons, reference docs, or mock-exam explanations, wherever a visual would help.

The written explanation stays authoritative; a diagram supports it, not the other way round. If Mermaid isn't available, describe the structure clearly in prose instead.

## Jupyter notebooks

Use a notebook (the registered `opencode-jupyter` kernel, if set up) for calculations that are cheap and reliable to verify programmatically rather than by hand: statistics, numerical analysis, dataset exploration, plots, formula checks, simulations, worked examples with many values. This is especially relevant when the student has supplied a real dataset — build and verify exercises on its actual values, not invented ones.

Keep the division of labor clean: `teach` explains the concept, Jupyter computes or verifies the example, `teach` interprets the result back to the student. The notebook is a verification tool, not where the teaching happens. If Jupyter isn't available, solve it directly and say so.

## Anki MCP

Anki is an output and spaced-repetition system, not a source of truth — `SOURCES.md`, `SYLLABUS.md`, `GLOSSARY.md`, `NOTES.md`, and `learning-records/` remain authoritative regardless of what's in a deck.

- Create cards primarily for definitions, terminology, factual recall, formulas, classifications, and short relationships — things explicitly worth memorizing, not long explanations.
- Prefer atomic cards: one testable idea per card.
- Don't generate a card for every syllabus entry by default; only where the material actually benefits from spaced repetition. A workspace with hundreds of low-value cards is worse than one with a hundred good ones.
- Before adding a card, check whether an equivalent one already exists rather than creating a duplicate.
- Never silently delete or rewrite the student's existing cards.

Typical flow: source material → `teach` identifies a memorization target → it lands in `GLOSSARY.md` or `SYLLABUS.md` → an Anki card is created from it. Conceptual, applied-understanding topics stay in lessons and quizzes rather than becoming cards.

## External research and grounded citations

The Source of Truth section in `SKILL.md` already treats the student's materials as primary and web research as a rare exception — this just operationalizes it for the `grounded-citations` skill specifically. Only reach outside the materials when:

1. the student explicitly asks for external research or verification,
2. something the exam clearly needs is genuinely missing from what they've given you, or
3. outside context is necessary to understand material that's otherwise opaque.

When `grounded-citations` is available and one of those applies: log the source in `SOURCES.md` under "External sources," cite it, prefer authoritative primary sources over secondary ones, and keep it visually distinguishable from material that came from the student (the *(external source: …)* flag already used elsewhere in `SKILL.md`). Never let externally sourced content quietly blend into material that reads as if it came from the course.

## arXiv

Optional, and narrower than general external research. Use it only when external research is already permitted by the policy above, and specifically when:

- the materials reference a paper that wasn't itself provided (e.g. "Smith et al. 2024," an `arXiv:xxxx.xxxxx` citation),
- the student explicitly asks to inspect a paper, or
- a cited result needs verification.

Don't go looking for papers just because a topic happens to be academic. Anything pulled from a paper gets the same external-source flagging as above.

## Socratic mode

`socrates` carries a strong internal rule — never give the answer directly — that would actively conflict with how `teach` normally works (explaining, grounding, lessons that end with a clear takeaway). Treat it as an explicit, opt-in mode rather than a peer skill:

- Enter it only when the student asks for Socratic practice, oral-exam rehearsal, or to be walked through a problem without being handed the answer, or when `teach` proposes it and the student agrees.
- While in Socratic mode, its no-direct-answers rule governs. Outside it, normal `teach` behavior applies — Socratic rules never leak into an ordinary lesson or quiz.
- When the exercise ends, return to the normal workflow (deciding what to study next, logging a learning record from what the exchange revealed, etc.) rather than staying in questioning mode by default.
