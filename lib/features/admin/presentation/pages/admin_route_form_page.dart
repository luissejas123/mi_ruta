import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/route_management_bloc.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/route_management_event.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/route_management_state.dart';
import 'package:mi_ruta/features/admin/presentation/widgets/admin_bottom_navigation_bar.dart';
import 'package:mi_ruta/features/routes/domain/entities/route_entity.dart';

class AdminRouteFormPage extends StatefulWidget {
  /// Si es null se crea una ruta nueva; si no, se edita.
  final RouteEntity? route;

  const AdminRouteFormPage({super.key, this.route});

  @override
  State<AdminRouteFormPage> createState() => _AdminRouteFormPageState();
}

class _AdminRouteFormPageState extends State<AdminRouteFormPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _refController;
  late final TextEditingController _colorController;
  late final TextEditingController _descriptionController;
  bool _active = true;
  String? _errorLocal;

  bool get _isEditing => widget.route != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.route?.name ?? '');
    _refController = TextEditingController(text: widget.route?.ref ?? '');
    _colorController =
        TextEditingController(text: widget.route?.color ?? '');
    _descriptionController =
        TextEditingController(text: widget.route?.description ?? '');
    _active = widget.route?.active ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _refController.dispose();
    _colorController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _guardar() {
    final name = _nameController.text.trim();
    final ref = _refController.text.trim();

    if (name.isEmpty || ref.isEmpty) {
      setState(() => _errorLocal = 'Nombre y referencia son obligatorios');
      return;
    }
    setState(() => _errorLocal = null);

    final color = _colorController.text.trim().isEmpty
        ? null
        : _colorController.text.trim();
    final description = _descriptionController.text.trim().isEmpty
        ? null
        : _descriptionController.text.trim();

    final bloc = context.read<RouteManagementBloc>();
    if (_isEditing) {
      bloc.add(
        UpdateAdminRouteEvent(
          routeId: widget.route!.id,
          name: name,
          ref: ref,
          color: color,
          description: description,
          active: _active,
        ),
      );
    } else {
      bloc.add(
        CreateAdminRouteEvent(
          name: name,
          ref: ref,
          color: color,
          description: description,
        ),
      );
    }
  }

  Future<void> _eliminar() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar ruta'),
        content: Text(
          '¿Seguro que quieres desactivar la ruta "${widget.route!.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context
          .read<RouteManagementBloc>()
          .add(DeleteAdminRouteEvent(widget.route!.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar ruta' : 'Nueva ruta'),
        centerTitle: true,
      ),
      body: BlocConsumer<RouteManagementBloc, RouteManagementState>(
        listener: (context, state) {
          // Éxito de creación/actualización/eliminación: la página de listado
          // muestra el SnackBar; aquí solo se cierra el formulario.
          if (state is RouteManagementSuccess && context.mounted) {
            Navigator.pop(context);
          }
          if (state is RouteManagementError && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red.shade700,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is RouteManagementLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la ruta *',
                    prefixIcon: Icon(Icons.route_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _refController,
                  decoration: const InputDecoration(
                    labelText: 'Referencia (número) *',
                    prefixIcon: Icon(Icons.tag),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _colorController,
                  decoration: const InputDecoration(
                    labelText: 'Color (hex, ej: FF5733)',
                    prefixIcon: Icon(Icons.color_lens_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                ),
                if (_isEditing)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Ruta activa',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    value: _active,
                    activeTrackColor: const Color(0xFFFFC12F),
                    onChanged: (value) => setState(() => _active = value),
                  ),
                if (_errorLocal != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _errorLocal!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC12F),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: isLoading ? null : _guardar,
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            'GUARDAR',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                if (_isEditing) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade700),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: isLoading ? null : _eliminar,
                      child: const Text(
                        'ELIMINAR RUTA',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: const AdminBottomNavigationBar(
        currentIndex: 0,
      ),
    );
  }
}
