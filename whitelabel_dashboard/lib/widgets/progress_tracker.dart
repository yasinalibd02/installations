import 'package:flutter/material.dart';

enum BuildStep {
  uploadingLogo,
  triggeringWorkflow,
  updatingAppName,
  updatingPackageName,
  updatingLauncherIcon,
  buildingApk,
  uploadingArtifact,
  completed,
}

class ProgressTracker extends StatelessWidget {
  final BuildStep currentStep;
  final String? errorMessage;
  final String? downloadUrl;
  final VoidCallback? onDownload;

  const ProgressTracker({
    super.key,
    required this.currentStep,
    this.errorMessage,
    this.downloadUrl,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final steps = BuildStep.values;
    final currentIndex = currentStep.index;
    final hasError = errorMessage != null;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade900.withOpacity(0.3),
            Colors.blue.shade900.withOpacity(0.3),
          ],
        ),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasError ? 'Build Failed' : 'Build Progress',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),

          // Progress steps
          ...steps.take(steps.length - 1).map((step) {
            final stepIndex = step.index;
            final isCompleted = stepIndex < currentIndex;
            final isCurrent = stepIndex == currentIndex;
            final isPending = stepIndex > currentIndex;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildStepItem(
                step: step,
                isCompleted: isCompleted && !hasError,
                isCurrent: isCurrent && !hasError,
                isPending: isPending || hasError,
                hasError: hasError && isCurrent,
              ),
            );
          }),

          // Error message
          if (hasError) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade900.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Success and download button
          if (currentStep == BuildStep.completed && !hasError) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade700, Colors.teal.shade700],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 48),
                      SizedBox(width: 16),
                      Text(
                        'Build Completed!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (downloadUrl != null)
                    ElevatedButton.icon(
                      onPressed: onDownload,
                      icon: const Icon(Icons.download),
                      label: const Text('Download APK'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.teal.shade700,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required BuildStep step,
    required bool isCompleted,
    required bool isCurrent,
    required bool isPending,
    required bool hasError,
  }) {
    IconData icon;
    Color iconColor;
    Color textColor;

    if (hasError) {
      icon = Icons.error;
      iconColor = Colors.redAccent;
      textColor = Colors.redAccent;
    } else if (isCompleted) {
      icon = Icons.check_circle;
      iconColor = Colors.greenAccent;
      textColor = Colors.white;
    } else if (isCurrent) {
      icon = Icons.autorenew;
      iconColor = Colors.cyanAccent;
      textColor = Colors.cyanAccent;
    } else {
      icon = Icons.radio_button_unchecked;
      iconColor = Colors.white30;
      textColor = Colors.white30;
    }

    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          child: Icon(icon, color: iconColor, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            _getStepLabel(step),
            style: TextStyle(
              fontSize: 16,
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
              color: textColor,
            ),
          ),
        ),
        if (isCurrent && !hasError)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
            ),
          ),
      ],
    );
  }

  String _getStepLabel(BuildStep step) {
    switch (step) {
      case BuildStep.uploadingLogo:
        return 'Uploading logo to repository';
      case BuildStep.triggeringWorkflow:
        return 'Triggering GitHub Actions workflow';
      case BuildStep.updatingAppName:
        return 'Updating app name';
      case BuildStep.updatingPackageName:
        return 'Updating package name';
      case BuildStep.updatingLauncherIcon:
        return 'Updating launcher icon';
      case BuildStep.buildingApk:
        return 'Building APK files';
      case BuildStep.uploadingArtifact:
        return 'Uploading artifacts';
      case BuildStep.completed:
        return 'Completed';
    }
  }
}
