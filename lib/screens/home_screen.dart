import 'package:flutter/material.dart';
import 'package:wave/wave.dart';
import 'package:wave/config.dart';

class HomeScreen extends StatelessWidget {
  final int currentVolume = 1283; // Volume saat ini dalam ml
  final int targetVolume = 2000; // Target harian dalam ml
  int _waveHeight = 50;
  double _waveAmplitude = 10;

  @override
  Widget build(BuildContext context) {
    final double percentage = (currentVolume / targetVolume).clamp(0.0, 1.0);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.lightBlueAccent,
      body: Stack(
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              color: Colors.transparent,
              height: double.parse(_waveHeight.toString()),
              child: WaveWidget(
                config: CustomConfig(
                  colors: [
                    Colors.blue.withOpacity(0.1),
                    Colors.blue.withOpacity(0.3),
                    Colors.blue.withOpacity(0.5),
                  ],
                  durations: [3000, 6000, 12000],
                  heightPercentages: [0.15, 0.20, 0.25],
                  blur: MaskFilter.blur(BlurStyle.solid, 10),
                ),
                size:
                    Size(double.infinity, double.parse(_waveHeight.toString())),
                waveAmplitude: _waveAmplitude,
              ),
            ),
          ),
          // Teks Volume dan Jam di Pojok Kanan Atas
          Positioned(
            top: size.height * 0.15, // Jarak dari atas
            right: size.width * 0.15, // Jarak dari kanan
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '9:41',
                  style: TextStyle(
                    fontSize: size.width * 0.05,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$currentVolume ml',
                  style: TextStyle(
                    fontSize: size.width * 0.05,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),
          ),
          // Konten Utama di Tengah
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: size.width * 0.5,
                      height: size.width * 0.5,
                      child: CustomPaint(
                        painter: CircularPainter(percentage),
                      ),
                    ),
                    // Teks Persentase di Tengah
                    Text(
                      '${(percentage * 100).toInt()}%', // Persentase
                      style: TextStyle(
                        fontSize: size.width * 0.1,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          // Ikon Panda di Bawah
          Positioned(
            bottom: size.height * 0.25,
            left: 0,
            right: 0,
            child: Text(
              "200 ml",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          // Ikon Tambahan di Sisi Bawah Kiri dan Kanan
          Positioned(
            bottom: size.height * 0.15,
            left: size.width * 0.12,
            child: CircleAvatar(
              backgroundColor: Colors.lightBlueAccent,
              child: Icon(
                Icons.add,
                color: Colors.white,
                size: size.width * 0.07,
              ),
            ),
          ),
          Positioned(
            bottom: size.height * 0.05,
            right: 0,
            left: 0,
            child: CircleAvatar(
              backgroundColor: Colors.lightBlueAccent,
              child: Icon(
                Icons.coffee, // Ikon cangkir
                color: Colors.white,
                size: size.width * 0.07,
              ),
            ),
          ),
          Positioned(
            bottom: size.height * 0.15,
            right: size.width * 0.12,
            child: CircleAvatar(
              backgroundColor: Color.fromARGB(255, 247, 96, 96),
              child: Icon(
                Icons.remove, // Ikon cangkir
                color: Colors.white,
                size: size.width * 0.07,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CircularPainter extends CustomPainter {
  final double percentage;

  CircularPainter(this.percentage);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint backgroundPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;

    final Paint progressPaint = Paint()
      ..color = Colors.lightBlue[500]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final Rect arcRect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Gambar background lingkaran 3/4
    canvas.drawArc(
      arcRect,
      3.14 * 3 / 4, // Mulai dari jam 8 (135 derajat)
      3 * 3.14 / 2, // 3/4 lingkaran
      false,
      backgroundPaint,
    );

    // Gambar progress lingkaran 3/4
    canvas.drawArc(
      arcRect,
      3.14 * 3 / 4, // Mulai dari jam 8 (135 derajat)
      3 * 3.14 / 2 * percentage, // 3/4 lingkaran dengan nilai progress
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
