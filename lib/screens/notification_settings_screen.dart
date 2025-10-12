import 'package:flutter/material.dart';
import 'package:mandyapp/helpers/extensions/string.dart';
import 'package:mandyapp/helpers/theme/app_theme.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/utils/app_helper.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  late ThemeData theme;
  
  // Notification settings state
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _smsNotifications = true;
  bool _orderNotifications = true;
  bool _promotionalNotifications = false;
  bool _chatNotifications = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    theme = AppTheme.shoppingManagerTheme;
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Load saved notification settings
    final pushNotif = await AppHelper.getPreferences('push_notifications');
    final emailNotif = await AppHelper.getPreferences('email_notifications');
    final smsNotif = await AppHelper.getPreferences('sms_notifications');
    final orderNotif = await AppHelper.getPreferences('order_notifications');
    final promoNotif = await AppHelper.getPreferences('promotional_notifications');
    final chatNotif = await AppHelper.getPreferences('chat_notifications');
    final sound = await AppHelper.getPreferences('notification_sound');
    final vibration = await AppHelper.getPreferences('notification_vibration');

    setState(() {
      _pushNotifications = pushNotif ?? true;
      _emailNotifications = emailNotif ?? false;
      _smsNotifications = smsNotif ?? true;
      _orderNotifications = orderNotif ?? true;
      _promotionalNotifications = promoNotif ?? false;
      _chatNotifications = chatNotif ?? true;
      _soundEnabled = sound ?? true;
      _vibrationEnabled = vibration ?? true;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    await AppHelper.savePreferences(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: MyText.titleMedium('notification_settings'.tr(), fontWeight: 600),
      ),
      body: ListView(
        padding: MySpacing.all(16),
        children: [
          MySpacing.height(8),
          
          // General Notifications Section
          _buildSectionHeader('general'.tr()),
          _buildSwitchTile(
            icon: Icons.notifications_active,
            title: 'push_notifications'.tr(),
            subtitle: 'push_notifications_desc'.tr(),
            value: _pushNotifications,
            onChanged: (value) {
              setState(() => _pushNotifications = value);
              _saveSetting('push_notifications', value);
            },
          ),
          _buildSwitchTile(
            icon: Icons.email,
            title: 'email_notifications'.tr(),
            subtitle: 'email_notifications_desc'.tr(),
            value: _emailNotifications,
            onChanged: (value) {
              setState(() => _emailNotifications = value);
              _saveSetting('email_notifications', value);
            },
          ),
          _buildSwitchTile(
            icon: Icons.sms,
            title: 'sms_notifications'.tr(),
            subtitle: 'sms_notifications_desc'.tr(),
            value: _smsNotifications,
            onChanged: (value) {
              setState(() => _smsNotifications = value);
              _saveSetting('sms_notifications', value);
            },
          ),
          
          MySpacing.height(24),
          
          // Notification Types Section
          _buildSectionHeader('notification_types'.tr()),
          _buildSwitchTile(
            icon: Icons.shopping_bag,
            title: 'order_notifications'.tr(),
            subtitle: 'order_notifications_desc'.tr(),
            value: _orderNotifications,
            onChanged: (value) {
              setState(() => _orderNotifications = value);
              _saveSetting('order_notifications', value);
            },
          ),
          _buildSwitchTile(
            icon: Icons.chat_bubble,
            title: 'chat_notifications'.tr(),
            subtitle: 'chat_notifications_desc'.tr(),
            value: _chatNotifications,
            onChanged: (value) {
              setState(() => _chatNotifications = value);
              _saveSetting('chat_notifications', value);
            },
          ),
          _buildSwitchTile(
            icon: Icons.local_offer,
            title: 'promotional_notifications'.tr(),
            subtitle: 'promotional_notifications_desc'.tr(),
            value: _promotionalNotifications,
            onChanged: (value) {
              setState(() => _promotionalNotifications = value);
              _saveSetting('promotional_notifications', value);
            },
          ),
          
          MySpacing.height(24),
          
          // Alert Settings Section
          _buildSectionHeader('alert_settings'.tr()),
          _buildSwitchTile(
            icon: Icons.volume_up,
            title: 'sound'.tr(),
            subtitle: 'sound_desc'.tr(),
            value: _soundEnabled,
            onChanged: (value) {
              setState(() => _soundEnabled = value);
              _saveSetting('notification_sound', value);
            },
          ),
          _buildSwitchTile(
            icon: Icons.vibration,
            title: 'vibration'.tr(),
            subtitle: 'vibration_desc'.tr(),
            value: _vibrationEnabled,
            onChanged: (value) {
              setState(() => _vibrationEnabled = value);
              _saveSetting('notification_vibration', value);
            },
          ),
          
          MySpacing.height(40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: MySpacing.bottom(12),
      child: MyText.titleSmall(
        title,
        fontWeight: 600,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: MySpacing.xy(16, 12),
      margin: MySpacing.bottom(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.dividerColor,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: MySpacing.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 24,
              color: theme.colorScheme.primary,
            ),
          ),
          MySpacing.width(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText.bodyMedium(
                  title,
                  fontWeight: 600,
                  color: theme.colorScheme.onBackground,
                ),
                MySpacing.height(4),
                MyText.bodySmall(
                  subtitle,
                  color: theme.colorScheme.onBackground.withOpacity(0.6),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          MySpacing.width(12),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
