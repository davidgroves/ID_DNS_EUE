# Internet Draft Template

A Git template repository for writing IETF Internet Drafts in Markdown.

## Features

- **Containerized build system** - No local dependencies required (just Docker)
- **kramdown-rfc Markdown** - Write drafts in Markdown with YAML frontmatter
- **Auto-rebuild on save** - Watch mode rebuilds when files change
- **Live preview** - VS Code Live Server auto-refreshes HTML output
- **GitHub Actions CI** - Auto-build, GitHub Pages, and IETF submission

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [VS Code](https://code.visualstudio.com/) or [Cursor](https://cursor.sh/) (recommended)

## Quick Start

1. **Create a new repository from this template**

   Click "Use this template" on GitHub, or clone and reinitialize:
   ```bash
   git clone https://github.com/YOUR_USER/YOUR_REPO.git
   cd YOUR_REPO
   ```

2. **Rename the draft file**

   Rename `draft-todo-yourname-protocol.md` to match your draft name:
   ```bash
   mv draft-todo-yourname-protocol.md draft-smith-example-protocol.md
   ```
   
   Update the `docname` field inside the file to match.

3. **Build the draft**

   ```bash
   make
   ```
   
   This builds `draft-*.html` and `draft-*.txt` files.

4. **Preview in browser**

   Open the generated HTML file, or use VS Code Live Server for auto-refresh.

## Usage

### Build Commands

| Command | Description |
|---------|-------------|
| `make` | Build all drafts (HTML + TXT) |
| `make watch` | Watch for changes and rebuild automatically |
| `make shell` | Open interactive shell in build container |
| `make clean` | Remove build artifacts |
| `make clean-all` | Remove artifacts and Docker volumes |

### VS Code / Cursor

1. Install recommended extensions when prompted
2. **Auto-start**: Watch mode starts automatically when you open the folder
   - VS Code will ask to allow this the first time; click "Allow"
   - The initial build runs, creating `draft-*.html`
3. **Preview**: Right-click `draft-*.html` → "Show Preview"
   - Opens an embedded preview panel inside VS Code
   - Or use Command Palette → "Live Preview: Show Preview"
4. **Manual build**: Press `Ctrl+Shift+B` (or `Cmd+Shift+B` on Mac)

The watch service rebuilds on every save, and the preview auto-refreshes.

## Draft Format

Drafts use [kramdown-rfc](https://github.com/cabo/kramdown-rfc) Markdown format:

```markdown
---
title: "Your Draft Title"
abbrev: "Short Title"
docname: draft-yourname-topic-latest
category: info
# ... more YAML frontmatter ...
---

--- abstract

Your abstract here.

--- middle

# Introduction

Your content here.

# Security Considerations

TODO Security

# IANA Considerations

This document has no IANA actions.

--- back

# Acknowledgments
{:numbered="false"}

Thanks to everyone.
```

See the [kramdown-rfc documentation](https://github.com/cabo/kramdown-rfc) for full syntax.

## GitHub Actions

The included workflow automatically:

- Builds drafts on every push and pull request
- Publishes HTML to GitHub Pages
- Submits to IETF datatracker when you create a tagged release

### Submitting to IETF

1. Create a Git tag with the draft version:
   ```bash
   git tag -a draft-smith-example-protocol-00
   git push origin draft-smith-example-protocol-00
   ```

2. The GitHub Action will automatically submit to the IETF datatracker.

## File Structure

```
.
├── Dockerfile              # Build container with inotify-tools
├── docker-compose.yml      # Container orchestration
├── Makefile                # Build commands
├── draft-*.md              # Your Internet Draft(s)
├── .github/workflows/      # GitHub Actions CI
└── .vscode/                # Editor configuration
```

## References

- [IETF Author Resources](https://authors.ietf.org/)
- [kramdown-rfc](https://github.com/cabo/kramdown-rfc)
- [i-d-template](https://github.com/martinthomson/i-d-template)
- [RFC Editor Style Guide](https://www.rfc-editor.org/styleguide/)

## License

This template is released under [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/).
Your drafts are subject to [IETF Trust provisions](https://trustee.ietf.org/license-info/).
