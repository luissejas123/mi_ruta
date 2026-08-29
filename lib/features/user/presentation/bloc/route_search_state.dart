import 'package:equatable/equatable.dart';
import 'package:mi_ruta/features/user/domain/services/route_finder_service.dart';

abstract class RouteSearchState extends Equatable {
  const RouteSearchState();

  @override
  List<Object?> get props => [];
}

class RouteSearchInitial extends RouteSearchState {
  const RouteSearchInitial();
}

class RouteSearchLoading extends RouteSearchState {
  const RouteSearchLoading();
}

class RouteSearchSuccess extends RouteSearchState {
  final List<RouteMatch> matches;

  const RouteSearchSuccess({required this.matches});

  @override
  List<Object?> get props => [matches];
}

class RouteSearchEmpty extends RouteSearchState {
  final String message;

  const RouteSearchEmpty({required this.message});

  @override
  List<Object?> get props => [message];
}

class RouteSearchError extends RouteSearchState {
  final String message;

  const RouteSearchError({required this.message});

  @override
  List<Object?> get props => [message];
}
