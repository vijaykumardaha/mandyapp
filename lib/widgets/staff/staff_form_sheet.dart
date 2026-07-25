import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandyapp/blocs/user/user_bloc.dart';
import 'package:mandyapp/helpers/theme/app_theme.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/models/user_model.dart';

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

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.staff != null;
    return Padding(
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
                    Navigator.pop(context);
                  },
                  child: MyText.bodyMedium(isEditing ? 'Update' : 'Add'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
