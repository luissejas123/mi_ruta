import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/admin/domain/services/admin_privileges_service.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/admin_privileges_event.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/admin_privileges_state.dart';

class AdminPrivilegesBloc
    extends Bloc<AdminPrivilegesEvent, AdminPrivilegesState> {
  final AdminPrivilegesService _service;

  AdminPrivilegesBloc({required AdminPrivilegesService service})
    : _service = service,
      super(AdminPrivilegesInitial()) {
    on<LoadAdminPrivileges>(_onLoad);
    on<SaveAdminPrivileges>(_onSave);
  }

  Future<void> _onLoad(
    LoadAdminPrivileges event,
    Emitter<AdminPrivilegesState> emit,
  ) async {
    emit(AdminPrivilegesLoading());
    try {
      final privileges = await _service.getPrivileges(event.adminId);
      emit(AdminPrivilegesLoaded(privileges));
    } catch (error) {
      emit(AdminPrivilegesError('Error al cargar privilegios: $error'));
    }
  }

  Future<void> _onSave(
    SaveAdminPrivileges event,
    Emitter<AdminPrivilegesState> emit,
  ) async {
    emit(AdminPrivilegesSaving(event.privileges));
    try {
      await _service.savePrivileges(event.adminId, event.privileges);
      emit(AdminPrivilegesSaved(event.privileges));
    } catch (error) {
      emit(AdminPrivilegesError('Error al guardar privilegios: $error'));
    }
  }
}
