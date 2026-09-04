import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/core/utils/user_category.dart';
import 'package:mi_ruta/features/admin/domain/entities/admin_user_entity.dart';
import 'package:mi_ruta/features/admin/domain/entities/role_hierarchy.dart';
import 'package:mi_ruta/features/admin/domain/services/admin_access_service.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/admin_privileges_bloc.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/user_management_bloc.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/user_management_event.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/user_management_state.dart';
import 'package:mi_ruta/features/admin/presentation/widgets/admin_bottom_navigation_bar.dart';
import 'package:mi_ruta/features/user/domain/entities/user_entity.dart';

const _amarillo = Color(0xFFFFC12F);

const _roleFilters = <String?, String>{
  null: 'Todos',
  'passenger': 'Pasajeros',
  'driver': 'Choferes',
  //'tickeador': 'Tickeadores',
  'admin': 'Administradores',
  'presidente': 'Dirigentes',
};

const Map<String, Color> _roleColors = {
  'passenger': Color(0xFFFFC12F),
  'usuario': Color(0xFFFFC12F),
  'driver': Color(0xFF8D5E3B),
  'chofer': Color(0xFF8D5E3B),
  //'tickeador': Color(0xFF7C4DFF),
  'admin': Color(0xFF7C4DFF),
  'presidente': Color(0xFFEF6C00),
  'dirigente': Color(0xFFEF6C00),
};

Color roleColorForUserType(String? userType) {
  final normalized = (userType ?? '').trim().toLowerCase();
  if (normalized.isEmpty) {
    return _roleColors['passenger']!;
  }
  return _roleColors[normalized] ?? _roleColors['passenger']!;
}

String _roleLabel(String userType) => _roleFilters[userType] ?? userType;

/// Gestión de cuentas de cualquier rol (RQ-71 gestión de usuarios,
/// RQ-72 aprobación/bloqueo) — accesible para admin y presidente.
class UserManagementPage extends StatelessWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  late final TextEditingController _searchController;
  String? _roleFilter;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    context.read<UserManagementBloc>().add(const LoadUsersEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _canManageAdmins {
    final authState = context.read<AuthBloc>().state;
    return authState is AuthLoaded && authState.user.canManageAdmins;
  }

  Future<void> _confirmPromote(AdminUserEntity user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Promover a administrador'),
        content: Text(
          '¿Seguro que quieres convertir a "${user.fullName}" en administrador?\n'
          'Se actualizará su role a "admin" en Firestore.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Promover',
              style: TextStyle(color: Color(0xFFFFC12F)),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleFilterBar extends StatelessWidget {
  const _RoleFilterBar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: BlocBuilder<UserManagementBloc, UserManagementState>(
        builder: (context, state) {
          final activeFilter = state is UserManagementLoaded ? state.activeFilter : null;
          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            children: _roleFilters.entries.map((entry) {
              final selected = entry.key == activeFilter;
              final chipColor = roleColorForUserType(entry.key);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    entry.value,
                    style: TextStyle(
                      color: selected ? Colors.white : chipColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  selected: selected,
                  selectedColor: chipColor,
                  backgroundColor: chipColor.withValues(alpha: 0.12),
                  showCheckmark: false,
                  side: BorderSide(
                    color: chipColor.withValues(alpha: selected ? 0 : 0.5),
                    width: 1,
                  ),
                  onSelected: (_) => context
                      .read<UserManagementBloc>()
                      .add(LoadManagedUsers(userTypeFilter: entry.key)),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserEntity user;
  final bool isUpdating;

  const _UserTile({required this.user, required this.isUpdating});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: user.isActive ? null : Border.all(color: Colors.red.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: roleColorForUserType(user.userType),
            backgroundImage:
                user.profileImageUrl.isNotEmpty ? NetworkImage(user.profileImageUrl) : null,
            child: user.profileImageUrl.isEmpty
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName.isNotEmpty ? user.fullName : user.email,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: [
                    _Badge(
                      label: _roleLabel(user.userType),
                      color: roleColorForUserType(user.userType),
                    ),
                    _Badge(
                      label: user.isActive ? 'Aprobado' : 'Bloqueado',
                      color: user.isActive ? Colors.green : Colors.red,
                    ),
                    if (user.qaAccess) const _Badge(label: 'Acceso QA', color: Colors.purple),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            _DetailRow(label: 'UID', value: user.uid),
            if (user.phoneNumber.isNotEmpty)
              _DetailRow(label: 'Teléfono', value: user.phoneNumber),
            _DetailRow(label: 'Role', value: user.role),
            const SizedBox(height: 20),
            if (RoleHierarchy.canGrant(user.roles.toSet(), 'admin') && _canManageAdmins)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC12F),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _confirmPromote(user);
                  },
                  child: const Text(
                    'Promover a administrador',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            if (RoleHierarchy.canGrant(user.roles.toSet(), 'presidente') &&
                _canManageAdmins) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFFC12F), width: 1.5),
                  ),
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _confirmPromoteToPresidente(user);
                  },
                  child: const Text(
                    'Promover a presidente',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
            if (user.isAdmin)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC12F),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: getIt<AdminPrivilegesBloc>(),
                          child: AdminPermissionsEditPage(user: user),
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'Ver privilegios',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddAdminDialog() async {
    final bloc = context.read<UserManagementBloc>();
    final state = bloc.state;
    if (state is! UserManagementLoaded) return;

    final candidates = state.users.where((u) => !u.isAdmin).toList();
    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay usuarios sin rol de administrador'),
        ),
      );
      return;
    }

    final selected = await showModalBottomSheet<AdminUserEntity>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (context, scrollController) => ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: candidates.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Selecciona un usuario para promover',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              );
            }
            final user = candidates[index - 1];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFFFC12F),
                child: Text(
                  user.fullName.isNotEmpty
                      ? user.fullName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              title: Text(user.fullName),
              subtitle: Text(user.email),
              onTap: () => Navigator.pop(sheetContext, user),
            );
          },
        ),
      ),
    );

    if (selected != null) {
      _confirmPromote(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de usuarios'),
        centerTitle: true,
      ),
      body: BlocConsumer<UserManagementBloc, UserManagementState>(
        listener: (context, state) {
          if (state is UserManagementSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green.shade700,
              ),
            );
          }
          if (state is UserManagementError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red.shade700,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is UserManagementLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFC12F)),
            );
          }
          if (state is UserManagementError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context
                          .read<UserManagementBloc>()
                          .add(const LoadUsersEvent()),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is! UserManagementLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final visible = _roleFilter == null
              ? state.filteredUsers
              : state.filteredUsers
                  .where((u) => u.role == _roleFilter)
                  .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre, correo o teléfono...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              context
                                  .read<UserManagementBloc>()
                                  .add(const SearchUsersEvent(''));
                            },
                          ),
                  ),
                  onChanged: (value) =>
                      context.read<UserManagementBloc>().add(SearchUsersEvent(value)),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    for (final filter in _roleFilters)
                      _RoleChip(
                        label: filter.label,
                        selected: _roleFilter == filter.role,
                        onTap: () =>
                            setState(() => _roleFilter = filter.role),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: visible.isEmpty
                    ? const Center(
                        child: Text(
                          'No se encontraron usuarios',
                          style: TextStyle(color: Colors.black54),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => context
                            .read<UserManagementBloc>()
                            .add(const LoadUsersEvent()),
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
                          itemCount: visible.length,
                          itemBuilder: (context, index) {
                            final user = visible[index];
                            return Card(
                              margin:
                                  const EdgeInsets.symmetric(vertical: 6),
                              elevation: 0,
                              color: const Color(0xFFF7F1E3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => _showUserDetails(user),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: getUserCategoryColor(
                                              user.role,
                                            ),
                                            width: 5,  //aqui es el borde del avatar, se puede cambiar el color segun el role del usuario
                                          ),
                                        ),
                                        child: CircleAvatar(
                                          radius: 26,
                                          backgroundColor:
                                              const Color(0xFFFFC12F),
                                          child: Text(
                                            user.fullName.isNotEmpty
                                                ? user.fullName[0].toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              user.fullName,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              user.email,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.black54,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              getUserCategoryDescription(
                                                user.role,
                                              ),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.black54,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                            if (user.phoneNumber.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                user.phoneNumber,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ],
                                            const SizedBox(height: 10),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 4,
                                              children: [
                                                _RoleBadge(role: user.role),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.chevron_right,
                                        color: Colors.black45,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _canManageAdmins
          ? FloatingActionButton.small(
              heroTag: 'add_admin',
              backgroundColor: const Color(0xFFFFC12F),
              foregroundColor: Colors.black,
              tooltip: 'Agregar nuevo administrador',
              onPressed: _showAddAdminDialog,
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: const AdminBottomNavigationBar(
        currentIndex: 0,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final Color color;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}

class _RoleFilter {
  final String label;
  final String? role;

  const _RoleFilter(this.label, this.role);
}

const _roleFilters = [
  _RoleFilter('Todos', null),
  _RoleFilter('Pasajeros', 'user'),
  _RoleFilter('Choferes', 'driver'),
  _RoleFilter('Tickeadores', 'tickeador'),
  _RoleFilter('Administradores', 'admin'),
  _RoleFilter('Dirigentes', 'presidente'),
];

class _RoleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? const Color(0xFFFFC12F) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: selected ? const Color(0xFFFFC12F) : Colors.grey.shade300,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: Text(
              label,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == 'admin';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isAdmin ? const Color(0xFFFFC12F) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        getUserCategoryLabel(role),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isAdmin ? Colors.black : Colors.black87,
        ),
      ),
    );
  }
}

class _RoleFilter {
  final String label;
  final String? role;

  const _RoleFilter(this.label, this.role);
}

const _roleFilters = [
  _RoleFilter('Todos', null),
  _RoleFilter('Pasajeros', 'user'),
  _RoleFilter('Choferes', 'driver'),
  _RoleFilter('Tickeadores', 'tickeador'),
  _RoleFilter('Administradores', 'admin'),
  _RoleFilter('Dirigentes', 'presidente'),
];

class _RoleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? const Color(0xFFFFC12F) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: selected ? const Color(0xFFFFC12F) : Colors.grey.shade300,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: Text(
              label,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == 'admin';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isAdmin ? const Color(0xFFFFC12F) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        getUserCategoryLabel(role),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isAdmin ? Colors.black : Colors.black87,
        ),
      ),
    );
  }
}
