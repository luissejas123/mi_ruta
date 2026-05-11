import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/user/presentation/bloc/user_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/user_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/user_state.dart';

/// Página de Perfil de Usuario - Ejemplo de uso del UserBloc
class UserProfilePage extends StatefulWidget {
  final String userId;

  const UserProfilePage({
    super.key,
    required this.userId,
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  @override
  void initState() {
    super.initState();
    // Cargar usuario cuando la página se inicializa
    // ✅ FORMA CORRECTA: A través del BLoC, sin llamadas directas a Firestore
    context.read<UserBloc>().add(GetUserByIdEvent(uid: widget.userId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil de Usuario'),
      ),
      body: BlocBuilder<UserBloc, UserState>(
        builder: (context, state) {
          // Estado de carga
          if (state is UserLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Usuario cargado correctamente
          if (state is UserLoaded) {
            final user = state.user;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: NetworkImage(user.profileImageUrl),
                  ),
                  const SizedBox(height: 16),

                  // Nombre
                  Text(
                    user.fullName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),

                  // Email
                  Text(
                    user.email,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),

                  const SizedBox(height: 32),

                  // Información General
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _infoRow('Teléfono', user.phoneNumber),
                          _infoRow('Tipo de Usuario', user.userType),
                          _infoRow(
                            'Estado',
                            user.isActive ? 'Activo' : 'Inactivo',
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Calificación
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Calificación'),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber),
                                  Text('${user.rating.toStringAsFixed(1)}/5'),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${user.reviewsCount} reseñas',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Billetera
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Text('Saldo de Billetera'),
                          const SizedBox(height: 8),
                          Text(
                            '\$${user.walletBalance.toStringAsFixed(2)}',
                            style:
                                Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: Colors.green,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Botón para actualizar usuario
                  ElevatedButton(
                    onPressed: () {
                      // ✅ FORMA CORRECTA: Actualizar a través del BLoC
                      context.read<UserBloc>().add(
                            UpdateUserEvent(
                              uid: widget.userId,
                              data: {'phoneNumber': '+591 XXXXXX'},
                            ),
                          );
                    },
                    child: const Text('Actualizar Perfil'),
                  ),

                  const SizedBox(height: 16),

                  // Botón para obtener calificación
                  ElevatedButton.icon(
                    onPressed: () {
                      // ✅ FORMA CORRECTA: Obtener calificación a través del BLoC
                      context.read<UserBloc>().add(
                            GetUserRatingEvent(uid: widget.userId),
                          );
                    },
                    icon: const Icon(Icons.star),
                    label: const Text('Ver Calificación Detallada'),
                  ),
                ],
              ),
            );
          }

          // Error
          if (state is UserError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context
                          .read<UserBloc>()
                          .add(GetUserByIdEvent(uid: widget.userId));
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          // Estado inicial
          return const Center(child: Text('Cargando usuario...'));
        },
      ),
    );
  }

  /// Widget auxiliar para mostrar información
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
