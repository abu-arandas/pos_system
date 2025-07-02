import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/store_controller.dart';
import '../../services/security_service.dart';
import '../../models/store_model.dart';

class AddStoreView extends GetView<StoreController> {
  final StoreModel? store;
  
  const AddStoreView({super.key, this.store});

  @override
  Widget build(BuildContext context) {
    final isEditing = store != null;
    final formKey = GlobalKey<FormState>();
    
    // Form controllers
    final nameController = TextEditingController(text: store?.name ?? '');
    final descriptionController = TextEditingController(text: store?.description ?? '');
    final addressController = TextEditingController(text: store?.address ?? '');
    final cityController = TextEditingController(text: store?.city ?? '');
    final stateController = TextEditingController(text: store?.state ?? '');
    final countryController = TextEditingController(text: store?.country ?? '');
    final postalCodeController = TextEditingController(text: store?.postalCode ?? '');
    final phoneController = TextEditingController(text: store?.phone ?? '');
    final emailController = TextEditingController(text: store?.email ?? '');

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Store' : 'Add Store'),
        actions: [
          TextButton(
            onPressed: () => _saveStore(
              context,
              formKey,
              nameController,
              descriptionController,
              addressController,
              cityController,
              stateController,
              countryController,
              postalCodeController,
              phoneController,
              emailController,
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
              
              // Store Name
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Store Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter store name';
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
              
              const SizedBox(height: 24),
              
              // Location Information Section
              _buildSectionHeader(context, 'Location Information'),
              const SizedBox(height: 16),
              
              // Address
              TextFormField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Street Address',
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // City and State
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: cityController,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: stateController,
                      decoration: const InputDecoration(
                        labelText: 'State/Province',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Country and Postal Code
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: countryController,
                      decoration: const InputDecoration(
                        labelText: 'Country',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: postalCodeController,
                      decoration: const InputDecoration(
                        labelText: 'Postal Code',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Contact Information Section
              _buildSectionHeader(context, 'Contact Information'),
              const SizedBox(height: 16),
              
              // Phone
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Email
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty && !GetUtils.isEmail(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 32),
              
              // Save Button
              Obx(() => ElevatedButton(
                onPressed: controller.isLoading.value
                    ? null
                    : () => _saveStore(
                          context,
                          formKey,
                          nameController,
                          descriptionController,
                          addressController,
                          cityController,
                          stateController,
                          countryController,
                          postalCodeController,
                          phoneController,
                          emailController,
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
                    : Text(isEditing ? 'Update Store' : 'Add Store'),
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

  void _saveStore(
    BuildContext context,
    GlobalKey<FormState> formKey,
    TextEditingController nameController,
    TextEditingController descriptionController,
    TextEditingController addressController,
    TextEditingController cityController,
    TextEditingController stateController,
    TextEditingController countryController,
    TextEditingController postalCodeController,
    TextEditingController phoneController,
    TextEditingController emailController,
    bool isEditing,
  ) async {
    if (!formKey.currentState!.validate()) return;

    final currentUser = Get.find<SecurityService>().currentUser;
    if (currentUser == null) return;

    final storeData = StoreModel(
      id: store?.id ?? '',
      name: nameController.text.trim(),
      description: descriptionController.text.trim(),
      businessId: currentUser.businessId,
      managerId: store?.managerId ?? '', // Keep existing manager or empty for new stores
      address: addressController.text.trim(),
      city: cityController.text.trim(),
      state: stateController.text.trim(),
      country: countryController.text.trim(),
      postalCode: postalCodeController.text.trim(),
      phone: phoneController.text.trim(),
      email: emailController.text.trim(),
      createdAt: store?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    bool success;
    if (isEditing) {
      success = await controller.updateStore(storeData);
    } else {
      success = await controller.addStore(storeData);
    }

    if (success) {
      Get.back();
    }
  }
}
