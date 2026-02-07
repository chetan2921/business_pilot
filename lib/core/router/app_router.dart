import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/auth/forgot_password_screen.dart';
import '../../presentation/screens/dashboard/dashboard_screen.dart';
import '../../presentation/screens/expenses/expenses_list_screen.dart';
import '../../presentation/screens/expenses/add_expense_screen.dart';
import '../../presentation/screens/invoices/invoices_list_screen.dart';
import '../../presentation/screens/invoices/create_invoice_screen.dart';
import '../../presentation/screens/invoices/invoice_detail_screen.dart';
import '../../presentation/screens/customers/customers_screen.dart';
import '../../presentation/screens/ai/ai_chat_screen.dart';
import '../../presentation/screens/reports/reports_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/inventory/products_screen.dart';
import '../../presentation/screens/inventory/add_product_screen.dart';
import '../../presentation/screens/inventory/product_detail_screen.dart';
import '../../presentation/screens/inventory/barcode_scanner_screen.dart';
import '../../presentation/screens/inventory/inventory_insights_screen.dart';
import '../../presentation/screens/pos/quick_sale_screen.dart';
import '../../presentation/screens/reports/analytics_dashboard_screen.dart';
import '../../presentation/screens/customers/customer_detail_screen.dart';
import '../../presentation/screens/agent/agent_insights_screen.dart';
import '../../presentation/screens/agent/cash_flow_forecast_screen.dart';
import '../../presentation/screens/settings/workflow_settings_screen.dart';

/// App Router configuration using GoRouter with Riverpod
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isGoingToAuth =
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register ||
          state.matchedLocation == AppRoutes.forgotPassword;
      final isGoingToSplash = state.matchedLocation == AppRoutes.splash;

      // If on splash, let it handle the redirect
      if (isGoingToSplash) {
        return null;
      }

      // If not logged in and not going to auth pages, redirect to login
      if (!isLoggedIn && !isGoingToAuth) {
        return AppRoutes.login;
      }

      // If logged in and going to auth pages, redirect to dashboard
      if (isLoggedIn && isGoingToAuth) {
        return AppRoutes.dashboard;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.expenses,
        name: 'expenses',
        builder: (context, state) => const ExpensesListScreen(),
      ),
      GoRoute(
        path: AppRoutes.addExpense,
        name: 'addExpense',
        builder: (context, state) => const AddExpenseScreen(),
      ),
      GoRoute(
        path: AppRoutes.invoices,
        name: 'invoices',
        builder: (context, state) => const InvoicesListScreen(),
      ),
      GoRoute(
        path: '/create-invoice',
        name: 'createInvoice',
        builder: (context, state) => const CreateInvoiceScreen(),
      ),
      GoRoute(
        path: '/invoice/:id',
        name: 'invoiceDetail',
        builder: (context, state) =>
            InvoiceDetailScreen(invoiceId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.customers,
        name: 'customers',
        builder: (context, state) => const CustomersListScreen(),
      ),
      GoRoute(
        path: '/add-customer',
        name: 'addCustomer',
        builder: (context, state) => const AddCustomerScreen(),
      ),
      GoRoute(
        path: '/customer/:id',
        name: 'customerDetail',
        builder: (context, state) =>
            CustomerDetailScreen(customerId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.aiChat,
        name: 'aiChat',
        builder: (context, state) => const AIChatScreen(),
      ),
      GoRoute(
        path: AppRoutes.reports,
        name: 'reports',
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.products,
        name: 'products',
        builder: (context, state) => const ProductsScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.products}/:id',
        name: 'productDetail',
        builder: (context, state) =>
            ProductDetailScreen(productId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.addProduct,
        name: 'addProduct',
        builder: (context, state) {
          final editId = state.uri.queryParameters['edit'];
          return AddProductScreen(productId: editId);
        },
      ),
      GoRoute(
        path: AppRoutes.barcodeScanner,
        name: 'barcodeScanner',
        builder: (context, state) => const BarcodeScannerScreen(),
      ),
      GoRoute(
        path: AppRoutes.quickSale,
        name: 'quickSale',
        builder: (context, state) => const QuickSaleScreen(),
      ),
      GoRoute(
        path: AppRoutes.inventoryInsights,
        name: 'inventoryInsights',
        builder: (context, state) => const InventoryInsightsScreen(),
      ),
      GoRoute(
        path: AppRoutes.analytics,
        name: 'analytics',
        builder: (context, state) => const AnalyticsDashboardScreen(),
      ),
      GoRoute(
        path: '/agent',
        name: 'agentInsights',
        builder: (context, state) => const AgentInsightsScreen(),
      ),
      GoRoute(
        path: '/agent/cash-flow',
        name: 'cashFlowForecast',
        builder: (context, state) => const CashFlowForecastScreen(),
      ),
      GoRoute(
        path: '/settings/workflows',
        name: 'workflowSettings',
        builder: (context, state) => const WorkflowSettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.matchedLocation,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.dashboard),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
});
