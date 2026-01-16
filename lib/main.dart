import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const WhiteLabelApp());
}

class WhiteLabelApp extends StatelessWidget {
  const WhiteLabelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'White-Label Automation',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1), // Indigo
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _repoController = TextEditingController();
  final _patController = TextEditingController();
  final _appNameController = TextEditingController();
  final _packageNameController = TextEditingController();
  final _domainController = TextEditingController();

  String? _logoBase64;
  String? _logoName;
  bool _isLoading = false;
  String? _statusMessage;
  bool _isError = false;

  Future<void> _pickLogo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true, // Important for web
    );

    if (result != null) {
      PlatformFile file = result.files.first;
      if (file.bytes != null) {
        setState(() {
          _logoName = file.name;
          _logoBase64 = base64Encode(file.bytes!);
        });
      }
    }
  }

  Future<void> _triggerBuild() async {
    if (!_formKey.currentState!.validate()) return;
    if (_logoBase64 == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please upload a logo')));
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      String repo = _repoController.text.trim();
      // Clean up if user pasted full URL (with or without protocol)
      repo = repo.replaceFirst(
        RegExp(r'^(https?:\/\/(www\.)?)?github\.com\/'),
        '',
      );
      if (repo.endsWith('/')) repo = repo.substring(0, repo.length - 1);
      final pat = _patController.text.trim();

      final url = Uri.parse('https://api.github.com/repos/$repo/dispatches');

      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'Authorization': 'token $pat',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'event_type': 'build_app',
          'client_payload': {
            'app_name': _appNameController.text.trim(),
            'package_name': _packageNameController.text.trim(),
            'domain': _domainController.text.trim(),
            'logo_base64': _logoBase64,
          },
        }),
      );

      if (response.statusCode == 204) {
        setState(() {
          _statusMessage =
              'Build triggered successfully! Check GitHub Actions.';
          _isError = false;
        });
      } else if (response.statusCode == 403) {
        setState(() {
          _statusMessage =
              'Permission denied (403). Grant "workflow" scope at github.com/settings/tokens';
          _isError = true;
        });
      } else {
        setState(() {
          _statusMessage =
              'Failed to trigger build: ${response.statusCode} ${response.body}';
          _isError = true;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
        _isError = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                _buildHeader(),
                const SizedBox(height: 40),
                _buildSectionTitle('GitHub Configuration'),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _repoController,
                  label: 'Repository (user/repo)',
                  hint: 'e.g., yasinali/flutter-whitelabel-base',
                  icon: Icons.code,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _patController,
                  label: 'Personal Access Token (PAT)',
                  hint: 'ghp_...',
                  icon: Icons.lock_outline,
                  obscureText: true,
                ),

                const SizedBox(height: 32),
                _buildSectionTitle('App Customization'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _appNameController,
                        label: 'App Name',
                        hint: 'Your App Name',
                        icon: Icons.branding_watermark,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _packageNameController,
                        label: 'Package Name',
                        hint: 'com.example.app',
                        icon: Icons.domain,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _domainController,
                  label: 'Domain / API URL',
                  hint: 'https://api.myapp.com',
                  icon: Icons.link,
                ),

                const SizedBox(height: 32),
                _buildSectionTitle('Branding'),
                const SizedBox(height: 16),
                _buildLogoPicker(),

                const SizedBox(height: 40),
                if (_statusMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isError
                          ? Colors.red.shade50
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isError
                            ? Colors.red.shade200
                            : Colors.green.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isError
                              ? Icons.error_outline
                              : Icons.check_circle_outline,
                          color: _isError ? Colors.red : Colors.green,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _statusMessage!,
                            style: TextStyle(
                              color: _isError
                                  ? Colors.red.shade900
                                  : Colors.green.shade900,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _triggerBuild,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Build & Update App',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
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
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.build_circle_outlined,
            size: 40,
            color: Color(0xFF6366F1),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'White-Label Automation',
          style: GoogleFonts.outfit(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Deploy custom branded apps with a single click',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade500,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'This field is required';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
        floatingLabelStyle: const TextStyle(color: Color(0xFF6366F1)),
      ),
    );
  }

  Widget _buildLogoPicker() {
    return InkWell(
      onTap: _pickLogo,
      borderRadius: BorderRadius.circular(12),
      child: DottedBorder(
        options: RectDottedBorderOptions(
          dashPattern: [10, 5],
          strokeWidth: 2,
          padding: EdgeInsets.all(16),
        ),

        child: Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: _logoBase64 != null
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                        image: DecorationImage(
                          image: MemoryImage(base64Decode(_logoBase64!)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _logoName ?? 'Logo Selected',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Click to change',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 32,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Click to upload app logo',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PNG format required',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
