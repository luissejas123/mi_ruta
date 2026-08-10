class UserPreferencesState {
  final bool notificationsEnabled;
  final bool locationEnabled;
  final bool autoSyncEnabled;
  final bool isLoading;

  const UserPreferencesState({
    this.notificationsEnabled = true,
    this.locationEnabled = true,
    this.autoSyncEnabled = true,
    this.isLoading = false,
  });

  UserPreferencesState copyWith({
    bool? notificationsEnabled,
    bool? locationEnabled,
    bool? autoSyncEnabled,
    bool? isLoading,
  }) {
    return UserPreferencesState(
      notificationsEnabled:
          notificationsEnabled ?? this.notificationsEnabled,
      locationEnabled: locationEnabled ?? this.locationEnabled,
      autoSyncEnabled: autoSyncEnabled ?? this.autoSyncEnabled,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
