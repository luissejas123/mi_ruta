import 'package:flutter/material.dart';

class TripSummaryView extends StatelessWidget {
  final String walkStartSublabel;
  final String busLabel;
  final String walkEndSublabel;
  final String destinationName;

  const TripSummaryView({
    super.key,
    required this.walkStartSublabel,
    required this.busLabel,
    required this.walkEndSublabel,
    required this.destinationName,
  });

  static const Color _cardColor = Color(0xFFFFC12F);
  static const Color _textColor = Color(0xFF221A00);
  static const Color _iconFillColor = Color(0xFFFFF7D1);

  @override
  Widget build(BuildContext context) {
    final alightAtDestination =
        walkEndSublabel == '0 m' || walkEndSublabel == '0m';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SummaryStage(
            icon: Icons.directions_walk,
            title: 'Caminar hasta la parada',
            subtitle: walkStartSublabel,
          ),
          const _StageConnector(),
          _SummaryStage(
            icon: Icons.directions_bus,
            title: busLabel,
            subtitle: 'Abordar el micro / trufi',
          ),
          const _StageConnector(),
          _SummaryStage(
            icon: Icons.directions_walk,
            title: alightAtDestination
                ? 'Bajada en el destino'
                : 'Bajarse y caminar al destino',
            subtitle: alightAtDestination
                ? 'Tu destino esta en la parada'
                : walkEndSublabel,
          ),
          const _StageConnector(),
          _SummaryStage(
            icon: Icons.location_on,
            title: destinationName,
            subtitle: 'Tu destino',
          ),
        ],
      ),
    );
  }
}

class _SummaryStage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SummaryStage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: TripSummaryView._iconFillColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: TripSummaryView._textColor, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: TripSummaryView._textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: TripSummaryView._textColor.withValues(alpha: 0.72),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StageConnector extends StatelessWidget {
  const _StageConnector();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 20),
        child: Container(
          width: 2,
          height: 18,
          decoration: BoxDecoration(
            color: TripSummaryView._textColor.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
