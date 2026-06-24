import 'package:flutter/material.dart';
import '../../../data/models/medicine_model.dart';

class MedicineDueCard extends StatelessWidget {
  final MedicineModel medicine;
  final VoidCallback onTaken;

  const MedicineDueCard({
    super.key,
    required this.medicine,
    required this.onTaken,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1D9E75).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.medication,
              color: Color(0xFF1D9E75),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicine.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  medicine.dosage ?? medicine.frequency,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onTaken,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1D9E75),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: const Text('Taken', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
