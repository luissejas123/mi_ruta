import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/core/theme/theme_cubit.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_event.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/auth/presentation/pages/iniciar_sesion_page.dart';
import 'package:mi_ruta/features/user/presentation/bloc/user_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/wallet_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/recharge_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/trip_payment_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/benefit_request_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/notification_preferences_cubit.dart';
import 'dart:async';
import 'package:mi_ruta/features/routes/domain/services/route_data_sync_service.dart';
import 'package:mi_ruta/features/user/presentation/pages/mi_ruta_screen.dart';
import 'package:mi_ruta/features/user/presentation/bloc/mi_ruta_bloc.dart';
import 'package:mi_ruta/features/driver/presentation/pages/driver_home_page.dart';

/// Handler de nivel superior para mensajes FCM recibidos en segundo plano
/// o cuando la app está terminada. Debe ser una función de nivel superior
/// (no un método de una clase) y estar anotada con @pragma('vm:entry-point').
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp();
  final title = message.notification?.title;
  final body = message.notification?.body;
  debugPrint('[FCM] Mensaje recibido en background: ${message.messageId}');
  debugPrint('[FCM] Título: $title | Cuerpo: $body');
  if (message.data.isNotEmpty) {
    debugPrint('[FCM] Data: ${message.data}');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp();
  setupDependencies();

  // ── Inicialización mínima de Firebase Cloud Messaging (RQ-44) ──
  debugPrint('[FCM] Inicializando Firebase Messaging');
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Solicitar permiso de notificaciones (Android 13+ requiere runtime).
  final permission = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  debugPrint('[FCM] Permiso solicitado: ${permission.toString()}');

  // Obtener el token de registro (solo se muestra por log, no se almacena).
  final token = await FirebaseMessaging.instance.getToken();
  debugPrint('[FCM] Token: ${token ?? 'null'}');

  // Escuchar mensajes en primer plano.
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final title = message.notification?.title;
    final body = message.notification?.body;
    debugPrint('[FCM] Mensaje recibido en foreground: ${message.messageId}');
    debugPrint('[FCM] Título: $title | Cuerpo: $body');
    if (message.data.isNotEmpty) {
      debugPrint('[FCM] Data: ${message.data}');
    }
  });

// Escuchar renovación del token (solo se muestra por log).
  FirebaseMessaging.instance.onTokenRefresh.listen((String newToken) {
    debugPrint('[FCM] Token actualizado: $newToken');
  });

  // Manejar apertura de la app desde una notificación (app terminada).
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    debugPrint(
      '[FCM] App abierta desde notificación: ${initialMessage.messageId}',
    );
  }

  unawaited(getIt<RouteDataSyncService>().ensureDataReady());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // ✅ ThemeCubit para modo oscuro
<<<<<<< HEAD
        BlocProvider<ThemeCubit>(
          create: (context) => ThemeCubit(),
        ),
        BlocProvider<NotificationPreferencesCubit>(
          create: (context) => NotificationPreferencesCubit(),
        ),
=======
        BlocProvider<ThemeCubit>(create: (context) => ThemeCubit()),
>>>>>>> origin/dev-alex-villca
        BlocProvider<AuthBloc>(
          create: (context) =>
              getIt<AuthBloc>()..add(const GetCurrentUserEvent()),
        ),
        BlocProvider<UserBloc>(create: (context) => getIt<UserBloc>()),
        BlocProvider<WalletBloc>(create: (context) => getIt<WalletBloc>()),
        BlocProvider<RechargeBloC>(create: (context) => getIt<RechargeBloC>()),
        BlocProvider<TripPaymentBLoC>(
          create: (context) => getIt<TripPaymentBLoC>(),
        ),
        BlocProvider<BenefitRequestBLoC>(
          create: (context) => getIt<BenefitRequestBLoC>(),
        ),
        BlocProvider<MiRutaBloc>(create: (context) => getIt<MiRutaBloc>()),
      ],
      // ✅ BlocBuilder para aplicar tema en toda la app
      child: BlocBuilder<ThemeCubit, bool>(
        builder: (context, isDarkMode) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'MiRuta',
            theme: ThemeData(
              brightness: Brightness.light,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFFFFC12F),
                brightness: Brightness.light,
              ),
              scaffoldBackgroundColor: Colors.white,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
                titleTextStyle: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                iconTheme: IconThemeData(color: Colors.black),
              ),
              bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                backgroundColor: Colors.white,
                selectedItemColor: Color(0xFFFFC12F),
                unselectedItemColor: Colors.grey,
              ),
              cardTheme: const CardThemeData(
                color: Colors.white,
                surfaceTintColor: Colors.transparent,
              ),
              listTileTheme: const ListTileThemeData(
                textColor: Colors.black87,
                iconColor: Colors.black54,
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                hintStyle: const TextStyle(color: Colors.black38),
              ),
              textTheme: const TextTheme(
                bodyLarge: TextStyle(color: Colors.black87),
                bodyMedium: TextStyle(color: Colors.black87),
                bodySmall: TextStyle(color: Colors.black54),
                titleLarge: TextStyle(color: Colors.black),
                titleMedium: TextStyle(color: Colors.black87),
                titleSmall: TextStyle(color: Colors.black54),
              ),
              iconTheme: const IconThemeData(color: Colors.black87),
              dividerColor: Colors.grey,
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFFFFC12F),
                brightness: Brightness.dark,
              ),
              scaffoldBackgroundColor: const Color(0xFF121212),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF1E1E1E),
                foregroundColor: Colors.white,
                elevation: 0,
                titleTextStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                iconTheme: IconThemeData(color: Colors.white),
              ),
              bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                backgroundColor: Color(0xFF1E1E1E),
                selectedItemColor: Color(0xFFFFC12F),
                unselectedItemColor: Colors.grey,
              ),
              cardTheme: const CardThemeData(
                color: Color(0xFF1E1E1E),
                surfaceTintColor: Colors.transparent,
              ),
              listTileTheme: ListTileThemeData(
                tileColor: Colors.transparent,
                textColor: Colors.white70,
                iconColor: Colors.grey.shade400,
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: const Color(0xFF2C2C2C),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                hintStyle: const TextStyle(color: Colors.white38),
                labelStyle: const TextStyle(color: Colors.white70),
              ),
              textTheme: const TextTheme(
                bodyLarge: TextStyle(color: Colors.white70),
                bodyMedium: TextStyle(color: Colors.white70),
                bodySmall: TextStyle(color: Colors.white54),
                titleLarge: TextStyle(color: Colors.white),
                titleMedium: TextStyle(color: Colors.white70),
                titleSmall: TextStyle(color: Colors.white54),
              ),
              iconTheme: const IconThemeData(color: Colors.white70),
              dividerColor: Color(0xFF2C2C2C),
              cardColor: const Color(0xFF1E1E1E),
            ),
            // ✅ Aplica el tema según el estado
            themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const _AuthGate(),
          );
        },
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading || state is AuthInitial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state is AuthLoaded) {
          final role = state.user.role;
          if (role == 'driver' || role == 'presidente') {
            return const DriverHomePage();
          }
          return const MiRutaScreen();
        }
        return const IniciarSesionPage();
      },
    );
  }
}
