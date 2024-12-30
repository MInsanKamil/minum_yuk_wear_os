import 'package:flutter/material.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class CurvedWaveSlider extends StatefulWidget {
  final double min;
  final double max;
  final double value;
  final ValueChanged<double> onChanged;

  const CurvedWaveSlider({
    Key? key,
    this.min = 0,
    this.max = 100,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  _CurvedWaveSliderState createState() => _CurvedWaveSliderState();
}

class _CurvedWaveSliderState extends State<CurvedWaveSlider> {
  late double _dragValue;
  // bool _isInitialized = false; // Track initialization status

  @override
  void initState() {
    super.initState();
    _loadDragValue();
  }

  // Load saved drag value from SharedPreferences
  void _loadDragValue() async {
    setState(() {
      _dragValue = widget.value;
      // _isInitialized = true; // Set to true once the value is loaded
    });
  }

  // // Save drag value to SharedPreferences
  // void _saveDragValue(double value) async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   await prefs.setDouble('dragValue', value);
  // }

  void _updateDragPosition(Offset position, Size size) {
    double progress = position.dx / size.width;
    progress = progress.clamp(0.0, 1.0);
    double newValue = widget.min + (progress * (widget.max - widget.min));

    // Round the new value to the nearest multiple of 10
    newValue = (newValue / 10).roundToDouble() * 10;

    setState(() {
      _dragValue = newValue;
    });

    widget.onChanged(newValue);
    // _saveDragValue(newValue);
  }

  @override
  Widget build(BuildContext context) {
    // if (!_isInitialized) {
    //   return const Center(
    //       child:
    //           CircularProgressIndicator()); // Show a loading indicator while loading
    // }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onPanUpdate: (details) {
            _updateDragPosition(details.localPosition, constraints.biggest);
          },
          child: CustomPaint(
            size: Size(constraints.maxWidth, 100), // Height remains constant
            painter: CurvedWavePainter(
              value: _dragValue, // Use the current value directly
              min: widget.min,
              max: widget.max,
              color: Colors.white,
              activeColor: const Color.fromARGB(255, 36, 109, 143),
            ),
          ),
        );
      },
    );
  }
}

class CurvedWavePainter extends CustomPainter {
  final double value;
  final double min;
  final double max;
  final Color color;
  final Color activeColor;

  CurvedWavePainter({
    required this.value,
    required this.min,
    required this.max,
    required this.color,
    required this.activeColor,
  });

  double _calculateBezierY(double t, double height, double controlHeight) {
    double p0 = height;
    double p1 = height - controlHeight;
    double p2 = height;
    return pow(1 - t, 2) * p0 + 2 * (1 - t) * t * p1 + pow(t, 2) * p2;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double progress = (value - min) / (max - min);

    final Paint inactivePaint = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;

    final Paint activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;

    final Path inactivePath = Path();
    final Path activePath = Path();

    double controlHeight = size.height * 0.5;

    // Full inactive path
    inactivePath.moveTo(0, size.height);
    inactivePath.quadraticBezierTo(
      size.width / 2,
      size.height - controlHeight,
      size.width,
      size.height,
    );
    // Tambahkan garis horizontal di ujung path
    inactivePath.lineTo(size.width + 5, size.height - 5);
    inactivePath.moveTo(size.width, size.height);
    inactivePath.lineTo(size.width - 5, size.height + 5);

    // Add a horizontal line at the other end of the path
    inactivePath.moveTo(0, size.height);
    inactivePath.lineTo(5, size.height + 5);
    inactivePath.moveTo(0, size.height);
    inactivePath.lineTo(-5, size.height - 5);

    // Active path up to the progress point
    activePath.moveTo(0, size.height);
    for (double t = 0; t <= progress; t += 0.01) {
      double x = t * size.width;
      double y = _calculateBezierY(t, size.height, controlHeight);
      if (t == 0) {
        activePath.moveTo(x, y);
      } else {
        activePath.lineTo(x, y);
      }
    }

    activePath.moveTo(0, size.height);
    activePath.lineTo(5, size.height + 5);
    activePath.moveTo(0, size.height);
    activePath.lineTo(-5, size.height - 5);

    // Draw inactive path
    canvas.drawPath(inactivePath, inactivePaint);

    // Draw active path
    canvas.drawPath(activePath, activePaint);

    // Calculate slider position
    double sliderX = progress * size.width;
    double sliderY = _calculateBezierY(progress, size.height, controlHeight);

    // Render the background circle
    final double circleRadius =
        size.width * 0.15; // Adjust the radius as needed
    final Paint circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(sliderX, sliderY), circleRadius, circlePaint);

    // Render the icon at the slider position
    final icon = Icons.local_drink;
    final iconSize = size.width * 0.25;
    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: iconSize,
          color: const Color.fromARGB(255, 36, 109, 143),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Save the canvas state
    canvas.save();

    // Move the canvas origin to the slider position
    canvas.translate(sliderX, sliderY);

    // Rotate the canvas by 90 degrees (in radians)
    canvas.rotate(pi / 2);

    // Draw the icon after rotating it
    iconPainter.paint(canvas, Offset(-iconSize / 2, -iconSize / 2));

    double textHeight = size.width * 0.11; // Text height based on font size
    canvas.translate(0, -(iconSize / 2 + textHeight)); // Move below the icon

    // Draw the text
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${value.round()} ml',
        style: TextStyle(
          color: const Color.fromARGB(255, 36, 109, 143),
          fontWeight: FontWeight.bold,
          fontSize: size.width * 0.075,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, Offset(-textPainter.width / 2, 0));

    // Restore the canvas to its original state
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
