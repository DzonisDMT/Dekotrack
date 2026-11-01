# DecoTrack

**DEKOBYGG AS equipment tracking app** · Version **0.1.0**

The Expo / React Native mobile app is the primary product. The static web demo in `index.html` is only a browser preview and is not the source of truth.

## Mobile app (Android first)

### Requirements
- Node.js LTS
- npm
- Expo Go on an Android phone for quick testing, or Android Studio for an emulator

### Run locally
```bash
npm install
npx expo start
```
Scan the QR code from the Expo CLI with Expo Go. For an Android emulator:
```bash
npm run android
```

### Current prototype features
- Lithuanian and English interface switch
- Light and dark appearance switch
- Dashboard with equipment totals
- Tool register, search and add-tool flow
- Tool bags and project lists
- Equipment transfer form and transfer history
- QR code display for each tool and camera QR scanning
- Local persistence on the device with AsyncStorage

### Important prototype limitations
Version 0.1.0 stores data locally on one device. It does **not** yet provide employee accounts, a shared cloud database, multi-device synchronization, server-side audit history, or production permissions. Do not use the demo data as real company inventory. These are planned for the next development stage.

## Versioning
We use Semantic Versioning:
- Patch (0.1.1): bug fixes
- Minor (0.2.0): backward-compatible features
- Major (1.0.0): first stable production release

Update `package.json` and `app.json` together for every mobile release, and document changes in `CHANGELOG.md`.

## Project structure
- `App.tsx` — primary Expo mobile application
- `app.json` — Expo / Android configuration
- `package.json` — mobile dependencies and version
- `index.html` — separate responsive web preview
- `assets/` — brand and app assets

## Branding
The current mobile header uses a text wordmark placeholder. Replace it with the approved original DEKOBYGG AS logo asset before production.
