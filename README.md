# Flutter White-Label Automation - Universal App

A beautiful Flutter application that runs on **Web, Android, and iOS** to automate the white-labeling process for Flutter apps using GitHub Actions.

## ✨ Universal Features

- 🌐 **Web App** - Deploy to Vercel and use from any browser
- 📱 **Mobile App** - Install native APK/IPA on Android/iOS
- 🎨 **Premium UI** - Responsive design that works on all screen sizes
- 🚀 **Automated Workflow** - Trigger GitHub Actions to build customized APKs

## 🚀 Deployment Options

### Option 1: Web Deployment (Vercel)

This is the easiest way to share the tool.

1.  **Clone/Fork** this repository
2.  **Connect to Vercel**:
    - Import the project
    - Framework Preset: `Flutter` (or `Other` if Flutter isn't auto-detected)
    - Build Command: `flutter build web --release`
    - Output Directory: `build/web`
3.  **Deploy**: Vercel will build and host the site.
4.  **Share URL**: Send the Vercel link to anyone.

**How it works on Vercel:**
- Users visit your URL
- They input THEIR repo URL and Token
- The app triggers actions on THEIR repository
- It updates THEIR app name, package, logo
- It builds an APK in THEIR repo artifacts

### Option 2: Mobile App (Android/iOS)

1.  **Build APK**:
    ```bash
    flutter build apk --release
    ```
2.  **Install**: Transfer `build/app/outputs/flutter-apk/app-release.apk` to your phone.
3.  **Use**: Open the app and build white-label apps from your phone.

## 🛠️ Usage Guide

1.  **Open the App** (Web or Mobile)
2.  **Fill Configuration**:
    - **Repository URL**: `https://github.com/username/repo`
    - **Token**: GitHub Personal Access Token (`repo`, `workflow` scopes)
    - **App Name**: New name for the app
    - **Package Name**: `com.example.newname`
    - **Logo**: Upload a PNG file
3.  **Click Build**: Watch the progress tracking!
4.  **Download Result**: Get the white-labeled APK from the link provided.

## ⚡ Integration Steps

To use this tool with your Flutter project, ensure your target repository has:

1.  **Dependencies** in `pubspec.yaml`:
    ```yaml
    dev_dependencies:
      rename_app: ^1.6.1
      change_app_package_name: ^1.1.0
      flutter_launcher_icons: ^0.13.1

    flutter_icons:
      image_path: "assets/logo/launcher.png"
      android: true
      ios: true
    ```
2.  **Workflow File**: Copy `.github/workflows/whitelabel-build.yml` to your repo.

## 📱 Platforms

- **Web**: Chrome, Safari, Firefox, Edge
- **Android**: API 21+
- **iOS**: iOS 11+

---

## 🔧 Troubleshooting

**Vercel Deployment**:
- Ensure `.vercelignore` allows `build/` folder.
- Build command must be `flutter build web --release`.

**Mobile Build**:
- Ensure Android SDK / Xcode is installed.

Made with ❤️ using Flutter
