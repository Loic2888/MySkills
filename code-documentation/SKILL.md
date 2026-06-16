---
name: code-documentation
description: >
  Automatically documents an entire codebase by injecting inline comments directly into source files.
  Use this skill whenever the user asks to "document project X", "add documentation", "write docs for",
  "document this codebase", "add comments to", "generate documentation for", or any similar request
  about producing or improving code documentation. Triggers on any language (JS, TS, Python, C, Java,
  Go, Rust, PHP, Ruby, etc.). Never rewrites logic — only adds or updates comments. Covers all
  granularity levels: project overview (README), file/module headers, class headers, and per-function
  inline comments. Always writes documentation in plain English prose.
---

# Code Documenter Skill

Document an entire project by injecting inline comments directly into source files. Never rewrite
or alter any logic, imports, or code structure — only add or update documentation comments.

---

## Core Principles

1. **Never touch code** — Do not modify any logic, variable names, imports, or code structure.
   Only add or update documentation comments.
2. **Plain English prose** — No `@param` / `@returns` annotation-heavy style. Write clear,
   human-readable sentences describing what things do.
3. **Native comment syntax** — Use the comment style that is idiomatic for each language.
   See [Language Comment Syntax Reference](#language-comment-syntax-reference) below.
4. **All granularity levels** — Cover the full documentation pyramid: project → file → class → function.
5. **Generic across all languages** — Auto-detect language from file extension. Apply correct syntax.

---

## Step-by-Step Workflow

### Step 1 — Explore the project

Before writing a single comment, map the entire project:

```
1. List all files and directories (tree or find)
2. Identify: language(s) used, framework hints, entry points, config files
3. Note: which files are source code vs. config vs. assets vs. tests
4. Read the source files before starting to write documentation (see sampling strategy below)
```

**Check for a CLAUDE.md first.** If the project has a `CLAUDE.md` file, read it before anything
else. It is the authoritative source for the project's purpose, architecture, conventions, and
important constraints — use it as the primary reference instead of inferring everything from the
code. Treat its contents as ground truth when writing the README and file headers, and only fall
back to inferring from code for details it does not cover.

Only document **source code files**. Skip: `node_modules/`, `__pycache__/`, `.git/`, `dist/`,
`build/`, lock files, binary files, and auto-generated files.

#### Reading strategy by project size

Reading *every* file fully is only realistic for small projects. Scale the approach to the size:

- **Small (under ~20 source files):** read every source file fully before documenting.
- **Medium (~20–100 files):** read entry points and core modules fully. For the rest, read each
  file fully *at the moment you document it* rather than all upfront — keep the map in mind, but
  don't try to hold every file in context at once.
- **Large (100+ files):** sample first to build a mental model, then document in passes:
  1. Read the README/CLAUDE.md, entry points, and main config to understand the architecture.
  2. Sample a few representative files per directory to learn the conventions and patterns.
  3. Document file-by-file in priority order (see [Handling Large Projects](#handling-large-projects)),
     reading each file fully right before you document it.

In all cases, never document a file you have not read in full — sampling is for *planning*, not for
writing comments. The comments for any given file must be based on having read that entire file.

### Step 2 — Write the project overview (README.md)

Include:

- **What the project does** — one clear paragraph
- **Architecture overview** — how the main components relate to each other
- **Entry points** — where execution starts
- **Key files and their roles** — a brief directory breakdown
- **Dependencies** — what the project relies on (inferred from package.json, requirements.txt, etc.)

**If a `README.md` already exists, improve it — do not replace it.** Keep its existing structure,
tone, and any accurate content. Fill in missing sections, correct anything outdated, and expand
thin areas, but preserve what the author already wrote. Only create a README from scratch when none
exists.

Do not invent information. Only describe what you observe in the code (and in `CLAUDE.md`, if present).

### Step 3 — Document each source file

For each source file, working top to bottom:

#### 3a. File header comment

At the very top of the file (before imports if possible, otherwise after them), add a block comment
describing:
- What this file/module does
- Its role in the overall project
- Any important notes about its design

#### 3b. Class/struct/interface headers

Directly above each class, struct, or interface declaration, add a comment describing:
- What this class represents or encapsulates
- Its main responsibilities
- Relationship to other classes if relevant

#### 3c. Function/method comments

Directly above each function or method, add a comment describing:
- What the function does (not *how* — describe behavior, not implementation)
- What each parameter represents (by name, in prose)
- What it returns, if anything
- Any side effects (modifies state, writes to DB, calls external API, etc.)
- Any important edge cases or assumptions

**Good example:**
```
// Fetches the user profile for a given ID from the database.
// userId is the unique identifier of the user to retrieve.
// Returns the full user object if found, or null if no user exists with that ID.
// Throws an error if the database connection fails.
```

**Bad example (do not do this):**
```
// Get user
// @param userId - user id
// @returns user
```

### Step 4 — Verify nothing was broken

Because this skill only adds comments and never alters code, a simple re-read is enough — there is
no need to run the test suite or diff against a build. After documenting each file:
- Re-read the file to confirm all original code is intact and unchanged
- Confirm all comments are syntactically valid for the language
- Confirm no imports, logic, or variable names were modified

---

## Language Comment Syntax Reference

| Language | Single-line | Multi-line block | Function/class doc style |
|---|---|---|---|
| JavaScript / TypeScript | `//` | `/* ... */` | `/** ... */` above declaration |
| Python | `#` | `"""..."""` (docstring) | `"""..."""` as first line inside def/class |
| C / C++ | `//` | `/* ... */` | `/** ... */` or `/* ... */` above declaration |
| Java | `//` | `/* ... */` | `/** ... */` above declaration |
| Go | `//` | `/* ... */` | `//` lines above declaration (GoDoc style) |
| Rust | `//` | `/* ... */` | `///` lines above declaration |
| PHP | `//` | `/* ... */` | `/** ... */` above declaration |
| Ruby | `#` | `=begin ... =end` | `#` lines above method |
| Swift | `//` | `/* ... */` | `///` or `/** */` above declaration |
| Kotlin | `//` | `/* ... */` | `/** ... */` above declaration |
| C# | `//` | `/* ... */` | `///` lines above declaration (plain prose, no XML tags) |
| Shell / Bash | `#` | `#` block | `#` lines above function |

**When in doubt:** use single-line comments (`//` or `#`) stacked above the declaration.

**No annotation tags — ever.** This applies to every language. Do not use XML doc tags
(`<summary>`, `<param>`, `<returns>`), JSDoc/PHPDoc tags (`@param`, `@returns`, `@throws`), or any
similar structured annotation. Even where the language's doc style technically supports them (C#
`///`, Java/JS `/** */`, etc.), write plain English prose only. The doc *delimiter* (`///`, `/** */`)
is fine; the *tags* inside are not.

```csharp
// Good:
/// Fetches the user profile for the given ID from the database.
/// Returns the matching user, or null if no user has that ID.
public User GetUser(int userId) { ... }

// Bad (do not do this):
/// <summary>Gets a user.</summary>
/// <param name="userId">The user id.</param>
/// <returns>The user.</returns>
public User GetUser(int userId) { ... }
```

For Python specifically: place the docstring **inside** the function/class body as the first statement,
not above it. This is the standard Python convention.

```python
def calculate_total(items, tax_rate):
    """
    Calculates the total price for a list of items including tax.
    items is a list of dicts, each containing a 'price' key with a numeric value.
    tax_rate is a float representing the tax percentage (e.g., 0.2 for 20%).
    Returns the total as a float rounded to two decimal places.
    """
    subtotal = sum(item['price'] for item in items)
    return round(subtotal * (1 + tax_rate), 2)
```

---

## What NOT to Document

- **Auto-generated code** — migration files, compiled output, generated GraphQL types, etc.
- **Trivial getters/setters** — if a function is `getX() { return this.x }`, a one-liner note
  like `// Returns the current value of x.` is sufficient; don't over-explain.
- **Self-evident variable names** — don't add a comment above `const PI = 3.14159` saying
  "PI is the value of pi."
- **Config files** — `package.json`, `tsconfig.json`, `.env.example`, etc. do not need inline docs.

---

## Output Quality Checklist

Before finishing, verify:

- [ ] `README.md` created or updated with project overview and architecture
- [ ] Every source file has a header comment describing its role
- [ ] Every class/struct has a comment above it
- [ ] Every function/method has a comment above (or inside for Python) it
- [ ] All comments are in plain English prose — no terse one-word descriptions
- [ ] No code logic was modified — only comments added
- [ ] Comment syntax is correct for each language
- [ ] No invented or hallucinated information about behavior

---

## Handling Large Projects

If the project has many files (20+):

1. Start with the README and architecture overview
2. Prioritize: entry points → core business logic → utilities → tests
3. Announce progress file by file so the user can follow along
4. If a file is very long (500+ lines), process it section by section

---

## Edge Cases

**Mixed-language projects** (e.g., Python backend + TypeScript frontend):
Apply the correct comment syntax per file independently.

**Existing partial documentation:**
If a function already has a comment, evaluate it. If it's adequate, leave it. If it's vague or
missing key information, improve it — but keep any existing accurate content.

**Minified or obfuscated files:**
Skip them. Note to the user that they appear to be generated/minified.

**Test files:**
Document them the same way as source files. Test function comments should describe what scenario
or behavior is being tested.
