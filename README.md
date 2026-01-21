# White-Label Automation - Mobile App

This is a **mobile application** for Android and iOS. It is **NOT** a web application and cannot be deployed to Vercel.

## 📱 This is a Mobile App Only

This Flutter project is configured for:
- ✅ Android
- ✅ iOS
- ❌ Web (removed)

## 🚫 Cannot Deploy to Vercel

Vercel is for web applications only. This project builds mobile APK/IPA files, not web apps.

## 📦 How to Use

### Build Android APK

```bash
flutter build apk --release
```

APK location: `build/app/outputs/flutter-apk/app-release.apk`

### Build iOS App

```bash
flutter build ios --release
```

Then open in Xcode to sign and install.

## 📤 How to Share

1. **Upload APK to cloud storage** (Google Drive, Dropbox, etc.)
2. **Share the download link** with others
3. They can download and install on Android devices

## ❓ Want a Web Version?

If you want to deploy to Vercel, you would need to:
1. Add web platform: `flutter create --platforms=web .`
2. Build web: `flutter build web --release`
3. Deploy `build/web/` to Vercel

But this is currently a **mobile-only app**.

---

**Current APK**: 47.7MB
**App Name**: White-Label Builder
**Package**: com.whitelabel.whitelabel_dashboard
