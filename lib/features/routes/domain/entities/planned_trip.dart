import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum LegType { bus, walking }

class PlannedTripLeg extends Equatable {
  final LegType type;
  final String routeId;
  final String routeName;
  final String routeRef;
  final String? directionId;
  final LatLng boardingPoint;
  final LatLng alightingPoint;
  // For bus legs: distance on vehicle.
  // For walking legs: total walk distance (stored in transitMeters for symmetry).
  final double walkToMeters;
  final double transitMeters;
  final double walkFromMeters;

  const PlannedTripLeg({
    this.type = LegType.bus,
    required this.routeId,
    required this.routeName,
    required this.routeRef,
    this.directionId,
    required this.boardingPoint,
    required this.alightingPoint,
    this.walkToMeters = 0,
    required this.transitMeters,
    this.walkFromMeters = 0,
  });

  bool get isBus => type == LegType.bus;
  bool get isWalking => type == LegType.walking;

  int get estimatedMinutes {
    if (isWalking) return (transitMeters / 80).ceil();
    return ((walkToMeters + walkFromMeters) / 80 + transitMeters / 250).ceil();
  }

  /// Factory for an explicit walking leg between two points.
  factory PlannedTripLeg.walk({
    required LatLng from,
    required LatLng to,
    required double meters,
  }) =>
      PlannedTripLeg(
        type: LegType.walking,
        routeId: '',
        routeName: 'Caminando',
        routeRef: '',
        boardingPoint: from,
        alightingPoint: to,
        transitMeters: meters,
      );

  @override
  List<Object?> get props => [
        type,
        routeId,
        routeName,
        routeRef,
        directionId,
        boardingPoint,
        alightingPoint,
        walkToMeters,
        transitMeters,
        walkFromMeters,
      ];
}

class PlannedTrip extends Equatable {
  final String id;
  final String userId;
  final String originName;
  final LatLng originLatLng;
  final String destinationName;
  final LatLng destinationLatLng;
  final List<PlannedTripLeg> legs;
  final DateTime createdAt;
  final bool isCompleted;

  const PlannedTrip({
    required this.id,
    required this.userId,
    required this.originName,
    required this.originLatLng,
    required this.destinationName,
    required this.destinationLatLng,
    required this.legs,
    required this.createdAt,
    this.isCompleted = false,
  });

  PlannedTrip copyWith({String? id}) => PlannedTrip(
        id: id ?? this.id,
        userId: userId,
        originName: originName,
        originLatLng: originLatLng,
        destinationName: destinationName,
        destinationLatLng: destinationLatLng,
        legs: legs,
        createdAt: createdAt,
        isCompleted: isCompleted,
      );

  List<PlannedTripLeg> get busLegs => legs.where((l) => l.isBus).toList();

  int get totalMinutes => legs.fold(0, (s, l) => s + l.estimatedMinutes);
  double get totalDistanceKm =>
      legs.fold(
              0.0,
              (s, l) =>
                  s + l.walkToMeters + l.transitMeters + l.walkFromMeters) /
      1000;
  double get totalCostBs => busLegs.length * 2.5;
  String get routesSummary => busLegs.map((l) => l.routeName).join(' + ');

  @override
  List<Object?> get props => [id, userId, legs, isCompleted];
}
