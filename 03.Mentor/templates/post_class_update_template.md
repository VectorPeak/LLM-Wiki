# Post-Class Update Checklist

Use this checklist after a real Mentor session. The goal is to synchronize the three learning layers without turning every file into a transcript.

## Required Updates

- [ ] Update `30_active_learning_dashboard.md` with active tracks, weak points, next session candidates, and recent mastery changes.
- [ ] Archive stale or completed active progress into `20_session_index.md` when applicable.
- [ ] Append compact learning trace to `01.raw/02.DailyNotes/<current-range>.md` if meaningful.
- [ ] Preserve user-provided reference materials/context paths in the session note or index entry.
- [ ] Add expanded material rewrites to `book_notes/` only when the source itself needs improvement.

## Self-Regulated Learning Review

- [ ] Plan captured: goal, prior knowledge, reference/context, expected output.
- [ ] Perform captured: learner attempt, AI feedback, practice result, Feynman output.
- [ ] Reflect captured: weak point, mastery delta, next drill, next review.
- [ ] The session did not end as passive explanation only; learner output is recorded.

## Reference / Context Update

When the learner provides materials, record enough context for future agents to reconstruct the session.

- [ ] Source type recorded: pasted text / file / image / code / link / prior note / repo context.
- [ ] Source path or URL preserved when available.
- [ ] Key claim or excerpt summarized without bloating the active dashboard.
- [ ] Any uncertainty or conflict marked explicitly.
- [ ] DailyNotes receives only a compact trace, not the full source dump.

## 2.5h AI-Feynman Rhythm Review

Use this section when the session is part of the daily 2.5h learning rhythm.

| Block | Done? | Evidence | Follow-up |
|---|---|---|---|
| 30 min new concept | [ ] | TBD | TBD |
| 60 min hands-on practice | [ ] | TBD | TBD |
| 20 min Feynman explanation | [ ] | TBD | TBD |
| 10 min relation graph / analogy | [ ] | TBD | TBD |
| 10 min review cards | [ ] | TBD | TBD |

## Input Type Update

- Concept input: update or create a mastery card if the concept will recur.
- Code input: record reusable bug patterns, edge cases, commands, or interview variants.
- Question input: add the question to the question bank if it exposed a real gap.
- Reference/context input: preserve source paths and summarize only the learning-relevant claims.
- Mixed input: split outputs into source trace, concept memory, practice result, and next action.

## DailyNotes Entry Shape

Only include sections that actually have content. Keep it compact and raw.

```markdown
### Mentor

- Goal:
- Reference / Context:
- Question:
- Concept:
- Code:
- Output:
- Feedback:
- Weak point:
- Next:
```

## `20_session_index.md` Entry Shape

```markdown
### YYYY-MM-DD - Topic

- Daily raw: `01.raw/02.DailyNotes/YYYY-MM-DD_YYYY-MM-DD.md#YYYY-MM-DD`
- Session note: `03.Mentor/sessions/YYYY-MM-DD - Topic.md`
- Reference/context: pasted text | file | code | image | link | prior note
- Tutor: Ganyu | Keqing | mixed
- Mode: feynman-student | analogy | relation-graph | deliberate-practice | compression | mixed
- Summary:
- Key learning:
- Weak point:
- Mastery delta: before -> after
- Next review:
```