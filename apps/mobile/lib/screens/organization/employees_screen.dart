import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_level.dart';
import '../../providers/user_profile_provider.dart';
import '../../theme/app_theme.dart';

class EmployeesScreen extends ConsumerWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeesNotifierProvider);
    final accountType = ref.watch(accountTypeProvider);

    if (!accountType.canManageEmployees) {
      return Scaffold(
        appBar: AppBar(title: const Text('Employés')),
        body: const Center(
          child: Text('Cette fonctionnalité n\'est pas disponible pour votre type de compte.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des employés'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(employeesNotifierProvider.notifier).refresh(),
          ),
        ],
      ),
      body: employeesAsync.when(
        data: (employees) {
          if (employees.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 80,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun employé',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ajoutez votre premier employé',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _showAddEmployeeDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter un employé'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: employees.length,
            itemBuilder: (context, index) {
              final employee = employees[index];
              return _EmployeeCard(
                employee: employee,
                onEdit: () => _showEditEmployeeDialog(context, ref, employee),
                onDelete: () => _confirmDeleteEmployee(context, ref, employee),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Erreur: $error'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.read(employeesNotifierProvider.notifier).refresh(),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEmployeeDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
    );
  }

  void _showAddEmployeeDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddEmployeeForm(
        onSubmit: (name, email, role, phone) async {
          final success = await ref.read(employeesNotifierProvider.notifier).addEmployee(
            name: name,
            email: email,
            role: role,
            phone: phone,
          );
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(success ? 'Employé ajouté' : 'Erreur lors de l\'ajout'),
                backgroundColor: success ? AppColors.success : Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  void _showEditEmployeeDialog(BuildContext context, WidgetRef ref, Employee employee) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _EditEmployeeForm(
        employee: employee,
        onSubmit: (name, role, isActive) async {
          final success = await ref.read(employeesNotifierProvider.notifier).updateEmployee(
            employee.id,
            name: name,
            role: role,
            isActive: isActive,
          );
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(success ? 'Employé mis à jour' : 'Erreur lors de la mise à jour'),
                backgroundColor: success ? AppColors.success : Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  void _confirmDeleteEmployee(BuildContext context, WidgetRef ref, Employee employee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'employé'),
        content: Text('Voulez-vous vraiment supprimer ${employee.name} de votre équipe ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(employeesNotifierProvider.notifier)
                  .removeEmployee(employee.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Employé supprimé' : 'Erreur lors de la suppression'),
                    backgroundColor: success ? null : Colors.red,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final Employee employee;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EmployeeCard({
    required this.employee,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: employee.photoUrl != null
              ? NetworkImage(employee.photoUrl!)
              : null,
          child: employee.photoUrl == null
              ? Text(employee.name.isNotEmpty ? employee.name[0].toUpperCase() : '?')
              : null,
        ),
        title: Row(
          children: [
            Text(employee.name),
            if (!employee.isActive) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Inactif',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(employee.role.displayName),
            if (employee.email != null)
              Text(
                employee.email!,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Modifier'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Supprimer', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        isThreeLine: employee.email != null,
      ),
    );
  }
}

class _AddEmployeeForm extends StatefulWidget {
  final Future<void> Function(String name, String email, EmployeeRole role, String? phone) onSubmit;

  const _AddEmployeeForm({required this.onSubmit});

  @override
  State<_AddEmployeeForm> createState() => _AddEmployeeFormState();
}

class _AddEmployeeFormState extends State<_AddEmployeeForm> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  EmployeeRole _role = EmployeeRole.groom;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Ajouter un employé', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nom complet *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Téléphone',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<EmployeeRole>(
            value: _role,
            decoration: const InputDecoration(
              labelText: 'Rôle',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.work),
            ),
            items: EmployeeRole.values.map((r) => DropdownMenuItem(
              value: r,
              child: Text(r.displayName),
            )).toList(),
            onChanged: (v) => setState(() => _role = v!),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _submit() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nom et email requis')),
      );
      return;
    }

    setState(() => _isLoading = true);
    await widget.onSubmit(
      _nameController.text,
      _emailController.text,
      _role,
      _phoneController.text.isNotEmpty ? _phoneController.text : null,
    );
    if (mounted) setState(() => _isLoading = false);
  }
}

class _EditEmployeeForm extends StatefulWidget {
  final Employee employee;
  final Future<void> Function(String name, EmployeeRole role, bool isActive) onSubmit;

  const _EditEmployeeForm({
    required this.employee,
    required this.onSubmit,
  });

  @override
  State<_EditEmployeeForm> createState() => _EditEmployeeFormState();
}

class _EditEmployeeFormState extends State<_EditEmployeeForm> {
  late final TextEditingController _nameController;
  late EmployeeRole _role;
  late bool _isActive;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.employee.name);
    _role = widget.employee.role;
    _isActive = widget.employee.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Modifier l\'employé', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nom complet *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<EmployeeRole>(
            value: _role,
            decoration: const InputDecoration(
              labelText: 'Rôle',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.work),
            ),
            items: EmployeeRole.values.map((r) => DropdownMenuItem(
              value: r,
              child: Text(r.displayName),
            )).toList(),
            onChanged: (v) => setState(() => _role = v!),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Actif'),
            subtitle: Text(_isActive ? 'L\'employé peut accéder à l\'application' : 'L\'employé ne peut plus accéder'),
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _submit() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nom est requis')),
      );
      return;
    }

    setState(() => _isLoading = true);
    await widget.onSubmit(_nameController.text, _role, _isActive);
    if (mounted) setState(() => _isLoading = false);
  }
}
