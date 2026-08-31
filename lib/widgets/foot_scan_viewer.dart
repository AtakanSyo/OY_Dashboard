import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class FootScanViewer extends StatelessWidget {
  final String leftFootPath;
  final String rightFootPath;
  final bool showBoth;

  const FootScanViewer({
    super.key,
    required this.leftFootPath,
    required this.rightFootPath,
    this.showBoth = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("3D Foot Scan"),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: showBoth
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildModel(leftFootPath, "Left Foot")),
                  const SizedBox(width: 12),
                  Expanded(child: _buildModel(rightFootPath, "Right Foot")),
                ],
              )
            : _buildModel(leftFootPath, "Foot Scan"),
      ),
    );
  }

  Widget _buildModel(String assetPath, String label) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(label,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ModelViewer(
                src: assetPath,
                alt: "3D foot scan model",
                ar: false,
                autoRotate: true,
                cameraControls: true,
                disableZoom: false,
                backgroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
