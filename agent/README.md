# Agents

Custom VS Code Copilot **subagents** shareable via this repo.

## Available agents

| File | Description |
|------|-------------|
| [m365-roadmap.agent.md](m365-roadmap.agent.md) | Busca atualizações recentes no Microsoft 365 Roadmap e retorna um resumo filtrado em pt-BR. |
| [m365-roadmap-page.agent.md](m365-roadmap-page.agent.md) | Gera a página HTML mensal do M365 Roadmap a partir do template e do JSON do coletor. |
| [copilot-readiness.agent.md](copilot-readiness.agent.md) | Builds the Copilot Chat Readiness HTML — a hands-on, 8-step implementation guide for Microsoft 365 Copilot Chat (Foundational vs. Optimized paths, deliverables, PowerShell verification). Sourced from the official Microsoft Tech Readiness Guide PPTX + Adoption hub + Microsoft Learn. |
| [copilot-readiness-refresh.agent.md](copilot-readiness-refresh.agent.md) | Quarterly maintenance for `copilot-chat-readiness.html`: URL health check (detects Microsoft Learn URL drift), PPTX content diff, and non-destructive `fix` mode for URL replacements. Read-only by default. |
| [coach.agent.md](coach.agent.md) | Personal coaching agent: career advisory, LinkedIn engagement expert, audience growth strategist. Reviews posts/articles in `linkedin/`, suggests hooks/CTAs/hashtags, builds weekly content plans. Bilingual pt-BR / en-US. |

## Install (per teammate)

1. Clone or pull this repo.
2. Copy the desired `*.agent.md` file into your VS Code **user agents folder**:

   **Windows (PowerShell):**
   ```powershell
   $dst = "$env:APPDATA\Code\User\agents"
   New-Item -ItemType Directory -Path $dst -Force | Out-Null
   Copy-Item .\agent\*.agent.md $dst -Force
   ```

   **macOS / Linux (bash):**
   ```bash
   dst="$HOME/Library/Application Support/Code/User/agents"   # macOS
   # dst="$HOME/.config/Code/User/agents"                     # Linux
   mkdir -p "$dst"
   cp ./agent/*.agent.md "$dst"/
   ```

3. In VS Code, run **Developer: Reload Window** (Ctrl+Shift+P).
4. The agent is now available:
   - **Subagent**: invoked automatically by Copilot when relevant, or via `runSubagent`.
   - **Chat mention**: type `@m365-roadmap <filtro>` in chat (e.g. `@m365-roadmap Teams`).

## Workspace-only install (alternative)

To enable an agent **only inside this repo** (not user-wide), copy the file to `.github/agents/` instead. It will load automatically when this workspace is open.

## Authoring notes

- File extension must be `.agent.md`.
- Frontmatter supported: `description`, `argument-hint`, `tools`, `model`.
- Body is the system prompt for the agent.
- Only list tools that are actually available in your VS Code Copilot setup.
