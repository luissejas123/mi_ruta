import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/user/domain/entities/benefit_request.dart';
import 'package:mi_ruta/features/user/domain/services/benefit_request_service.dart';

class AdministracionBeneficiosPage extends StatefulWidget {
  const AdministracionBeneficiosPage({super.key});

  @override
  State<AdministracionBeneficiosPage> createState() =>
      _AdministracionBeneficiosPageState();
}

class _AdministracionBeneficiosPageState
    extends State<AdministracionBeneficiosPage> {
  final _searchController = TextEditingController();
  late final BenefitRequestService _service;
  late Future<List<BenefitRequest>> _requests;
  String _filter = 'all';
  int _tabIndex = 0;
  // Al tocar un tipo en la pestaña "Beneficios" (_BenefitsList), se activa
  // esto y se salta a "Solicitudes" ya filtrado por ese tipo — antes esa
  // fila no hacía nada al tocarla.
  String? _benefitTypeFilter;

  @override
  void initState() {
    super.initState();
    _service = getIt<BenefitRequestService>();
    _requests = _service.getAllBenefitRequests();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() => _requests = _service.getAllBenefitRequests());
    await _requests;
  }

  bool _authorized(AuthState state) {
    if (state is! AuthLoaded) return false;
    return {'admin', 'administrador'}.contains(state.user.role.toLowerCase());
  }

  List<BenefitRequest> _filtered(List<BenefitRequest> requests) {
    final query = _searchController.text.trim().toLowerCase();
    return requests.where((request) {
      final matchesFilter = _filter == 'all' || request.status == _filter;
      final matchesType =
          _benefitTypeFilter == null || request.benefitType == _benefitTypeFilter;
      final searchable = [
        request.userName,
        request.userEmail,
        request.userPhone,
        request.benefitType,
        request.description,
      ].whereType<String>().join(' ').toLowerCase();
      return matchesFilter &&
          matchesType &&
          (query.isEmpty || searchable.contains(query));
    }).toList();
  }

  Future<void> _decide(BenefitRequest request, bool approve) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthLoaded || request.status != 'pending') return;
    var notes = '';
    if (!approve) {
      final result = await _rejectionReason();
      if (result == null) return;
      notes = result;
    }
    try {
      if (approve) {
        await _service.approveBenefitRequest(
          request.id,
          notes,
          authState.user.uid,
        );
      } else {
        await _service.rejectBenefitRequest(
          request.id,
          notes,
          authState.user.uid,
        );
      }
      if (!mounted) return;
      Navigator.pop(context);
      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approve
                ? 'Beneficio aprobado correctamente'
                : 'Solicitud rechazada',
          ),
          backgroundColor: approve
              ? Colors.green.shade700
              : Colors.red.shade700,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo procesar la solicitud: $error')),
      );
    }
  }

  Future<String?> _rejectionReason() async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar solicitud'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Motivo (opcional)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
    controller.dispose();
    return reason;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (!_authorized(authState)) {
          return const Scaffold(
            body: Center(
              child: Text('No tienes permisos para administrar beneficios.'),
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Aprobación de beneficios',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
          ),
          body: FutureBuilder<List<BenefitRequest>>(
            future: _requests,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFFC12F)),
                );
              }
              if (snapshot.hasError) {
                return _ErrorView(onRetry: _reload);
              }
              final requests = snapshot.data ?? const <BenefitRequest>[];
              return Column(
                children: [
                  _SearchAndTabs(
                    controller: _searchController,
                    selectedFilter: _filter,
                    tabIndex: _tabIndex,
                    benefitTypeFilter: _benefitTypeFilter,
                    onFilterChanged: (value) => setState(() => _filter = value),
                    onTabChanged: (value) => setState(() => _tabIndex = value),
                    onClearTypeFilter: () => setState(() => _benefitTypeFilter = null),
                  ),
                  Expanded(
                    child: _tabIndex == 0
                        ? _RequestList(
                            requests: _filtered(requests),
                            onTap: _showDetails,
                            onRefresh: _reload,
                          )
                        : _BenefitsList(
                            requests: requests,
                            onTypeTap: (type) => setState(() {
                              _benefitTypeFilter = type;
                              _filter = 'all';
                              _tabIndex = 0;
                            }),
                          ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _showDetails(BenefitRequest request) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _RequestDetails(
        request: request,
        onDecision: (approve) => _decide(request, approve),
      ),
    );
  }
}

class _SearchAndTabs extends StatelessWidget {
  final TextEditingController controller;
  final String selectedFilter;
  final int tabIndex;
  final String? benefitTypeFilter;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<int> onTabChanged;
  final VoidCallback onClearTypeFilter;

  const _SearchAndTabs({
    required this.controller,
    required this.selectedFilter,
    required this.tabIndex,
    required this.benefitTypeFilter,
    required this.onFilterChanged,
    required this.onTabChanged,
    required this.onClearTypeFilter,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
    child: Column(
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Buscar por nombre, correo o teléfono...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    onPressed: controller.clear,
                    icon: const Icon(Icons.clear),
                  ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Solicitudes')),
                  ButtonSegment(value: 1, label: Text('Beneficios')),
                ],
                selected: {tabIndex},
                onSelectionChanged: (value) => onTabChanged(value.first),
              ),
            ),
          ],
        ),
        if (tabIndex == 0) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final option in const [
                  ('all', 'Todos'),
                  ('pending', 'Pendientes'),
                  ('approved', 'Aprobados'),
                  ('rejected', 'Rechazados'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 6, top: 8),
                    child: ChoiceChip(
                      label: Text(option.$2),
                      selected: selectedFilter == option.$1,
                      onSelected: (_) => onFilterChanged(option.$1),
                    ),
                  ),
              ],
            ),
          ),
          // Viene de tocar un tipo en la pestaña "Beneficios" — antes esa
          // fila no filtraba nada al tocarla.
          if (benefitTypeFilter != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: InputChip(
                  avatar: const Icon(Icons.filter_alt_outlined, size: 18),
                  label: Text('Solo ${_benefitLabel(benefitTypeFilter!)}'),
                  onDeleted: onClearTypeFilter,
                ),
              ),
            ),
        ],
      ],
    ),
  );
}

class _RequestList extends StatelessWidget {
  final List<BenefitRequest> requests;
  final ValueChanged<BenefitRequest> onTap;
  final Future<void> Function() onRefresh;

  const _RequestList({
    required this.requests,
    required this.onTap,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return const Center(child: Text('No hay solicitudes para este filtro.'));
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: const Color(0xFFFFC12F),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: requests.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, index) => _RequestCard(
          request: requests[index],
          onTap: () => onTap(requests[index]),
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final BenefitRequest request;
  final VoidCallback onTap;

  const _RequestCard({required this.request, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = request.userName?.trim().isNotEmpty == true
        ? request.userName!
        : 'Usuario ${request.userId}';
    final status = _status(request.status);
    return Card(
      elevation: 0,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFFFC12F),
          child: Text(name.substring(0, 1).toUpperCase()),
        ),
        title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${request.userEmail ?? 'Correo no disponible'}\n${_userTypeLabel(request.userType)} · ${_benefitLabel(request.benefitType)}',
        ),
        isThreeLine: true,
        trailing: _StatusChip(label: status.$1, color: status.$2),
      ),
    );
  }
}

class _RequestDetails extends StatelessWidget {
  final BenefitRequest request;
  final ValueChanged<bool> onDecision;

  const _RequestDetails({required this.request, required this.onDecision});

  @override
  Widget build(BuildContext context) {
    final status = _status(request.status);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _benefitLabel(request.benefitType),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _Detail('Nombre', request.userName ?? 'No disponible'),
            _Detail('Correo', request.userEmail ?? 'No disponible'),
            _Detail('Teléfono', request.userPhone ?? 'No disponible'),
            _Detail('Tipo de usuario', _userTypeLabel(request.userType)),
            _Detail('Fecha de solicitud', _date(request.createdAt)),
            _Detail('Estado actual', status.$1),
            _Detail('Detalle', request.description),
            if (request.documentUrls.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Documentos',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              // Antes mostraba la URL cruda como texto — nadie va a pegarla
              // en el navegador para revisar un comprobante. Botón directo
              // a verla en grande.
              for (var i = 0; i < request.documentUrls.length; i++)
                _DocumentButton(
                  label: request.documentUrls.length > 1
                      ? 'Ver documento ${i + 1}'
                      : 'Ver documento',
                  url: request.documentUrls[i],
                ),
            ],
            if (request.adminNotes?.isNotEmpty == true)
              _Detail('Observación administrativa', request.adminNotes!),
            if (request.status == 'pending') ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => onDecision(true),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Aprobar beneficio'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => onDecision(false),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Rechazar solicitud'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BenefitsList extends StatelessWidget {
  final List<BenefitRequest> requests;
  final ValueChanged<String> onTypeTap;
  const _BenefitsList({required this.requests, required this.onTypeTap});

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<BenefitRequest>>{};
    for (final request in requests) {
      grouped.putIfAbsent(request.benefitType, () => []).add(request);
    }
    if (grouped.isEmpty) {
      return const Center(child: Text('Aún no hay beneficios registrados.'));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: grouped.entries.map((entry) {
        final approved = entry.value
            .where((r) => r.status == 'approved')
            .length;
        return Card(
          child: ListTile(
            // Antes no tenía onTap: mostraba el resumen pero no llevaba a
            // las solicitudes de ese tipo.
            onTap: () => onTypeTap(entry.key),
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFFFC12F),
              child: Icon(Icons.school_outlined, color: Colors.black),
            ),
            title: Text(_benefitLabel(entry.key)),
            subtitle: Text(
              '${entry.value.length} solicitudes · $approved usuarios beneficiados',
            ),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      }).toList(),
    );
  }
}

/// Botón que abre el documento subido (siempre imagen — `SolicitudBeneficioPage`
/// solo permite `ImagePicker`, nunca PDF) para revisarlo antes de aprobar o
/// rechazar, en vez de mostrar la URL en texto plano.
class _DocumentButton extends StatelessWidget {
  final String label;
  final String url;
  const _DocumentButton({required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: OutlinedButton.icon(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => Dialog(
            child: InteractiveViewer(
              child: Image.network(
                url,
                errorBuilder: (_, _, _) => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No se pudo cargar la imagen.'),
                ),
              ),
            ),
          ),
        ),
        icon: const Icon(Icons.image_outlined, size: 18),
        label: Text(label),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  final String label;
  final String value;
  const _Detail(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: value),
        ],
      ),
    ),
  );
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Chip(
    label: Text(label, style: TextStyle(color: color, fontSize: 11)),
    backgroundColor: color.withValues(alpha: .12),
    side: BorderSide.none,
    visualDensity: VisualDensity.compact,
  );
}

class _ErrorView extends StatelessWidget {
  final Future<void> Function() onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('No se pudieron cargar las solicitudes.'),
        TextButton(onPressed: onRetry, child: const Text('Reintentar')),
      ],
    ),
  );
}

(String, Color) _status(String value) {
  switch (value) {
    case 'approved':
      return ('APROBADO', Colors.green.shade700);
    case 'rejected':
      return ('RECHAZADO', Colors.red.shade700);
    default:
      return ('PENDIENTE', Colors.orange.shade800);
  }
}

String _userTypeLabel(String? value) {
  switch (value?.toLowerCase()) {
    case 'student':
    case 'estudiante':
      return 'Estudiante';
    case 'university':
    case 'universitario':
      return 'Universitario';
    default:
      return value?.isNotEmpty == true ? value! : 'No disponible';
  }
}

String _benefitLabel(String value) {
  switch (value) {
    case 'student':
      return 'Tarifa estudiantil';
    case 'university':
      return 'Tarifa universitaria';
    case 'senior':
      return 'Beneficio adulto mayor';
    default:
      return value.isEmpty ? 'Beneficio' : value;
  }
}

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
