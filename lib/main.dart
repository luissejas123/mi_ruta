import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mi_ruta/core/connectivity/connectivity_cubit.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/core/theme/theme_cubit.dart';
import 'package:mi_ruta/core/theme/app_theme.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_event.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/auth/presentation/pages/iniciar_sesion_page.dart';
import 'package:mi_ruta/features/user/presentation/bloc/user_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/user_event.dart' hide GetCurrentUserEvent;
import 'package:mi_ruta/features/user/presentation/bloc/wallet_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/recharge_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/trip_payment_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/benefit_request_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/notification_preferences_cubit.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_bloc.dart';
import 'dart:async';
import 'package:mi_ruta/features/routes/domain/services/route_data_sync_service.dart';
import 'package:mi_ruta/features/user/presentation/bloc/mi_ruta_bloc.dart';
import 'package:mi_ruta/core/widgets/route_update_banner.dart';
import 'package:mi_ruta/core/navigation/home_router.dart';
import 'package:mi_ruta/core/connectivity/connectivity_service.dart';
import 'package:mi_ruta/core/dev/dev_admin_bootstrap.dart';
import 'package:mi_ruta/core/dev/dev_driver_bootstrap.dart';
import 'package:mi_ruta/features/user/domain/services/notification_service.dart';

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
    // Procesar notificaciones operativas
    await _processOperationalNotification(message);
  }
}

/// Procesa notificaciones operativas específicas para RQ-44
Future<void> _processOperationalNotification(RemoteMessage message) async {
  try {
    final type = message.data['type'];
    final userId = message.data['userId'];
    final title = message.data['title'] ?? message.notification?.title;
    final body = message.data['body'] ?? message.notification?.body;

    // Solo procesar tipos operativos específicos
    if (type != 'stop_request' && 
        type != 'maintenance' && 
        type != 'block' && 
        type != 'protest' && 
        type != 'service_status') {
      return;
    }

    // Validar campos requeridos
    if (userId == null || userId.isEmpty) {
      debugPrint('[FCM] Falta userId en notificación operativa');
      return;
    }
    
    if (title == null || title.isEmpty) {
      debugPrint('[FCM] Falta title en notificación operativa');
      return;
    }
    
    if (body == null || body.isEmpty) {
      debugPrint('[FCM] Falta body en notificación operativa');
      return;
    }

    // Guardar notificación operativa usando el servicio existente
    final notificationService = getIt<NotificationService>();
    await notificationService.saveOperationalNotification(
      userId,
      title,
      body,
    );
  } catch (e) {
    debugPrint('[FCM] Error procesando notificación operativa: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Object? startupError;

  try {
    await dotenv.load(fileName: '.env');
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: dotenv.env['FIREBASE_API_KEY'] ?? '',
          appId: dotenv.env['FIREBASE_WEB_APP_ID'] ?? '',
          messagingSenderId: dotenv.env['FIREBASE_PROJECT_NUMBER'] ?? '',
          projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
          authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN'],
          storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'],
          databaseURL: dotenv.env['FIREBASE_DATABASE_URL'],
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
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
      // Procesar notificaciones operativas
      _processOperationalNotification(message);
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

  // RQ-57: al restablecerse la conexión, reanudar la sincronización de rutas.
  unawaited(
    getIt<ConnectivityService>().listenForReconnection(() {
      getIt<RouteDataSyncService>().ensureDataReady();
    }),
  );
    // SOLO DESARROLLO: asegura la cuenta admin@miruta.com (no ejecuta en release).
    unawaited(DevAdminBootstrap.ensureDevAdmin());
    // SOLO DESARROLLO: asegura la cuenta chofer@miruta.com (no ejecuta en release).
    unawaited(DevDriverBootstrap.ensureDevDriver());
  } catch (error) {
    startupError = error;
  }

  runApp(
    startupError == null
        ? const MyApp()
        : StartupErrorApp(error: startupError.toString()),
  );
}

class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({required this.error, super.key});

  final String error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SelectableText(
              'No se pudo iniciar la aplicación:\n\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // ✅ ThemeCubit para modo oscuro
        BlocProvider<ThemeCubit>(
          create: (context) => ThemeCubit(),
        ),
        BlocProvider<ConnectivityCubit>(
          create: (context) => ConnectivityCubit(),
        ),
        // Sin este provider, NotificacionesPage/PreferenciasNotificacionPage
        // reventaban con "Could not find the correct Provider<...>": no
        // estaba registrado en ningún lado (ni DI, ni BlocProvider local).
        BlocProvider<NotificationPreferencesCubit>(
          create: (context) => NotificationPreferencesCubit(),
        ),
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
        BlocProvider<DriverBloc>(
          create: (context) => getIt<DriverBloc>(),
        ),
      ],
      // ✅ BlocBuilder para aplicar tema en toda la app
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthLoaded) {
            context.read<UserBloc>().add(
              StartUserStreamEvent(uid: state.user.uid),
            );
          } else if (state is AuthUnauthenticated) {
            context.read<UserBloc>().add(const StopUserStreamEvent());
          }
        },
        child: BlocBuilder<ThemeCubit, bool>(
          builder: (context, isDarkMode) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'MiRuta',
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              // ✅ Aplica el tema según el estado
              themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
              home: const _AuthGate(),
              // Ambos banners globales se componen en un unico `builder`:
              // MaterialApp solo admite uno.
              builder: (context, child) => RouteUpdateBanner(
                status: getIt<RouteDataSyncService>().syncStatus,
                child: _ConnectivityBanner(
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
          );
          },
        ),
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
          // Criterio unico de enrutamiento por rol, ver core/navigation/home_router.dart
          return homeScreenForRole(state.user);
        }
        return const IniciarSesionPage();
      },
    );
  }
}


/// Banner persistente que avisa cuando no hay conexión a internet.
/// Las rutas/planes ya cacheados en SQLite siguen funcionando sin conexión;
/// esto solo avisa que operaciones contra Firestore (login, beneficios,
/// billetera, etc.) no funcionarán hasta reconectar.
class _ConnectivityBanner extends StatelessWidget {
  final Widget child;

  const _ConnectivityBanner({required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityCubit, bool>(
      builder: (context, isOnline) {
        return Column(
          children: [
            if (!isOnline)
              Material(
                color: Colors.red.shade700,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.wifi_off, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Sin conexión. Las rutas guardadas siguen disponibles.',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}
