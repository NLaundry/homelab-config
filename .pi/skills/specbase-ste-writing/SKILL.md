---
name: specbase-ste-writing
description: Write prose in Simplified Technical English: short active sentences, no marketing adjectives, no banned complex words. Apply whenever writing or revising READMEs, skill docs, generated agent docs, or CLI copy.
allowed-tools: Bash(specbase:*)
license: MIT
compatibility: Requires specbase CLI.
metadata:
  author: specbase
  version: "1.0"
  generatedBy: "1.6.0"
---

Write in Simplified Technical English (STE, ASD-STE100). STE is the
controlled-language standard that keeps prose short, active, and unambiguous.

**Trigger**: apply this skill whenever you WRITE or REVISE prose — READMEs, skill
docs, generated agent docs, CLI copy, design notes, or any text a human or agent
will read. Do not wait to be asked.

## The rules

- **Short active sentences.** One topic per sentence. Prefer the active voice:
  "the CLI prints the report", never "the report is printed by the CLI".
- **No marketing adjectives.** Drop words like *seamless*, *robust*, *powerful*,
  *cutting-edge*, *effortless*, *world-class*, *state-of-the-art*,
  *game-changing*, *first-class*. Say what the thing does, do not grade it.
- **No banned complex words.** Prefer the plain equivalent: *begin* for
  "commence", *use* for "utilize"/"leverage", *make sure* for "ensure",
  *before* for "prior to", *get* for "obtain", *also* for "additionally".
- **No phrasal-verb slop.** Say "start", not "kick off"/"spin up"; say "remove",
  not "tear down"; say "distribute", not "roll out".
- **No modal hedging.** Never write "it is important to note that" or "please
  note that"; just state the thing.
- **Few passives and nominalizations.** Prefer the verb: "the committee decided",
  not "a decision was made by the committee" or "the committee made a decision".
- **No em-dash slop.** Prefer two short sentences or a comma over an em dash.

## How to check your work

Run the linter over what you wrote and drive its counts to the project's gate:

```bash
specbase ste-lint <the files you wrote>
specbase ste-lint <files> --max <threshold>   # the gate; exit non-zero if over
```

The report separates **errors** (banned words, marketing adjectives) from
**warnings** (long sentences, passives, em-dash slop). Fix the errors first,
then the warnings that matter. The gate counts `total_per100w`; use the threshold
specified by the invoking task. Do not invent a permanent threshold when no
Governance pair declares one.
