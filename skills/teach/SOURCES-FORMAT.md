# SOURCES.md Format

`SOURCES.md` is the source-of-truth register for this workspace: everything the student has given you, plus a short, clearly separated record of the rare cases you went outside it. See Source of Truth in [SKILL.md](./SKILL.md) for the policy this file supports.

## Structure

```md
# {Exam} Sources

## Provided by the student

- **Lecture slides, Weeks 1-4** (`slides-w1-4.pdf`) — added 2026-09-10
  Covers: cell division, mitosis vs meiosis. Fully read.
- **Past paper, 2024** (`past-paper-2024.pdf`) — added 2026-09-10
  Covers: whole syllabus, 3 essay questions + 20 MCQs. Fully read. Use for mock exam format.
- **Problem set 3** (`problem-set-3.csv`) — added 2026-09-12
  Dataset for the regression exercises in Week 6. Fully read.

## External sources (use sparingly)

- **{Source name/title, link if applicable}** — used on {date} because {materials didn't cover X / needed to explain implicit prerequisite Y}
  Where it was used: {which lesson or reference doc}. Reliability: {why this source is trustworthy — official textbook, exam board publication, peer-reviewed, etc.}

## Gaps

{Topics EXAM.md or SYLLABUS.md suggests are in scope, but no material actually covers yet. Ask the student for these before generating content about them.}
```

## Rules

- **Log every material as it arrives**, not in a batch at the end. A source you forget to log is a source you might silently stop treating as authoritative.
- **One line on what it covers and how thoroughly you've read it.** "Added" isn't "read" — note when a large document is only partially reviewed so far.
- **The External sources list should usually be empty or nearly so.** Every entry needs a stated reason and a reliability justification — see Source of Truth in [SKILL.md](./SKILL.md) for what counts as reliable. If this list is growing long, that's a sign to ask the student for more of their own materials rather than keep researching around the gap.
- **Surface gaps explicitly.** If the syllabus implies a topic no material covers, write it down under Gaps rather than quietly filling it from general knowledge.
- **Prune what turns out to be wrong or irrelevant.** If an external source turns out to be off-target, remove it rather than leaving it to mislead a future session.
