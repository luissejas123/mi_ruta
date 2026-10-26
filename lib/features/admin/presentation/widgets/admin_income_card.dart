import 'package:flutter/material.dart';
import 'package:mi_ruta/core/theme/app_colors.dart';
import 'package:mi_ruta/features/admin/domain/entities/admin_income_report.dart';

/// Tarjeta "Ingresos del período" del panel de métricas (Obs. 8).
class AdminIncomeCard extends StatelessWidget {
  final AdminIncomeReport report;

  const AdminIncomeCard({super.key, required this.report});

  String _bs(double v) => 'Bs. ${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final theme = Theme.of(context);

    final tiles = [
      _IncomeTile(
        label: 'Cobrado en pasajes',
        value: _bs(report.collected),
        detail: '${report.paidTrips} viajes pagados',
        icon: Icons.payments_outlined,
        color: colors.success,
      ),
      _IncomeTile(
        label: 'Reembolsado',
        value: _bs(report.refunded),
        detail: '${report.refundedTrips} cancelaciones',
        icon: Icons.undo,
        color: colors.danger,
      ),
      _IncomeTile(
        label: 'Ingreso neto',
        value: _bs(report.netIncome),
        detail: 'Cobrado − reembolsado',
        icon: Icons.account_balance_wallet_outlined,
        color: colors.accentText,
      ),
      _IncomeTile(
        label: 'Recargas aprobadas',
        value: _bs(report.recharges),
        detail: '${report.approvedRecharges} recargas',
        icon: Icons.add_card,
        color: colors.info,
      ),
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.monetization_on_outlined, color: colors.accentText),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ingresos del período',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 2 columnas en celulares, 4 en pantallas anchas (tablet).
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 600 ? 4 : 2;
                const gap = 10.0;
                final width =
                    (constraints.maxWidth - gap * (columns - 1)) / columns;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final tile in tiles)
                      SizedBox(width: width, child: tile),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Ingresos por línea',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            if (report.byLine.isEmpty)
              Text(
                'Sin pasajes cobrados en este período.',
                style: TextStyle(color: colors.textSecondary),
              )
            else
              ...report.byLine.map(
                (line) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              line.line,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                            ),
                            Text(
                              '${line.paidTrips} viajes',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _bs(line.collected),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colors.accentText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _IncomeTile extends StatelessWidget {
  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;

  const _IncomeTile({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
          ),
          Text(
            detail,
            style: TextStyle(fontSize: 11, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
