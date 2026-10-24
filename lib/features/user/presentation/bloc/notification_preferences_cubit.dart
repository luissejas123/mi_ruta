import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPreferences extends Equatable {
  final bool masterEnabled;
  final bool tripsEnabled;
  final bool rechargesEnabled;
  final bool giftsEnabled;
  // true once the saved values have been read from SharedPreferences; lets
  // listeners tell an actual user change apart from the initial hydration.
  final bool isHydrated;

  const NotificationPreferences({
    this.masterEnabled = true,
    this.tripsEnabled = true,
    this.rechargesEnabled = true,
    this.giftsEnabled = true,
    this.isHydrated = false,
  });

  NotificationPreferences copyWith({
    bool? masterEnabled,
    bool? tripsEnabled,
    bool? rechargesEnabled,
    bool? giftsEnabled,
  }) {
    return NotificationPreferences(
      masterEnabled: masterEnabled ?? this.masterEnabled,
      tripsEnabled: tripsEnabled ?? this.tripsEnabled,
      rechargesEnabled: rechargesEnabled ?? this.rechargesEnabled,
      giftsEnabled: giftsEnabled ?? this.giftsEnabled,
      isHydrated: true,
    );
  }

  @override
  List<Object?> get props =>
      [masterEnabled, tripsEnabled, rechargesEnabled, giftsEnabled, isHydrated];
}

/// Preferencias de notificación del usuario, persistidas localmente.
/// Sigue el mismo patrón que [ThemeCubit]: estado simple respaldado por
/// SharedPreferences, sin necesidad de pasar por un repositorio.
class NotificationPreferencesCubit extends Cubit<NotificationPreferences> {
  static const _keyMaster = 'notif_pref_master';
  static const _keyTrips = 'notif_pref_trips';
  static const _keyRecharges = 'notif_pref_recharges';
  static const _keyGifts = 'notif_pref_gifts';

  NotificationPreferencesCubit() : super(const NotificationPreferences()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    emit(
      NotificationPreferences(
        masterEnabled: prefs.getBool(_keyMaster) ?? true,
        tripsEnabled: prefs.getBool(_keyTrips) ?? true,
        rechargesEnabled: prefs.getBool(_keyRecharges) ?? true,
        giftsEnabled: prefs.getBool(_keyGifts) ?? true,
        isHydrated: true,
      ),
    );
  }

  Future<void> setMasterEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMaster, value);
    emit(state.copyWith(masterEnabled: value));
  }

  Future<void> setTripsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTrips, value);
    emit(state.copyWith(tripsEnabled: value));
  }

  Future<void> setRechargesEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRecharges, value);
    emit(state.copyWith(rechargesEnabled: value));
  }

  Future<void> setGiftsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyGifts, value);
    emit(state.copyWith(giftsEnabled: value));
  }
}
