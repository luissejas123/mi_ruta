import 'package:equatable/equatable.dart';
import 'package:mi_ruta/features/presidente/domain/entities/tariff_entity.dart';

abstract class TariffState extends Equatable {
  const TariffState();

  @override
  List<Object?> get props => [];
}

class TariffInitial extends TariffState {
  const TariffInitial();
}

class TariffLoading extends TariffState {
  const TariffLoading();
}

/// [tariff] es null si la línea todavía no tiene tarifa configurada.
/// [justSaved] es transitorio: true justo después de guardar, para que la
/// UI muestre una confirmación una sola vez.
class TariffLoaded extends TariffState {
  final TariffEntity? tariff;
  final bool justSaved;

  const TariffLoaded({required this.tariff, this.justSaved = false});

  @override
  List<Object?> get props => [tariff, justSaved];
}

class TariffError extends TariffState {
  final String message;
  const TariffError({required this.message});

  @override
  List<Object?> get props => [message];
}
