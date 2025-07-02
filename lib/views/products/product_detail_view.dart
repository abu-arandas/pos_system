import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/product_model.dart';
import '../../services/security_service.dart';
import 'add_product_view.dart';

class ProductDetailView extends StatelessWidget {
  final ProductModel product;

  const ProductDetailView({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          if (Get.find<SecurityService>().hasPermission(Permission.manageProducts))
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => Get.to(() => AddProductView(product: product)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image Section
            if (product.imageUrls.isNotEmpty)
              _buildImageSection(context)
            else
              _buildPlaceholderImage(context),
            
            const SizedBox(height: 24),
            
            // Basic Information
            _buildInfoSection(
              context,
              'Basic Information',
              [
                _buildInfoRow('Name', product.name),
                if (product.description.isNotEmpty)
                  _buildInfoRow('Description', product.description),
                if (product.categoryId.isNotEmpty)
                  _buildInfoRow('Category', product.categoryId),
                _buildInfoRow('Type', _getProductTypeLabel(product.type)),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Pricing Information
            _buildInfoSection(
              context,
              'Pricing',
              [
                _buildInfoRow('Selling Price', '\$${product.price.toStringAsFixed(2)}'),
                if (product.costPrice != null)
                  _buildInfoRow('Cost Price', '\$${product.costPrice!.toStringAsFixed(2)}'),
                if (product.costPrice != null)
                  _buildInfoRow(
                    'Profit Margin',
                    '${product.profitMargin.toStringAsFixed(1)}%',
                    valueColor: product.profitMargin > 0 ? Colors.green : Colors.red,
                  ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Product Identification
            if (product.sku != null || product.barcode != null)
              _buildInfoSection(
                context,
                'Product Identification',
                [
                  if (product.sku != null)
                    _buildInfoRow('SKU', product.sku!),
                  if (product.barcode != null)
                    _buildInfoRow('Barcode', product.barcode!),
                ],
              ),
            
            const SizedBox(height: 24),
            
            // Inventory Information
            if (product.trackInventory)
              _buildInventorySection(context),
            
            const SizedBox(height: 24),
            
            // Product Variants
            if (product.variants.isNotEmpty)
              _buildVariantsSection(context),
            
            const SizedBox(height: 24),
            
            // Metadata
            _buildInfoSection(
              context,
              'Additional Information',
              [
                _buildInfoRow('Created', _formatDate(product.createdAt)),
                _buildInfoRow('Last Updated', _formatDate(product.updatedAt)),
                _buildInfoRow('Status', product.isActive ? 'Active' : 'Inactive'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceVariant,
      ),
      child: PageView.builder(
        itemCount: product.imageUrls.length,
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              product.imageUrls[index],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(context),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaceholderImage(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceVariant,
      ),
      child: Icon(
        Icons.inventory_2_outlined,
        size: 64,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
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

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
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
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: valueColor != null ? FontWeight.w500 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventorySection(BuildContext context) {
    return _buildInfoSection(
      context,
      'Inventory',
      [
        _buildInfoRow('Track Inventory', product.trackInventory ? 'Yes' : 'No'),
        _buildInfoRow(
          'Stock Quantity',
          '${product.stockQuantity}',
          valueColor: product.isOutOfStock
              ? Colors.red
              : product.isLowStock
                  ? Colors.orange
                  : Colors.green,
        ),
        if (product.lowStockThreshold != null)
          _buildInfoRow('Low Stock Alert', '${product.lowStockThreshold}'),
        _buildInfoRow(
          'Stock Status',
          product.isOutOfStock
              ? 'Out of Stock'
              : product.isLowStock
                  ? 'Low Stock'
                  : 'In Stock',
          valueColor: product.isOutOfStock
              ? Colors.red
              : product.isLowStock
                  ? Colors.orange
                  : Colors.green,
        ),
      ],
    );
  }

  Widget _buildVariantsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product Variants',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...product.variants.map((variant) => Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: ListTile(
            title: Text(variant.name),
            subtitle: Text('\$${variant.price.toStringAsFixed(2)}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (variant.sku != null)
                  Text(
                    'SKU: ${variant.sku}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                Text(
                  'Stock: ${variant.stockQuantity}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  String _getProductTypeLabel(ProductType type) {
    switch (type) {
      case ProductType.simple:
        return 'Simple Product';
      case ProductType.variable:
        return 'Variable Product';
      case ProductType.service:
        return 'Service';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
