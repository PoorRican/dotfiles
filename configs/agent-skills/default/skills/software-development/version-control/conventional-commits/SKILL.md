---
name: conventional-commits
description: Commit changes in a git workspace using the Conventional Commits specification. Use when the user asks to commit, stage, or save changes to git, or mentions "conventional commits". Analyzes staged/unstaged changes, groups related modifications, generates properly formatted commit messages, and commits files separately or together as appropriate. Confirms with user when commit ordering is ambiguous.
---

# Conventional Commits

Commit git changes using the [Conventional Commits v1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) specification.

## Commit Message Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

## Commit Types

| Type | Description | SemVer |
|------|-------------|--------|
| `feat` | New feature | MINOR |
| `fix` | Bug fix | PATCH |
| `docs` | Documentation only | - |
| `style` | Formatting, whitespace (no code change) | - |
| `refactor` | Code restructuring (no feature/fix) | - |
| `perf` | Performance improvement | - |
| `test` | Adding/updating tests | - |
| `build` | Build system or dependencies | - |
| `ci` | CI configuration | - |
| `chore` | Maintenance tasks | - |
| `revert` | Reverting commits | - |

**Breaking changes**: Add `!` after type/scope (e.g., `feat!:` or `feat(api)!:`) or include `BREAKING CHANGE:` footer.

## Workflow

1. **Analyze workspace state**
   ```bash
   git status
   git diff --stat
   git diff --staged --stat
   ```

2. **Review actual changes** for each modified file to understand the nature of changes:
   ```bash
   git diff <file>        # unstaged
   git diff --staged <file>  # staged
   ```

3. **Group changes logically**
   - **Separate commits** (default): Each distinct change gets its own commit
   - **Combined commits**: Only when changes are tightly coupled and make no sense apart
   
   Examples of separate commits:
   - Adding a feature + updating docs → 2 commits
   - Fixing bug A + fixing bug B → 2 commits
   - Refactoring module X + adding tests → 2 commits
   
   Examples of combined commits:
   - Feature code + its unit tests (if tests only make sense with the feature)
   - Migration file + model changes (if they're atomic)

4. **Determine commit order**
   - Infrastructure/build changes first
   - Core functionality before dependent features
   - Tests can go with or after the code they test
   - Documentation typically last
   
   **When order is ambiguous**: Ask the user before proceeding.

5. **Stage and commit each group**
   ```bash
   git add <files>
   git commit -m "<type>[scope]: <description>"
   ```

## Writing Good Commit Messages

**Description (first line)**:
- Use imperative mood: "add feature" not "added feature"
- No period at end
- Under 72 characters
- Be specific: "fix null pointer in user auth" not "fix bug"

**Scope** (optional):
- Module, component, or area affected
- Examples: `feat(auth):`, `fix(parser):`, `docs(readme):`

**Body** (when needed):
- Explain *what* and *why*, not *how*
- Wrap at 72 characters
- Separate from description with blank line

**Footer** (when needed):
- `BREAKING CHANGE: <description>` for breaking changes
- `Refs: #123` for issue references
- `Reviewed-by: Name` for attribution

## Examples

```bash
# Simple feature
git add src/auth/oauth.py
git commit -m "feat(auth): add OAuth2 support for Google login"

# Bug fix with scope
git add lib/parser.js
git commit -m "fix(parser): handle empty arrays in JSON input"

# Docs only
git add README.md
git commit -m "docs: add installation instructions for Windows"

# Breaking change
git add api/v2/
git commit -m "feat(api)!: redesign user endpoints for v2

BREAKING CHANGE: /users endpoint now requires authentication.
Old endpoint /users/list is removed, use /users instead."

# Refactor with body
git add src/utils/
git commit -m "refactor(utils): extract date formatting to separate module

Moved date formatting logic from multiple components into
a centralized utils/dates.py module to reduce duplication
and ensure consistent formatting across the application."
```

## Handling Ambiguity

Ask the user when:
- Multiple unrelated changes exist and commit order matters for history
- Changes span features that could be atomic or separate
- It's unclear whether changes are one logical unit or multiple

Example prompt:
> I see changes to the auth module and the API routes. Should I:
> 1. Commit them separately (auth first, then routes)?
> 2. Commit them together as a single feature?
> 3. Different order?
