import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/user_bloc.dart';
import 'package:mi_ruta/features/user/presentation/pages/register_page.dart';
import 'package:mi_ruta/features/payment/presentation/pages/payment_home_page.dart';
import 'package:mi_ruta/features/payment/presentation/pages/recharge_balance_page.dart';
import 'package:mi_ruta/features/payment/presentation/pages/payment_success_page.dart';
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    setupDependencies();
  } catch (e) {
    debugPrint('Error durante inicialización: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (context) => getIt<AuthBloc>()),
        BlocProvider<UserBloc>(create: (context) => getIt<UserBloc>()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MiRuta',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
          useMaterial3: true,
        ),
        home: const PaymentHomePage(),
        routes: {
          '/payment/home': (context) => const PaymentHomePage(),
          '/payment/recharge': (context) => const RechargeBalancePage(),
          '/payment/success': (context) => const PaymentSuccessPage(),
          '/auth/register': (context) => const RegisterPage(),
        },
      ),
    );
  }
}
