# Subagent Usage Guide

This guide explains when, where, and how to use subagents to preserve context and improve efficiency in Claude Code workflows.

---

## Overview

**Subagents** are specialized Claude instances spawned via the `Task` tool that handle specific tasks independently. They:
- Have their own context window (don't consume main context)
- Return a summary to the main conversation
- Can use different models (Haiku for quick tasks, Sonnet for complex ones)

**Key Principle**: Use main context for decisions and implementation; delegate reading/searching to subagents.

---

## Available Subagent Types

| Type | Purpose | Tools Available |
|------|---------|-----------------|
| `Explore` | Codebase exploration, file search, context gathering | Glob, Grep, Read, WebFetch, WebSearch |
| `general-purpose` | Complex multi-step research tasks | All tools |
| `Plan` | Architecture and implementation planning | All read tools |
| `Bash` | Command execution | Bash only |

---

## When to Use Subagents

### Use Subagents For:

| Situation | Agent Type | Why |
|-----------|------------|-----|
| Reading large docs (ROADMAP, features) | Explore | Don't bloat main context with full docs |
| Searching SOPs for patterns | Explore + Haiku | Quick lookup, minimal cost |
| Exploring codebase before planning | Explore | Lossy summary preserves main context |
| Complex research across files | general-purpose | Full tool access with context inheritance |
| Finding specific code patterns | Explore | Parallel searches more efficient |

### Don't Use Subagents For:

| Situation | Why Not |
|-----------|---------|
| Reading a specific known file | Direct Read tool is faster |
| Simple single-file edit | Overhead not worth it |
| Quick question about visible code | Context already loaded |
| Tasks requiring conversation context | Subagents don't see prior messages |

---

## Where to Use in Workflow

### /feature Command

Use Explore subagent to read ROADMAP.md and extract relevant items:

```markdown
## Step 1: Gather Context (via Subagent)

Use the Task tool with subagent_type="Explore" and model="haiku":
- Prompt: "Read .agent/ROADMAP.md and extract items related to [feature description]. Return:
  - Matching roadmap item IDs (R1.1, R2.3, etc.)
  - Their descriptions
  - The phase they belong to"
- This preserves main context for requirements gathering.
```

### /plan Command

Use Explore to understand codebase before task breakdown:

```markdown
## Step: Analyze Codebase (via Subagent)

Use Task tool with subagent_type="Explore":
- Prompt: "Analyze the codebase structure for [feature area]:
  - List relevant files in src/
  - Identify patterns used for similar features
  - Note any existing code that can be reused"
```

### /workflow:implement-task

Use Explore to find related code patterns:

```markdown
## Step: Find Related Code (via Subagent)

Use Task tool with subagent_type="Explore":
- Prompt: "Find examples of [pattern] in the codebase:
  - How is authentication handled?
  - What's the error handling pattern?
  - Where are similar components defined?"
```

### SOP Lookups

Use Haiku + Explore for quick rule lookups:

```markdown
## Quick SOP Lookup

Use Task tool with subagent_type="Explore" and model="haiku":
- Prompt: "Read ~/.claude/workflow/sops/git-workflow.md and extract:
  - The commit message format
  - Rules for PR creation"
```

---

## How to Use Subagents

### Basic Pattern

```markdown
Use the Task tool:
- subagent_type: "Explore"
- model: "haiku" (for quick tasks) or "sonnet" (for complex)
- prompt: "Clear, specific task description"
```

### Prompt Writing Tips

**Be Specific**:
```
# Good
"Read .agent/features/001-sidebar/README.md and extract:
- Acceptance criteria list
- User stories marked as High priority"

# Bad
"Read the feature doc"
```

**Request Structured Output**:
```
# Good
"Return a JSON object with:
- files: array of relevant file paths
- patterns: object mapping pattern name to example"

# Bad
"Tell me about the code"
```

**Limit Scope**:
```
# Good
"Search src/components/ for Button component usage"

# Bad
"Search the entire codebase for all component usage patterns"
```

### Example: Explore Agent Call

```javascript
// In command logic:
Task({
  subagent_type: "Explore",
  model: "haiku",
  prompt: `Read .agent/ROADMAP.md and find items matching "${featureDescription}".

Return:
- matching_items: list of {id, title, description, phase}
- suggested_phase: which phase this likely belongs to
- related_items: other items that might be related`,
  description: "Find roadmap items"
})
```

---

## Context Preservation Strategy

### Main Context Budget

| Content | Budget |
|---------|--------|
| Conversation history | ~50% |
| Current working files | ~30% |
| Tool outputs | ~15% |
| System prompts | ~5% |

### Offload to Subagents

| Task | Main Context Cost | With Subagent |
|------|-------------------|---------------|
| Read 10-file feature doc | ~5000 tokens | ~200 tokens (summary) |
| Search 50 files | ~10000 tokens | ~300 tokens (results) |
| Read all SOPs | ~3000 tokens | ~150 tokens (relevant rules) |

### When to Compact

Use `/compact` at ~60% context usage. Subagents help delay this by keeping main context lean.

---

## Model Selection

### Use Haiku When:
- Quick file reads
- Simple searches
- Pattern matching
- SOP lookups
- Costs: ~5x cheaper than Sonnet

### Use Sonnet When:
- Complex analysis needed
- Multiple reasoning steps
- Code understanding required
- Default if unsure

### Use Opus When:
- Critical decisions
- Complex architecture questions
- Nuanced analysis

---

## Parallel Subagents

Launch multiple subagents simultaneously for independent tasks:

```markdown
## Parallel Context Gathering

Launch these searches in parallel:

1. Task(subagent_type="Explore", prompt="Find all API endpoints in src/routes/")
2. Task(subagent_type="Explore", prompt="Find authentication middleware usage")
3. Task(subagent_type="Explore", prompt="Find database schema files")

Wait for all results, then synthesize.
```

---

## Background Agents

For long-running tasks, use `run_in_background: true`:

```javascript
Task({
  subagent_type: "general-purpose",
  run_in_background: true,
  prompt: "Comprehensive analysis of test coverage...",
  description: "Analyze test coverage"
})

// Continue working, check results later with Read on output_file
```

---

## Common Patterns

### Pattern 1: Context Gathering Before Action

```markdown
1. Use Explore subagent to gather context
2. Receive summary in main context
3. Make decisions based on summary
4. Implement with full main context available
```

### Pattern 2: Parallel Search

```markdown
1. Launch multiple Explore agents in parallel
2. Each searches different aspect
3. Synthesize results
4. Proceed with comprehensive understanding
```

### Pattern 3: Iterative Refinement

```markdown
1. Quick Haiku search for initial results
2. Based on results, targeted Sonnet search
3. Final implementation with precise context
```

---

## Integration with Hooks

Hooks and subagents serve different purposes:

| Need | Use Hooks | Use Subagents |
|------|-----------|---------------|
| Inject < 1000 tokens | ✓ | |
| Read large documents | | ✓ |
| Static context | ✓ | |
| Dynamic analysis | | ✓ |
| Every prompt | ✓ | |
| Specific commands | ✓ | ✓ |

**Combined approach**:
- Hooks inject minimal overview (< 500 tokens)
- Subagents fetch detailed context when needed

---

## Best Practices

### DO:
- Use Explore for codebase searches
- Use Haiku for quick lookups
- Request structured output
- Launch parallel agents for independent tasks
- Keep prompts specific and scoped

### DON'T:
- Use subagents for known file reads
- Spawn agents for tiny tasks
- Forget to specify model for cost optimization
- Request unbounded searches
- Ignore returned summaries

---

## Troubleshooting

### Agent Takes Too Long
- Reduce search scope
- Use more specific patterns
- Consider if direct Read is better

### Results Too Verbose
- Request summarized output
- Specify output format
- Limit number of items returned

### Missing Context
- Agent doesn't see conversation history
- Include all necessary context in prompt
- Use "general-purpose" for inherited context

---

## Quick Reference

```markdown
# Quick file read (use Haiku)
Task(subagent_type="Explore", model="haiku", prompt="Read X and extract Y")

# Codebase search (use Sonnet)
Task(subagent_type="Explore", prompt="Find all files matching X pattern")

# Complex analysis
Task(subagent_type="general-purpose", prompt="Analyze X considering Y and Z")

# Background task
Task(subagent_type="general-purpose", run_in_background=true, prompt="Long analysis...")
```
