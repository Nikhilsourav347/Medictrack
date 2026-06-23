import 'package:flutter/material.dart';

enum DateRangeOption { last7Days, last30Days, custom }

class DateRangePickerWidget extends StatelessWidget {
  final DateRangeOption selected;
  final DateTime startDate;
  final DateTime endDate;
  final ValueChanged<DateRangeOption> onOptionChanged;
  final VoidCallback onPickCustomRange;

  const DateRangePickerWidget({
    super.key,
    required this.selected,
    required this.startDate,
    required this.endDate,
    required this.onOptionChanged,
    required this.onPickCustomRange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Date Range',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _OptionChip(
                label: 'Last 7 days',
                isSelected: selected == DateRangeOption.last7Days,
                onTap: () => onOptionChanged(DateRangeOption.last7Days),
              ),
              const SizedBox(width: 8),
              _OptionChip(
                label: 'Last 30 days',
                isSelected: selected == DateRangeOption.last30Days,
                onTap: () => onOptionChanged(DateRangeOption.last30Days),
              ),
              const SizedBox(width: 8),
              _OptionChip(
                label: 'Custom',
                isSelected: selected == DateRangeOption.custom,
                icon: Icons.date_range_outlined,
                onTap: () {
                  onOptionChanged(DateRangeOption.custom);
                  onPickCustomRange();
                },
              ),
            ],
          ),
          if (selected == DateRangeOption.custom) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: onPickCustomRange,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D9E75).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFF1D9E75).withOpacity(0.2)),
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_month_outlined,
                      size: 16, color: Color(0xFF1D9E75)),
                  const SizedBox(width: 8),
                  Text(
                    '${_fmt(startDate)}  →  ${_fmt(endDate)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D9E75),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.edit_outlined,
                      size: 14, color: Color(0xFF1D9E75)),
                ]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')} ${_month(dt.month)} ${dt.year}';

  String _month(int m) {
    const n = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return n[m];
  }
}

class _OptionChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final IconData? icon;
  final VoidCallback onTap;

  const _OptionChip({
    required this.label,
    required this.isSelected,
    this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1D9E75)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1D9E75)
                : Colors.grey.shade200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14,
                  color: isSelected ? Colors.white : Colors.grey.shade600),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
