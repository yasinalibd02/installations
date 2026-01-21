import 'dart:typed_data';

import '../models/build_config.dart';
import '../services/github_service.dart';
import '../widgets/file_upload_widget.dart';
import '../widgets/progress_tracker.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repoUrlController = TextEditingController();
  final _tokenController = TextEditingController();
  final _appNameController = TextEditingController();
  final _packageNameController = TextEditingController();
  final _domainController = TextEditingController();

  final _githubService = GitHubService();

  Uint8List? _logoBytes;
  String? _logoFileName;
  bool _isProcessing = false;
  BuildStep _currentStep = BuildStep.uploadingLogo;
  String? _errorMessage;
  String? _downloadUrl;
  String? _workflowUrl;

  @override
  void dispose() {
    _repoUrlController.dispose();
    _tokenController.dispose();
    _appNameController.dispose();
    _appNameController.dispose();
    _packageNameController.dispose();
    _domainController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_logoBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a logo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _currentStep = BuildStep.uploadingLogo;
      _errorMessage = null;
      _downloadUrl = null;
      _workflowUrl = null;
    });

    try {
      // Parse repo URL
      final repoInfo = _githubService.parseRepoUrl(
        _repoUrlController.text.trim(),
      );
      final owner = repoInfo['owner']!;
      final repo = repoInfo['repo']!;
      final token = _tokenController.text.trim();

      // Step 1: Upload logo
      setState(() => _currentStep = BuildStep.uploadingLogo);
      final logoPath = await _githubService.uploadLogo(
        token: token,
        owner: owner,
        repo: repo,
        logoBytes: _logoBytes!,
        fileName: _logoFileName ?? 'launcher.png',
      );

      // Step 2: Trigger workflow
      setState(() => _currentStep = BuildStep.triggeringWorkflow);
      final config = BuildConfig(
        repoUrl: _repoUrlController.text.trim(),
        token: token,
        appName: _appNameController.text.trim(),
        packageName: _packageNameController.text.trim(),
        logoPath: logoPath,
        domain: _domainController.text.trim(),
      );

      final runId = await _githubService.triggerWorkflow(
        token: token,
        owner: owner,
        repo: repo,
        config: config,
      );

      // Step 3-7: Poll workflow status
      await for (final status in _githubService.pollWorkflowStatus(
        token: token,
        owner: owner,
        repo: repo,
        runId: runId,
      )) {
        if (status.containsKey('error')) {
          throw Exception(status['error']);
        }

        // Update workflow URL
        if (status['html_url'] != null) {
          setState(() => _workflowUrl = status['html_url']);
        }

        // Map GitHub workflow status to our build steps
        final workflowStatus = status['status'];
        if (workflowStatus == 'in_progress') {
          // Cycle through steps for visual feedback
          setState(() {
            if (_currentStep.index < BuildStep.uploadingArtifact.index) {
              _currentStep = BuildStep.values[_currentStep.index + 1];
            }
          });
        } else if (workflowStatus == 'completed') {
          final conclusion = status['conclusion'];
          if (conclusion == 'success') {
            // Get artifact URL
            final artifactUrl = await _githubService.getArtifactUrl(
              token: token,
              owner: owner,
              repo: repo,
              runId: runId,
            );

            setState(() {
              _currentStep = BuildStep.completed;
              _downloadUrl = artifactUrl ?? status['html_url'];
            });
          } else {
            throw Exception('Workflow failed with conclusion: $conclusion');
          }
          break;
        }

        await Future.delayed(const Duration(seconds: 3));
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade900,
              Colors.black,
              Colors.blue.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    _buildHeader(),
                    const SizedBox(height: 48),

                    // Main content
                    LayoutBuilder(
                      builder: (context, constraints) {
                        // Mobile-first design: single column for screens < 900px
                        if (constraints.maxWidth < 900) {
                          return Column(
                            children: [
                              _buildForm(),
                              const SizedBox(height: 24),
                              _buildProgressSection(),
                            ],
                          );
                        } else {
                          // Desktop: side-by-side layout
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildForm()),
                              const SizedBox(width: 32),
                              Expanded(child: _buildProgressSection()),
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Colors.cyanAccent, Colors.purpleAccent],
            ),
          ),
          child: const Icon(Icons.auto_awesome, size: 48, color: Colors.white),
        ),
        const SizedBox(height: 24),
        const Text(
          'Flutter White-Label Automation',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Automate app customization and APK building with GitHub Actions',
          style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.7)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Configuration',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // Repository URL
            TextFormField(
              controller: _repoUrlController,
              validator: BuildConfig.validateRepoUrl,
              enabled: !_isProcessing,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'GitHub Repository URL',
                hintText: 'https://github.com/username/repo',
                prefixIcon: const Icon(Icons.link, color: Colors.cyanAccent),
                labelStyle: const TextStyle(color: Colors.white70),
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.cyanAccent,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Personal Access Token
            TextFormField(
              controller: _tokenController,
              validator: BuildConfig.validateToken,
              enabled: !_isProcessing,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Personal Access Token',
                hintText: 'ghp_xxxxxxxxxxxx',
                prefixIcon: const Icon(Icons.key, color: Colors.cyanAccent),
                labelStyle: const TextStyle(color: Colors.white70),
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.cyanAccent,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // App Name
            TextFormField(
              controller: _appNameController,
              validator: BuildConfig.validateAppName,
              enabled: !_isProcessing,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'App Name',
                hintText: 'My Awesome App',
                prefixIcon: const Icon(Icons.apps, color: Colors.cyanAccent),
                labelStyle: const TextStyle(color: Colors.white70),
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.cyanAccent,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Package Name
            TextFormField(
              controller: _packageNameController,
              validator: BuildConfig.validatePackageName,
              enabled: !_isProcessing,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Package Name',
                hintText: 'com.example.myapp',
                prefixIcon: const Icon(
                  Icons.inventory_2,
                  color: Colors.cyanAccent,
                ),
                labelStyle: const TextStyle(color: Colors.white70),
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.cyanAccent,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Domain (Optional)
            TextFormField(
              controller: _domainController,
              validator: BuildConfig.validateDomain,
              enabled: !_isProcessing,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Domain (Optional)',
                hintText: 'example.com',
                prefixIcon: const Icon(Icons.public, color: Colors.cyanAccent),
                labelStyle: const TextStyle(color: Colors.white70),
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.cyanAccent,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Logo Upload
            FileUploadWidget(
              onFileSelected: (bytes, fileName) {
                setState(() {
                  _logoBytes = bytes;
                  _logoFileName = fileName;
                });
              },
              onFileClear: () {
                setState(() {
                  _logoBytes = null;
                  _logoFileName = null;
                });
              },
            ),

            const SizedBox(height: 32),

            // Submit Button
            ElevatedButton(
              onPressed: _isProcessing ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 8,
              ),
              child: _isProcessing
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.black,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Processing...',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : const Text(
                      'Build APK',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    if (!_isProcessing &&
        _currentStep == BuildStep.uploadingLogo &&
        _errorMessage == null) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white.withOpacity(0.05),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        child: Column(
          children: [
            Icon(
              Icons.info_outline,
              size: 64,
              color: Colors.cyanAccent.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Fill in the form and click "Build APK" to start',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ProgressTracker(
      currentStep: _currentStep,
      errorMessage: _errorMessage,
      downloadUrl: _downloadUrl ?? _workflowUrl,
      onDownload: _downloadUrl != null || _workflowUrl != null
          ? () => _launchUrl(_downloadUrl ?? _workflowUrl!)
          : null,
    );
  }
}
