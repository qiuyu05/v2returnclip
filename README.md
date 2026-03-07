# ReturnClip 📦

**AI-Powered Returns Verification for Shopify — Built for Hack Canada 2026**

## What It Does

ReturnClip is an Apple App Clip that verifies item condition against merchant return policies in 30 seconds. Customers scan a QR code, upload photos, and AI determines refund eligibility automatically.

## The Flow

1. **QR Scan** → Contains order ID, purchase date, location
2. **Return Reason** → Customer selects why they're returning
3. **Photo Upload** → Guided capture with demo video
4. **AI Analysis** → Cloudinary Vision checks condition
5. **Policy Check** → Gemini reasons against return policy
6. **Instant Decision** → Full refund, partial, exchange, or store credit

## Tech Stack

| Component | Technology |
|-----------|------------|
| App | Swift 5.0 + SwiftUI |
| Framework | Reactiv ClipKit Lab |
| Image Analysis | Cloudinary AI Vision (REST) |
| Policy Reasoning | Google Gemini API (REST) |
| Order Data | Shopify Storefront API (mock) |

## Project Structure

```
returnclip/
├── ReturnClipKit/
│   ├── ReturnClipKit.xcodeproj
│   └── ReturnClipKit/
│       ├── ReturnClipKitApp.swift
│       ├── Experience/
│       │   └── ReturnClipExperience.swift
│       ├── Screens/
│       │   ├── OrderConfirmationView.swift
│       │   ├── ReturnReasonView.swift
│       │   ├── PhotoCaptureView.swift
│       │   ├── ConditionResultView.swift
│       │   ├── RefundOptionsView.swift
│       │   └── ConfirmationView.swift
│       ├── Services/
│       │   ├── CloudinaryService.swift
│       │   └── GeminiService.swift
│       ├── Models/
│       │   ├── Order.swift
│       │   ├── ReturnPolicy.swift
│       │   └── ConditionAssessment.swift
│       ├── MockData/
│       │   └── MockData.swift
│       └── Config/
│           └── APIKeys.swift
├── SUBMISSION.md
└── README.md
```

## Setup

1. Clone this repo
2. Open `ReturnClipKit/ReturnClipKit.xcodeproj` in Xcode 26+
3. Add your API keys to `Config/APIKeys.swift`:
   - Cloudinary Cloud Name + Upload Preset
   - Gemini API Key
4. Select iPhone simulator
5. Build and Run (Cmd+R)

## API Keys Required

### Cloudinary
1. Sign up at [cloudinary.com](https://cloudinary.com)
2. Get your Cloud Name from Dashboard
3. Create unsigned upload preset in Settings > Upload Presets
4. Enable AI Vision add-on in Settings > Add-ons

### Google Gemini
1. Get API key from [ai.google.dev](https://ai.google.dev)
2. Enable Gemini API in Google Cloud Console

## URL Pattern

```
returnclip.app/return/:orderId
```

Example: `returnclip.app/return/12345`

## Team

Built for Hack Canada 2026

## License

Submitted under Reactiv ClipKit Lab terms.
