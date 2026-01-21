# Flutter White-Label Automation - Mobile App

A beautiful Flutter mobile application (Android & iOS) that automates the white-labeling process for Flutter apps using GitHub Actions.

## ✨ Features

- 📱 **Native Mobile App** - Works on Android and iOS devices
- 🎨 **Premium UI** - Modern, dark-themed interface optimized for mobile
- 🚀 **Automated Workflow** - Trigger GitHub Actions to build customized APKs
- 📊 **Real-time Progress** - Track build progress with animated indicators
- 💾 **Direct Download** - Download generated APK files from GitHub
- 🔒 **Secure** - Uses GitHub Personal Access Tokens

## 📱 Installation

### Android

1. Download the APK from releases or build it yourself
2. Enable "Install from Unknown Sources" in your Android settings
3. Install the APK
4. Open "White-Label Builder" app

### iOS

1. Build the app using Xcode
2. Sign with your Apple Developer account
3. Install on your device

## 🛠️ Building from Source

### Prerequisites

- Flutter SDK (3.10.7 or higher)
- Android Studio / Xcode
- GitHub account with repository access

### Build Android APK

```bash
cd /Users/yasinali/Documents/installations/whitelabel_dashboard
flutter build apk --release
```

The APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

### Build iOS App

```bash
flutter build ios --release
```

Then open in Xcode to sign and install.

### Build for Both Platforms

```bash
# Android
flutter build apk --split-per-abi --release

# iOS
flutter build ios --release
```

## 🔑 GitHub Personal Access Token Setup

1. Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. Give it a descriptive name (e.g., "White-Label Automation")
4. Select the following scopes:
   - ✅ `repo` (Full control of private repositories)
   - ✅ `workflow` (Update GitHub Action workflows)
5. Click "Generate token"
6. **Copy the token immediately** (you won't be able to see it again!)

## 📋 Usage

### Step 1: Prepare Your Flutter Repository

Ensure your Flutter project has the following in `pubspec.yaml`:

```yaml
dev_dependencies:
  change_app_package_name: ^1.5.0
  flutter_launcher_icons: ^0.11.0
  rename_app: ^1.1.0

flutter_icons:
  android: "launcher_icon"
  ios: false
  image_path: "assets/logo/launcher.png"
```

### Step 2: Add the Workflow File

Copy `.github/workflows/whitelabel-build.yml` to your repository.

### Step 3: Use the Mobile App

1. **Open the app** on your device
2. **Fill in the form**:
   - **Repository URL**: Your GitHub repository URL
   - **Personal Access Token**: The token you generated
   - **App Name**: The new name for your app
   - **Package Name**: The new package identifier (e.g., `com.example.myapp`)
   - **Logo**: Tap to select a PNG file from your device
3. **Tap "Build APK"** and watch the progress!
4. **Download your APK** when the build completes

## 🎯 What Happens During the Build?

1. ✅ Uploads your logo to the repository
2. ✅ Triggers the GitHub Actions workflow
3. ✅ Updates the app name
4. ✅ Updates the package name
5. ✅ Updates the launcher icon
6. ✅ Builds release APK files
7. ✅ Commits changes to a new branch
8. ✅ Uploads APK files as artifacts

## 📱 APK Information

- **App Name**: White-Label Builder
- **Package**: com.whitelabel.whitelabel_dashboard
- **Min SDK**: 21 (Android 5.0)
- **Target SDK**: Latest
- **Size**: ~48MB (release build)

## 🔧 Troubleshooting

### "Failed to upload logo"
- Check your internet connection
- Verify your Personal Access Token has `repo` permissions
- Ensure the repository URL is correct

### "Failed to trigger workflow"
- Ensure the workflow file exists in your repository
- Check that your token has `workflow` permissions
- Verify you have write access to the repository

### "Cannot install APK"
- Enable "Install from Unknown Sources" in Android settings
- Make sure you have enough storage space

## 🎨 Screenshots

The app features:
- Beautiful gradient background
- Responsive form fields
- File picker for logo upload
- Real-time progress tracking
- Success/error states

## 📄 Technical Details

### Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0              # GitHub API calls
  file_picker: ^8.0.0       # Logo file upload
  google_fonts: ^6.1.0      # Premium typography
  url_launcher: ^6.2.0      # Open GitHub links
  cupertino_icons: ^1.0.8   # iOS icons
```

### Permissions

**Android**:
- `INTERNET` - For GitHub API calls
- `ACCESS_NETWORK_STATE` - Check network connectivity

**iOS**:
- Network access (automatically granted)

## 🚀 Deployment

### Share the APK

1. Build the release APK
2. Upload to your server or cloud storage
3. Share the download link

### Publish to Play Store (Optional)

1. Create a Google Play Developer account
2. Build a signed release APK
3. Upload to Play Console
4. Follow the publishing guidelines

## 📞 Support

If you encounter any issues:
1. Check the troubleshooting section
2. Verify your GitHub token permissions
3. Ensure your repository has the workflow file
4. Check GitHub Actions logs for detailed errors

## 🔗 Related Files

- **GitHub Workflow**: `.github/workflows/whitelabel-build.yml`
- **Main App**: `lib/main.dart`
- **Home Screen**: `lib/screens/home_screen.dart`
- **GitHub Service**: `lib/services/github_service.dart`

---

Made with ❤️ using Flutter
