# Agent-Friendly CLI — SOP Checklist

Complete Phase 1 before writing any code. Phases 2–4 are implementation and review.

---

## Phase 1: Design Contract (pre-implementation)

### 1.1 Command Taxonomy

Fill this table and confirm before writing any command:

| Command | Type | Aliases | Notes |
|---------|------|---------|-------|
| `<resource> list` | subcommand | `ls` | |
| `<resource> get <id>` | subcommand | | |
| `<top-level>` | top-level | | single-action resource |

Rules:
- [ ] Top-level for single-action resources; subcommand group when multiple actions
- [ ] Every `list` has `ls` alias
- [ ] Names match API terminology — no CRUD genericization
- [ ] Deprecated/hidden names listed and marked

### 1.2 Output Samples

Produce and confirm before writing any formatter:

- [ ] Human list output sample (blank-line-separated blocks — see Phase 2)
- [ ] Single-item get output sample (key-value)
- [ ] Tree output sample (if hierarchical data exists)
- [ ] Empty state output (what prints when list is empty)

### 1.3 Behavior Semantics

Answer before coding:

- [ ] Multi-value filter (e.g. `--tags a,b`): AND or OR?
- [ ] Default filter scope per list command (e.g. incomplete-only, last 30 days)?
- [ ] Empty result: silent exit 0 or print a message?
- [ ] Detail hint wording: `Use "<cli> <get-cmd> <id>" for details.`

---

## Phase 2: Output Format

### Human list output

```
<status> <title>
<id>
Area: x  |  Project: y    ← omit entirely if both empty
Tags: a | b | c            ← omit if no tags
Deadline: date             ← omit if no deadline

<next item>

Use "<cli> <get-cmd> <id>" for details.
```

- [ ] Blank-line-separated blocks — no TSV tables, no column alignment
- [ ] Status symbols: `[ ]` incomplete, `[x]` completed, `[-]` canceled
- [ ] Title full-width on first line
- [ ] ID on its own line immediately below title
- [ ] Secondary lines omitted when empty (no blank placeholders)
- [ ] Footer hint on last line of every non-empty list

### Human get output (single item)

```
id       abc123
title    Example task
status   incomplete
project  My Project
tags     work, urgent
```

- [ ] Key-value via aligned tabwriter
- [ ] Empty fields omitted entirely

### Tree output (hierarchical data)

```
[id] Root  (shortcut)
├── [id] Child
│   ├── [id] Grandchild
│   └── [id] Last grandchild
└── [id] Last child
```

- [ ] `├──` for non-last siblings, `└──` for last
- [ ] `│   ` under non-last parents, `    ` under last parents
- [ ] ID in brackets for every node
- [ ] Shortcut/secondary label in parentheses if present

### `--plain` output (scripting)

- [ ] Full tab-separated rows, no headers
- [ ] All fields included, IDs always present
- [ ] Column order stable across releases

### `--json` output

- [ ] Valid JSON, indented
- [ ] `--jq` via embedded gojq — never shell out
- [ ] `--json` and `--plain` mutually exclusive
- [ ] `--jq` requires `--json`

### General

- [ ] Hints, warnings, progress → stderr only
- [ ] No spinners or progress bars on stdout

---

## Phase 3: Help System

### Directory structure

```
docs/help/
├── embed.go          # package helpdocs; //go:embed topics/*.md
├── topics/
│   ├── exit-codes.md # required
│   └── <topic>.md
└── errors/           # add when named error codes are defined
    └── <code>.md
```

- [ ] `embed.go` uses `//go:embed topics/*.md` (no `../` in embed paths)
- [ ] `exit-codes.md` exists and matches exit codes in `root.go`

### Root `--help` HELP TOPICS block

```
HELP TOPICS
  exit-codes      Exit code reference
  <topic>         One-line description

Use "<cli> help <topic>" for more information about a topic.
```

- [ ] Block appears in root `--help` after flags
- [ ] Topics auto-populated from filenames in `docs/help/topics/`
- [ ] Each description is the first non-heading line of that file

### `help` command routing (in this order)

1. `errcode-<code>` → `errors/<code>.md`
2. Topic name → `topics/<topic>.md`
3. Subcommand name → Cobra command help
4. Unknown → non-zero exit + list of available topics

- [ ] Output is raw markdown to stdout — no rendering, no paging

### Topic file template

```markdown
# <Topic Name>

<One-sentence TL;DR.>

## Overview
## Commands
## Constraints
## Examples
## Related Topics   ← optional
```

- [ ] Every topic has a `## Constraints` section
- [ ] Constraints describe user-observable behavior only
- [ ] No backend names in help text (URL Scheme, AppleScript, SQLite, etc.)
- [ ] ✓ "Delete requires macOS and Things to be running"
- [ ] ✗ "URL Scheme cannot delete" (implementation detail)

### Error code topics (when error codes are defined)

```markdown
# Error <code>: <Short Name>

<One-sentence description.>

## Cause
## Resolution
```

Accessible via `<cli> help errcode-<code>`.

---

## Phase 4: Golden Snapshot Tests

Output format changes must be explicit decisions, not silent side effects.

- [ ] Snapshot for root `--help` output
- [ ] Snapshot for at least one human list output
- [ ] Snapshot for tree output (if hierarchical resource exists)
- [ ] Snapshot for empty state output
- [ ] Snapshot for `help <topic>` (valid topic)
- [ ] Snapshot for `help <unknown>` (exits non-zero, lists topics)
- [ ] `-update` flag convention to regenerate snapshots
- [ ] Snapshot changes require snapshot file update in same commit
