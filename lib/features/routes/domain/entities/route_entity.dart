import 'package:equatable/equatable.dart';

class RouteEntity extends Equatable {
  final String id;
  final String name;
  final String ref;
  final String? color;
  final List<Map<String, double>>? stops; // paradas: {lat, lng}
  final List<Map<String, double>>?
  polyline; // coordenadas de la ruta: {lat, lng}
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool active;

  const RouteEntity({
    required this.id,
    required this.name,
    required this.ref,
    this.color,
    this.stops,
    this.polyline,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.active = true,
  });

  RouteEntity copyWith({
    String? id,
    String? name,
    String? ref,
    String? color,
    List<Map<String, double>>? stops,
    List<Map<String, double>>? polyline,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? active,
  }) {
    return RouteEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      ref: ref ?? this.ref,
      color: color ?? this.color,
      stops: stops ?? this.stops,
      polyline: polyline ?? this.polyline,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      active: active ?? this.active,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    ref,
    color,
    stops,
    polyline,
    description,
    createdAt,
    updatedAt,
    active,
  ];
}
