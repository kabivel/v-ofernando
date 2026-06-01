# v-ofernando

Collection of Microsoft 365 / Azure administration scripts, reports, and dashboards.

## Repository structure

- **[index.html](index.html)** — M365 Roadmap dashboard (April 2026, root entry).
- **[keyvault_acess.ps1](keyvault_acess.ps1)** — Azure Key Vault access helper script.
- **[Intune/](Intune/)** — Entra ID / Intune device management scripts.
- **[Exchange/](Exchange/)** — Exchange Online reports (e.g. `Mailflow.html`).
- **[Graph Report API/](Graph%20Report%20API/)** — Microsoft Graph reporting scripts:
  - `0_Setup_AppCretion.ps1` — App registration setup.
  - `0-Start.ps1` — Entry point.
  - `1_Blob.ps1` / `1_unificado.ps1` — Blob storage / unified report.
  - `2_Graph_Only.ps1` / `2_Graph_Only_Interactive.ps1` — Graph-only (silent / interactive).
  - `3_users_azure.ps1` — Azure user enumeration.
  - `Export/` — Sample CSV/JSON exports (Copilot usage, M365 active users, etc.).
- **[Identity management/](Identity%20management/)** — Okta, Active Directory, and Entra ID practical guideline.
- **[Sharepoint/](Sharepoint/)** — SharePoint guidance and deployment plans.

## Live dashboards

GitHub Pages root: https://kabivel.github.io/v-ofernando/

- M365 Roadmap (April 2026): https://kabivel.github.io/v-ofernando/
- Exchange Mailflow report: https://kabivel.github.io/v-ofernando/Exchange/Mailflow.html
- Okta, Active Directory, and Entra ID guideline: https://kabivel.github.io/v-ofernando/Identity%20management/
- PAW — Privileged Access Workstation guideline: https://kabivel.github.io/v-ofernando/Identity%20management/paw-privileged-access-workstation.html
- FIDO2 + Certificate (Intune) two-factor guide: https://kabivel.github.io/v-ofernando/Identity%20management/fido2-plus-certificate-intune.html
- SharePoint Version History — Deployment Plan (static): https://kabivel.github.io/v-ofernando/Sharepoint/version-history-deployment-plan.html

> **Note:** GitHub Pages must be enabled — repo **Settings → Pages → Source: Deploy from a branch → Branch: `main` / folder: `/ (root)`**.

## Run locally

Open any `.html` file directly in a browser. PowerShell scripts require the `Az` and/or `Microsoft.Graph` modules — see each script header for prerequisites.
