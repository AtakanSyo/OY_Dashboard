import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class InteractiveFootModel extends StatelessWidget {
  final String modelPath;
  final String label;

  const InteractiveFootModel({
    super.key,
    required this.modelPath,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            AspectRatio(
              aspectRatio: 1.1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ModelViewer(
                  src: modelPath, // .stl veya .glb dosyası
                  alt: "3D foot scan",
                  ar: false,
                  autoRotate: true,
                  rotationPerSecond: "30deg",
                  autoRotateDelay: 0,
                  cameraControls: true,
                  disableZoom: false,
                  shadowIntensity: 1,
                  shadowSoftness: 0.8,
                  environmentImage: "neutral",
                  cameraOrbit: "0deg 75deg 2.5m",
                  minCameraOrbit: "-45deg 45deg 1.5m",
                  maxCameraOrbit: "45deg 100deg 3m",
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
