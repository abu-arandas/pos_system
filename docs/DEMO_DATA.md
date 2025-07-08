# Demo Data Management System

This system provides comprehensive demo data for the POS system to facilitate testing and demonstration purposes.

## Overview

The demo data system includes:
- **Users**: Admin, manager, and cashier accounts with different permissions
- **Stores**: Multiple store locations with different settings
- **Products**: Various product types including simple, variable, and service products
- **Transactions**: Sample transactions in different states (completed, pending, refunded)

## Components

### Services
- `DemoDataService`: Generates all demo data
- `JsonExportService`: Handles JSON export and clipboard operations
- `DemoDataController`: Manages upload/download operations with Firebase

### Views
- `DemoDataView`: Admin interface for managing demo data

## Demo Data Structure

### Users (4 total)
- **Admin**: John Administrator (admin@demo.com)
  - Full system access
  - Business ID: demo_business_001
  
- **Manager**: Sarah Manager (manager@demo.com)
  - Store management permissions
  - Assigned to Downtown Main Store
  
- **Cashiers**: Mike Johnson & Emily Davis
  - Transaction processing permissions
  - Assigned to different stores

### Stores (3 total)
- **Downtown Main Store**: Flagship location
- **Mall Location**: Shopping center location  
- **Outlet Store**: Discount/clearance location

### Products (8 total)
- **Simple Products**: Standard inventory items
  - Wireless Bluetooth Headphones ($199.99)
  - Premium Coffee Beans ($14.99)
  - Wireless Mouse ($29.99)
  - Energy Drink ($2.99)
  - Notebook Set ($12.99) - Low stock example

- **Variable Products**: Items with variants
  - Smartphone Case (different phone models and colors)
  - Cotton T-Shirt (different sizes and colors)

- **Service Products**: Non-inventory items
  - Tech Support Service ($75.00)

### Transactions (6 total)
- **Completed**: Successful sales with different payment methods
- **Pending**: Incomplete transaction (customer getting cash)
- **Refunded**: Returned defective item

## Usage

### Access Demo Data Management
1. Sign in as an admin user
2. Go to Settings
3. Scroll to "Debug Settings" (admin-only section)
4. Click "Demo Data Management"

### Upload Demo Data
1. Click "Upload Demo Data" button
2. Confirm the action in the dialog
3. Monitor progress with the progress bar
4. View status messages for success/failure

### Additional Features
- **Validate Demo Data**: Check data integrity before upload
- **Clear Demo Data**: Remove all demo data from backend
- **Copy JSON**: Export demo data to clipboard as JSON

### JSON Export
The system can export all demo data as properly formatted JSON for:
- Manual data inspection
- External tool integration
- Backup purposes
- Documentation

## Firebase Collections

Data is uploaded to the following Firestore collections:
- `users`: User accounts and profiles
- `stores`: Store locations and settings
- `products`: Inventory items and variants
- `transactions`: Sales and transaction history

## Data Relationships

The demo data maintains proper relationships:
- Users are assigned to specific businesses and stores
- Products belong to specific stores and businesses
- Transactions reference valid products, users, and stores
- Variants are properly linked to their parent products

## Business Logic Examples

### Inventory Management
- Products with different stock levels
- Low stock threshold examples
- Out of stock scenarios
- Variant-based inventory tracking

### Transaction Processing
- Multiple payment methods (cash, card, digital wallet)
- Discount applications
- Tax calculations
- Change calculations for cash payments

### User Permissions
- Role-based access control examples
- Store-specific user assignments
- Permission inheritance patterns

## Development Notes

### Extending Demo Data
To add new demo data:
1. Update `DemoDataService` methods
2. Ensure proper ID references
3. Maintain data relationships
4. Update validation logic

### Data Consistency
- All dates use ISO 8601 format
- Monetary values use proper decimal precision
- IDs follow consistent naming patterns
- Required fields are always populated

### Testing Scenarios
The demo data supports testing:
- Multi-store operations
- Role-based permissions
- Inventory management
- Transaction processing
- Data export/import
- Analytics and reporting

## Best Practices

1. **Always validate** data before uploading
2. **Clear existing demo data** before uploading new data to avoid duplicates
3. **Monitor upload progress** for large datasets
4. **Use proper error handling** for network issues
5. **Maintain data relationships** when modifying demo data

## Troubleshooting

### Upload Failures
- Check Firebase connection
- Verify user permissions
- Validate data format
- Monitor Firestore quotas

### Data Inconsistencies
- Run validation before upload
- Check relationship integrity
- Verify required fields
- Review data types

### Performance Issues
- Upload data in batches
- Monitor Firestore limits
- Use appropriate indices
- Optimize query patterns
