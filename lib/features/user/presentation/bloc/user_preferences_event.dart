abstract class UserPreferencesEvent {
  const UserPreferencesEvent();
}

/// Carga las preferencias guardadas localmente.
class LoadUserPreferencesEvent extends UserPreferencesEvent {
  const LoadUserPreferencesEvent();
}

/// Cambia el estado de las notificaciones.
class ToggleNotificationsEvent extends UserPreferencesEvent {
  final bool enabled;

  const ToggleNotificationsEvent(this.enabled);
}

/// Cambia el estado de la ubicación.
class ToggleLocationEvent extends UserPreferencesEvent {
  final bool enabled;

  const ToggleLocationEvent(this.enabled);
}

/// Cambia el estado de la sincronización automática.
class ToggleAutoSyncEvent extends UserPreferencesEvent {
  final bool enabled;

  const ToggleAutoSyncEvent(this.enabled);
}
