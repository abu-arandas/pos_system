import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/product_controller.dart';
import '../../services/security_service.dart';
import '../../models/product_model.dart';

class AddProductView extends GetView<ProductController> {
  final ProductModel? product;
  
  const AddProductView({super.key, this.product});

  @override
  Widget build(BuildContext context) {
    final isEditing = product != null;
    final formKey = GlobalKey<FormState>();
    
    // Form controllers
    final nameController = TextEditingController(text: product?.name ?? '');
    final descriptionController = TextEditingController(text: product?.description ?? '');
    final priceController = TextEditingController(text: product?.price.toString() ?? '');
    final costPriceController = TextEditingController(text: product?.costPrice?.toString() ?? '');
    final skuController = TextEditingController(text: product?.sku ?? '');
    final barcodeController = TextEditingController(text: product?.barcode ?? '');
    final stockController = TextEditingController(text: product?.stockQuantity.toString() ?? '0');
    final lowStockController = TextEditingController(text: product?.lowStockThreshold?.toString() ?? '5');
    final categoryController = TextEditingController(text: product?.categoryId ?? '');
    
    // Form state
    final trackInventory = ValueNotifier<bool>(product?.trackInventory ?? true);
    final productType = ValueNotifier<ProductType>(product?.type ?? ProductType.simple);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Product' : 'Add Product'),
        actions: [
          TextButton(
            onPressed: () => _saveProduct(
              context,
              formKey,
              nameController,
              descriptionController,
              priceController,
              costPriceController,
              skuController,
              barcodeController,
              stockController,
              lowStockController,
              categoryController,
              trackInventory,
              productType,
              isEditing,
            ),
            child: Text(isEditing ? 'Update' : 'Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Basic Information Section
              _buildSectionHeader(context, 'Basic Information'),
              const SizedBox(height: 16),
              
              // Product Name
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter product name';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Description
              TextFormField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Category
              TextFormField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Electronics, Clothing, Food',
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Product Type
              ValueListenableBuilder<ProductType>(
                valueListenable: productType,
                builder: (context, type, child) {
                  return DropdownButtonFormField<ProductType>(
                    value: type,
                    decoration: const InputDecoration(
                      labelText: 'Product Type',
                      border: OutlineInputBorder(),
                    ),
                    items: ProductType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(_getProductTypeLabel(type)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        productType.value = value;
                      }
                    },
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              // Pricing Section
              _buildSectionHeader(context, 'Pricing'),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Selling Price *',
                        border: OutlineInputBorder(),
                        prefixText: '\$',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter selling price';
                        }
                        if (double.tryParse(value) == null || double.parse(value) < 0) {
                          return 'Please enter valid price';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: costPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Cost Price',
                        border: OutlineInputBorder(),
                        prefixText: '\$',
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (double.tryParse(value) == null || double.parse(value) < 0) {
                            return 'Please enter valid cost price';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Product Identification Section
              _buildSectionHeader(context, 'Product Identification'),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: skuController,
                      decoration: const InputDecoration(
                        labelText: 'SKU',
                        border: OutlineInputBorder(),
                        hintText: 'Stock Keeping Unit',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: barcodeController,
                      decoration: const InputDecoration(
                        labelText: 'Barcode',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Inventory Section
              _buildSectionHeader(context, 'Inventory Management'),
              const SizedBox(height: 16),
              
              ValueListenableBuilder<bool>(
                valueListenable: trackInventory,
                builder: (context, track, child) {
                  return Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Track Inventory'),
                        subtitle: const Text('Enable stock quantity tracking'),
                        value: track,
                        onChanged: (value) => trackInventory.value = value,
                      ),
                      
                      if (track) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: stockController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Stock Quantity',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (track && (value == null || value.isEmpty)) {
                                    return 'Please enter stock quantity';
                                  }
                                  if (value != null && value.isNotEmpty) {
                                    if (int.tryParse(value) == null || int.parse(value) < 0) {
                                      return 'Please enter valid quantity';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: lowStockController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Low Stock Alert',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    if (int.tryParse(value) == null || int.parse(value) < 0) {
                                      return 'Please enter valid threshold';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  );
                },
              ),
              
              const SizedBox(height: 32),
              
              // Save Button
              Obx(() => ElevatedButton(
                onPressed: controller.isLoading.value
                    ? null
                    : () => _saveProduct(
                          context,
                          formKey,
                          nameController,
                          descriptionController,
                          priceController,
                          costPriceController,
                          skuController,
                          barcodeController,
                          stockController,
                          lowStockController,
                          categoryController,
                          trackInventory,
                          productType,
                          isEditing,
                        ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: controller.isLoading.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEditing ? 'Update Product' : 'Add Product'),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
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

  void _saveProduct(
    BuildContext context,
    GlobalKey<FormState> formKey,
    TextEditingController nameController,
    TextEditingController descriptionController,
    TextEditingController priceController,
    TextEditingController costPriceController,
    TextEditingController skuController,
    TextEditingController barcodeController,
    TextEditingController stockController,
    TextEditingController lowStockController,
    TextEditingController categoryController,
    ValueNotifier<bool> trackInventory,
    ValueNotifier<ProductType> productType,
    bool isEditing,
  ) async {
    if (!formKey.currentState!.validate()) return;

    final currentUser = Get.find<SecurityService>().currentUser;
    if (currentUser == null) return;

    final productData = ProductModel(
      id: product?.id ?? '',
      name: nameController.text.trim(),
      description: descriptionController.text.trim(),
      businessId: currentUser.businessId,
      storeId: currentUser.storeId ?? '',
      categoryId: categoryController.text.trim(),
      type: productType.value,
      price: double.parse(priceController.text),
      costPrice: costPriceController.text.isNotEmpty 
          ? double.parse(costPriceController.text) 
          : null,
      sku: skuController.text.trim().isNotEmpty 
          ? skuController.text.trim() 
          : null,
      barcode: barcodeController.text.trim().isNotEmpty 
          ? barcodeController.text.trim() 
          : null,
      stockQuantity: trackInventory.value 
          ? int.parse(stockController.text) 
          : 0,
      lowStockThreshold: trackInventory.value && lowStockController.text.isNotEmpty
          ? int.parse(lowStockController.text)
          : null,
      trackInventory: trackInventory.value,
      createdAt: product?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    bool success;
    if (isEditing) {
      success = await controller.updateProduct(productData);
    } else {
      success = await controller.addProduct(productData);
    }

    if (success) {
      Get.back();
    }
  }
}
