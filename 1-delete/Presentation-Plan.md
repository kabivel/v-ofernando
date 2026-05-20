# Presentation Plan — E5 Renewal Strategy (BCA, 3-Year)

> Source material (only): `1-delete/Call with Luis Sanchez Diaz.vtt`, `1-delete/Microsoft-365-Matrix-Export 2(Microsoft-365-Matrix-Export).csv`

## 1. Context (from the call)
- 3-year E5 renewal, **risky**: budget pressure + customer feels they "haven't received too much value" after 3 years.
- Customer self-built a ~500-row feature matrix and asked us to help them define priorities.
- Original sales plan: **Year 1 = Teams Phone**, Year 2 = Data Security (Purview), Year 3 = Cloud Security + AI.
- Two blockers on Teams Phone Year 1:
  1. Avanade currently has **no Teams Phone specialist** available; market scarcity.
  2. Teams Phone does not produce the "value story" needed to defend the renewal.
- Agreed pivot in the call: **Year 1 Security → Year 2 Copilot (E5 usage uplift) → Year 3 Teams Phone**.

---

## 2. Presentation Storyline (recommended slide order)

### Slide 1 — Why we are revisiting the proposal
- Renewal is a decision about **value realized**, not just licenses renewed.
- Customer-built matrix shows large surface area of E5 that is **paid for but not in use**.
- We propose a sequence that turns that unused entitlement into measurable outcomes.

### Slide 2 — What is NOT in use today (from the BCA matrix)
Items the customer marked as licensed in E5 but **blank in "Currently In-Use"**, grouped by theme:

**Data Security / Compliance (Purview)**
- Compliance Manager, Content Search, Data Lifecycle Management, Data Loss Prevention, Retention Labels, Retention Policies
- Communication Compliance, Customer Key, Customer Lockbox, Information Barriers, Records Management
- Copilot Data Loss Prevention / DSPM for Copilot (flagged by customer: "Especially as Copilot interest ramps up")
- Endpoint DLP, Trainable Classifiers, Insider Risk Management, Adaptive Protection
- Message Encryption (advanced), Double Key Encryption, Exact Data Match
- 10-Year Audit Log Retention (customer note: "We should be enabling this")

**Identity & Access (Entra ID P2 / Suite)**
- Access Reviews, Entitlement Management, App Governance (customer: "Yes, but further down the line")
- Privileged Access Management, 3rd Party MFA Integration
- Entra Verified ID, Entra ID Governance, Lifecycle Workflows, ML-Assisted Access Reviews

**Endpoint & Threat (Defender / Intune Suite)**
- Defender for Office 365 P2: Attack Simulation, Threat Explorer, Threat Trackers, Teams Message Quarantine, Compromised User Detection
- Defender Vulnerability Management (premium) — most sub-features unused
- Intune Suite: Cloud PKI, Endpoint Privilege Management, Enterprise App Management, Remote Help (customer marked as wanted)
- Defender Experts for Hunting / XDR
- Security Copilot, Microsoft Sentinel benefit
- Office 365 Cloud App Security (customer: "good to start looking into")

**Copilot & Productivity surface**
- Microsoft 365 Copilot Chat — installed, **not widely used** (confirmed in call)
- SharePoint Advanced Management (all Copilot-related governance features unused)
- Microsoft Places, Loop Workspaces, Power Automate (seldom used), Power BI Pro, Viva Insights Premium

**Teams Phone track (intentionally deferred)**
- Teams Phone, Calling Plans, Operator Connect, Queues App — all marked "Planned for 2026 Telephony Modernization"

### Slide 3 — The value problem
- Customer is paying for E5 but consuming mostly E3-equivalent workloads + Copilot Chat.
- Renewing without changing the consumption pattern will reproduce the same "no value" feeling in 3 more years.
- The matrix itself is the evidence — it was built by the customer.

### Slide 4 — Why Teams Phone should NOT be Year 1 (reframing, not refusing)
Three honest reasons, in the order to present them:
1. **Risk to value perception.** Teams Phone is an infrastructure swap. It does not visibly raise the ROI of the E5 license they are already paying for — which is exactly the complaint driving this renewal.
2. **Cost exposure first.** Security gaps in the unused list (DLP, Insider Risk, Defender P2 features, PIM, audit retention) translate directly into financial risk: data leak, ransomware, regulatory exposure. Closing those first **protects budget** rather than spending it.
3. **Delivery readiness.** Specialist availability for Teams Phone is constrained right now; starting Year 1 here risks a slow, low-visibility delivery — the worst possible outcome for a "risky renewal."

> Frame it as: *"We are moving Teams Phone, not removing it."*

### Slide 5 — Why Secure Data first, then Copilot, then Phone
- **Year 1 — Secure the data and identity surface.**
  Activate already-paid features: Purview DLP / Retention / Insider Risk, Defender for Identity, PIM, Conditional Access maturity, 10-year audit retention, DSPM for Copilot. Outcome: measurable reduction in risk exposure using licenses they already own.
- **Year 2 — Unlock Copilot value.**
  Copilot Chat is installed but not adopted. Workshops + adoption + Copilot DLP/DSPM (only safe after Year 1) drive the productivity story the business wants. This is where the E5 + Copilot spend visibly pays back.
- **Year 3 — Teams Phone / Telephony Modernization.**
  By Year 3: specialist market has loosened, data perimeter is safe, users are Copilot-mature, and the phone migration becomes a clean modernization project rather than the renewal's risk anchor.

Key one-liner for the customer:
> *"Secure what you have, prove value with Copilot, then modernize the phone — in that order, you stop paying for E5 features you don't use, and you remove the risk before you add new workloads."*

### Slide 6 — Year-by-year proposal (no fixed hours, two engagements per year)
- **Year 1 — Data & Identity Security**
  - Suggested engagements: Purview DLP / Retention rollout, Defender for Identity + PIM hardening.
- **Year 2 — Copilot Value Realization**
  - Suggested engagements: Copilot adoption workshops (scoped after skill-check), DSPM/DLP for Copilot.
- **Year 3 — Telephony Modernization**
  - Suggested engagements: Teams Phone / Operator Connect / Queues App rollout.

(Per Luis: the contract format gives the customer the right to **pick 2 engagements per year** from each pillar — we present pillars, not hours.)

### Slide 7 — Next steps
- Sales rebuilds the PPT with the reordered pillars (Security → Copilot → Phone).
- Pre-call alignment between Fernando and Luis before tomorrow's customer meeting.
- After signature: scoping call per year to confirm the 2 selected engagements and run a skill-check before sizing workshops (1 / 3 / 5 days).
- Engagements run **serial, not parallel**, to avoid messy multi-front delivery.

---

## 3. Talking points to keep handy
- "The matrix you built is the business case — most of what you are paying for in E5 is not switched on."
- "Security is the only pillar where *not* acting has a direct financial cost."
- "Copilot is already in your tenant; we just need to make people use it — that is the fastest visible ROI."
- "Teams Phone in Year 3 is a better project for you: cheaper specialists, safer data, trained users."
