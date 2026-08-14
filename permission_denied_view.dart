import 'package:flutter/material.dart';
import '../services/permission_service.dart';

/// Clear, non-crashing fallback shown whenever a permission the current
/// feature needs was denied or permanently denied — used for camera,
/// gallery, location, and notifications alike.
class PermissionDeniedView extends StatelessWidget {
  final String featureName;
  final AppPermissionStatus status;
  final VoidCallback onRetry;

  const PermissionDeniedView({
    super.key,
    required this.featureName,
    required this.status,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final permanentlyDenied = status == AppPermissionStatus.permanentlyDenied;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, size: 40, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            '$featureName access is ${permanentlyDenied ? 'permanently ' : ''}denied',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            permanentlyDenied
                ? 'Enable $featureName access in system settings to use this feature.'
                : 'This feature needs $featureName access to work. You can try again.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: permanentlyDenied
                ? () => PermissionService().openSettings()
                : onRetry,
            child: Text(permanentlyDenied ? 'Open Settings' : 'Try Again'),
          ),
        ],
      ),
    );
  }
}
