class BuildConfig {
  final String repoUrl;
  final String token;
  final String appName;
  final String packageName;
  final String logoPath;
  final String? domain;

  BuildConfig({
    required this.repoUrl,
    required this.token,
    required this.appName,
    required this.packageName,
    required this.logoPath,
    this.domain,
  });

  Map<String, dynamic> toJson() {
    return {
      'repo_url': repoUrl,
      'token': token,
      'app_name': appName,
      'package_name': packageName,
      'logo_path': logoPath,
      'domain': domain,
    };
  }

  factory BuildConfig.fromJson(Map<String, dynamic> json) {
    return BuildConfig(
      repoUrl: json['repo_url'] as String,
      token: json['token'] as String,
      appName: json['app_name'] as String,
      packageName: json['package_name'] as String,
      logoPath: json['logo_path'] as String,
      domain: json['domain'] as String?,
    );
  }

  // Validation methods
  static String? validateRepoUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'Repository URL is required';
    }

    // Check if it's a valid GitHub URL
    final githubPattern = RegExp(
      r'^https?://github\.com/[\w-]+/[\w-]+/?$',
      caseSensitive: false,
    );

    if (!githubPattern.hasMatch(value)) {
      return 'Please enter a valid GitHub repository URL\n(e.g., https://github.com/username/repo)';
    }

    return null;
  }

  static String? validateToken(String? value) {
    if (value == null || value.isEmpty) {
      return 'Personal Access Token is required';
    }

    if (value.length < 20) {
      return 'Token seems too short. Please check your token';
    }

    return null;
  }

  static String? validateAppName(String? value) {
    if (value == null || value.isEmpty) {
      return 'App name is required';
    }

    if (value.length < 3) {
      return 'App name must be at least 3 characters';
    }

    return null;
  }

  static String? validatePackageName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Package name is required';
    }

    // Check if it matches package name format (e.g., com.example.app)
    final packagePattern = RegExp(r'^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$');

    if (!packagePattern.hasMatch(value)) {
      return 'Invalid package name format\n(e.g., com.example.myapp)';
    }

    return null;
  }

  static String? validateDomain(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional
    }

    final domainPattern = RegExp(
      r'^(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,6}$',
    );

    if (!domainPattern.hasMatch(value)) {
      return 'Invalid domain format (e.g., example.com)';
    }

    return null;
  }
}
