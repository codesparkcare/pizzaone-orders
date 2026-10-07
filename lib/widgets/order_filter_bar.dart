import 'package:flutter/material.dart';
import '../core/localization/app_strings.dart';
import '../core/theme/app_theme.dart';

class OrderFilterBar extends StatelessWidget {
  final String activeFilter;
  final Map<String, int> counts;
  final Function(String) onFilterSelected;

  const OrderFilterBar({
    super.key,
    required this.activeFilter,
    required this.counts,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final filters = [
      {'key': 'all', 'label': context.tr('filter_all'), 'count': counts.values.fold(0, (a, b) => a + b), 'color': AppTheme.textPrimary},
      {'key': 'pending', 'label': context.tr('filter_pending'), 'count': counts['pending'] ?? 0, 'color': AppTheme.statusPending},
      {'key': 'preparing', 'label': context.tr('filter_kitchen'), 'count': (counts['confirmed'] ?? 0) + (counts['preparing'] ?? 0), 'color': AppTheme.statusPreparing},
      {'key': 'ready', 'label': context.tr('filter_ready'), 'count': counts['ready'] ?? 0, 'color': AppTheme.statusReady},
      {'key': 'delivered', 'label': context.tr('filter_delivered'), 'count': counts['delivered'] ?? 0, 'color': AppTheme.statusDelivered},
      {'key': 'cancelled', 'label': context.tr('filter_cancelled'), 'count': counts['cancelled'] ?? 0, 'color': AppTheme.statusCancelled},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: filters.map((f) {
          final isSelected = activeFilter == f['key'];
          final filterColor = f['color'] as Color;
          final count = f['count'] as int;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              showCheckmark: false,
              backgroundColor: AppTheme.surfaceElevated,
              selectedColor: filterColor.withValues(alpha: 0.2),
              side: BorderSide(
                color: isSelected ? filterColor : AppTheme.surfaceBorder,
                width: isSelected ? 1.5 : 1,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    f['label'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected ? filterColor : AppTheme.surfaceBorder,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        count.toString(),
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              onSelected: (_) => onFilterSelected(f['key'] as String),
            ),
          );
        }).toList(),
      ),
    );
  }
}
