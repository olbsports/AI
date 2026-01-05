import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../providers/riders_provider.dart';
import '../../widgets/loading_button.dart';

class RiderFormScreen extends ConsumerStatefulWidget {
  final String? riderId;

  const RiderFormScreen({super.key, this.riderId});

  @override
  ConsumerState<RiderFormScreen> createState() => _RiderFormScreenState();
}

class _RiderFormScreenState extends ConsumerState<RiderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  File? _selectedPhoto;
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.riderId != null;
    if (_isEditing) {
      _loadRiderData();
    }
  }

  Future<void> _loadRiderData() async {
    final rider = await ref.read(riderProvider(widget.riderId!).future);
    setState(() {
      _firstNameController.text = rider.firstName;
      _lastNameController.text = rider.lastName;
      _emailController.text = rider.email ?? '';
      _phoneController.text = rider.phone ?? '';
      _notesController.text = rider.notes ?? '';
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedPhoto = File(image.path);
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final data = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        if (_emailController.text.isNotEmpty)
          'email': _emailController.text.trim(),
        if (_phoneController.text.isNotEmpty)
          'phone': _phoneController.text.trim(),
        if (_notesController.text.isNotEmpty)
          'notes': _notesController.text.trim(),
      };

      dynamic rider;
      if (_isEditing) {
        rider = await ref.read(ridersNotifierProvider.notifier).updateRider(
              widget.riderId!,
              data,
            );
      } else {
        rider = await ref.read(ridersNotifierProvider.notifier).createRider(data);
      }

      if (rider != null && _selectedPhoto != null) {
        await ref.read(ridersNotifierProvider.notifier).uploadPhoto(
              rider.id,
              _selectedPhoto!,
            );
      }

      if (mounted) {
        if (rider != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditing ? 'Cavalier modifié' : 'Cavalier ajouté'),
            ),
          );
          context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de l\'enregistrement'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier le cavalier' : 'Nouveau cavalier'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo
              Center(
                child: InkWell(
                  onTap: _pickImage,
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(50),
                      image: _selectedPhoto != null
                          ? DecorationImage(
                              image: FileImage(_selectedPhoto!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _selectedPhoto == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Photo',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // First name
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'Prénom *',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le prénom est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Last name
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Nom *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le nom est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 16),

              // Phone
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  prefixIcon: Icon(Icons.notes),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),

              // Submit
              LoadingButton(
                onPressed: _handleSubmit,
                isLoading: _isLoading,
                text: _isEditing ? 'Enregistrer' : 'Ajouter le cavalier',
                icon: _isEditing ? Icons.save : Icons.add,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
