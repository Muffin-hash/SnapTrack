import 'dart:io';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/image_service.dart';
import '../services/location_service.dart';
import '../services/permission_service.dart';
import '../services/storage_service.dart';
import '../widgets/permission_denied_view.dart';

/// The Week 4 mini-project screen: create a post, attach a captured/picked
/// image, and optionally attach the device's current location — with
/// every permission-gated step handled explicitly rather than assumed.
class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _authService = AuthService();
  final _databaseService = DatabaseService();
  final _storageService = StorageService();
  final _imageService = ImageService();
  final _locationService = LocationService();
  final _permissionService = PermissionService();

  File? _selectedImage;
  double? _latitude;
  double? _longitude;
  String? _locationLabel;

  bool _isSaving = false;
  bool _isFetchingLocation = false;
  AppPermissionStatus? _cameraDenial;
  AppPermissionStatus? _locationDenial;
  String? _errorMessage;

  Future<void> _handleCapture() async {
    final status = await _permissionService.requestCamera();
    if (status != AppPermissionStatus.granted) {
      setState(() => _cameraDenial = status);
      return;
    }
    setState(() => _cameraDenial = null);
    final file = await _imageService.captureFromCamera();
    if (file != null) setState(() => _selectedImage = file);
  }

  Future<void> _handleGalleryPick() async {
    final status = await _permissionService.requestGallery();
    if (status != AppPermissionStatus.granted) {
      setState(() => _cameraDenial = status);
      return;
    }
    setState(() => _cameraDenial = null);
    final file = await _imageService.pickFromGallery();
    if (file != null) setState(() => _selectedImage = file);
  }

  Future<void> _handleAttachLocation() async {
    final status = await _permissionService.requestLocation();
    if (status != AppPermissionStatus.granted) {
      setState(() => _locationDenial = status);
      return;
    }
    setState(() {
      _locationDenial = null;
      _isFetchingLocation = true;
    });
    try {
      final loc = await _locationService.getCurrentLocation();
      setState(() {
        _latitude = loc.latitude;
        _longitude = loc.longitude;
        _locationLabel = loc.label;
      });
    } on LocationServiceDisabledException {
      setState(() => _errorMessage = 'Location services are turned off on this device.');
    } catch (_) {
      setState(() => _errorMessage = 'Could not read location. Please try again.');
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  Future<void> _handleSave() async {
    final uid = _authService.currentUser?.id;
    if (uid == null) {
      setState(() => _errorMessage = 'You must be signed in to create a post.');
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Title is required.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final post = await _databaseService.createPost(
        ownerUid: uid,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      if (_selectedImage != null) {
        try {
          final url = await _storageService.uploadPostImage(
            file: _selectedImage!,
            ownerUid: uid,
          );
          await _databaseService.attachImageUrl(post.id, url);
        } catch (_) {
          // Post already exists without the image — surface a warning
          // instead of failing the whole save (Validation Rules: safely
          // handle failed uploads before updating the UI).
          setState(() => _errorMessage = 'Post saved, but the image failed to upload.');
        }
      }

      if (_latitude != null && _longitude != null) {
        await _databaseService.attachLocation(
          postId: post.id,
          latitude: _latitude!,
          longitude: _longitude!,
          locationLabel: _locationLabel,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      setState(() => _errorMessage = 'Could not save your post. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Post')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 20),

            // --- Image section ---
            Text('Photo', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (_selectedImage != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.file(_selectedImage!, fit: BoxFit.cover),
              ),
            if (_cameraDenial != null)
              PermissionDeniedView(
                featureName: 'Camera/Gallery',
                status: _cameraDenial!,
                onRetry: _handleCapture,
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _handleCapture,
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Camera'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _handleGalleryPick,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Gallery'),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 20),

            // --- Location section ---
            Text('Location (optional)', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (_locationDenial != null)
              PermissionDeniedView(
                featureName: 'Location',
                status: _locationDenial!,
                onRetry: _handleAttachLocation,
              )
            else if (_isFetchingLocation)
              const Center(child: CircularProgressIndicator())
            else if (_latitude != null)
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _locationLabel ??
                          '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                    ),
                  ),
                ],
              )
            else
              OutlinedButton.icon(
                onPressed: _handleAttachLocation,
                icon: const Icon(Icons.my_location),
                label: const Text('Attach Current Location'),
              ),
            const SizedBox(height: 24),

            if (_errorMessage != null) ...[
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
            ],

            FilledButton(
              onPressed: _isSaving ? null : _handleSave,
              child: _isSaving
                  ? const SizedBox(
                      height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save Post'),
            ),
          ],
        ),
      ),
    );
  }
}
