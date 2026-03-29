# wk-ckills

A collection of custom [Claude Code](https://claude.ai/claude-code) skills.

## Skills

### `/forge` — Rigorous Development Workflow

A phased development workflow skill designed for high-accuracy projects. Enforces strict planning, execution discipline, debugging rigor, and documentation tracking throughout the entire development lifecycle.

#### Core Principles

| # | Principle | Enforcement |
|---|-----------|-------------|
| 1 | **Self-Monitoring** | `PreToolUse` hook injects rules every 10 tool calls; blocks if docs not maintained |
| 2 | **Continuous Execution** | `Stop` hook blocks premature stopping; user interrupts via ESC/Ctrl+C |
| 3 | **Phased Development** | META-PHASE A→B→C→D: plan → review → execute → accept |
| 4 | **Functional Acceptance** | Compile/verify after each phase; deviations become tracked issues |
| 5 | **Debugging Discipline** | No workarounds; diagnose root cause first; escalation protocol (3/5/N thresholds) |
| 6 | **Documentation** | Formal language; verifiable sources; append-only during execution; cross-referenced findings |
| 7 | **Autonomous Planning** | Auto-scans unresolved issues and unverified findings to plan next task |

#### Workflow

```
/forge <task description>
  │
  ├─ Bootstrap: creates docs/{plan,progress,issue}/
  ├─ META-PHASE A: plan with alternatives & trade-offs
  ├─ META-PHASE B: review plan (direct edits allowed)
  ├─ META-PHASE C: for each phase:
  │    ├─ execute → review → functional acceptance
  │    ├─ FAIL → issue tracking → debug (follows same plan/review/accept cycle)
  │    └─ PASS → next phase
  ├─ META-PHASE D: final review, mark completed
  └─ RULE 7: assess state, auto-plan next task
```

#### Documentation Structure

The skill creates and maintains a `docs/` directory in the target project:

```
docs/
├── plan/<name>.md      — phased plans with expected results
├── progress/<name>.md  — chronological execution logs
└── issue/<name>.md     — defect tracking with diagnosis
```

All documents support a cross-referencing system (`[plan/<name>#PhaseN]`, `[issue/<name>#ISS-NNN]`) and a **Findings** mechanism (`[F-NNN]`) for recording discoveries across any document type.

## Installation

```bash
# In Claude Code, add the marketplace and install:
/plugin marketplace add /path/to/wk-ckills
/plugin install wk-ckills@wk-ckills
/reload-plugins
```

Or for development/testing:

```bash
claude --plugin-dir /path/to/wk-ckills
```

## Project Structure

```
wk-ckills/
├── .claude-plugin/
│   ├── plugin.json              # Plugin metadata
│   └── marketplace.json         # Marketplace config
├── hooks/
│   └── hooks.json               # Plugin-level hooks (PreToolUse + Stop)
└── skills/
    └── forge/
        ├── SKILL.md             # Main skill definition (7 rules)
        ├── hooks-handlers/
        │   ├── pre-tool-use-guard.sh   # L1: rules injection + L2: docs monitoring
        │   └── stop-guard.sh           # L4: stop blocking for active plans
        ├── scripts/
        │   ├── init-docs.sh            # Bootstrap docs/ structure
        │   └── check-doc-format.sh     # Documentation validation
        ├── templates/
        │   ├── plan.md                 # Plan document template
        │   ├── progress.md             # Progress log template
        │   └── issue.md               # Issue tracker template
        └── references/
            └── rules-compact.md        # Compact rules for periodic injection
```

## License

MIT
