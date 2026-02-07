# Feature Implementor

You are implementing features for BigFace, a simple video calling app for seniors. Work through features one at a time, following the specs exactly.

## Configuration

```
EXIT_SCRIPT: .claude/ralph/bin/kill-claude
```

## Project Context

- **Data model**: See `docs/agents/data-model.md`
- **Features**: See `docs/agents/ralph/features/`
- **Progress**: See `docs/agents/ralph/progress.md`
- **Rails conventions**: See `.claude/rules/rails.md`

## Running Things

```bash
# Start the app
bin/dev

# Run all tests
bin/rails test

# Run specific test file
bin/rails test test/models/user_test.rb

# Run system tests
bin/rails test:system

# Run full CI (tests, lint, security)
bin/ci
```

## Workflow

### 1. Check Progress

Read `docs/agents/ralph/progress.md` to see:
- What's been done
- What to work on next
- Any notes from previous sessions

### 2. Pick a Feature

Choose from `docs/agents/ralph/features/`. Pick a `.md` file (not `.md.done`) whose dependencies are satisfied.

If unclear which to pick, check `progress.md` for suggestions.

### 3. Implement the Feature

Read the feature spec thoroughly. It contains:
- Description of the behavior
- Models/data involved
- Test descriptions
- Implementation notes
- Dependencies

Implement:
1. Write tests first (based on spec's test descriptions)
2. Write code to make tests pass
3. Run tests to verify

### 4. Verify

Run the full test suite. All tests must pass before proceeding.

```bash
bin/rails test
```

### 5. QA Review (REQUIRED)

**A feature CANNOT be marked as done unless QA approves it.**

After tests pass, call the QA agent:

```
/agent ralph-qa
```

Wait for QA to complete. The QA agent will review your implementation and either:
- **APPROVE**: You may proceed to commit and mark complete
- **FAIL**: You must fix the issues and re-run QA

**If QA fails:**
1. Read the QA feedback carefully
2. Fix all issues identified
3. Run tests again
4. Re-run the QA agent
5. Repeat until QA approves

Do NOT proceed to commit until QA has approved the implementation.

### 6. Commit

Commit your changes with a clear message describing the feature:

```bash
git add -A
```

Then commit (separate command):

```bash
git commit -m "Implement [feature-name]"
```

### 7. Mark Complete

When feature is done, tests pass, and **QA has approved**:

1. Rename the feature file:
   ```bash
   mv docs/agents/ralph/features/XX-feature-name.md docs/agents/ralph/features/XX-feature-name.md.done
   ```

2. Update `docs/agents/ralph/progress.md`:
   - Add entry to Session History
   - Update Current State
   - Suggest next feature

### 8. Exit

**ONLY after QA has approved and the feature is marked complete**, exit by running:

```bash
.claude/ralph/bin/kill-claude
```

The loop will restart you with fresh context.

**NEVER call the exit script if you are blocked or have problems.** Use `AskUserQuestion` instead.

## Rules

### Do

- Follow the spec exactly
- Write tests based on the spec's test descriptions
- Use `AskUserQuestion` if something is unclear or blocking
- Update progress.md with useful notes for future sessions
- Exit after each feature (keeps context fresh)
- Follow `.claude/rules/rails.md` conventions

### Don't

- Change test assertions without asking first
- Skip tests
- Implement features out of dependency order
- Stay in one session for multiple features (exit and restart)
- Exit without updating progress.md
- Exit when blocked - use `AskUserQuestion` instead
- Mark a feature complete without QA approval
- Skip QA or proceed after QA failure without fixing issues
- Add comments to code
- Leave trailing whitespace

## If Blocked

If you can't proceed:
1. Use `AskUserQuestion` to ask the human
2. Document the blocker in progress.md
3. Wait for the human to respond - do NOT exit

## Session Notes Format

When updating progress.md, use this format:

```markdown
### Session [DATE]

**Feature**: [feature-name]
**Status**: Completed | Blocked | In Progress

**What was done**:
- [bullet points]

**Notes for next session**:
- [anything important to know]
```
