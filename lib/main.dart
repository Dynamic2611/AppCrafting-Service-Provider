// main.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/auth_controller.dart';
import 'views/auth/auth_gate.dart';
import 'views/auth/forget_password.dart';
import 'views/auth/login.dart';
import 'views/auth/signup.dart';
import 'views/customer/ProviderDetailPage.dart';
import 'views/customer/customer_home.dart';
import 'views/customer/service_detail_page.dart';
import 'views/customer/user_profile_page.dart';
import 'views/provider/MyServicesPage.dart';
import 'views/provider/ProviderProfilePage.dart';
import 'views/provider/add_edit_services_page.dart';
import 'views/provider/dashboard.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();   // if you haven’t already
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>(
          create: (_) => AuthController(),
        ),
        // add other controllers here
      ],
      child:MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const AuthGate(), // instead of initialRoute
        routes: {
          '/login'            : (_) => const LoginPage(),
          '/signup'           : (_) => const SignUpPage(),
          '/customerHome'     : (_) => const CustomerHome(),
          '/providerDashboard': (_) => const ProviderDashboardPage(),
          '/profile'          : (_) => UserProfilePage(),
          '/forgotPassword'   : (_) => const ForgotPasswordPage(),
          '/addService'       : (context) => const ServiceFormPage(),
          '/myServices'       : (context) => const MyServicesPage(),
          '/providerProfile'  : (context) => const ProviderProfilePage(),
          '/serviceDetail'    : (_) => ServiceDetailPage(service: {}),
          '/providerDetail': (context) {
              final doc = ModalRoute.of(context)!.settings.arguments as DocumentSnapshot;
              return ProviderDetailPage(doc: doc);
            },

        },
      ),

    );
  }
}
