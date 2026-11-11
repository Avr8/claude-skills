# Slop patterns — catalogue with fixes

Each entry: the pattern, why it reads as slop, and a before → after.

## 1. Throat-clearing openers
Delays the point; signals the writer didn't know where to start.
- Before: "In today's fast-paced digital landscape, observability has become more important than ever."
- After: "We couldn't see why calls were dropping, so we added tracing."

## 2. Hedge stacks
Multiple qualifiers on one claim ("can potentially", "may help to", "it's worth noting"). Keep at most one hedge, and only when uncertainty is real.
- Before: "This approach can potentially help to somewhat reduce latency in many cases."
- After: "This cut p95 latency by 40 ms." / "This might reduce latency; we haven't measured it."

## 3. Stock vocabulary
Words that appear far more in model output than in human writing. Replace with plain words or delete.

| Slop | Plain |
|---|---|
| delve into | look at / cover |
| leverage (verb) | use |
| utilize | use |
| robust | (say what it survives) |
| seamless(ly) | (delete, or say what friction was removed) |
| a testament to | shows |
| tapestry / landscape / realm | (delete) |
| unlock / elevate / empower | (say the concrete effect) |
| navigate the complexities of | handle / deal with |
| pivotal / crucial / paramount | important (or delete) |
| embark on a journey | start |
| foster | build / encourage |
| boasts | has |

## 4. Reflexive triplets
Lists of three adjectives or clauses produced for rhythm, not content.
- Before: "Our platform is fast, secure, and scalable."
- After: "Our platform handles 10k calls/sec." (keep only the property you can back up)

## 5. "It's not X — it's Y"
Manufactured contrast. Keep only when X is a belief the reader actually holds.
- Before: "This isn't just a tool — it's a mindset."
- After: (delete)

## 6. Em-dash confetti
More than one em dash per paragraph. Swap for comma, colon, parentheses, or a new sentence.

## 7. Summary echo / empty conclusion
"In conclusion", "Ultimately", "At the end of the day", "By following these steps you'll be well on your way". Delete, or end with the single next action.

## 8. Fake engagement
"Let that sink in.", "Here's the thing:", "Thoughts? 👇", "Agree?", rocket/sparkle emoji, "🚀 Key takeaways:". Remove in professional contexts; on social posts keep at most one CTA that's a real question.

## 9. Over-signposting
"First, let's understand… Now that we've covered X, let's move on to Y." Headings already do this.

## 10. Abstract nouns instead of actors
- Before: "Implementation of the migration was carried out by the team."
- After: "We migrated it."

## 11. Uniform sentence length
Every sentence 15–20 words reads like a metronome. Mix in a short sentence. Break one long one.

## 12. Bolded everything
Bold at most one phrase per section — the thing a skimmer must not miss.

## 13. Sycophantic or performative tone
"Absolutely!", "Great question", "I hope this helps!", "Happy coding!" — cut.

## 14. Vague intensifiers
very, really, incredibly, extremely, truly, deeply. Delete; if the sentence collapses, it needed a fact, not an adverb.
