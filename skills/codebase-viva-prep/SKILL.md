---
name: codebase-viva-prep
description: Prepare someone to defend or explain a codebase they built or inherited — for a university project viva, thesis defense, technical interview take-home review, demo day, or handover. Builds an architecture walkthrough grounded in the actual code, predicts the questions an examiner or interviewer will ask (with model answers citing file:line), runs a mock viva one question at a time, and assigns small hands-on modification tasks examiners like to ask for live ("add a field", "change this validation"). Use whenever someone says viva, defense, project evaluation, "explain my project", "what will they ask me", "help me prepare to present my code", interview walkthrough, or "I don't fully understand the code I wrote with AI".
---

# Codebase viva prep

Examiners don't check whether code runs — they check whether *you* understand it. They ask "why", "what if", and "show me where". This skill builds that understanding from the real code, then rehearses it.

## 0. Set the scene (ask briefly, then proceed)
- What's the occasion (university viva, interview, handover) and how long is it?
- Any rubric, problem statement, or list of required features? Read it if provided — examiners follow it.
- Which parts did they write themselves vs. use AI or templates for? Weak spots get more practice.
- When is it? (Sets how much to cover per session.)

## 1. Map the codebase
Read the code — entry points, config, models/schema, routes/API, core business logic, background jobs, frontend structure, tests. Produce a **one-page map**:
- Tech stack and *why each piece is there* (examiners love "why Redis?" / "why Celery?")
- Directory layout with one line per important folder
- A Mermaid diagram of the main request flow (e.g. browser → API → service → DB → cache → job queue)
- Data model: entities and relationships (ER-style list or Mermaid `erDiagram`)
- The 3–5 features most likely to be demoed, with the files that implement each

## 2. Deep-dive walkthroughs
For each important feature, walk through **one concrete request end-to-end** with `file:line` references: what the user does → which route → validation → business logic → DB queries → response → frontend update. Explain non-obvious lines. Keep each walkthrough short enough to re-read the night before.

## 3. Predict the questions
Write a question bank grouped by type, each with a concise model answer citing code:
- **Design "why"**: Why this framework/DB/auth method? Why is this logic in the backend not the frontend?
- **"What if"**: What if two users book the last slot simultaneously? What if the job queue is down? What if the token expires mid-session?
- **"Show me where"**: Where is the password hashed? Where is role-based access enforced? Where is caching invalidated?
- **Security**: SQL injection, XSS, CSRF, authorization checks on every endpoint, secrets in code.
- **Trade-offs and limits**: What doesn't scale? What would you change with more time?
- **Live modification** (see step 5)

Flag honestly where the code has a weakness an examiner could find (missing authorization check, N+1 query, no input validation) — better to fix it or have an answer ready than be surprised.

## 4. Mock viva
Ask questions **one at a time** and wait. Mix difficulties; follow up on vague answers the way an examiner would ("and where exactly is that enforced?"). After each answer: brief verdict, what a strong answer would add, the `file:line` to revisit. Track weak areas and come back to them later in the session.

## 5. Live-modification practice
Examiners often say "change X right now". Assign 3–5 small tasks graded by difficulty, e.g.:
- Add a new field to a model and show it in the UI
- Change a validation rule and its error message
- Add a filter/sort to a list endpoint
- Add a role check to an endpoint
Let the user attempt each themselves; give hints, not solutions, unless asked. Afterwards, review their diff. If they ask you to make the change, make it — but in a **branch or copy**, and never touch real databases or user data while testing.

## 6. Leave behind
A `VIVA_PREP.md` (if they want a file) with: the map, the walkthroughs, the question bank with answers, and a "weak spots to revise" list from the mock viva. Keep it skimmable.

Respect academic rules: if the user mentions parts where AI help is not allowed, don't write that code for them — explain and quiz instead.
