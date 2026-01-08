import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../models/horse.dart';
import '../../providers/horses_provider.dart';
import '../../widgets/loading_button.dart';

class HorseFormScreen extends ConsumerStatefulWidget {
  final String? horseId;

  const HorseFormScreen({super.key, this.horseId});

  @override
  ConsumerState<HorseFormScreen> createState() => _HorseFormScreenState();
}

class _HorseFormScreenState extends ConsumerState<HorseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _sireIdController = TextEditingController();
  final _microchipController = TextEditingController();
  final _breedController = TextEditingController();
  final _colorController = TextEditingController();
  final _heightController = TextEditingController();
  final _notesController = TextEditingController();

  HorseGender _gender = HorseGender.male;
  HorseStatus _status = HorseStatus.active;
  HorseDiscipline _discipline = HorseDiscipline.none;
  int _level = 0; // 0 = non spécifié, 1-7 = niveau
  DateTime? _birthDate;
  File? _selectedPhoto;
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.horseId != null;
    if (_isEditing) {
      _loadHorseData();
    }
  }

  Future<void> _loadHorseData() async {
    try {
      final horse = await ref.read(horseProvider(widget.horseId!).future);
      if (mounted) {
        setState(() {
          _nameController.text = horse.name;
          _sireIdController.text = horse.sireId ?? '';
          _microchipController.text = horse.microchip ?? '';
          _breedController.text = horse.breed ?? '';
          _colorController.text = horse.color ?? '';
          _heightController.text = horse.heightCm?.toString() ?? '';
          _notesController.text = horse.notes ?? '';
          _gender = horse.gender;
          _status = horse.status;
          _discipline = horse.discipline;
          _level = horse.level;
          _birthDate = horse.birthDate;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors du chargement des données'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sireIdController.dispose();
    _microchipController.dispose();
    _breedController.dispose();
    _colorController.dispose();
    _heightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    // Demander la permission
    PermissionStatus status;
    if (Platform.isAndroid) {
      // Android 13+ utilise photos au lieu de storage
      if (await Permission.photos.isGranted) {
        status = PermissionStatus.granted;
      } else {
        status = await Permission.photos.request();
        // Fallback pour Android < 13
        if (status.isDenied) {
          status = await Permission.storage.request();
        }
      }
    } else {
      // iOS
      status = await Permission.photos.request();
    }

    if (status.isGranted) {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedPhoto = File(image.path);
        });
      }
    } else if (status.isPermanentlyDenied) {
      if (mounted) {
        _showPermissionDialog();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission d\'accès aux photos refusée'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission requise'),
        content: const Text(
          'L\'accès aux photos est nécessaire pour ajouter une photo de profil. '
          'Veuillez autoriser l\'accès dans les paramètres de l\'application.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Ouvrir les paramètres'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectBirthDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now().subtract(const Duration(days: 365 * 5)),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _birthDate = date;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final data = {
        'name': _nameController.text.trim(),
        'gender': _gender.name,
        'status': _status.name,
        if (_sireIdController.text.isNotEmpty)
          'sireId': _sireIdController.text.trim(),
        if (_microchipController.text.isNotEmpty)
          'microchip': _microchipController.text.trim(),
        if (_breedController.text.isNotEmpty)
          'breed': _breedController.text.trim(),
        if (_colorController.text.isNotEmpty)
          'color': _colorController.text.trim(),
        if (_heightController.text.isNotEmpty)
          'heightCm': int.tryParse(_heightController.text),
        if (_birthDate != null)
          'birthDate': _birthDate!.toIso8601String(),
        if (_notesController.text.isNotEmpty)
          'notes': _notesController.text.trim(),
        if (_discipline != HorseDiscipline.none)
          'discipline': _discipline.name,
        if (_level > 0)
          'level': _level,
      };

      Horse? horse;
      if (_isEditing) {
        horse = await ref.read(horsesNotifierProvider.notifier).updateHorse(
          widget.horseId!,
          data,
        );
      } else {
        horse = await ref.read(horsesNotifierProvider.notifier).createHorse(data);
      }

      if (horse != null && _selectedPhoto != null) {
        try {
          final photoUrl = await ref.read(horsesNotifierProvider.notifier).uploadPhoto(
            horse.id,
            _selectedPhoto!,
          );
          if (photoUrl == null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('La photo n\'a pas pu être téléchargée'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Erreur lors du téléchargement de la photo'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }

      if (!mounted) return;

      if (horse != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Cheval modifié' : 'Cheval ajouté'),
          ),
        );
        if (mounted) {
          context.go('/horses/${horse.id}');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'enregistrement'),
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
        title: Text(_isEditing ? 'Modifier le cheval' : 'Nouveau cheval'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo section
              _buildPhotoSection(),
              const SizedBox(height: 24),

              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom *',
                  prefixIcon: Icon(Icons.pets),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le nom est requis';
                  }
                  if (value.length < 2) {
                    return 'Le nom doit contenir au moins 2 caractères';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Gender
              DropdownButtonFormField<HorseGender>(
                initialValue: _gender,
                decoration: const InputDecoration(
                  labelText: 'Sexe *',
                  prefixIcon: Icon(Icons.male),
                ),
                items: HorseGender.values.map((gender) {
                  return DropdownMenuItem(
                    value: gender,
                    child: Text(_genderLabel(gender)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _gender = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Birth date
              InkWell(
                onTap: _selectBirthDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date de naissance',
                    prefixIcon: Icon(Icons.cake),
                  ),
                  child: Text(
                    _birthDate != null
                        ? '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'
                        : 'Sélectionner',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: _birthDate == null
                              ? Theme.of(context).colorScheme.onSurfaceVariant
                              : null,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Breed
              TextFormField(
                controller: _breedController,
                decoration: const InputDecoration(
                  labelText: 'Race',
                  prefixIcon: Icon(Icons.category),
                ),
              ),
              const SizedBox(height: 16),

              // Color
              TextFormField(
                controller: _colorController,
                decoration: const InputDecoration(
                  labelText: 'Robe',
                  prefixIcon: Icon(Icons.palette),
                ),
              ),
              const SizedBox(height: 16),

              // Height
              TextFormField(
                controller: _heightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Taille (cm)',
                  prefixIcon: Icon(Icons.straighten),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final height = int.tryParse(value);
                    if (height == null) {
                      return 'Entrez un nombre valide';
                    }
                    if (height < 100 || height > 250) {
                      return 'La taille doit être entre 100 et 250 cm';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // SIRE
              TextFormField(
                controller: _sireIdController,
                decoration: const InputDecoration(
                  labelText: 'Numéro SIRE',
                  prefixIcon: Icon(Icons.numbers),
                ),
              ),
              const SizedBox(height: 16),

              // Microchip
              TextFormField(
                controller: _microchipController,
                decoration: const InputDecoration(
                  labelText: 'Numéro de puce',
                  prefixIcon: Icon(Icons.qr_code),
                ),
              ),
              const SizedBox(height: 16),

              // Discipline
              DropdownButtonFormField<HorseDiscipline>(
                initialValue: _discipline,
                decoration: const InputDecoration(
                  labelText: 'Discipline',
                  prefixIcon: Icon(Icons.sports),
                ),
                items: HorseDiscipline.values.map((discipline) {
                  return DropdownMenuItem(
                    value: discipline,
                    child: Text(_disciplineLabel(discipline)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _discipline = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Level
              DropdownButtonFormField<int>(
                initialValue: _level,
                decoration: const InputDecoration(
                  labelText: 'Niveau',
                  prefixIcon: Icon(Icons.military_tech),
                ),
                items: [
                  const DropdownMenuItem(value: 0, child: Text('Non spécifié')),
                  ...List.generate(7, (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text('Niveau ${i + 1}'),
                  )),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _level = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Status
              DropdownButtonFormField<HorseStatus>(
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'Statut',
                  prefixIcon: Icon(Icons.info),
                ),
                items: HorseStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(_statusLabel(status)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _status = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  prefixIcon: Icon(Icons.notes),
                  alignLabelWithHint: true,
                ),
                maxLength: 1000,
              ),
              const SizedBox(height: 24),

              // Submit button
              LoadingButton(
                onPressed: _handleSubmit,
                isLoading: _isLoading,
                text: _isEditing ? 'Enregistrer' : 'Ajouter le cheval',
                icon: _isEditing ? Icons.save : Icons.add,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Center(
      child: InkWell(
        onTap: _pickImage,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
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
                      size: 40,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ajouter photo',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                )
              : Stack(
                  children: [
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  String _genderLabel(HorseGender gender) {
    switch (gender) {
      case HorseGender.male:
        return 'Mâle';
      case HorseGender.female:
        return 'Femelle';
      case HorseGender.gelding:
        return 'Hongre';
    }
  }

  String _statusLabel(HorseStatus status) {
    switch (status) {
      case HorseStatus.active:
        return 'Actif';
      case HorseStatus.retired:
        return 'Retraité';
      case HorseStatus.sold:
        return 'Vendu';
      case HorseStatus.deceased:
        return 'Décédé';
    }
  }

  String _disciplineLabel(HorseDiscipline discipline) {
    switch (discipline) {
      case HorseDiscipline.none:
        return 'Non spécifié';
      case HorseDiscipline.dressage:
        return 'Dressage';
      case HorseDiscipline.jumping:
        return 'Saut d\'obstacles';
      case HorseDiscipline.eventing:
        return 'Concours complet';
      case HorseDiscipline.endurance:
        return 'Endurance';
      case HorseDiscipline.western:
        return 'Western';
      case HorseDiscipline.polo:
        return 'Polo';
      case HorseDiscipline.racing:
        return 'Courses';
      case HorseDiscipline.leisure:
        return 'Loisir';
    }
  }
}
