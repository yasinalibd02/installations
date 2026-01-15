# White-Label Automation Assets

This directory contains the automation assets required to white-label your Flutter app using GitHub Actions.

## Contents

1.  `whitelabel_workflow.yml`: The GitHub Actions workflow file.
2.  `process.py`: As helper Python script to handle string replacements and asset updates.

## Setup Instructions

### 1. Copy Files
Copy these files to your target Flutter repository:

- Move `whitelabel_workflow.yml` to `.github/workflows/whitelabel_workflow.yml`.
- Move `process.py` to the root of your repository (or adjust the path in the workflow file).

### 2. Configure Secrets
Go to your GitHub Repository Settings -> Secrets and Variables -> Actions -> New Repository Secret.

- **Name**: `PAT` (Personal Access Token)
  - This is required if you want to trigger builds from the Dashboard App.
  - The token must have `repo` scope.
- **Note**: The workflow uses `GITHUB_TOKEN` to push changes to the new branch, so ensure your Workflow permissions (Settings -> Actions -> General) are set to "Read and write permissions".

### 3. Usage
You can trigger the build via the **Flutter White-Label Dashboard** you just built.
Simply enter the Repo Owner/Name, your PAT, and the desired App details.

Alternatively, you can manually trigger it via Postman or cURL:

```bash
curl -X POST -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token YOUR_PAT" \
  https://api.github.com/repos/OWNER/REPO/dispatches \
  -d '{"event_type": "build_app", "client_payload": {"app_name": "MyApp", "package_name": "com.my.app", "domain": "https://api.my.app", "logo_base64": "..."}}'
```
