# Identity & Hybrid Join — Clarifications

_Date: 2026-05-20_
_Author: Fernando A. da Silva_
_Status: Draft for review_
_Scope: Okta + Entra coexistence, `.local` domain impact, macOS login, Hybrid Azure AD Join_

---

## Executive summary

| Question | Short answer |
|---|---|
| Need Entra Connect alongside Okta? | **Yes** — for hybrid identity, HAADJ, Intune compliance. |
| `.local` domain a blocker? | **No** — if UPN is routable and domain verified. |
| macOS login with Entra creds? | **Platform SSO via Intune** is the native path. |
| Hybrid Azure AD Join feasible? | **Yes**, contingent on Entra Connect + identity matching done first. |

---

## 1. Do we still need Microsoft Entra Connect if Okta is already provisioning?

**Yes — in most hybrid scenarios Okta does not replace Entra Connect.**

| Capability | Okta Provisioning (SCIM / AD Agent) | Entra Connect (Sync / Cloud Sync) |
|---|---|---|
| Creates user in Entra ID | Yes | Yes |
| Links on-prem AD object ↔ Entra (same identity) | **No** (separate identity) | **Yes** (via `ImmutableID` / `sourceAnchor`) |
| Hybrid Azure AD Join | Not supported standalone | **Required** |
| Intune device compliance tied to hybrid identity | Breaks without sync | Works |
| Password Hash Sync / Pass-through Auth | No | Yes |
| Write-back (password, groups, devices) | No | Yes |

### Identity matching
- **Soft match** — by `userPrincipalName` or `primarySMTPAddress`. Useful when the cloud object already exists (created by Okta) and sync is enabled afterward.
- **Hard match** — by `ImmutableID` (Base64 of AD `objectGUID`). Definitive method; plan for this to avoid duplicates.

### Recommendation — ID mapping audit before enabling Entra Connect
1. Export `objectGUID` + UPN from on-prem AD.
2. Export `ImmutableID` + UPN from cloud objects created by Okta.
3. Where `ImmutableID` is empty, perform a hard match via Microsoft Graph PowerShell **before** the first sync — otherwise duplicates require manual merge:
   ```powershell
   Update-MgUser -UserId <cloudUserId> -OnPremisesImmutableId <base64objectGuid>
   ```
   (The legacy `Set-MsolUser` / MSOnline module was retired in 2024.)

### Connect Sync vs Cloud Sync
For greenfield or simple topologies, **Entra Cloud Sync** (lightweight agent, no SQL, multi-agent HA) is now Microsoft's recommended path over the legacy **Entra Connect Sync**. Use Connect Sync only when you need features Cloud Sync still lacks (e.g., device write-back for HAADJ in some topologies, Exchange hybrid writeback, pass-through auth at scale).

> If the long-term goal is to retire Okta as IdP, Entra Connect (or Cloud Sync) is a prerequisite for transitioning without re-provisioning devices.

---

## 2. Does the non-routable `.local` domain affect Azure / Entra?

**No impact on sync or Azure, provided the UPN is routable.**

Validation checklist:
- **UPN suffix** `allvuesystems.com` added in *AD Domains and Trusts* and applied to every synced user (no leftover `user@corp.local` UPNs).
- **Domain verified in Entra** (`allvuesystems.com` via TXT record).
- **Primary SMTP** aligned with UPN (best practice for Teams / OneDrive / SSO).
- **Hybrid Azure AD Join** with `.local`: works, but the **Service Connection Point (SCP)** published in AD must point to the correct Entra tenant; device certificate is issued against the routable UPN, not the `.local` suffix.
- **DNS**: split-brain DNS for `allvuesystems.com` (internal zone overriding public records) is a common blocker — ensure internal resolvers either forward correctly or host the records needed for Autodiscover / SCP / device registration endpoints.
- **Autodiscover / Exchange Hybrid** (if applicable): use public names only, never `.local`.

Residual risk: internal AD CS certificates issued for `*.corp.local` are not externally trusted — irrelevant to Entra, but matters for clients validating SAN.

---

## 3. macOS login with O365 / Entra credentials post-enrollment

**Current state:** Intune enrollment works, but local macOS login still uses a local account (no login-screen SSO).

| Solution | How it works | Requirements |
|---|---|---|
| **Platform SSO (PSSO)** — recommended, native | Company Portal + SSO Extension profile binds the local macOS account to Entra; lock-screen login uses Entra password / Passkey | Intune **SSO Extension** configuration profile (not just Company Portal install), Company Portal 5.2402+, macOS 13+ for `Password` mode, **macOS 14+ for `Secure Enclave` / `SmartCard`** modes |
| **Enterprise SSO plug-in (Microsoft)** | SSO for Microsoft apps after login; machine login stays local | Simpler; does not solve the request |
| **Jamf Connect / XCreds** | Replaces macOS login window with OIDC flow against Entra | Extra license (Jamf) or open-source (XCreds); more flexible, more to manage |
| **Okta Device Trust + Okta Verify** | If Okta remains the IdP, use Okta FastPass | Keeps Okta dependency |

**Recommended:** **Platform SSO** in *Secure Enclave Key* or *Password* mode, delivered via Intune SSO Extension profile. Meets the requirement without third-party tooling.

PSSO modes:
- `Password` — local account password is synchronized to match the Entra password on next sign-in (closest to "login with O365 credentials").
- `Secure Enclave` — hardware-bound key on the chip; passwordless. **Requires macOS 14+.**
- `SmartCard` — for CAC / PIV scenarios. **Requires macOS 14+.**

**FileVault caveat:** the pre-boot FileVault unlock screen does **not** use PSSO — it uses the local account password set at enrollment. PSSO kicks in on the macOS login screen after the disk is unlocked. Plan user comms accordingly.

Practical prerequisites: user must already exist in Entra (see section 1), MDM enrollment with user affinity, Company Portal signed in at least once.

---

## 4. Hybrid Azure AD Join — discussion points

- **Rollout path**: pilot by AD OU, SCP pointing to tenant, registration triggered by the built-in scheduled task `\Microsoft\Windows\Workplace Join\Automatic-Device-Join` (use `dsregcmd /status` to verify state).
- **OS baseline**: Windows 10 1809+ / Windows 11 / Server 2019+ for full HAADJ + Intune co-management.
- **Critical prereq**: healthy Entra Connect (or Cloud Sync with device options) + resolved identity matching (back to section 1).
- **Co-management vs cloud-native**: worth discussing whether new machines should target **Entra Join + Intune (cloud-native)**, keeping hybrid only for legacy. Reduces complexity mid-term.
- **Conditional Access**: device-compliance policies only work after hybrid join + Intune enrollment is complete (`dsregcmd /status` shows `AzureAdJoined: YES`, `DomainJoined: YES`, `MDM Url` populated).
- **Common blockers**: proxy intercepting `login.microsoftonline.com`, `enterpriseregistration.windows.net`, `device.login.microsoftonline.com`; clock skew; UPN mismatch between AD and Entra.
