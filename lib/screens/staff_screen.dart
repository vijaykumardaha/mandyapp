import 'package:flutter/material.dart';
import 'package:mandyapp/utils/info_controller.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandyapp/blocs/user/user_bloc.dart';
import 'package:mandyapp/helpers/theme/app_theme.dart';
import 'package:mandyapp/widgets/common/my_text.dart';
import 'package:mandyapp/models/user_model.dart';
import 'package:mandyapp/widgets/staff/staff_form_sheet.dart';

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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StaffFormSheet(staff: staff),
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
            Info.error(state.errorMsg, context: context);
          } else if (state is UserUpdated) {
            Info.message('Staff member updated successfully', context: context);
            // Reload the staff list
            context.read<UserBloc>().add(LoadUsersByRole(role: 'staff'));
          } else if (state is UserDeleted) {
            Info.message('Staff member deleted successfully', context: context);
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
                final isActive = staff.isEnabled;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isActive
                          ? theme.colorScheme.primary.withOpacity(0.1)
                          : theme.colorScheme.onSurfaceVariant.withOpacity(0.1),
                      child: Text(
                        initials.toUpperCase(),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: isActive
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: MyText.bodyLarge(
                            staff.name ?? 'Unknown',
                            fontWeight: 500,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: MyText.bodySmall(
                            isActive ? 'Active' : 'Disabled',
                            color: isActive ? Colors.green : Colors.red,
                            fontWeight: 500,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    subtitle: MyText.bodyMedium(
                      staff.mobile ?? 'No mobile',
                      color: theme.colorScheme.primary,
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showStaffDialog(staff);
                        } else if (value == 'toggle') {
                          context.read<UserBloc>().add(
                            ToggleUserActive(
                              userId: staff.id!,
                              active: !isActive,
                            ),
                          );
                          context.read<UserBloc>().add(LoadUsersByRole(role: 'staff'));
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
                        PopupMenuItem(
                          value: 'toggle',
                          child: Row(
                            children: [
                              Icon(
                                isActive ? Icons.block : Icons.check_circle,
                                size: 16,
                                color: isActive ? Colors.red : Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Text(isActive ? 'Disable' : 'Enable'),
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
