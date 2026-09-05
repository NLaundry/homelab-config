# Agent instructions

- Solve the current problem with the smallest understandable change. Do not build for hypothetical future needs.
- Before non-trivial work, briefly explain the approach, real risks, and relevant checks. A chat plan is normally enough.
- Prefer existing tools and direct code over new frameworks, registries, or wrappers.
- Write comments in Simplified Technical English: one short sentence per comment that explains why or how, with no unexplained jargon. Remove comments that only repeat the code; preserve required tool directives.
- Give runbooks short action headings and numbered substeps so operators can skim the procedure without missing checks or recovery steps.
- Test meaningful behavior and failure risks. Do not copy documentation or incidental configuration values into tests.
- No new test is a valid outcome when existing checks suffice. Test verification helpers only where failure could hide an operational fault or harm live state.
- Specs preserve important intent and constraints. Use OpenSpec workflows only when explicitly requested; do not automatically recreate retired evidence bookkeeping or conformance machinery.
- Question unnecessary tasks in an existing plan rather than implementing them mechanically.
- Report what was checked and what remains uncertain. Do not imply that evaluation, VM tests, or live health checks prove more than they do.
- Never activate a host, reboot it, or run state-changing live probes without the user's authorization.
