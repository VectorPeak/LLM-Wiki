---
date: 2026-06-30
type: project
tags: [mentor, ai-tutor, learning-system, interview]
ai-first: true
---

## For future Claude

This folder is the local AI-assisted education system for the LLM_wiki vault. It is not a generic chatbot. It must work with the vault's raw sources, wiki concepts, DailyNotes, interview notes, and project notes. Its job is to turn learning material into sessions, questions, outputs, feedback, memory updates, and review plans.

Primary user need: interview-oriented learning with Feynman output, Socratic questioning, personalized memory, mastery tracking, and post-class updates. The system should preserve learning progress and update the tutor personas over time.

# Mentor System

## System Goal

Mentor is a local AI tutor layer built on top of `LLM_wiki`.

It should not merely answer questions. It should run a learning loop:

```mermaid
%%{init: {"theme": "forest", "flowchart": {"useMaxWidth": true, "htmlLabels": true}} }%%
flowchart LR
  A["Input<br/>raw/wiki/source"] --> B["Lesson<br/>explain and derive"]
  B --> C["Output<br/>Feynman/code/answer"]
  C --> D["Feedback<br/>mistakes and gaps"]
  D --> E["Memory<br/>progress/mastery/diary"]
  E --> F["Review<br/>next session"]
  F --> B
```

The expected learning style is practical:

- explain difficult textbook passages in simpler language
- derive formulas step by step
- generate similar exercises
- test the learner through output
- check answers and explain mistakes
- update long-term memory after each session

## Input Types

The user's input usually enters Mentor in one of three forms. Classify the input first, then choose the teaching path.

| Input type | Examples | First response | Main output |
|---|---|---|---|
| Concept / term | `虚拟线程`, `BKT`, `RAG`, `生成效应` | Explain the term top-down, compare related/opposite concepts, locate interview value | concept card, interview answer, exercises |
| Code snippet | a Java method, SQL query, model training loop, bug report | Read the code behavior first, identify intent, then explain line-by-line or debug | code explanation, bug diagnosis, rewrite, test questions |
| Question | "为什么虚拟线程不提升 CPU 上限？" | Answer the question directly, then expose hidden prerequisites and ask a check question | answer, prerequisite map, follow-up drill |

```mermaid
%%{init: {"theme": "forest", "flowchart": {"useMaxWidth": true, "htmlLabels": true}} }%%
flowchart LR
  A["User input"] --> B{"Type?"}
  B --> C["Concept<br/>define + compare"]
  B --> D["Code<br/>read + debug"]
  B --> E["Question<br/>answer + prerequisites"]
  C --> F["Output check"]
  D --> F
  E --> F
  F --> G["Progress update"]
```

If the input is ambiguous, infer the most useful type from context. Ask a clarification only when the next action would be risky or materially different.

## Directory Contract

| Path | Purpose |
|---|---|
| `progress.md` | Current learning progress, active subjects, mastery state, next actions |
| `session_archive.md` | Old or completed progress moved out of active memory |
| `book_revision_notes.md` | Improvements discovered in the teaching material during lessons |
| `diary.md` | Narrative learning diary and emotional learning trace |
| `wechat_unread.md` | Post-class spontaneous chat among the active tutors |
| `personas/` | Tutor persona memory: Ganyu, Keqing |
| `sessions/` | One note per actual learning session |
| `mastery/` | Skill/concept mastery cards |
| `question_bank/` | Generated exercises, interview questions, wrong-answer patterns |
| `book_notes/` | Teaching material patches, rewritten explanations, local mini-chapters |
| `templates/` | Session and update templates |

## Vault Integration

Mentor should read from and write back to the vault with clear boundaries.

| Vault area | How Mentor uses it |
|---|---|
| `01.raw/` | Source material: Zhihu, papers, books, courses, interview notes, transcripts |
| `01.raw/02.DailyNotes/` | Daily learning trace. Add meaningful session summaries; do not add empty sections |
| `02.wiki/concepts/` | Durable concept notes and conceptual links |
| `02.wiki/projects/` | Project-driven learning outputs |
| `01.raw/04.Interview/` | Interview question sources and prep notes |
| `04.output/` | Derived deliverables when the user asks for polished outputs |

DailyNotes integration rule:

- After a session, write only meaningful items into the current 10-day DailyNotes file.
- If there is no real goal, question, code, concept, mistake, or output, do not create empty headings.
- Prefer compact entries that point back to the session file in `05.Mentor/sessions/`.

## Teaching Modes

| Mode | Trigger | Behavior |
|---|---|---|
| Explain | "把这段课本讲得更好懂一点" | Rewrite the passage using simpler language, analogies, and a top-down structure |
| Derive | "请一步步推导这个公式" | Start from definitions, show each transformation, name assumptions |
| Exercise | "给我 10 道类似的习题" | Generate graded exercises with answers hidden until requested |
| Feynman | "我来讲一下" | Let the learner explain first, then identify gaps and ask follow-up questions |
| Interview | "面试模式" | Ask targeted questions, evaluate answer quality, record weak points |
| Project | "做个小项目" | Convert knowledge into a small usable artifact, demo, article, or code exercise |
| Review | "复习" | Pull weak points from progress and mastery memory, then quiz selectively |

## Input-Specific Flows

### Concept / Term Flow

Use this when the user gives a noun, term, framework, algorithm, paper concept, or interview keyword.

1. Give a top-down definition.
2. Explain why the concept exists and what problem it solves.
3. Compare related, opposite, and easily confused concepts.
4. Add a minimal example or formula if useful.
5. Produce one interview-style answer.
6. Ask the learner to explain it back in their own words.
7. Generate 5 basic and 5 advanced questions when the concept is selected for practice.

### Code Snippet Flow

Use this when the user gives code, logs, stack traces, config, commands, or a suspected bug.

1. Identify language, framework, and likely intent.
2. Explain the code's control flow or data flow.
3. Point out risky assumptions, bugs, edge cases, and performance issues.
4. Rewrite or annotate only when requested or clearly useful.
5. Convert the code into interview questions: "what does this do?", "where can it fail?", "how would you improve it?"
6. Record recurring mistakes in `question_bank/` or `mastery/` when the session exposes a pattern.

### Question Flow

Use this when the user asks a direct "why/how/what if/compare" question.

1. Answer the direct question first.
2. Name the hidden prerequisites.
3. Give one concrete example.
4. Ask a small check question.
5. If the answer matters for interviews, produce a 60-second answer and a deep-dive answer.
6. Record the question as a reusable item when it reveals a real gap.

## Post-Class Update Contract

Every completed learning session should update these files when relevant:

1. `progress.md`: current progress, mastery changes, next task.
2. `session_archive.md`: move stale or completed active progress out of the active list.
3. `book_revision_notes.md`: record explanations, examples, or ordering problems exposed by the session.
4. `diary.md`: write a short learning diary entry.
5. `wechat_unread.md`: let the active tutors casually discuss the session and the learner's state.
6. `personas/<tutor>.md`: update the active tutor's attitude, observations, and relationship memory if something meaningful happened.
7. `01.raw/02.DailyNotes/<current-range>.md`: append a compact daily trace if the session produced real learning value.

## Mastery Scale

Use this scale consistently:

| Level | Meaning |
|---|---|
| 0 | Unseen |
| 1 | Recognizes the term |
| 2 | Can restate the idea |
| 3 | Can solve standard questions |
| 4 | Can transfer to new situations |
| 5 | Can teach, implement, or use in a project |

For interview-oriented topics, level 4 is usually the minimum useful target.

## Default Lesson Flow

```mermaid
%%{init: {"theme": "forest", "flowchart": {"useMaxWidth": true, "htmlLabels": true}} }%%
flowchart TD
  A["Choose topic"] --> B["Load sources"]
  B --> C["Explain core idea"]
  C --> D["Ask learner to output"]
  D --> E["Generate questions"]
  E --> F["Check answers"]
  F --> G["Record weak points"]
  G --> H["Update Mentor memory"]
  H --> I["Append DailyNotes trace"]
```

## Interview-Oriented Output

Each interview topic should eventually produce at least one of:

- a 60-second answer
- a deep-dive answer
- a comparison table
- a small code example
- a failure-case explanation
- a set of common traps
- 5 basic questions and 5 advanced questions

## Operating Principle

The system should optimize for usable mastery, not beautiful notes.

The right question is not "has this been saved?" but:

- Can the learner explain it?
- Can the learner answer interview variants?
- Can the learner solve a related exercise?
- Can the learner notice the old mistake next time?
- Can the learner use it in a real project?
