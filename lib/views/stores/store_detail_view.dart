import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/store_model.dart';
import '../../services/security_service.dart';
import '../../controllers/store_controller.dart';
import 'add_store_view.dart';

class StoreDetailView extends StatefulWidget {
  final StoreModel store;

  const StoreDetailView({super.key, required this.store});

  @override
  State<StoreDetailView> createState() => _StoreDetailViewState();
}

class _StoreDetailViewState extends State<StoreDetailView> {
  final storeController = Get.find<StoreController>();
  Map<String, dynamic> storeStats = {};
  bool isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStoreStatistics();
  }

  Future<void> _loadStoreStatistics() async {
    setState(() => isLoadingStats = true);
    final stats = await storeController.getStoreStatistics(widget.store.id);
    setState(() {
      storeStats = stats;
      isLoadingStats = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.store.name),
        actions: [
          if (Get.find<SecurityService>().hasPermission(Permission.manageStores))
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => Get.to(() => AddStoreView(store: widget.store)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Store Status Card
            _buildStatusCard(context),
            
            const SizedBox(height: 24),
            
            // Statistics Section
            _buildStatisticsSection(context),
            
            const SizedBox(height: 24),
            
            // Basic Information
            _buildInfoSection(
              context,
              'Basic Information',
              [
                _buildInfoRow('Store Name', widget.store.name),
                if (widget.store.description.isNotEmpty)
                  _buildInfoRow('Description', widget.store.description),
                _buildInfoRow('Status', widget.store.isActive ? 'Active' : 'Inactive'),
                _buildInfoRow('Manager', storeController.getManagerName(widget.store.managerId)),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Location Information
            if (widget.store.fullAddress.isNotEmpty)
              _buildInfoSection(
                context,
                'Location',
                [
                  if (widget.store.address.isNotEmpty)
                    _buildInfoRow('Address', widget.store.address),
                  if (widget.store.city.isNotEmpty)
                    _buildInfoRow('City', widget.store.city),
                  if (widget.store.state.isNotEmpty)
                    _buildInfoRow('State/Province', widget.store.state),
                  if (widget.store.country.isNotEmpty)
                    _buildInfoRow('Country', widget.store.country),
                  if (widget.store.postalCode.isNotEmpty)
                    _buildInfoRow('Postal Code', widget.store.postalCode),
                ],
              ),
            
            const SizedBox(height: 24),
            
            // Contact Information
            if (widget.store.phone.isNotEmpty || widget.store.email.isNotEmpty)
              _buildInfoSection(
                context,
                'Contact Information',
                [
                  if (widget.store.phone.isNotEmpty)
                    _buildInfoRow('Phone', widget.store.phone),
                  if (widget.store.email.isNotEmpty)
                    _buildInfoRow('Email', widget.store.email),
                ],
              ),
            
            const SizedBox(height: 24),
            
            // Metadata
            _buildInfoSection(
              context,
              'Additional Information',
              [
                _buildInfoRow('Created', _formatDate(widget.store.createdAt)),
                _buildInfoRow('Last Updated', _formatDate(widget.store.updatedAt)),
                _buildInfoRow('Store ID', widget.store.id),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    return Card(
      color: widget.store.isActive 
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              widget.store.isActive ? Icons.check_circle : Icons.error,
              color: widget.store.isActive 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.error,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.store.isActive ? 'Store Active' : 'Store Inactive',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: widget.store.isActive 
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.error,
                    ),
                  ),
                  Text(
                    widget.store.isActive 
                        ? 'This store is currently operational'
                        : 'This store has been deactivated',
                    style: TextStyle(
                      color: widget.store.isActive 
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Store Statistics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 12),
        
        if (isLoadingStats)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          )
        else if (storeStats.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'No statistics available',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          )
        else
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                context,
                'Today\'s Sales',
                '\$${(storeStats['todaySales'] ?? 0.0).toStringAsFixed(2)}',
                Icons.attach_money,
                Colors.green,
              ),
              _buildStatCard(
                context,
                'Today\'s Orders',
                '${storeStats['todayTransactions'] ?? 0}',
                Icons.receipt_long,
                Colors.blue,
              ),
              _buildStatCard(
                context,
                'Month Sales',
                '\$${(storeStats['monthSales'] ?? 0.0).toStringAsFixed(2)}',
                Icons.trending_up,
                Colors.orange,
              ),
              _buildStatCard(
                context,
                'Total Products',
                '${storeStats['totalProducts'] ?? 0}',
                Icons.inventory,
                Colors.purple,
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 28,
              color: color,
            ),
            
            const SizedBox(height: 8),
            
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            
            const SizedBox(height: 4),
            
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: children,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
