import 'package:flutter/material.dart';

class AnalysisCardTemplate extends StatelessWidget {
  final String title;
  final Widget leftContent;
  final Widget rightContent;
  final String? bottomNote;

  const AnalysisCardTemplate({
    super.key,
    required this.title,
    required this.leftContent,
    required this.rightContent,
    this.bottomNote,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Başlık
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),

          const SizedBox(height: 20),

          /// Sol - Sağ kolonlar
          Row(
            children: [
              Expanded(child: leftContent),
              const SizedBox(width: 16),
              Expanded(child: rightContent),
            ],
          ),

          if (bottomNote != null) ...[
            const SizedBox(height: 20),
            Text(
              bottomNote!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ]
        ],
      ),
    );
  }
}
