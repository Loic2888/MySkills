# MySkills

A curated collection of **Claude Code skills**, **custom agents**, and **agentic frameworks** — built, discovered, or adapted over time.

This repository serves as a personal library and a sharing point for anyone interested in extending Claude Code's capabilities with reusable, composable building blocks.

---

## What's in here

| Type | Description |
|------|-------------|
| **Skills** | Slash-command extensions for Claude Code (`/skill-name`) — self-contained prompts that teach Claude how to handle a specific class of task |
| **Agents** | Custom agent definitions with specialized toolsets and personas, ready to drop into the Claude Agent SDK |
| **Agentic frameworks** | Patterns, templates, and orchestration blueprints for multi-agent workflows |

---

## Skills

### `create-course`
Generates a complete, in-depth training course on any subject as a standalone navigable HTML page (chapters, lessons, examples, exercises).

**Usage:** `/create-course <subject>`

---

## How to use a skill

Copy the skill folder into your project's `.claude/` directory (or your global `~/.claude/` for cross-project access), then invoke it with `/skill-name` inside Claude Code.

```
.claude/
└── create-course/
    └── SKILL.md
```

---

## Contributing / Structure

Each skill or agent lives in its own folder and follows the Claude Code skill format:

```
my-skill/
├── SKILL.md            # Skill definition (frontmatter + prompt)
└── structure-reference.md  # Optional supporting docs
```

Agents and frameworks will follow the same pattern with their own README per entry.

---

## License

MIT — use freely, adapt, and share back what you improve.
