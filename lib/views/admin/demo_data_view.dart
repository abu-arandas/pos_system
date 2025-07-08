import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/demo_data_controller.dart';

class DemoDataView extends StatelessWidget {
  const DemoDataView({super.key});

  @override
  Widget build(BuildContext context) {
    final DemoDataController controller = Get.put(DemoDataController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Demo Data Management'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.data_saver_on,
                      size: 48,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Demo Data Management',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload or manage demo data for testing and demonstration purposes',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Statistics Section
            Obx(() {
              final stats = controller.getDemoDataStatistics();
              return Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Demo Data Statistics',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Users',
                              stats['users']['total'].toString(),
                              Icons.people,
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Stores',
                              stats['stores']['total'].toString(),
                              Icons.store,
                              Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Products',
                              stats['products']['total'].toString(),
                              Icons.inventory,
                              Colors.purple,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Transactions',
                              stats['transactions']['total'].toString(),
                              Icons.receipt,
                              Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            // Progress Section
            Obx(() => controller.isLoading.value
                ? Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          LinearProgressIndicator(
                            value: controller.uploadProgress.value,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            controller.uploadStatus.value,
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${controller.uploadedItems.value} / ${controller.totalItems.value} items',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Container()),

            // Status Section
            Obx(() => !controller.isLoading.value && controller.uploadStatus.value.isNotEmpty
                ? Card(
                    elevation: 2,
                    color: controller.uploadStatus.value.contains('Error') ? Colors.red.shade50 : Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            controller.uploadStatus.value.contains('Error') ? Icons.error : Icons.check_circle,
                            color: controller.uploadStatus.value.contains('Error') ? Colors.red : Colors.green,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              controller.uploadStatus.value,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: controller.uploadStatus.value.contains('Error')
                                        ? Colors.red.shade800
                                        : Colors.green.shade800,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Container()),

            const Spacer(),

            // Action Buttons
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: Obx(() => ElevatedButton.icon(
                        onPressed: controller.isLoading.value
                            ? null
                            : () async {
                                final confirmed = await _showConfirmationDialog(
                                  context,
                                  'Upload Demo Data',
                                  'This will upload demo data to the backend. This action will add new data to your database.',
                                );
                                if (confirmed) {
                                  controller.uploadAllDemoData();
                                }
                              },
                        icon: controller.isLoading.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.cloud_upload),
                        label: Text(
                          controller.isLoading.value ? 'Uploading...' : 'Upload Demo Data',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      )),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: Obx(() => OutlinedButton.icon(
                        onPressed: controller.isLoading.value
                            ? null
                            : () async {
                                final confirmed = await _showConfirmationDialog(
                                  context,
                                  'Clear Demo Data',
                                  'This will remove all demo data from the backend. This action cannot be undone.',
                                  isDestructive: true,
                                );
                                if (confirmed) {
                                  controller.clearAllDemoData();
                                }
                              },
                        icon: const Icon(Icons.delete_sweep),
                        label: const Text('Clear Demo Data'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(color: Colors.red.shade700),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      )),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: Obx(() => TextButton.icon(
                        onPressed: controller.isLoading.value
                            ? null
                            : () {
                                final isValid = controller.validateDemoData();
                                Get.snackbar(
                                  isValid ? 'Validation Passed' : 'Validation Failed',
                                  isValid ? 'Demo data is valid and ready for upload' : 'Demo data contains errors',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: isValid ? Colors.green : Colors.red,
                                  colorText: Colors.white,
                                );
                              },
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Validate Demo Data'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                        ),
                      )),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: Obx(() => TextButton.icon(
                        onPressed: controller.isLoading.value ? null : () => controller.copyDemoDataToClipboard(),
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy JSON to Clipboard'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue.shade700,
                        ),
                      )),
                ),
              ],
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _showConfirmationDialog(
    BuildContext context,
    String title,
    String content, {
    bool isDestructive = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(title),
              content: Text(content),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDestructive ? Colors.red : Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isDestructive ? 'Delete' : 'Upload'),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}
