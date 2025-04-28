part of 'app_pages.dart';

abstract class Routes {
  Routes._();
  static const LOGIN = _Paths.LOGIN;
  static const DASHBOARD = _Paths.DASHBOARD;
  static const PRODUCTS = _Paths.PRODUCTS;
  static const INVENTORY = _Paths.INVENTORY;
  static const SALES = _Paths.SALES;
  static const CUSTOMERS = _Paths.CUSTOMERS;
  static const REPORTS = _Paths.REPORTS;
  static const SETTINGS = _Paths.SETTINGS;
  static const NO_ACCESS = _Paths.NO_ACCESS;
  static const CHECKOUT = _Paths.CHECKOUT;
  static const PAYMENT_SELECTION = _Paths.PAYMENT_SELECTION;
  static const REFUND = _Paths.REFUND;
  static const REFUND_HISTORY = _Paths.REFUND_HISTORY;
}

abstract class _Paths {
  _Paths._();
  static const LOGIN = '/login';
  static const DASHBOARD = '/dashboard';
  static const PRODUCTS = '/products';
  static const INVENTORY = '/inventory';
  static const SALES = '/sales';
  static const CUSTOMERS = '/customers';
  static const REPORTS = '/reports';
  static const SETTINGS = '/settings';
  static const NO_ACCESS = '/no_access';
  static const CHECKOUT = '/checkout';
  static const PAYMENT_SELECTION = '/payment-selection';
  static const REFUND = '/refund';
  static const REFUND_HISTORY = '/refund-history';
}
