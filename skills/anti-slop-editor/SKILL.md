---
name: anti-slop-editor
description: Edit prose so it stops sounding AI-generated — removes filler, hedging, stock phrases ("delve", "in today's fast-paced world", "it's important to note"), em-dash overuse, triplet lists, fake enthusiasm and empty summaries, while keeping the author's meaning and voice. Use whenever someone asks to "de-AI", "humanize", "make this sound less like ChatGPT", "tighten", "cut the fluff", or edit a blog post, LinkedIn post, cover letter, README, email or essay that reads generic — even if they just say "make this better".
---

# Anti-slop editor

Make writing sound like a specific person wrote it on purpose. The goal is not "sound human" by adding typos or slang — it's to remove the patterns that signal *nobody decided anything here*.

## How to edit

1. **Read the whole piece first.** Figure out what the author is actually claiming. Slop is usually a symptom of a missing point; if the point is missing, say so rather than polishing around it.
2. **Cut, then fix.** Most of the improvement comes from deletion. Remove a sentence and see if anything was lost.
3. **Keep the voice.** If the author writes casually, stay casual. If they use British spelling, keep it. Don't swap their vocabulary for yours.
4. **Preserve facts exactly** — numbers, names, links, technical terms, quotes. Never invent specifics to make prose "concrete"; if a claim needs an example the author didn't give, mark it `[example?]`.
5. **Don't resolve ambiguity by guessing.** If the original is vague about the actual news ("a new journey": leaving? promoted? new team?), keep a placeholder for it (`[the news: new role at X / leaving Y?]`) and ask in one line. Don't pick one reading and write it as fact. The same goes for feelings and outcomes the author never stated ("I'm proud of…", "I learned so much…").
   Placeholders are only for facts that are genuinely missing. Never use one in place of something the author actually said: rewrite their sentences instead of deleting them. If they asked to keep the length, the edited text without placeholders should still be within about 20% of the original.
6. **Don't swap one tell for another.** Replacing "thrilled to share" with "Some news:" or "Big update:" is still a template opener. Start with the fact itself.

## What to look for

Read `references/patterns.md` for the full catalogue with before/after examples. The big ones:

- **Throat-clearing openers**: "In today's rapidly evolving landscape…", "Let's dive in", "Great question!" → start with the point.
- **Hedge stacks**: "It's worth noting that this can potentially help…" → "This helps…" (or delete if it doesn't).
- **Stock vocabulary**: delve, tapestry, testament, leverage (as verb for "use"), robust, seamless, unlock, elevate, navigate the complexities, game-changer, crucial/pivotal.
- **Reflexive triplets**: "fast, reliable, and scalable" when only one was argued for.
- **"It's not X, it's Y"** constructions used for drama rather than a real contrast.
- **Em-dash confetti**: more than ~1 per paragraph. Use commas, colons, or full stops.
- **Summary echoes**: closing paragraphs that restate the intro ("In conclusion…", "Ultimately…"). Delete or replace with the one thing the reader should do next.
- **Fake engagement**: "Thoughts? 👇", "Let that sink in.", emoji bullets in professional writing.
- **Uniform rhythm**: every sentence the same length. Vary it — a short one lands harder after two long ones.

## Output

Default: return the edited text, then a short **"What changed"** list (3–6 bullets, the categories of edits — not a line-by-line diff). If the user wants a diff, or the text is long and only partly sloppy, show changed passages as before → after instead.

If the user asks for a score, give a 1–10 "slop score" before and after with one sentence of justification each. Don't volunteer scores otherwise.

## When not to edit heavily

Legal text, quoted material, API docs with required phrasing, and anything where the user says "light touch". For those, flag issues and fix only the clear ones. "Light touch" means keeping the author's sentence structure and every non-slop piece of information. For example, "for VoIP developers" tells the reader who it's for, so keep it in plain words rather than deleting it with the hype around it.
