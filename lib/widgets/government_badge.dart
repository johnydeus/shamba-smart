import 'package:flutter/material.dart';

// Gold badge shown wherever official Ministry of Agriculture data appears
class GovernmentBadge extends StatelessWidget {
  const GovernmentBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF57F17),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        '📋 Serikali 2022',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// Source attribution footer for all official-data screens
class GovernmentSourceFooter extends StatelessWidget {
  const GovernmentSourceFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.account_balance,
              size: 14, color: Color(0xFF757575)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Chanzo: Wizara ya Kilimo Tanzania, 2022\n'
              '"Kilimo Ni Biashara — Ajenda 10/30"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
