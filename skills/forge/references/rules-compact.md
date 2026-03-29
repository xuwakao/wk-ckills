[/forge workflow rules — periodic refresh]

1. SELF-MONITORING: Re-read the active plan file before each phase. If unsure about rules, re-read SKILL.md at ${CLAUDE_PLUGIN_ROOT}/skills/forge/SKILL.md.

2. CONTINUOUS EXECUTION: Do not pause, do not ask "shall I continue?", do not explain next steps — execute them. Only stop if user interrupts (ESC/Ctrl+C) or explicitly requests pause.

3. PHASED DEVELOPMENT: Follow META-PHASE A→B→C→D. CRITICAL — every review must produce a named artifact:
   - Plan Review (META-PHASE B): write "### Plan Review" checklist in progress with PASS/FAIL/RISK per item. One-line "no changes needed" is NEVER acceptable.
   - Phase Review (C.3): write "### Review: Phase N" in progress with expected-vs-actual comparison, evidence, and PASS/FAIL verdict. A phase without this entry CANNOT be marked COMPLETE.
   Plan corrections during execution are append-only (mark old as [DEPRECATED], create new, cross-reference).

4. FUNCTIONAL ACCEPTANCE: After each phase — compile/build, compare results against plan expectations. PASS → continue. FAIL → record issue, enter debugging.

5. DEBUGGING DISCIPLINE: No workarounds. Diagnose root cause before fixing (exception: debug logs). Fix process follows principles 3+4 (plan fix → review → execute → verify + regression). Escalation: 3 failed fixes → change strategy; 5 failed plans → full re-evaluation; N similar issues → check broader scope systemically.

6. DOCUMENTATION: Update docs/progress/ and docs/issue/ continuously. Formal technical language only. All claims require verifiable sources. Mark unverified content [UNVERIFIED]. Use /git-commit for commits.

7. AUTONOMOUS PLANNING: When current phases complete or no next task is specified, scan docs/ for unresolved issues, blocked tasks, unverified findings. Prioritize by blocking severity and impact. Create new plan and continue.
