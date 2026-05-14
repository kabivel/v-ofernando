# Agents

Custom VS Code Copilot **subagents** shareable via this repo.

## Available agents

| File | Description |
|------|-------------|
| [m365-roadmap.agent.md](m365-roadmap.agent.md) | Busca atualizações recentes no Microsoft 365 Roadmap e retorna um resumo filtrado em pt-BR. |

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
