import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/user/domain/usecases/user_usecases.dart';
import 'package:mi_ruta/features/user/presentation/bloc/user_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/user_state.dart';

/// BLoC para gestionar la lógica de Usuario
class UserBloc extends Bloc<UserEvent, UserState> {
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final GetUserByIdUseCase getUserByIdUseCase;
  final GetUsersByIdsUseCase getUsersByIdsUseCase;
  final UpdateUserUseCase updateUserUseCase;
  final GetUserRatingUseCase getUserRatingUseCase;
  final GetUserStreamUseCase getUserStreamUseCase;

  UserBloc({
    required this.getCurrentUserUseCase,
    required this.getUserByIdUseCase,
    required this.getUsersByIdsUseCase,
    required this.updateUserUseCase,
    required this.getUserRatingUseCase,
    required this.getUserStreamUseCase,
  }) : super(const UserInitial()) {
    // Registrar handlers para cada evento
    on<GetCurrentUserEvent>(_onGetCurrentUser);
    on<GetUserByIdEvent>(_onGetUserById);
    on<GetUsersByIdsEvent>(_onGetUsersByIds);
    on<UpdateUserEvent>(_onUpdateUser);
    on<GetUserRatingEvent>(_onGetUserRating);
    on<StartUserStreamEvent>(_onStartUserStream);
  }

  /// Handler: Obtener usuario actual
  Future<void> _onGetCurrentUser(
    GetCurrentUserEvent event,
    Emitter<UserState> emit,
  ) async {
    emit(const UserLoading());
    final result = await getCurrentUserUseCase();
    result.fold(
      (failure) => emit(UserError(message: failure.message)),
      (user) => emit(UserLoaded(user: user)),
    );
  }

  /// Handler: Obtener usuario por ID
  Future<void> _onGetUserById(
    GetUserByIdEvent event,
    Emitter<UserState> emit,
  ) async {
    emit(const UserLoading());
    final result = await getUserByIdUseCase(event.uid);
    result.fold(
      (failure) => emit(UserError(message: failure.message)),
      (user) => emit(UserLoaded(user: user)),
    );
  }

  /// Handler: Obtener múltiples usuarios
  Future<void> _onGetUsersByIds(
    GetUsersByIdsEvent event,
    Emitter<UserState> emit,
  ) async {
    emit(const UserLoading());
    final result = await getUsersByIdsUseCase(event.uids);
    result.fold(
      (failure) => emit(UserError(message: failure.message)),
      (users) => emit(UsersLoaded(users: users)),
    );
  }

  /// Handler: Actualizar usuario
  Future<void> _onUpdateUser(
    UpdateUserEvent event,
    Emitter<UserState> emit,
  ) async {
    emit(const UserLoading());
    final result = await updateUserUseCase(event.uid, event.data);
    result.fold(
      (failure) => emit(UserError(message: failure.message)),
      (_) => emit(
        const UserOperationSuccess(
          message: 'Usuario actualizado correctamente',
        ),
      ),
    );
  }

  /// Handler: Obtener calificación
  Future<void> _onGetUserRating(
    GetUserRatingEvent event,
    Emitter<UserState> emit,
  ) async {
    emit(const UserLoading());
    final result = await getUserRatingUseCase(event.uid);
    result.fold(
      (failure) => emit(UserError(message: failure.message)),
      (rating) => emit(UserRatingLoaded(rating: rating)),
    );
  }

  /// Handler: Stream en tiempo real
  Future<void> _onStartUserStream(
    StartUserStreamEvent event,
    Emitter<UserState> emit,
  ) async {
    await emit.forEach(
      getUserStreamUseCase(event.uid),
      onData: (result) {
        return result.fold(
          (failure) => UserError(message: failure.message),
          (user) => UserStreamLoaded(user: user),
        );
      },
      onError: (error, stackTrace) {
        return UserError(message: 'Error en stream: ${error.toString()}');
      },
    );
  }
}
