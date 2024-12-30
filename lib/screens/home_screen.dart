import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:minum_yuk_wear_os/widgets/curveSlider.dart';
import 'package:wave/wave.dart';
import 'package:wave/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/drinklog.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _ml = 0;
  int _waveHeight = 50;
  int _volume = 200;
  int _target = 2500;
  double _waveAmplitude = 10;
  bool isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadLatestDrinkLog();
    _loadTargetHarian();
    // _loadPreferences();
    // _nextNotificationFuture = _getNextNotificationTime();
  }

  void _loadTargetHarian() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _target = prefs.getInt('targetHarian') ?? _target;
    });
  }

  void _increaseDrink() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      _ml += _volume;
      _waveHeight += (_volume / 20).round();
      // _waveAmplitude += (_volume / 40).round();
    });

    // Mendapatkan waktu saat ini
    DateTime now = DateTime.now();

    // Simpan data ke dalam list
    List<String> drinkLog = prefs.getStringList('drinkLog') ?? [];
    String logEntry = jsonEncode({
      'volume': _volume,
      'time': now.toIso8601String(), // Store the date in ISO 8601 format
      'ml': _ml,
      'waveHeight': _waveHeight,
      'waveAmplitude': _waveAmplitude,
    });
    drinkLog.add(logEntry);

    // Simpan kembali ke SharedPreferences
    await prefs.setStringList('drinkLog', drinkLog);

    // if (isStopReminder && _ml >= _target) {
    //   await NotificationHelper.cancelAllNotifications();
    //   await prefs.remove('notification_times');
    //   setState(() {
    //     _nextNotificationFuture = _getNextNotificationTime();
    //   });
    // }
  }

  void _undoDrink() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> drinkLog = prefs.getStringList('drinkLog') ?? [];

    // Filter logs for today
    DateTime today = DateTime.now();
    String todayString =
        DateTime(today.year, today.month, today.day).toIso8601String();

    // Remove the latest log for today
    if (drinkLog.isNotEmpty) {
      Map<String, dynamic> lastLog = jsonDecode(drinkLog.last);
      DateTime logDate = DateTime.parse(lastLog['time']);
      String logDateString =
          DateTime(logDate.year, logDate.month, logDate.day).toIso8601String();

      if (logDateString == todayString) {
        drinkLog.removeLast(); // Remove the last log
        await prefs.setStringList('drinkLog', drinkLog); // Save back

        // Update state
        int lastMl = lastLog['ml'] as int;
        int lastVolume = lastLog['volume'] as int; // Cast to int
        setState(() {
          _ml -= lastVolume; // Update _ml
          _waveHeight -= (lastVolume / 20).round() as int; // Update wave height
          // _waveAmplitude -=
          //     (lastVolume / 40).round() as int; // Update wave amplitude
        });
      }
    }
  }

  void _loadLatestDrinkLog() async {
    // Nilai default
    int defaultMl = 0;
    int defaultVolume = 200;
    int defaultWaveHeight = 50;
    double defaultWaveAmplitude = 10;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? drinkLog = prefs.getStringList('drinkLog');

    Drinkslog latestTodayLog;

    if (drinkLog != null && drinkLog.isNotEmpty) {
      DateTime today = DateTime.now();
      latestTodayLog = drinkLog.reversed
          .map((entry) => Drinkslog.fromJson(jsonDecode(entry)))
          .firstWhere(
        (log) {
          DateTime logDate = DateTime.parse(log.time);
          return logDate.year == today.year &&
              logDate.month == today.month &&
              logDate.day == today.day;
        },
        orElse: () => Drinkslog(
          volume: defaultVolume,
          time: today.toIso8601String(),
          ml: defaultMl,
          waveHeight: defaultWaveHeight,
          waveAmplitude: defaultWaveAmplitude,
        ),
      );
    } else {
      // Jika tidak ada log sama sekali, gunakan objek default
      latestTodayLog = Drinkslog(
        volume: defaultVolume,
        time: DateTime.now().toIso8601String(),
        ml: defaultMl,
        waveHeight: defaultWaveHeight,
        waveAmplitude: defaultWaveAmplitude,
      );
    }

    setState(() {
      _ml = latestTodayLog.ml;
      _volume = latestTodayLog.volume;
      _waveHeight = latestTodayLog.waveHeight;
      _waveAmplitude = latestTodayLog.waveAmplitude;
      isDataLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double percentage = (_ml / _target).clamp(0.0, 1.0);
    final size = MediaQuery.of(context).size;
    _loadTargetHarian();
    if (!isDataLoaded) {
      return Scaffold(
        backgroundColor: Colors.lightBlueAccent[100]!,
        body: Center(child: CircularProgressIndicator()), // Show loading
      );
    }

    return Scaffold(
      backgroundColor: Colors.lightBlueAccent[100]!,
      body: Stack(
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 2000),
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
          // Konten Utama di Tengah
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                          begin: 0,
                          end: percentage), // Animasi dari 0 ke percentage
                      duration: const Duration(
                          milliseconds: 1000), // Durasi animasi 1 detik
                      builder: (context, animatedPercentage, child) {
                        return SizedBox(
                          width: size.width * 0.5,
                          height: size.width * 0.5,
                          child: CustomPaint(
                            painter: CircularPainter(
                                animatedPercentage), // Menggunakan nilai animasi
                          ),
                        );
                      },
                    ),
                    // Row untuk teks persentase dan gambar
                    Column(
                      children: [
                        Image.asset(
                          'assets/icon.png', // Gambar panda
                          width: size.width * 0.15,
                          height: size.width * 0.15,
                        ),
                        Text(
                          "Total Minum:",
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        TweenAnimationBuilder<int>(
                          tween: IntTween(
                              begin: 0,
                              end: _ml), // Animasi dari 0 ke nilai _ml
                          duration: const Duration(
                              milliseconds: 1000), // Durasi animasi 1 detik
                          builder: (context, value, child) {
                            return Text(
                              '$value ml', // Menampilkan angka dengan satuan "ml"
                              style: TextStyle(
                                fontSize: size.width * 0.05,
                                fontWeight: FontWeight.bold,
                                color: const Color.fromARGB(255, 36, 109, 143),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize:
                          MainAxisSize.min, // Supaya Row sesuai dengan isi
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                            width: size.width *
                                0.01), // Jarak antara teks dan gambar
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: size.height * 0.05,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  "Target Harian:",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                Text(
                  '$_target ml', // Menampilkan angka dengan satuan "ml"
                  style: TextStyle(
                    fontSize: size.width * 0.05,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 36, 109, 143),
                  ),
                )
              ],
            ),
          ),
          // Ikon Panda di Bawah
          Positioned(
            bottom: size.height * 0.23,
            left: 0,
            right: 0,
            child: TweenAnimationBuilder<int>(
              tween: IntTween(
                begin: 0, // Memulai animasi dari 0%
                end: (percentage * 100)
                    .toInt(), // Animasi hingga nilai persentase
              ),
              duration:
                  const Duration(milliseconds: 500), // Durasi animasi 1 detik
              builder: (context, value, child) {
                return Text(
                  '$value%', // Menampilkan angka dengan tanda "%"
                  style: TextStyle(
                    fontSize: size.width * 0.08,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                );
              },
            ),
          ),
          // Ikon Tambahan di Sisi Bawah Kiri dan Kanan
          Align(
            alignment: Alignment.bottomCenter,
            child: ElevatedButton(
              onPressed:
                  _increaseDrink, // Menghubungkan fungsi ke tindakan tombol
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(
                    255, 36, 109, 143), // Warna latar belakang tombol
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                      30), // Membuat tombol berbentuk melingkar
                ),
                padding: EdgeInsets.symmetric(
                  vertical: size.height * 0.02, // Padding atas dan bawah tombol
                  horizontal:
                      size.width * 0.05, // Padding kiri dan kanan tombol
                ),
              ),
              child: Text(
                "MINUM",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size.width * 0.05, // Ukuran font teks
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          Positioned(
            bottom: size.height * 0.25,
            right: size.width * 0.05,
            child: GestureDetector(
              onTap: () {
                _undoDrink(); // Call the _undoDrink function on tap
              },
              child: CircleAvatar(
                backgroundColor: Color.fromARGB(255, 36, 109, 143),
                child: Icon(
                  Icons.refresh, // Ikon cangkir
                  color: Colors.white,
                  size: size.width * 0.07,
                ),
              ),
            ),
          ),
// Botol slider
          Positioned(
            bottom: size.height * 0.25,
            right: size.width * 0.775, // Atur posisi sesuai kebutuhan
            child: Container(
              constraints: BoxConstraints(
                maxHeight: size.height * 0.5, // Batasi tinggi maksimal
              ),
              child: RotatedBox(
                quarterTurns: -1,
                child: CurvedWaveSlider(
                  value: _volume.toDouble(),
                  min: 0,
                  max: 2000,
                  onChanged: (value) {
                    setState(() {
                      _volume = value.toInt();
                    });
                  },
                ),
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
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final Paint progressPaint = Paint()
      ..color = const Color.fromARGB(255, 36, 109, 143)
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
