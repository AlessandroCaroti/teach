# Teach

An exam-focused teaching skill for building a persistent, source-grounded study workspace.

This repository is an exam-preparation adaptation of [Matt Pocock's `teach` skill](https://github.com/mattpocock/skills/tree/main/skills/productivity/teach). It keeps the upstream idea of teaching through short lessons, practice, feedback, and reusable reference material, while adding an explicit exam profile, syllabus mapping, source register, glossary, mock exams, and learning records.

## What it does

The skill helps a student prepare for one specific exam, test, quiz, or certification. It:

- Grounds explanations and practice in the student's own course materials
- Maps those materials to an exam-relevant syllabus
- Separates understanding from memorization and uses the right practice for each
- Builds lessons, reference documents, quizzes, flashcards, and mock exams
- Tracks misconceptions, strengths, and weak areas over time
- Keeps external research rare, clearly labeled, and recorded

The student's materials are the source of truth. General knowledge and web research are used only when necessary and are explicitly marked as outside the provided materials.

## Installation

Install or copy the `skills/teach` directory into the skills directory used by your agent environment. The skill entry point is:

```text
skills/teach/SKILL.md
```

The skill is configured with `disable-model-invocation: true`, so it should be invoked deliberately when the student wants to begin or continue exam preparation.

## Usage

Invoke `teach` and provide:

1. The exam, course, or certification
2. The exam date and format, if known
3. The study materials available, such as notes, slides, readings, exercises, datasets, or past papers

At the beginning of a workspace, the skill establishes the exam profile and waits for source materials before generating exam-specific content. In later sessions, it reads the existing study state and chooses the next useful activity based on exam weight, available time, prerequisites, and demonstrated weaknesses.

## Study workspace

The skill treats the current directory as the student's study workspace:

| Path | Purpose |
| --- | --- |
| `EXAM.md` | Exam subject, date, format, target, constraints, and out-of-scope topics |
| `SOURCES.md` | Materials supplied by the student and any rare external sources |
| `SYLLABUS.md` | Exam-relevant topics, source links, learning type, weight, and status |
| `GLOSSARY.md` | Canonical terms and definitions from the student's materials |
| `NOTES.md` | Study preferences, working notes, and output-language choices |
| `lessons/*.html` | Short, self-contained lessons for tightly scoped topics |
| `mock-exams/*.html` | Full or partial exam simulations |
| `reference/*.html` | Printable cheat sheets and quick-reference documents |
| `learning-records/*.md` | Evidence of strengths, misconceptions, and review needs |
| `assets/*` | Shared styles, widgets, diagrams, and other reusable lesson components |

Templates for the structured files live beside the skill:

- [EXAM-FORMAT.md](skills/teach/EXAM-FORMAT.md)
- [SOURCES-FORMAT.md](skills/teach/SOURCES-FORMAT.md)
- [SYLLABUS-FORMAT.md](skills/teach/SYLLABUS-FORMAT.md)
- [GLOSSARY-FORMAT.md](skills/teach/GLOSSARY-FORMAT.md)
- [LEARNING-RECORD-FORMAT.md](skills/teach/LEARNING-RECORD-FORMAT.md)

## Learning approach

The workflow distinguishes between understanding and retention:

- **Understanding:** clear explanations and summaries grounded in the supplied materials
- **Retention:** retrieval practice, spacing, interleaving, and realistic timed practice
- **Feedback:** immediate correction in quizzes and practice activities
- **Progress:** learning records provide evidence for changing syllabus status and selecting the next topic

Lessons should be short and focused on one tangible outcome. Mock exams should match the real exam's format as closely as the available materials allow, including topic mix, question style, marks, and timing.

## Optional integrations

The skill remains the orchestrator when optional capabilities are available. Document readers can extract source material, Jupyter can verify calculations, Mermaid can support useful diagrams, and Anki can hold selected memorization cards. These tools do not replace the exam profile, syllabus decisions, source register, or learning records.

See [ORCHESTRATION.md](skills/teach/ORCHESTRATION.md) for delegation rules and fallback behavior.

## Repository layout

```text
skills/
└── teach/
    ├── SKILL.md
    ├── ORCHESTRATION.md
    ├── *-FORMAT.md
    └── agents/
        └── openai.yaml
```

## Attribution

This project is based on the upstream [`teach` skill](https://github.com/mattpocock/skills/tree/main/skills/productivity/teach) from [Matt Pocock's `skills` repository](https://github.com/mattpocock/skills). The local implementation has been adapted for exam preparation and uses a different study-workspace model.