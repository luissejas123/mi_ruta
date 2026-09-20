import 'package:equatable/equatable.dart';

abstract class RouteManagementEvent extends Equatable {
  const RouteManagementEvent();

  @override
  List<Object?> get props => [];
}

class LoadAdminRoutesEvent extends RouteManagementEvent {
  const LoadAdminRoutesEvent();
}

class SearchAdminRoutesEvent extends RouteManagementEvent {
  final String query;

  const SearchAdminRoutesEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class CreateAdminRouteEvent extends RouteManagementEvent {
  final String name;
  final String ref;
  final String? color;
  final String? description;

  const CreateAdminRouteEvent({
    required this.name,
    required this.ref,
    this.color,
    this.description,
  });

  @override
  List<Object?> get props => [name, ref, color, description];
}

class UpdateAdminRouteEvent extends RouteManagementEvent {
  final String routeId;
  final String name;
  final String ref;
  final String? color;
  final String? description;
  final bool active;

  const UpdateAdminRouteEvent({
    required this.routeId,
    required this.name,
    required this.ref,
    this.color,
    this.description,
    required this.active,
  });

  @override
  List<Object?> get props => [routeId, name, ref, color, description, active];
}

class DeleteAdminRouteEvent extends RouteManagementEvent {
  final String routeId;

  const DeleteAdminRouteEvent(this.routeId);

  @override
  List<Object?> get props => [routeId];
}

class LoadRoutesFromGtfsAdminEvent extends RouteManagementEvent {
  const LoadRoutesFromGtfsAdminEvent();
}
