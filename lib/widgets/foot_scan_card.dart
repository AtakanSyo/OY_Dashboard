import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class FootScanCard extends StatelessWidget {
  final String modelPath;
  final String title;

  const FootScanCard({
    super.key,
    required this.modelPath,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.teal,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            height: 300,
            child: ModelViewer(
              src: modelPath,
              alt: '3D Foot Scan',
              ar: false,
              autoRotate: true,
              cameraControls: true,
              disableZoom: false,
              backgroundColor: Colors.white,
              interactionPrompt: InteractionPrompt.whenFocused,
              autoRotateDelay: 0,
              rotationPerSecond: "20deg",
            ),
          ),
        ],
      ),
    );
  }
}
