import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../services/security_service.dart';
import '../../services/logger_service.dart';

class SettingsController extends GetxController {
  final RxBool isDarkMode = false.obs;
  final RxDouble taxRate = 8.5.obs;
  final RxString currency = 'USD'.obs;
  final RxBool enableNotifications = true.obs;
  final RxBool autoBackup = true.obs;
  final RxBool enableAnalytics = true.obs;

  final LoggerService _logger = Get.find<LoggerService>();

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  void _loadSettings() {
    // Load settings from local storage or Firebase
    // For now, using default values
    _logger.info('Settings loaded');
  }

  void updateTaxRate(double rate) {
    taxRate.value = rate;
    _logger.info('Tax rate updated to $rate%');
    Get.snackbar('Settings', 'Tax rate updated successfully');
  }

  void updateCurrency(String curr) {
    currency.value = curr;
    _logger.info('Currency updated to $curr');
    Get.snackbar('Settings', 'Currency updated successfully');
  }

  void toggleDarkMode(bool value) {
    isDarkMode.value = value;
    Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
    _logger.info('Dark mode ${value ? 'enabled' : 'disabled'}');
  }

  void toggleNotifications(bool value) {
    enableNotifications.value = value;
    _logger.info('Notifications ${value ? 'enabled' : 'disabled'}');
  }

  void toggleAutoBackup(bool value) {
    autoBackup.value = value;
    _logger.info('Auto backup ${value ? 'enabled' : 'disabled'}');
  }

  void toggleAnalytics(bool value) {
    enableAnalytics.value = value;
    _logger.info('Analytics ${value ? 'enabled' : 'disabled'}');
  }

  void exportData() async {
    try {
      _logger.info('Data export started');
      // Implement data export logic
      Get.snackbar('Export', 'Data export started. You will be notified when complete.');
    } catch (e) {
      _logger.error('Data export failed: $e');
      Get.snackbar('Error', 'Data export failed: $e');
    }
  }

  void clearLogs() {
    _logger.clearLogs();
    Get.snackbar('Settings', 'Application logs cleared');
  }
}

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SettingsController());
    final authController = Get.find<AuthController>();
    final securityService = Get.find<SecurityService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Section
            _buildProfileSection(context),

            const SizedBox(height: 24),

            // Business Settings
            if (securityService.hasPermission(Permission.manageSettings)) _buildBusinessSettings(context, controller),

            const SizedBox(height: 24),

            // App Settings
            _buildAppSettings(context, controller),

            const SizedBox(height: 24),

            // Data Management
            if (securityService.hasPermission(Permission.exportData)) _buildDataManagement(context, controller),

            const SizedBox(height: 24),

            // Debug Settings (only for admins)
            if (securityService.currentUserRole == UserRole.admin) _buildDebugSettings(context, controller),

            const SizedBox(height: 24),

            // Account Actions
            _buildAccountActions(context, authController),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    final securityService = Get.find<SecurityService>();
    final user = securityService.currentUser;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            if (user != null) ...[
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      user.firstName[0] + user.lastName[0],
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          user.email,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            user.role.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessSettings(BuildContext context, SettingsController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Business Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Tax Rate Setting
            ListTile(
              leading: const Icon(Icons.percent),
              title: const Text('Tax Rate'),
              subtitle: Obx(() => Text('${controller.taxRate.value}%')),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showTaxRateDialog(context, controller),
            ),

            const Divider(),

            // Currency Setting
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('Currency'),
              subtitle: Obx(() => Text(controller.currency.value)),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showCurrencyDialog(context, controller),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppSettings(BuildContext context, SettingsController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'App Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Dark Mode
            Obx(() => SwitchListTile(
                  secondary: const Icon(Icons.dark_mode),
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Toggle app theme'),
                  value: controller.isDarkMode.value,
                  onChanged: controller.toggleDarkMode,
                )),

            const Divider(),

            // Notifications
            Obx(() => SwitchListTile(
                  secondary: const Icon(Icons.notifications),
                  title: const Text('Notifications'),
                  subtitle: const Text('Enable push notifications'),
                  value: controller.enableNotifications.value,
                  onChanged: controller.toggleNotifications,
                )),

            const Divider(),

            // Auto Backup
            Obx(() => SwitchListTile(
                  secondary: const Icon(Icons.backup),
                  title: const Text('Auto Backup'),
                  subtitle: const Text('Automatic data backup'),
                  value: controller.autoBackup.value,
                  onChanged: controller.toggleAutoBackup,
                )),

            const Divider(),

            // Analytics
            Obx(() => SwitchListTile(
                  secondary: const Icon(Icons.analytics),
                  title: const Text('Analytics'),
                  subtitle: const Text('Help improve the app'),
                  value: controller.enableAnalytics.value,
                  onChanged: controller.toggleAnalytics,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildDataManagement(BuildContext context, SettingsController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Management',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Export Data'),
              subtitle: const Text('Download your business data'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: controller.exportData,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.sync),
              title: const Text('Sync Now'),
              subtitle: const Text('Sync data with cloud'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Get.snackbar('Sync', 'Data sync started');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugSettings(BuildContext context, SettingsController controller) {
    final logger = Get.find<LoggerService>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Debug Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.bug_report, color: Colors.orange),
              title: const Text('View Logs'),
              subtitle: const Text('View application logs'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showLogsDialog(context, logger),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.clear_all, color: Colors.red),
              title: const Text('Clear Logs'),
              subtitle: const Text('Clear all application logs'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: controller.clearLogs,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.data_saver_on, color: Colors.blue),
              title: const Text('Demo Data Management'),
              subtitle: const Text('Upload or manage demo data'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => Get.toNamed('/demo-data'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountActions(BuildContext context, AuthController authController) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sign Out'),
              subtitle: const Text('Sign out of your account'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showSignOutDialog(context, authController),
            ),
          ],
        ),
      ),
    );
  }

  void _showTaxRateDialog(BuildContext context, SettingsController controller) {
    final textController = TextEditingController(text: controller.taxRate.value.toString());

    Get.dialog(
      AlertDialog(
        title: const Text('Set Tax Rate'),
        content: TextField(
          controller: textController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Tax Rate (%)',
            border: OutlineInputBorder(),
            suffixText: '%',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final rate = double.tryParse(textController.text);
              if (rate != null && rate >= 0 && rate <= 100) {
                controller.updateTaxRate(rate);
                Get.back();
              } else {
                Get.snackbar('Error', 'Please enter a valid tax rate (0-100)');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showCurrencyDialog(BuildContext context, SettingsController controller) {
    final currencies = ['USD', 'EUR', 'GBP', 'CAD', 'AUD', 'JPY'];

    Get.dialog(
      AlertDialog(
        title: const Text('Select Currency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: currencies
              .map((currency) => ListTile(
                    title: Text(currency),
                    onTap: () {
                      controller.updateCurrency(currency);
                      Get.back();
                    },
                    trailing: Obx(() => controller.currency.value == currency
                        ? const Icon(Icons.check, color: Colors.green)
                        : const SizedBox.shrink()),
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showLogsDialog(BuildContext context, LoggerService logger) {
    final logs = logger.getRecentLogs();

    Get.dialog(
      AlertDialog(
        title: const Text('Application Logs'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: logs.isEmpty
              ? const Center(child: Text('No logs available'))
              : ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _getLogIcon(log.level),
                                  size: 16,
                                  color: _getLogColor(log.level),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  log.level.name.toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _getLogColor(log.level),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  log.timestamp.toString().substring(11, 19),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(log.message),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, AuthController authController) {
    Get.dialog(
      AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              authController.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  IconData _getLogIcon(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Icons.bug_report;
      case LogLevel.info:
        return Icons.info;
      case LogLevel.warning:
        return Icons.warning;
      case LogLevel.error:
        return Icons.error;
    }
  }

  Color _getLogColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Colors.grey;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
    }
  }
}
