import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandiapp/blocs/reports/reports_bloc.dart';
import 'package:mandiapp/blocs/user/user_bloc.dart';
import 'package:mandiapp/helpers/theme/app_theme.dart';
import 'package:mandiapp/services/socket_service.dart';
import 'package:mandiapp/services/sync_service.dart';
import 'package:mandiapp/utils/info_controller.dart';
import 'package:mandiapp/widgets/common/common_app_bar.dart';
import 'package:mandiapp/widgets/common/my_button.dart';
import 'package:mandiapp/widgets/common/my_spacing.dart';
import 'package:mandiapp/widgets/common/my_text.dart';
import 'package:mandiapp/widgets/common/my_text_style.dart';

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
  bool _isSyncing = false;

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
      appBar: CommonAppBar(
        titleWidget: const MyText.titleMedium('Profile', fontWeight: 600),
        actions: [
          StreamBuilder<bool>(
            stream: SocketService.instance.connectionStream,
            initialData: SocketService.instance.isConnected,
            builder: (context, snapshot) {
              if (snapshot.data != true) return const SizedBox.shrink();
              return GestureDetector(
                onTap: _isSyncing
                    ? null
                    : () async {
                        setState(() => _isSyncing = true);
                        await SyncService.instance.bulkSync();
                        if (mounted) {
                          setState(() => _isSyncing = false);
                          this
                              .context
                              .read<ReportsBloc>()
                              .add(const LoadDashboardData());
                        }
                      },
                child: Container(
                  margin: const EdgeInsets.only(right: 15),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _isSyncing
                          ? SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            )
                          : Icon(Icons.sync_rounded,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        _isSyncing ? 'Data Syncing...' : 'Data Sync',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: BlocConsumer<UserBloc, UserState>(
              listener: (context, state) {
                if (state is UserUpdated) {
                  Info.message('Profile updated successfully',
                      context: context);
                } else if (state is UserError) {
                  Info.error(state.errorMsg, context: context);
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
                                MyText.titleLarge(
                                  user.name ?? 'User',
                                  fontWeight: 600,
                                ),
                                MySpacing.height(4),
                                MyText.bodyMedium(
                                  user.mobile ?? '',
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ],
                            ),
                          ),
                          MySpacing.height(32),

                          // Name Field
                          const MyText.bodyMedium('Mandi Name',
                              fontWeight: 600),
                          MySpacing.height(8),
                          TextFormField(
                            controller: _nameController,
                            enabled: false,
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
                          const MyText.bodyMedium('Mobile Number',
                              fontWeight: 600),
                          MySpacing.height(8),
                          TextFormField(
                            controller: _mobileController,
                            enabled: false,
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
                          const MyText.bodyMedium('New Password (Optional)',
                              fontWeight: 600),
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
                              if (_passwordController.text.isEmpty) {
                                Info.error('Please enter a new password',
                                    context: context);
                                return;
                              }
                              context.read<UserBloc>().add(
                                    UpdateUserProfile(
                                      name: _nameController.text,
                                      mobile: _mobileController.text,
                                      password: _passwordController.text,
                                    ),
                                  );
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
                      const MyText.bodyLarge('No user data available'),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_isSyncing)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
