import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/build_config.dart';

class GitHubService {
  static const String _baseUrl = 'https://api.github.com';

  /// Parse repository URL to extract owner and repo name
  /// Example: https://github.com/owner/repo -> {owner: 'owner', repo: 'repo'}
  Map<String, String> parseRepoUrl(String url) {
    final uri = Uri.parse(url);
    final pathSegments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

    if (pathSegments.length >= 2) {
      return {'owner': pathSegments[0], 'repo': pathSegments[1]};
    }

    throw Exception('Invalid repository URL format');
  }

  /// Upload logo to the repository
  Future<String> uploadLogo({
    required String token,
    required String owner,
    required String repo,
    required Uint8List logoBytes,
    required String fileName,
  }) async {
    final url = '$_baseUrl/repos/$owner/$repo/contents/assets/logo/$fileName';

    // Convert image to base64
    final base64Content = base64Encode(logoBytes);

    // Check if file already exists
    String? existingSha;
    try {
      final checkResponse = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      if (checkResponse.statusCode == 200) {
        final data = jsonDecode(checkResponse.body);
        existingSha = data['sha'];
      }
    } catch (e) {
      // File doesn't exist, that's fine
    }

    // Upload or update the file
    final body = {
      'message': 'Upload logo for white-labeling',
      'content': base64Content,
      if (existingSha != null) 'sha': existingSha,
    };

    final response = await http.put(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/vnd.github.v3+json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['content']['path'];
    } else {
      throw Exception(
        'Failed to upload logo: ${response.statusCode} - ${response.body}',
      );
    }
  }

  /// Trigger the white-label workflow
  Future<int> triggerWorkflow({
    required String token,
    required String owner,
    required String repo,
    required BuildConfig config,
  }) async {
    final url =
        '$_baseUrl/repos/$owner/$repo/actions/workflows/whitelabel-build.yml/dispatches';

    final body = {
      'ref': 'main', // or 'master' depending on your default branch
      'inputs': {
        'app_name': config.appName,
        'package_name': config.packageName,
        'logo_path': config.logoPath,
      },
    };

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/vnd.github.v3+json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 204) {
      // Workflow triggered successfully
      // Now we need to get the run ID
      await Future.delayed(
        const Duration(seconds: 2),
      ); // Wait a bit for the run to start
      return await _getLatestWorkflowRunId(token, owner, repo);
    } else {
      throw Exception(
        'Failed to trigger workflow: ${response.statusCode} - ${response.body}',
      );
    }
  }

  /// Get the latest workflow run ID
  Future<int> _getLatestWorkflowRunId(
    String token,
    String owner,
    String repo,
  ) async {
    final url = '$_baseUrl/repos/$owner/$repo/actions/runs?per_page=1';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/vnd.github.v3+json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final runs = data['workflow_runs'] as List;
      if (runs.isNotEmpty) {
        return runs[0]['id'];
      }
    }

    throw Exception('Could not find workflow run');
  }

  /// Get workflow status
  Future<Map<String, dynamic>> getWorkflowStatus({
    required String token,
    required String owner,
    required String repo,
    required int runId,
  }) async {
    final url = '$_baseUrl/repos/$owner/$repo/actions/runs/$runId';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/vnd.github.v3+json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'status': data['status'], // queued, in_progress, completed
        'conclusion': data['conclusion'], // success, failure, cancelled, etc.
        'html_url': data['html_url'],
      };
    } else {
      throw Exception('Failed to get workflow status: ${response.statusCode}');
    }
  }

  /// Get artifact download URL
  Future<String?> getArtifactUrl({
    required String token,
    required String owner,
    required String repo,
    required int runId,
  }) async {
    final url = '$_baseUrl/repos/$owner/$repo/actions/runs/$runId/artifacts';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/vnd.github.v3+json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final artifacts = data['artifacts'] as List;

      if (artifacts.isNotEmpty) {
        // Return the first artifact's archive download URL
        return artifacts[0]['archive_download_url'];
      }
    }

    return null;
  }

  /// Poll workflow until completion
  Stream<Map<String, dynamic>> pollWorkflowStatus({
    required String token,
    required String owner,
    required String repo,
    required int runId,
  }) async* {
    while (true) {
      try {
        final status = await getWorkflowStatus(
          token: token,
          owner: owner,
          repo: repo,
          runId: runId,
        );

        yield status;

        // If completed, stop polling
        if (status['status'] == 'completed') {
          break;
        }

        // Wait before next poll
        await Future.delayed(const Duration(seconds: 5));
      } catch (e) {
        yield {'error': e.toString()};
        break;
      }
    }
  }
}
