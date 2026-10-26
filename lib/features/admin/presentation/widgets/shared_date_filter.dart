import 'package:flutter/material.dart';

class SharedDateFilter extends StatelessWidget {
  final DateTime from;
  final DateTime to;
  final Future<void> Function(bool isFrom)? onPickDate;
  final void Function(DateTime from, DateTime to)? onDateRangeChanged;
  final VoidCallback? onApply;
  final String title;

  const SharedDateFilter({
    super.key,
    required this.from,
    required this.to,
    this.onPickDate,
    this.onDateRangeChanged,
    this.onApply,
    this.title = 'Filtro de fechas',
  });

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> _handlePick(BuildContext context, bool isFrom) async {
    if (onPickDate != null) {
      await onPickDate!(isFrom);
      return;
    }
    final initial = isFrom ? from : to;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    if (isFrom) {
      onDateRangeChanged?.call(picked, to);
    } else {
      onDateRangeChanged?.call(from, picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.date_range,
                  size: 20,
                  color: Color(0xFFFFC12F),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => _handlePick(context, true),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      'Desde: ${_formatDate(from)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => _handlePick(context, false),
                    icon: const Icon(Icons.event, size: 16),
                    label: Text(
                      'Hasta: ${_formatDate(to)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
            if (onApply != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC12F),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: onApply,
                  icon: const Icon(Icons.filter_alt, size: 18),
                  label: const Text(
                    'Aplicar período',
                    style: TextStyle(fontWeight: FontWeight.bold),
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
