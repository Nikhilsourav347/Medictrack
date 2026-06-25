// lib/features/reports/widgets/date_range_picker_widget.dart
import 'package:flutter/material.dart';

class DateRangePickerWidget extends StatelessWidget {
  final String selectedFilter;
  final Function(String filter, String startDate, String endDate) onFilterChanged;
  final String? startDate;
  final String? endDate;

  const DateRangePickerWidget({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    this.startDate,
    this.endDate,
  });

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildChip(
            context,
            label: 'Today',
            filterValue: 'today',
            calcStartDate: _formatDate(now),
            calcEndDate: _formatDate(now),
          ),
          const SizedBox(width: 8),
          _buildChip(
            context,
            label: 'Last 7 Days',
            filterValue: 'week',
            calcStartDate: _formatDate(now.subtract(const Duration(days: 7))),
            calcEndDate: _formatDate(now),
          ),
          const SizedBox(width: 8),
          _buildChip(
            context,
            label: 'Last 30 Days',
            filterValue: 'month',
            calcStartDate: _formatDate(now.subtract(const Duration(days: 30))),
            calcEndDate: _formatDate(now),
          ),
          const SizedBox(width: 8),
          _buildChip(
            context,
            label: 'Custom',
            filterValue: 'custom',
            calcStartDate: startDate ?? _formatDate(now),
            calcEndDate: endDate ?? _formatDate(now),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required String label,
    required String filterValue,
    required String calcStartDate,
    required String calcEndDate,
  }) {
    final isSelected = selectedFilter == filterValue;

    return GestureDetector(
      onTap: () => onFilterChanged(filterValue, calcStartDate, calcEndDate),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1D9E75) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF1D9E75) : Colors.grey.shade400,
            width: isSelected ? 1.0 : 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade600,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
