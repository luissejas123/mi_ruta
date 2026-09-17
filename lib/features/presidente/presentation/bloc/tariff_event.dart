import 'package:equatable/equatable.dart';

abstract class TariffEvent extends Equatable {
  const TariffEvent();

  @override
  List<Object?> get props => [];
}

class LoadTariff extends TariffEvent {
  final String routeRef;
  const LoadTariff(this.routeRef);

  @override
  List<Object?> get props => [routeRef];
}

class SaveTariffRequested extends TariffEvent {
  final String routeRef;
  final double pricePerKmBs;
  const SaveTariffRequested({required this.routeRef, required this.pricePerKmBs});

  @override
  List<Object?> get props => [routeRef, pricePerKmBs];
}
