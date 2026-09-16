# Learning Record Format

Learning records live in `./learning-records/` and use sequential numbering: `0001-slug.md`, `0002-slug.md`, etc. Create the directory lazily: only when the first record is written.

They are the study equivalent of ADRs: they capture non-obvious insights, corrected misconceptions, and confirmed prior knowledge that steer future sessions. They're what "Tracking Progress" and "What to Study Next" in [SKILL.md](./SKILL.md) draw on to find weak spots and decide what's actually ready to be left alone.

## Template

```md
# {Short title of what was learned or established}

{1-3 sentences: what was learned (or what prior knowledge was established), and why it matters for what to study next.}
```

That is the whole format. A learning record can be a single paragraph. The value is in recording _that_ this is now known (or not yet known) and _why_ it changes what comes next, not in filling out sections.

## Optional sections

Only include these when they add genuine value. Most records won't need them.

- **Status** frontmatter (`active | superseded by LR-NNNN`): useful when an earlier read on the student's understanding turns out to be wrong and is replaced.
- **Evidence**: how the student demonstrated it (a mock exam question, a quiz, prior coursework cited). Worth recording when the claim might be revisited.
- **Implications**: what this changes for future sessions — e.g. a topic in `SYLLABUS.md` that can now move to "solid," or a prerequisite that needs revisiting.

## Numbering

Scan `./learning-records/` for the highest existing number and increment by one.

## When to write a learning record

Write one when any of these is true:

1. **The student demonstrated real understanding of something non-trivial**: not just exposure, but evidence they can use it correctly — a mock exam question answered well, a quiz passed cleanly, a problem worked through unaided. Update the topic's status in `SYLLABUS.md` to match.
2. **The student disclosed prior knowledge**: "I already know this from last term." Record it, and the depth claimed, so future sessions don't re-teach it.
3. **A misconception was corrected**: the student previously believed something wrong and now sees why. These are high-value — they predict where related topics will trip the student up too.
4. **A mock exam, quiz, or lesson revealed a weak spot**: the student got something wrong, or hesitated where they should have been fluent. This is often more useful than a record of success — it's what drives the next session's priorities.
5. **The exam profile shifted in response to something learned**: scope narrowed, a topic turned out not to be tested after all. Cross-link to `EXAM.md` and update it.

### What does _not_ qualify

- Material that was merely covered. Coverage isn't learning. Wait for evidence.
- Anything already captured tersely in `GLOSSARY.md` as a term definition. Don't duplicate.
- Session-by-session activity logs. Learning records are not a journal — they're decision-grade insights.

## Supersession

When a later record contradicts an earlier one (the student's understanding deepened, or a "solid" topic turned out shakier under exam conditions), mark the old record `Status: superseded by LR-NNNN` rather than deleting it. The history of how understanding evolved is itself useful signal.
