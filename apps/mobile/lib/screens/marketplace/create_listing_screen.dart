import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/models.dart';
import '../../providers/horses_provider.dart';
import '../../widgets/loading_button.dart';

enum CreateListingType { sale, mare, stallion }

class CreateListingScreen extends ConsumerStatefulWidget {
  final CreateListingType type;

  const CreateListingScreen({super.key, required this.type});

  @override
  ConsumerState<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends ConsumerState<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();

  Horse? _selectedHorse;
  List<File> _photos = [];
  bool _isLoading = false;
  bool _priceOnRequest = false;

  // For stallion
  String? _studFee;
  bool _frozenSemen = false;
  bool _freshSemen = true;

  // For mare
  String? _breedingStatus;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  String get _screenTitle => switch (widget.type) {
    CreateListingType.sale => 'Vendre un cheval',
    CreateListingType.mare => 'Proposer une jument',
    CreateListingType.stallion => 'Proposer un étalon',
  };

  String get _priceLabel => switch (widget.type) {
    CreateListingType.sale => 'Prix de vente',
    CreateListingType.mare => 'Prix de la saillie',
    CreateListingType.stallion => 'Prix de la saillie',
  };

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();

    if (images.isNotEmpty) {
      setState(() {
        _photos.addAll(images.map((img) => File(img.path)));
        if (_photos.length > 10) {
          _photos = _photos.sublist(0, 10);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maximum 10 photos')),
          );
        }
      });
    }
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  Future<void> _selectHorse() async {
    final horses = await ref.read(horsesProvider.future);

    if (!mounted) return;

    // Filter horses by gender for mare/stallion
    final filteredHorses = horses.where((h) {
      if (widget.type == CreateListingType.mare) {
        return h.gender == HorseGender.female;
      } else if (widget.type == CreateListingType.stallion) {
        return h.gender == HorseGender.male;
      }
      return true;
    }).toList();

    if (filteredHorses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.type == CreateListingType.mare
                ? 'Aucune jument disponible'
                : widget.type == CreateListingType.stallion
                    ? 'Aucun étalon disponible'
                    : 'Aucun cheval disponible',
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => ListView.builder(
        itemCount: filteredHorses.length,
        itemBuilder: (context, index) {
          final horse = filteredHorses[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: horse.photoUrl != null
                  ? NetworkImage(horse.photoUrl!)
                  : null,
              child: horse.photoUrl == null
                  ? const Icon(Icons.pets)
                  : null,
            ),
            title: Text(horse.name),
            subtitle: Text('${horse.breed ?? 'Race inconnue'} - ${horse.age} ans'),
            onTap: () {
              setState(() {
                _selectedHorse = horse;
                if (_titleController.text.isEmpty) {
                  _titleController.text = horse.name;
                }
              });
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedHorse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un cheval')),
      );
      return;
    }

    if (_photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez ajouter au moins une photo')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // TODO: Implement API call to create listing
      // 1. Upload photos to S3
      // 2. Create listing with photo URLs
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Annonce créée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
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
        title: Text(_screenTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Horse selection
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: _selectedHorse?.photoUrl != null
                        ? NetworkImage(_selectedHorse!.photoUrl!)
                        : null,
                    child: _selectedHorse?.photoUrl == null
                        ? const Icon(Icons.pets)
                        : null,
                  ),
                  title: Text(_selectedHorse?.name ?? 'Sélectionner un cheval'),
                  subtitle: _selectedHorse != null
                      ? Text('${_selectedHorse!.breed ?? 'Race inconnue'} - ${_selectedHorse!.age} ans')
                      : const Text('Appuyez pour choisir'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _selectHorse,
                ),
              ),
              const SizedBox(height: 16),

              // Photos
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Photos (${_photos.length}/10)',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          TextButton.icon(
                            onPressed: _pickImages,
                            icon: const Icon(Icons.add_photo_alternate),
                            label: const Text('Ajouter'),
                          ),
                        ],
                      ),
                      if (_photos.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _photos.length,
                            itemBuilder: (context, index) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      _photos[index],
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => _removePhoto(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 12),
                        Container(
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                              style: BorderStyle.solid,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.photo_library,
                                  size: 32,
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Aucune photo',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title and description
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre de l\'annonce',
                  hintText: 'Ex: Magnifique KWPN de 7 ans',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le titre est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Décrivez votre cheval en détail...',
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La description est requise';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Price
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: _priceLabel,
                        hintText: 'Ex: 15000',
                        suffixText: '€',
                        enabled: !_priceOnRequest,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (!_priceOnRequest && (value == null || value.isEmpty)) {
                          return 'Le prix est requis';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    children: [
                      const Text('Sur demande'),
                      Switch(
                        value: _priceOnRequest,
                        onChanged: (value) => setState(() => _priceOnRequest = value),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Location
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Localisation',
                  hintText: 'Ex: Paris, France',
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La localisation est requise';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Type-specific fields
              if (widget.type == CreateListingType.stallion) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Options de monte',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        CheckboxListTile(
                          title: const Text('Monte en main / IAF'),
                          value: _freshSemen,
                          onChanged: (v) => setState(() => _freshSemen = v ?? true),
                        ),
                        CheckboxListTile(
                          title: const Text('Semence congelée (IAC)'),
                          value: _frozenSemen,
                          onChanged: (v) => setState(() => _frozenSemen = v ?? false),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (widget.type == CreateListingType.mare) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Statut reproductif',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _breedingStatus,
                          decoration: const InputDecoration(
                            labelText: 'Statut',
                          ),
                          items: const [
                            DropdownMenuItem(value: 'maiden', child: Text('Maiden (jamais pouliné)')),
                            DropdownMenuItem(value: 'proven', child: Text('A déjà pouliné')),
                            DropdownMenuItem(value: 'in_foal', child: Text('Actuellement gestante')),
                          ],
                          onChanged: (v) => setState(() => _breedingStatus = v),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 24),

              LoadingButton(
                onPressed: _handleSubmit,
                isLoading: _isLoading,
                text: 'Publier l\'annonce',
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
