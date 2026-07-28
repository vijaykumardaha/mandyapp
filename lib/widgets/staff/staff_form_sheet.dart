import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandiapp/blocs/user/user_bloc.dart';
import 'package:mandiapp/helpers/theme/app_theme.dart';
import 'package:mandiapp/widgets/common/my_spacing.dart';
import 'package:mandiapp/widgets/common/my_text.dart';
import 'package:mandiapp/utils/info_controller.dart';
import 'package:mandiapp/models/user_model.dart';

class StaffFormSheet extends StatefulWidget {
  final User? staff;

  const StaffFormSheet({super.key, this.staff});

  @override
  State<StaffFormSheet> createState() => _StaffFormSheetState();
}

class _StaffFormSheetState extends State<StaffFormSheet> {
  late ThemeData theme;
  late TextEditingController nameController;
  late TextEditingController mobileController;
  late TextEditingController passwordController;
  final String selectedRole = 'staff';
  bool _obscurePassword = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    theme = AppTheme.shoppingManagerTheme;
    nameController = TextEditingController(text: widget.staff?.name ?? '');
    mobileController = TextEditingController(text: widget.staff?.mobile ?? '');
    passwordController = TextEditingController(text: widget.staff?.password ?? '');
  }

  @override
  void dispose() {
    nameController.dispose();
    mobileController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _save() {
    if (nameController.text.trim().isEmpty) {
      Info.message('Please enter staff name', context: context);
      return;
    }

    if (mobileController.text.trim().isEmpty ||
        mobileController.text.length != 10) {
      Info.message('Please enter a valid 10-digit mobile number', context: context);
      return;
    }

    if (passwordController.text.trim().isEmpty) {
      Info.message('Please enter a password', context: context);
      return;
    }

    setState(() => _isSaving = true);

    if (widget.staff != null) {
      final updatedStaff = User(
        id: widget.staff?.id,
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
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.staff != null;
    return BlocListener<UserBloc, UserState>(
      listener: (context, state) {
        if (state is UserUpdated) {
          Navigator.pop(context);
          Info.message(isEditing ? 'Staff updated successfully' : 'Staff added successfully', context: context);
          context.read<UserBloc>().add(LoadUsersByRole(role: 'staff'));
        } else if (state is UserError) {
          setState(() => _isSaving = false);
          Info.error(state.errorMsg, context: context);
        }
      },
      child: Padding(
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
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: MyText.bodyMedium('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : MyText.bodyMedium(isEditing ? 'Update' : 'Add'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
