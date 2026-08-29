import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/user/domain/services/user_preferences_service.dart';
import 'package:mi_ruta/features/user/presentation/bloc/user_preferences_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/user_preferences_state.dart';

class UserPreferencesBloc
    extends Bloc<UserPreferencesEvent, UserPreferencesState> {
  final UserPreferencesService preferencesService;

  UserPreferencesBloc({
    required this.preferencesService,
  }) : super(const UserPreferencesState()) {
    on<LoadUserPreferencesEvent>(_onLoadPreferences);
    on<ToggleNotificationsEvent>(_onToggleNotifications);
    on<ToggleLocationEvent>(_onToggleLocation);
    on<ToggleAutoSyncEvent>(_onToggleAutoSync);
  }

  Future<void> _onLoadPreferences(
    LoadUserPreferencesEvent event,
    Emitter<UserPreferencesState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final preferences = await preferencesService.getPreferences();

    emit(
      state.copyWith(
        notificationsEnabled: preferences['notifications'] ?? true,
        locationEnabled: preferences['location'] ?? true,
        autoSyncEnabled: preferences['autoSync'] ?? true,
        isLoading: false,
      ),
    );
  }

  Future<void> _onToggleNotifications(
    ToggleNotificationsEvent event,
    Emitter<UserPreferencesState> emit,
  ) async {
    await preferencesService.setNotificationsEnabled(event.enabled);

    emit(
      state.copyWith(
        notificationsEnabled: event.enabled,
      ),
    );
  }

  Future<void> _onToggleLocation(
    ToggleLocationEvent event,
    Emitter<UserPreferencesState> emit,
  ) async {
    await preferencesService.setLocationEnabled(event.enabled);

    emit(
      state.copyWith(
        locationEnabled: event.enabled,
      ),
    );
  }

  Future<void> _onToggleAutoSync(
    ToggleAutoSyncEvent event,
    Emitter<UserPreferencesState> emit,
  ) async {
    await preferencesService.setAutoSyncEnabled(event.enabled);

    emit(
      state.copyWith(
        autoSyncEnabled: event.enabled,
      ),
    );
  }
}
