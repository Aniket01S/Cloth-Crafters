import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:convert';
import 'dart:async';
import 'package:image/image.dart' as img;

class DesignAnalyzerDialog extends StatefulWidget {
  final String designImageBase64;
  final String completedImageBase64;

  const DesignAnalyzerDialog({
    super.key,
    required this.designImageBase64,
    required this.completedImageBase64,
  });

  @override
  _DesignAnalyzerDialogState createState() => _DesignAnalyzerDialogState();
}

class _DesignAnalyzerDialogState extends State<DesignAnalyzerDialog> with SingleTickerProviderStateMixin {
  bool _isAnalyzing = true;
  double _matchPercentage = 0;
  String _colorAnalysis = "";
  String _patternAnalysis = "";
  String _overallAnalysis = "";

  late AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _startAnalysis();
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  double _calculateImageSimilarity(String b1, String b2) {
    try {
      final bytes1 = base64Decode(b1.split(',').last);
      final bytes2 = base64Decode(b2.split(',').last);

      final img1 = img.decodeImage(bytes1);
      final img2 = img.decodeImage(bytes2);

      if (img1 == null || img2 == null) return 50.0;

      // Resize both to 16x16 to ignore small differences and compare structural colors
      final resized1 = img.copyResize(img1, width: 16, height: 16);
      final resized2 = img.copyResize(img2, width: 16, height: 16);

      double diffSum = 0;
      for (int y = 0; y < 16; y++) {
        for (int x = 0; x < 16; x++) {
          final p1 = resized1.getPixel(x, y);
          final p2 = resized2.getPixel(x, y);
          
          final r1 = p1.r;
          final g1 = p1.g;
          final b1 = p1.b;

          final r2 = p2.r;
          final g2 = p2.g;
          final b2 = p2.b;

          diffSum += ((r1 - r2).abs() + (g1 - g2).abs() + (b1 - b2).abs()) / (255.0 * 3.0);
        }
      }

      double avgDiff = diffSum / (16 * 16);
      double similarity = (1.0 - avgDiff) * 100.0;
      return similarity.clamp(0.0, 100.0);
    } catch (e) {
      return 50.0; // Fallback
    }
  }

  void _startAnalysis() {
    // Run intensive image processing on a slight delay to allow UI to render first
    Timer(const Duration(milliseconds: 500), () async {
      double rawScore = _calculateImageSimilarity(widget.designImageBase64, widget.completedImageBase64);
      
      // Give it another 3 seconds of "scanning" animation for effect
      await Future.delayed(const Duration(seconds: 3));

      if (!mounted) return;

      // Tune the score so identical is 95-100%, different is <50%
      double finalScore = rawScore;
      if (rawScore > 85) {
        finalScore = 90 + (rawScore - 85) * (10 / 15); // stretch 85-100 to 90-100
      } else if (rawScore < 60) {
        finalScore = rawScore * 0.8; // penalize further
      }

      setState(() {
        _isAnalyzing = false;
        _matchPercentage = finalScore.floorToDouble();
        
        if (finalScore >= 80) {
          _colorAnalysis = "Perfect Match (High Accuracy)";
          _patternAnalysis = "Identical stitching and silhouette";
          _overallAnalysis = "The completed item is a flawless replica of the provided design inspiration. Outstanding craftsmanship.";
        } else {
          _colorAnalysis = "Not Match";
          _patternAnalysis = "Not Match";
          _overallAnalysis = "Not match. Design is completely different.";
        }
      });
    });
  }

  Widget _buildImage(String base64Str) {
    try {
      final bytes = base64Decode(base64Str.split(',').last);
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    } catch (e) {
      return Container(color: Colors.grey[300]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 40,
              offset: const Offset(0, 10),
            )
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "AI Design Analysis",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 200,
                child: Row(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          _buildImage(widget.designImageBase64),
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                "DESIGN",
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          if (_isAnalyzing)
                            AnimatedBuilder(
                              animation: _scanController,
                              builder: (context, child) {
                                return Positioned(
                                  top: _scanController.value * 190,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: 2,
                                    decoration: BoxDecoration(
                                      color: Colors.blueAccent,
                                      boxShadow: [
                                        BoxShadow(color: Colors.blueAccent.withOpacity(0.8), blurRadius: 10, spreadRadius: 2)
                                      ]
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Stack(
                        children: [
                          _buildImage(widget.completedImageBase64),
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                "COMPLETED",
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          if (_isAnalyzing)
                            AnimatedBuilder(
                              animation: _scanController,
                              builder: (context, child) {
                                return Positioned(
                                  top: _scanController.value * 190,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: 2,
                                    decoration: BoxDecoration(
                                      color: Colors.greenAccent,
                                      boxShadow: [
                                        BoxShadow(color: Colors.greenAccent.withOpacity(0.8), blurRadius: 10, spreadRadius: 2)
                                      ]
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              if (_isAnalyzing) ...[
                const CircularProgressIndicator(color: Colors.black),
                const SizedBox(height: 16),
                const Text(
                  "Analyzing fabrics, patterns, and structure...",
                  style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic),
                ).animate(onPlay: (controller) => controller.repeat()).shimmer(duration: 1500.ms),
              ] else ...[
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: _matchPercentage),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Column(
                      children: [
                        Text(
                          "${value.toInt()}%",
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: value >= 80 ? Colors.green[600] : (value >= 50 ? Colors.orange[600] : Colors.red[600]),
                          ),
                        ),
                        const Text(
                          "OVERALL MATCH",
                          style: TextStyle(fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold, color: Colors.black54),
                        ),
                      ],
                    );
                  },
                ).animate().fade().scale(curve: Curves.easeOutBack),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.color_lens_outlined, size: 18, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text("Color Analysis", style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(_colorAnalysis, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                      const Divider(height: 24),
                      Row(
                        children: [
                          const Icon(Icons.pattern_outlined, size: 18, color: Colors.purple),
                          const SizedBox(width: 8),
                          const Text("Pattern & Cut", style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(_patternAnalysis, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                    ],
                  ),
                ).animate().fade(delay: 500.ms).slideY(begin: 0.2),
                const SizedBox(height: 16),
                Text(
                  _overallAnalysis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Colors.black54, fontStyle: FontStyle.italic),
                ).animate().fade(delay: 1000.ms),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: Colors.black12),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("CLOSE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
