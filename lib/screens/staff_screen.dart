import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandyapp/blocs/user/user_bloc.dart';
import 'package:mandyapp/helpers/theme/app_theme.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/models/user_model.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  late ThemeData theme;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    theme = AppTheme.shoppingManagerTheme;
    context.read<UserBloc>().add(LoadUsersByRole(role: 'staff'));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showStaffDialog([User? staff]) {
    final isEditing = staff != null;
    final nameController = TextEditingController(text: staff?.name ?? '');
    final mobileController = TextEditingController(text: staff?.mobile ?? '');
    final passwordController = TextEditingController(text: staff?.password ?? '');
    final String selectedRole = 'staff';
    bool _obscurePassword = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              MyText.titleMedium(
                isEditing ? 'Edit Staff Member' : 'Add Staff Member',
                fontWeight: 600,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Staff Name',
                  border: OutlineInputBorder(),
                ),
              ),
              MySpacing.height(16),
              TextField(
                controller: mobileController,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number',
                  border: OutlineInputBorder(),
                  helperText: 'Enter 10-digit mobile number',
                ),
                keyboardType: TextInputType.phone,
                maxLength: 10,
              ),
              MySpacing.height(16),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  helperText: 'Enter password for staff login',
                  suffixIcon: InkWell(
                    onTap: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    child: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                obscureText: _obscurePassword,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: MyText.bodyMedium('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (nameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              behavior: SnackBarBehavior.floating,
                              margin: EdgeInsets.only(top: 16, left: 16, right: 16),
                              content: Text('Please enter staff name'),
                            ),
                          );
                          return;
                        }

                        if (mobileController.text.trim().isEmpty || 
                            mobileController.text.length != 10) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              behavior: SnackBarBehavior.floating,
                              margin: EdgeInsets.only(top: 16, left: 16, right: 16),
                              content: Text('Please enter a valid 10-digit mobile number'),
                            ),
                          );
                          return;
                        }

                        if (passwordController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              behavior: SnackBarBehavior.floating,
                              margin: EdgeInsets.only(top: 16, left: 16, right: 16),
                              content: Text('Please enter a password'),
                            ),
                          );
                          return;
                        }

                        if (isEditing) {
                          final updatedStaff = User(
                            id: staff?.id,
                            name: nameController.text.trim(),
                            mobile: mobileController.text.trim(),
                            password: passwordController.text.trim(),
                            role: selectedRole,
                          );
                          context.read<UserBloc>().add(UpdateUser(user: updatedStaff));
                        } else {
                          context.read<UserBloc>().add(SaveUser(
                            name: nameController.text.trim(),
                            mobile: mobileController.text.trim(),
                            password: passwordController.text.trim(),
                            role: selectedRole,
                          ));
                        }
                        Navigator.pop(context);
                      },
                      child: MyText.bodyMedium(isEditing ? 'Update' : 'Add'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteStaff(User staff) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: MyText.titleMedium('Delete Staff Member', fontWeight: 600),
        content: MyText.bodyMedium(
          'Are you sure you want to delete "${staff.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: MyText.bodyMedium('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (staff.id != null) {
                context.read<UserBloc>().add(DeleteUser(userId: staff.id!));
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: MyText.bodyMedium('Delete'),
          ),
        ],
      ),
    );
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: TextField(
          controller: _searchController,
          onChanged: (query) {
            setState(() {});
          },
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Search staff...',
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: theme.colorScheme.primary),
            ),
            prefixIcon: Icon(Icons.search, size: 20, color: theme.colorScheme.onSurfaceVariant),
            prefixIconConstraints: const BoxConstraints(minWidth: 36),
            suffixIcon: IconButton(
              icon: Icon(Icons.person_add_outlined, size: 20, color: theme.colorScheme.onSurfaceVariant),
              tooltip: 'Add staff',
              onPressed: () => _showStaffDialog(),
            ),
            suffixIconConstraints: const BoxConstraints(minWidth: 40),
          ),
        ),
      ),
      body: BlocConsumer<UserBloc, UserState>(
        listener: (context, state) {
          if (state is UserError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
                content: Text(state.errorMsg),
              ),
            );
          } else if (state is UserUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.only(top: 16, left: 16, right: 16),
                content: Text('Staff member updated successfully'),
              ),
            );
            // Reload the staff list
            context.read<UserBloc>().add(LoadUsersByRole(role: 'staff'));
          } else if (state is UserDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.only(top: 16, left: 16, right: 16),
                content: Text('Staff member deleted successfully'),
              ),
            );
            // Reload the staff list
            context.read<UserBloc>().add(LoadUsersByRole(role: 'staff'));
          }
        },
        builder: (context, state) {
          if (state is UserLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is UsersByRoleLoaded && state.role == 'staff') {
            final query = _searchController.text.trim().toLowerCase();
            final filtered = state.users.where((s) {
              if (query.isEmpty) return true;
              final name = s.name?.toLowerCase() ?? '';
              final mobile = s.mobile ?? '';
              return name.contains(query) || mobile.contains(query);
            }).toList();

            if (filtered.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people,
                      size: 64,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    MyText.bodyMedium(
                      query.isEmpty ? 'No staff members found' : 'No results found',
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    MyText.bodySmall(
                      query.isEmpty ? 'Add your first staff member to get started' : '',
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final staff = filtered[index];
                final name = staff.name ?? 'Unknown';
                final nameParts = name.split(RegExp(r'\s+'));
                final initials = nameParts.length >= 2
                    ? '${nameParts.first[0]}${nameParts.last[0]}'
                    : nameParts.first[0];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                      child: Text(
                        initials.toUpperCase(),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: MyText.bodyLarge(
                      staff.name ?? 'Unknown',
                      fontWeight: 500,
                    ),
                    subtitle: MyText.bodyMedium(
                      staff.mobile ?? 'No mobile',
                      color: theme.colorScheme.primary,
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showStaffDialog(staff);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 16),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          } else {
            return Center(
              child: MyText.bodyMedium(
                'Tap the + button to add staff members',
                color: theme.colorScheme.onSurfaceVariant,
              ),
            );
          }
        },
      ),
    );
  }
}
