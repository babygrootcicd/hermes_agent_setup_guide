# Hermes Agent Skill Library

This directory contains templates and examples of **Hermes Skills**. Skills are specialized instructions and tool sets that extend the capabilities of the Hermes Agent for specific domains or workflows.

## 🛠 What is a Hermes Skill?

A skill is a modular "plugin" for the agent. It typically consists of:
- **System Instructions**: High-level guidance on how the agent should behave in a specific context.
- **Tool Definitions**: Specifications for external tools or scripts the agent can invoke.
- **Examples**: Few-shot examples to guide the agent's output format and logic.

## 📂 Skill Structure

Skills in this library are stored as Markdown (`.md`) files. This makes them easy to read, version control, and share.

### Key Components:
1.  **Objective**: A clear statement of what the skill is for.
2.  **Capabilities**: List of specific tasks the skill enables.
3.  **Prompt Template**: The core instructions for the agent.
4.  **Tools**: (Optional) Definitions for any required CLI tools or APIs.

## 🚀 How to Load Skills

To use these skills with Hermes Agent, you can:

### 1. Manual Injection
Copy the content of a skill file into your chat session or include it in your system prompt configuration.

### 2. CLI Reference
If your version of Hermes supports it, you can point to the skill file directly:
```bash
hermes chat --skill examples/skills/code-review.md
```

### 3. Automated Loading
Place the skill file in your local configuration directory:
- **macOS/Linux**: `~/.hermes/skills/`
- **Windows**: `%USERPROFILE%\.hermes\skills\`

## 📝 Creating Your Own Skill

1.  **Use a Template**: Start with one of the templates in this directory (`code-review.md` or `data-formatter.md`).
2.  **Define the Scope**: Be specific about what the agent should and should NOT do.
3.  **Test Iteratively**: Use the `--verbose` flag with Hermes to see how it interprets your skill instructions.
4.  **Optimize for Prompt Engineering**: Use clear headings, bullet points, and explicit constraints.

---

*For more information on advanced tooling, see [docs/100-advanced-tooling.md](../../docs/100-advanced-tooling.md).*
