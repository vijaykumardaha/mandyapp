import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mandyapp/blocs/user/user_bloc.dart';
import 'package:mandyapp/helpers/theme/app_theme.dart';
import 'package:mandyapp/helpers/widgets/my_button.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/helpers/widgets/my_text_style.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late ThemeData theme;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    theme = AppTheme.shoppingManagerTheme;
    // Load current user when screen opens
    context.read<UserBloc>().add(LoadCurrentUser());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: MyText.titleMedium('Profile', fontWeight: 600),
      ),
      body: BlocConsumer<UserBloc, UserState>(
        listener: (context, state) {
          if (state is UserUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is UserError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMsg),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is UserLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is UserLoaded || state is UserUpdated) {
            final user = state is UserLoaded 
                ? state.user 
                : (state as UserUpdated).user;

            // Set initial values only if controllers are empty
            if (_nameController.text.isEmpty) {
              _nameController.text = user.name ?? '';
            }
            if (_mobileController.text.isEmpty) {
              _mobileController.text = user.mobile ?? '';
            }

            return SingleChildScrollView(
              padding: MySpacing.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: theme.colorScheme.primary,
                            child: Icon(
                              Icons.person,
                              size: 50,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                          MySpacing.height(12),
                          MyText.titleLarge(
                            user.name ?? 'User',
                            fontWeight: 600,
                          ),
                          MySpacing.height(4),
                          MyText.bodyMedium(
                            user.mobile ?? '',
                            color: theme.colorScheme.onBackground.withOpacity(0.6),
                          ),
                        ],
                      ),
                    ),
                    MySpacing.height(32),

                    // Name Field
                    MyText.bodyMedium('Name', fontWeight: 600),
                    MySpacing.height(8),
                    TextFormField(
                      controller: _nameController,
                      style: MyTextStyle.bodyMedium(),
                      decoration: InputDecoration(
                        hintText: 'Enter your name',
                        hintStyle: MyTextStyle.bodyMedium(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Icon(
                          Icons.person_outline,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    MySpacing.height(20),

                    // Mobile Field
                    MyText.bodyMedium('Mobile Number', fontWeight: 600),
                    MySpacing.height(8),
                    TextFormField(
                      controller: _mobileController,
                      style: MyTextStyle.bodyMedium(),
                      decoration: InputDecoration(
                        hintText: 'Enter mobile number',
                        hintStyle: MyTextStyle.bodyMedium(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Icon(
                          Icons.phone_outlined,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter mobile number';
                        }
                        if (value.length < 10) {
                          return 'Mobile number must be at least 10 digits';
                        }
                        return null;
                      },
                    ),
                    MySpacing.height(20),

                    // Password Field (Optional)
                    MyText.bodyMedium('New Password (Optional)', fontWeight: 600),
                    MySpacing.height(8),
                    TextFormField(
                      controller: _passwordController,
                      style: MyTextStyle.bodyMedium(),
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Leave blank to keep current password',
                        hintStyle: MyTextStyle.bodyMedium(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: theme.colorScheme.primary,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: theme.colorScheme.primary,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                    MySpacing.height(32),

                    // Update Button
                    MyButton.block(
                      padding: MySpacing.y(16),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // Update profile
                          context.read<UserBloc>().add(
                            UpdateUserProfile(
                              name: _nameController.text,
                              mobile: _mobileController.text,
                              password: _passwordController.text.isNotEmpty
                                  ? _passwordController.text
                                  : null,
                            ),
                          );
                        }
                      },
                      backgroundColor: theme.colorScheme.primary,
                      elevation: 0,
                      borderRadiusAll: 8,
                      child: MyText.bodyMedium(
                        'Update Profile',
                        fontWeight: 600,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48),
                MySpacing.height(16),
                MyText.bodyLarge('No user data available'),
              ],
            ),
          );
        },
      ),
    );
  }
}
