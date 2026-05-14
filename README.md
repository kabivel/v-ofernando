# v-ofernando

Collection of Microsoft 365 / Azure administration scripts, reports, and dashboards.

## Repository structure

- **[index.html](index.html)** — M365 Roadmap dashboard (root entry).
- **[m365-roadmap-april.html](m365-roadmap-april.html)** — Interactive single-page dashboard listing Microsoft 365 Roadmap features with GA in April 2026.
- **[keyvault_acess.ps1](keyvault_acess.ps1)** — Azure Key Vault access helper script.
- **[Exchange/](Exchange/)** — Exchange Online reports (e.g. `Mailflow.html`).
- **[Graph Report API/](Graph%20Report%20API/)** — Microsoft Graph reporting scripts:
  - `0_Setup_AppCretion.ps1` — App registration setup.
  - `0-Start.ps1` — Entry point.
  - `1_Blob.ps1` / `1_unificado.ps1` — Blob storage / unified report.
  - `2_Graph_Only.ps1` / `2_Graph_Only_Interactive.ps1` — Graph-only (silent / interactive).
  - `3_users_azure.ps1` — Azure user enumeration.
  - `Export/` — Sample CSV/JSON exports (Copilot usage, M365 active users, etc.).
- **[Sharepoint/](Sharepoint/)** — SharePoint guidance and deployment plans.

## Live dashboards

- M365 Roadmap (April 2026): https://kabivel.github.io/m365-roadmap-april/

## Run locally

Open any `.html` file directly in a browser. PowerShell scripts require the `Az` and/or `Microsoft.Graph` modules — see each script header for prerequisites.
