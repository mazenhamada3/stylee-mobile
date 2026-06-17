import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'screens/main_shell.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/search/search_screen.dart';
import 'screens/cart/cart_screen.dart';
import 'screens/checkout/checkout_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/product/product_detail_screen.dart';
import 'screens/admin/admin_screen.dart';
import 'models/product.dart';
import 'services/firestore_service.dart';

/// Fetch a Product by ID from Firestore
Future<Product> fetchProductById(String id) async {
  final service = FirestoreService();
  final products = await service.getProducts().first;
  return products.firstWhere((p) => p.id == id);
}

GoRouter createRouter(AuthProvider auth) => GoRouter(
      initialLocation: '/home',
      refreshListenable: auth,
      redirect: (context, state) {
        final loggedIn = auth.isLoggedIn;
        final loc = state.matchedLocation;
        final isAuth = loc == '/login' || loc == '/signup';

        if (!loggedIn && !isAuth) return '/login';
        if (loggedIn && isAuth) return '/home';
        if (loc == '/admin' && !auth.isAdmin) return '/home';

        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (_, __) => LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (_, __) => SignupScreen(),
        ),
        GoRoute(
          path: '/product/:id',
          builder: (_, state) {
            final productId = state.pathParameters['id']!;
            return FutureBuilder<Product>(
              future: fetchProductById(productId),
              builder: (_, snapshot) {
                if (!snapshot.hasData) {
                  return const Scaffold(
                      body: Center(child: CircularProgressIndicator()));
                }
                return ProductDetailScreen(product: snapshot.data!);
              },
            );
          },
        ),
        GoRoute(
          path: '/checkout',
          builder: (_, __) => CheckoutScreen(),
        ),
        GoRoute(
          path: '/admin',
          builder: (_, __) => AdminScreen(),
        ),
        ShellRoute(
          builder: (_, state, child) =>
              MainShell(child: child, location: state.matchedLocation),
          routes: [
            GoRoute(path: '/home', builder: (_, __) => HomeScreen()),
            GoRoute(path: '/search', builder: (_, __) => SearchScreen()),
            GoRoute(path: '/cart', builder: (_, __) => CartScreen()),
            GoRoute(path: '/profile', builder: (_, __) => ProfileScreen()),
          ],
        ),
      ],
    );