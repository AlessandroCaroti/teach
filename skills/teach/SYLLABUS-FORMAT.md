# SYLLABUS.md Format

`SYLLABUS.md` is the working map of what's actually going to be examined, extracted from the student's materials. It's the file "What to Study Next" and "Mapping the Syllabus" in [SKILL.md](./SKILL.md) both draw on, and it should change as often as the student's understanding does.

## Structure

```md
# {Exam} Syllabus Map

## {Topic area / week / chapter}

### {Concept or topic name}
- **Type**: memorization | understanding | both
- **Likely weight**: {why you think this is or isn't likely to be examined — repeated across materials, called out explicitly, appears in a past paper, anchors a whole chapter, etc.}
- **Status**: not started | studying | practiced | solid
- **Source**: {which material(s) this comes from}
- **Key content**: {the definitions, formulas, relationships, or examples that matter, in brief}

{repeat per concept}
```

## Rules

- **Every topic traces to a source.** If you can't name which material a topic came from, it doesn't belong here yet. See Source of Truth in [SKILL.md](./SKILL.md).
- **Tag memorization vs understanding honestly.** A formula the student needs to derive is "understanding"; the same formula, if they just need to recall and plug in, is "memorization." This tag decides which study technique to reach for.
- **Status reflects evidence, not exposure.** Only move a topic to "practiced" or "solid" once a learning record backs it up. A lesson being written isn't the same as the student having learned it.
- **Update incrementally.** Add topics as new materials arrive; update status after quizzes, lessons, and mock exams. Don't let this file go stale while `./learning-records/` moves on without it.
- **Group how the materials group.** Mirror the course's own structure (weeks, chapters, modules) rather than imposing your own organization. It's what the student already has a mental model for.
