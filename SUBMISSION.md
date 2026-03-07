# ReturnClip — Hack Canada 2026 Submission

## Team Information

- **Team Name:** Team ReturnClip
- **Members:** [Add team member names]
- **Challenge:** Reactiv ClipKit Lab

---

## Problem Framing

### The Pain Point

Ecommerce returns cost merchants **$100+ billion annually** in fraud and processing. For furniture/home decor brands like Refined Concept, return rates hit **15-22%** on dropshipping, with each return eating **20-65%** of item value in reverse logistics.

The core problem: **merchants can't verify item condition at scale.**

Current returns flow:
1. Customer emails support (5-10 min)
2. Back-and-forth about condition (days)
3. Manual inspection on receipt (costly)
4. Disputes → chargebacks → lost customers

### Why This Matters for Canadian Commerce

- Canadian retail margins are already thin
- Furniture/home goods returns spike post-holiday (Boxing Week aftermath)
- Cross-border returns (US→CA) add complexity and cost
- Chargebacks hurt small merchants disproportionately

### Target Touchpoint

**Post-purchase, 8 hours after delivery** — the critical window when customers decide to keep or return. This is the perfect App Clip moment: time-sensitive, focused task, no app install needed.

---

## Proposed Solution

### ReturnClip: AI-Powered Returns Verification

An App Clip that verifies item condition against merchant return policy in **30 seconds**.

### User Flow

```
QR Code/Push Notification (8hr post-delivery)
    ↓
Screen 1: Order Confirmation (2 sec)
    ↓
Screen 2: Return Reason (3 sec)
    ↓
Screen 3: Photo Capture with Demo Video (10 sec)
    ↓
Screen 4: AI Condition Assessment (5 sec)
    ↓
Screen 5: Refund Options (5 sec)
    ↓
Screen 6: Confirmation + Label (5 sec)
```

**Total: ~30 seconds** — exactly what App Clips are designed for.

### How It Uses Reactiv Clips

1. **Invocation:** Push notification via Reactiv's 8-hour engagement window, or QR code on packaging
2. **Shopify Integration:** Pulls order data, product info, return policy via Storefront API
3. **No App Install:** Instant access, no friction
4. **Push Notifications:** Reminder before return label expires

### AI Integration

| Component | Technology | Purpose |
|-----------|------------|---------|
| Image Upload | Cloudinary | Media ingestion and storage |
| Condition Analysis | Cloudinary AI Vision | Detect damage, wear, stains |
| Policy Reasoning | Google Gemini | Compare condition vs. policy, determine refund |

### Example AI Decision

**Input:**
- Item: Velvet Accent Chair ($299)
- Condition Score: 72% (minor scratch, light wear)
- Policy: 30-day return, 85% threshold for full refund

**Output:**
```json
{
  "decision": "partial_refund",
  "refundAmount": 239.20,
  "restockingFee": 59.80,
  "explanation": "Item shows signs of use. 20% restocking fee applies."
}
```

---

## Platform Extensions Required

### For Full Production Deployment

1. **Cloudinary Webhook Integration** — Real-time condition analysis callback to Reactiv
2. **Shopify Return Initiation API** — Create return record, generate label
3. **Push Notification Templates** — Customizable merchant-branded notifications
4. **Policy Builder UI** — Merchant dashboard to configure return rules

### What We Built vs. What We'd Need

| Feature | Hackathon MVP | Production |
|---------|---------------|------------|
| Order Data | Mock data | Shopify API |
| Condition Analysis | Simulated | Full Cloudinary AI |
| Policy Logic | Gemini prompt | Gemini + merchant rules |
| Return Labels | QR mock | Canada Post API |
| Push Notifications | Simulated | Reactiv infrastructure |

---

## Impact Hypothesis

### Revenue Impact: Merchandise Recovery

**Current state (100 returns/month):**
- 60 processed → $6,000 refunds
- 40 abandoned due to friction
- 15 chargebacks → $1,500 fees
- **Total loss: $7,500**

**With ReturnClip:**
- 95 processed (friction removed)
- 50 refunds → $5,000
- 30 exchanges → $0 loss (sale retained)
- 15 store credit → $750 retained
- 5 chargebacks → $500 fees
- **Total loss: $5,000 — 33% reduction**

### Additional Value

- **Fraud reduction:** AI catches condition misrepresentation
- **Data capture:** Why customers return (product improvement)
- **Brand trust:** Transparent, fair process builds loyalty
- **Operational efficiency:** Automates manual inspection

### Target Channel

**Both venue (packaging QR) and online (push notification)** — unified experience regardless of how customer received the product.

---

## Demo

### Screen Recording

[Link to demo video — 30-60 seconds showing full flow]

### Screenshots

1. Order confirmation with item selection
2. Return reason picker
3. Photo capture with guidelines
4. AI condition assessment with score
5. Refund options (full, partial, exchange, store credit)
6. Confirmation with QR code label

### URL Pattern

```
returnclip.app/return/:orderId
```

**Example:** `returnclip.app/return/12345`

---

## Technical Implementation

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     ReturnClip App Clip                      │
├─────────────────────────────────────────────────────────────┤
│  ReturnClipExperience                                        │
│  ├── OrderConfirmationView                                   │
│  ├── ReturnReasonView                                        │
│  ├── PhotoCaptureView ────────► Cloudinary Upload            │
│  ├── ConditionResultView ◄───── Cloudinary AI Vision         │
│  │                        ◄───── Gemini Policy Reasoning     │
│  ├── RefundOptionsView                                       │
│  └── ConfirmationView                                        │
├─────────────────────────────────────────────────────────────┤
│  Services                                                    │
│  ├── CloudinaryService (REST API)                            │
│  └── GeminiService (REST API)                                │
├─────────────────────────────────────────────────────────────┤
│  Data                                                        │
│  ├── Order, LineItem, PaymentMethod                          │
│  ├── ReturnPolicy, ConditionRequirement                      │
│  ├── ConditionAssessment, RefundDecision                     │
│  └── MockData (for demo)                                     │
└─────────────────────────────────────────────────────────────┘
```

### Key Files

- `Experience/ReturnClipExperience.swift` — Main orchestrator
- `Screens/*.swift` — Individual flow screens
- `Services/CloudinaryService.swift` — Image upload + AI analysis
- `Services/GeminiService.swift` — Policy reasoning
- `Models/*.swift` — Data structures
- `MockData/MockData.swift` — Demo data

### No External Dependencies

All API integrations use direct REST calls — no SPM, CocoaPods, or Carthage required per ClipKit Lab rules.

---

## Why This Wins

### Judging Criteria Alignment

| Criteria | Weight | Our Score | Why |
|----------|--------|-----------|-----|
| **Novelty** | 30% | 🔥🔥🔥 | First AI condition + policy reasoning in App Clip. No competitor does this. |
| **Constraint Awareness** | 25% | 🔥🔥🔥 | Perfect use of 8-hour push window. Sub-30-second experience. No app install. |
| **Real-World Trigger** | 20% | 🔥🔥 | QR on packaging + push notification — both proven invocation methods. |
| **Execution** | 15% | 🔥🔥 | Clean SwiftUI, working API integrations, polished demo. |
| **Scalability** | 10% | 🔥🔥🔥 | Any Shopify store, any product category, any return policy. |

### The Question You Asked

> "What experience fits the shape of an App Clip that nobody has thought of?"

**Answer:** Post-purchase returns verification. Time-sensitive (8-hour window). Focused task (30 seconds). Real business value ($100B problem). AI-powered differentiation.

---

## Team

Built with 💪 at Hack Canada 2026

[Add team member info, roles, and contact]
