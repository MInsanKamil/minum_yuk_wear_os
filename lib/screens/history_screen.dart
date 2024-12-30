import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Add this to your pubspec.yaml
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert'; // To decode JSON strings
import '../widgets/intake_record_box_widget.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedTab = 'HARI'; // Track selected tab
  DateTime _currentDate =
      DateTime.now().add(Duration(minutes: 5)); // Track selected day
  DateTime _today = DateTime.now(); // To compare with today's date
  List<Map<String, dynamic>> _drinkLogs = [];
  int _ml = 0;
  int maxY = 4000;
  int targetHarian = 0;

  @override
  void initState() {
    super.initState();
    _loadDrinkLog();
    _loadTargetHarian(); // Load logs when the screen is initialized
  }

  void _loadTargetHarian() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      targetHarian = prefs.getInt('targetHarian') ?? targetHarian;
    });
  }

  void _loadDrinkLog() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? drinkLog = prefs.getStringList('drinkLog');

    setState(() {
      // Cek apakah tab "MINGGU" dipilih
      if (_selectedTab == "MINGGU") {
        DateTime startOfWeek =
            _currentDate.subtract(Duration(days: _currentDate.weekday - 1));
        DateTime endOfWeek = startOfWeek.add(Duration(days: 6));

        // Filter drink logs untuk minggu yang sedang ditampilkan
        _drinkLogs = drinkLog!
            .map((log) => jsonDecode(log) as Map<String, dynamic>)
            .where((log) {
          DateTime logDate = DateTime.parse(log['time']).toLocal();

          // Mengatur jam, menit, detik ke nol untuk hanya mempertimbangkan tanggal
          DateTime logDateOnly =
              DateTime(logDate.year, logDate.month, logDate.day);
          DateTime startOfWeekOnly =
              DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
          DateTime endOfWeekOnly =
              DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day);

          return logDateOnly
                  .isAfter(startOfWeekOnly.subtract(Duration(days: 1))) &&
              logDateOnly.isBefore(endOfWeekOnly.add(Duration(days: 1)));
        }).toList();

        // Update _ml dengan nilai terbesar dari log['ml'] pada minggu tersebut
        _ml = _drinkLogs.fold(0, (sum, log) => sum + (log['volume'] as int));
        maxY = _drinkLogs.isNotEmpty
            ? _drinkLogs
                .map((log) => log['ml'] as int)
                .reduce((a, b) => a > b ? a : b)
            : 0;
      } else if (_selectedTab == "BULAN") {
        // Jika tab "BULAN" dipilih
        DateTime startOfMonth =
            DateTime(_currentDate.year, _currentDate.month, 1);
        DateTime endOfMonth =
            DateTime(_currentDate.year, _currentDate.month + 1, 1)
                .subtract(Duration(days: 1));

        // Filter drink logs untuk bulan yang sedang ditampilkan
        _drinkLogs = drinkLog!
            .map((log) => jsonDecode(log) as Map<String, dynamic>)
            .where((log) {
          DateTime logDate = DateTime.parse(log['time']).toLocal();

          // Mengatur jam, menit, detik ke nol untuk hanya mempertimbangkan tanggal
          DateTime logDateOnly =
              DateTime(logDate.year, logDate.month, logDate.day);
          DateTime startOfMonthOnly =
              DateTime(startOfMonth.year, startOfMonth.month, startOfMonth.day);
          DateTime endOfMonthOnly =
              DateTime(endOfMonth.year, endOfMonth.month, endOfMonth.day);

          return logDateOnly
                  .isAfter(startOfMonthOnly.subtract(Duration(days: 1))) &&
              logDateOnly.isBefore(endOfMonthOnly.add(Duration(days: 1)));
        }).toList();

        // Akumulasi nilai log['ml'] per minggu selama bulan tersebut
        Map<int, int> weeklyMl = {}; // Ganti dengan minggu numerik (1, 2, 3, 4)
        for (var log in _drinkLogs) {
          DateTime logDate = DateTime.parse(log['time']).toLocal();
          int weekOfMonth = ((logDate.day - 1) / 7).floor() + 1;

          // Jika minggu ke-5, gabungkan dengan minggu ke-4
          if (weekOfMonth > 4) {
            weekOfMonth = 4;
          }

          // Menambahkan volume ml per minggu
          weeklyMl[weekOfMonth] =
              (weeklyMl[weekOfMonth] ?? 0) + (log['volume'] as int);
        }
        _ml = _drinkLogs.fold(0, (sum, log) => sum + (log['volume'] as int));

        // Update _ml dengan akumulasi nilai log['ml'] terbesar per minggu dalam bulan tersebut
        maxY = weeklyMl.isNotEmpty
            ? weeklyMl.values.reduce((a, b) => a > b ? a : b)
            : 0;
      } else {
        // Jika tab bukan "MINGGU" atau "BULAN", gunakan filter per hari seperti sebelumnya
        _drinkLogs = drinkLog!
            .map((log) => jsonDecode(log) as Map<String, dynamic>)
            .where((log) {
          DateTime logDate = DateTime.parse(log['time']);
          return logDate.year == _currentDate.year &&
              logDate.month == _currentDate.month &&
              logDate.day == _currentDate.day;
        }).toList();

        // Update _ml dengan jumlah total minuman pada hari tersebut
        maxY = _drinkLogs.isNotEmpty ? _drinkLogs.last['ml'] ?? 0 : 0;
        _ml = _drinkLogs.isNotEmpty ? _drinkLogs.last['ml'] ?? 0 : 0;
      }
    });
  }

  void _onTabSelected(String tab) {
    setState(() {
      _selectedTab = tab;
      _currentDate = DateTime.now().add(Duration(minutes: 5));
      _loadDrinkLog();
    });
  }

  void _nextDay() {
    setState(() {
      if (_selectedTab == "MINGGU") {
        // Pindah langsung ke hari Senin minggu berikutnya
        DateTime startOfWeek = _currentDate
            .subtract(Duration(days: _currentDate.weekday - 1)); // Senin
        _currentDate = startOfWeek
            .add(Duration(days: 7)); // Pindah ke Senin minggu berikutnya
      } else if (_selectedTab == "BULAN") {
        // Pindah ke bulan berikutnya
        _currentDate = DateTime(
          _currentDate.year,
          _currentDate.month + 1,
          1,
        ); // Pindah ke tanggal 1 bulan berikutnya
      } else {
        // Pindah ke hari berikutnya jika tidak melewati hari ini
        if (_currentDate.isBefore(_today)) {
          _currentDate = _currentDate.add(Duration(days: 1));
        }
      }
      _loadDrinkLog();
    });
  }

  void _previousDay() {
    setState(() {
      if (_selectedTab == "MINGGU") {
        // Pindah langsung ke hari Senin minggu sebelumnya
        DateTime startOfWeek = _currentDate
            .subtract(Duration(days: _currentDate.weekday - 1)); // Senin
        _currentDate = startOfWeek.subtract(Duration(days: 7));
      } else if (_selectedTab == "BULAN") {
        // Pindah ke bulan sebelumnya
        _currentDate = DateTime(
          _currentDate.year,
          _currentDate.month - 1,
          1,
        ); // Pindah ke tanggal 1 bulan sebelumnya
      } else {
        // Pindah ke hari sebelumnya tanpa batas
        _currentDate = _currentDate.subtract(Duration(days: 1));
      }
      _loadDrinkLog();
    });
  }

  String _getDisplayDate() {
    if (_selectedTab == "MINGGU") {
      DateTime startOfWeek = _currentDate
          .subtract(Duration(days: _currentDate.weekday - 1)); // Senin
      DateTime endOfWeek = startOfWeek.add(Duration(days: 6)); // Minggu
      return "${startOfWeek.day}-${startOfWeek.month} s.d ${endOfWeek.day}-${endOfWeek.month}"; // Format: dd-mm s.d dd-mm
    } else if (_selectedTab == "BULAN") {
      // Format untuk tab "BULAN"
      return "${_currentDate.month}-${_currentDate.year}"; // Format: mm-yyyy
    }

    // Show "Hari Ini" if it's today's date
    if (_currentDate.year == _today.year &&
        _currentDate.month == _today.month &&
        _currentDate.day == _today.day) {
      return "Hari Ini";
    } else {
      return "${_currentDate.day}-${_currentDate.month}-${_currentDate.year}"; // Format: dd-mm-yyyy
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mengambil tinggi dan lebar layar
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 36, 109, 143),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70), // Sesuaikan tinggi AppBar
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(120), // Radius untuk bagian bawah AppBar
          ),
          child: AppBar(
            backgroundColor: const Color.fromARGB(255, 27, 87, 116),
            toolbarHeight: 70,
            title: Padding(
              padding: EdgeInsets.only(
                top: 50.0,
                bottom: 15.0, // Sesuaikan nilai top padding sesuai kebutuhan
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTabButton('HARI', screenWidth),
                      _buildTabButton('MINGGU', screenWidth),
                      _buildTabButton('BULAN', screenWidth),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: _previousDay,
                  ),
                  Text(
                    _getDisplayDate(),
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.arrow_forward,
                      color: _currentDate.isBefore(_today)
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                    ),
                    onPressed: _currentDate.isBefore(_today) ? _nextDay : null,
                  ),
                ],
              ),
              Column(
                children: [
                  // Graph Section
                  Container(
                    padding: EdgeInsets.only(
                      right: screenWidth * 0.15,
                      left: screenWidth * 0.15,
                      bottom: screenHeight * 0.05,
                    ),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 36, 109, 143),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: screenHeight * 0.41,
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: 1000,
                                getDrawingHorizontalLine: (value) {
                                  return FlLine(
                                    color: Colors.white54,
                                    strokeWidth: 1,
                                  );
                                },
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: false,
                                  ),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: false,
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  axisNameWidget: Text(
                                    '          Volume Air (ml)',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.04,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  sideTitles: SideTitles(
                                    reservedSize: screenWidth * 0.15,
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        '    ' + value.toInt().toString(),
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: screenWidth * 0.04),
                                      );
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  axisNameWidget: Text(
                                    _selectedTab == "MINGGU"
                                        ? 'Waktu (Hari)'
                                        : _selectedTab == "BULAN"
                                            ? 'Waktu (Minggu)'
                                            : 'Waktu (Jam)',
                                    style: TextStyle(
                                        fontSize: screenWidth * 0.04,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  sideTitles: SideTitles(
                                    reservedSize: screenWidth * 0.08,
                                    showTitles: true,
                                    interval: _selectedTab == "MINGGU"
                                        ? 1
                                        : (_selectedTab == "BULAN" ? 1 : 4),
                                    getTitlesWidget: (value, meta) {
                                      if (_selectedTab == "MINGGU") {
                                        const days = [
                                          'Sn',
                                          'Sl',
                                          'Rb',
                                          'Km',
                                          'Jm',
                                          'Sb',
                                          'Mn'
                                        ];
                                        int index = value.toInt() - 1;
                                        if (index >= 0 && index < 7) {
                                          return Text(
                                            days[index],
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: screenWidth * 0.035),
                                          );
                                        }
                                        return const SizedBox();
                                      } else if (_selectedTab == "BULAN") {
                                        if (value >= 1 && value <= 4) {
                                          return Text(
                                            value.toInt().toString(),
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: screenWidth * 0.04),
                                          );
                                        }
                                        return const SizedBox();
                                      } else {
                                        return Text(
                                          value.toInt().toString(),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: screenWidth * 0.04,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: _selectedTab == "MINGGU"
                                      ? _getWeeklySpots()
                                      : _selectedTab == "BULAN"
                                          ? _getMonthlySpots()
                                          : _drinkLogs.map((log) {
                                              DateTime logDate =
                                                  DateTime.parse(log['time']);
                                              double hour =
                                                  logDate.hour.toDouble();
                                              double minute =
                                                  logDate.minute.toDouble() /
                                                      60;
                                              return FlSpot(hour + minute,
                                                  log['ml'].toDouble());
                                            }).toList(),
                                  isCurved: true,
                                  color: Colors.white,
                                  barWidth: 3,
                                  belowBarData: BarAreaData(
                                    show: true,
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withOpacity(0.5),
                                        Colors.blue.withOpacity(0.3),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                              ],
                              minX: 0,
                              maxX: _selectedTab == "MINGGU"
                                  ? 7
                                  : _selectedTab == "BULAN"
                                      ? 4
                                      : 24,
                              maxY: max(
                                  4000,
                                  max(targetHarian.toDouble(),
                                      maxY.toDouble())),
                              minY: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.05),

                  // Water intake history (Catatan) section
                  Container(
                    height: screenHeight * 0.5,
                    margin: EdgeInsets.only(
                      right: screenWidth * 0.15,
                      left: screenWidth * 0.15,
                    ),
                    padding: EdgeInsets.only(
                      top: screenHeight * 0.05,
                      left: screenWidth * 0.05,
                      right: screenWidth * 0.05,
                      bottom: screenHeight * 0.05,
                    ),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 36, 109, 143),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Catatan',
                              style: TextStyle(
                                fontSize: screenWidth * 0.05,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Total',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.05,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '$_ml ml',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.045,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Expanded(
                          child: Scrollbar(
                            thumbVisibility: true,
                            radius: Radius.circular(10),
                            scrollbarOrientation: ScrollbarOrientation.right,
                            child: SingleChildScrollView(
                              padding:
                                  EdgeInsets.only(right: screenWidth * 0.03),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _drinkLogs.isNotEmpty
                                    ? (_selectedTab == "MINGGU"
                                        ? _getUniqueDailyLogs(_drinkLogs)
                                            .map((log) {
                                            DateTime logDate =
                                                DateTime.parse(log['time']);
                                            const days = [
                                              'Senin',
                                              'Selasa',
                                              'Rabu',
                                              'Kamis',
                                              'Jumat',
                                              'Sabtu',
                                              'Minggu'
                                            ];
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 10.0),
                                              child: IntakeRecord(
                                                intake: '${log['ml']} ml',
                                                time: days[logDate.weekday - 1],
                                                screenHeight: screenHeight,
                                                screenWidth: screenWidth,
                                              ),
                                            );
                                          }).toList()
                                        : _selectedTab == "BULAN"
                                            ? _getWeeklyIntake().map((weekLog) {
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 10.0),
                                                  child: IntakeRecord(
                                                    intake:
                                                        '${weekLog['totalMl'].round()} ml',
                                                    time:
                                                        'Minggu ${weekLog['week']}',
                                                    screenHeight: screenHeight,
                                                    screenWidth: screenWidth,
                                                  ),
                                                );
                                              }).toList()
                                            : _drinkLogs.map((log) {
                                                DateTime logDate =
                                                    DateTime.parse(log['time']);
                                                String formattedTime =
                                                    DateFormat('HH:mm')
                                                        .format(logDate);
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 10.0),
                                                  child: IntakeRecord(
                                                    intake:
                                                        '${log['volume']} ml',
                                                    time: formattedTime,
                                                    screenHeight: screenHeight,
                                                    screenWidth: screenWidth,
                                                  ),
                                                );
                                              }).toList())
                                    : [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              right: 21.0),
                                          child: Text(
                                            'Belum ada catatan minum untuk periode ini.',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: screenWidth * 0.05,
                                            ),
                                          ),
                                        ),
                                      ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.15),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Fungsi untuk mendapatkan spot mingguan
  List<FlSpot> _getWeeklySpots() {
    Map<int, double> weeklyData = {};

    // Mengelompokkan data berdasarkan hari
    for (var log in _drinkLogs) {
      DateTime logDate = DateTime.parse(log['time']);
      int weekday = logDate.weekday; // 1 = Senin, 7 = Minggu

      // Menjumlahkan volume air untuk setiap hari
      if (weeklyData.containsKey(weekday)) {
        weeklyData[weekday] =
            (weeklyData[weekday] ?? 0) + log['volume'].toDouble();
      } else {
        weeklyData[weekday] = log['volume'].toDouble();
      }
    }

    // Mengubah data ke dalam bentuk List<FlSpot>
    List<FlSpot> spots = weeklyData.entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();

    return spots;
  }

  List<FlSpot> _getMonthlySpots() {
    Map<int, double> monthlyData = {};

    // Mengelompokkan data berdasarkan minggu dalam bulan
    for (var log in _drinkLogs) {
      DateTime logDate = DateTime.parse(log['time']);

      // Menghitung minggu ke berapa dalam bulan ini
      int weekOfMonth = (logDate.day / 7).ceil();

      // Menjumlahkan volume air untuk setiap minggu
      if (monthlyData.containsKey(weekOfMonth)) {
        monthlyData[weekOfMonth] =
            (monthlyData[weekOfMonth] ?? 0) + log['volume'].toDouble();
      } else {
        monthlyData[weekOfMonth] = log['volume'].toDouble();
      }
    }

    // Jika ada data pada minggu ke-5, gabungkan ke minggu ke-4
    if (monthlyData.containsKey(5)) {
      monthlyData[4] = (monthlyData[4] ?? 0) + (monthlyData[5] ?? 0);
      monthlyData.remove(5);
    }

    // Mengubah data ke dalam bentuk List<FlSpot>
    List<FlSpot> spots = monthlyData.entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();

    return spots;
  }

  List<Map<String, dynamic>> _getWeeklyIntake() {
    Map<int, double> weeklyIntake = {};

    for (var log in _drinkLogs) {
      DateTime logDate = DateTime.parse(log['time']);

      // Menghitung minggu ke berapa dalam bulan ini
      int weekOfMonth = (logDate.day / 7).ceil();

      // Menjumlahkan volume air untuk setiap minggu
      if (weeklyIntake.containsKey(weekOfMonth)) {
        weeklyIntake[weekOfMonth] =
            (weeklyIntake[weekOfMonth] ?? 0) + log['volume'].toDouble();
      } else {
        weeklyIntake[weekOfMonth] = log['volume'].toDouble();
      }
    }

    if (weeklyIntake.containsKey(5)) {
      weeklyIntake[4] = (weeklyIntake[4] ?? 0) + (weeklyIntake[5] ?? 0);
      weeklyIntake.remove(5);
    }

    // Mengubah data ke dalam bentuk List<Map<String, dynamic>> untuk ditampilkan
    List<Map<String, dynamic>> result = [];
    for (var entry in weeklyIntake.entries) {
      result.add({
        'week': entry.key,
        'totalMl': entry.value,
      });
    }

    return result;
  }

  Widget _buildTabButton(String label, double screenWidth) {
    return TextButton(
      onPressed: () => _onTabSelected(label),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: _selectedTab == label
                  ? Colors.white
                  : Colors.white.withOpacity(0.7),
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_selectedTab == label)
            Container(
              height: 2,
              width: screenWidth * 0.1,
              color: Colors.white,
            ),
        ],
      ),
    );
  }
}

// Fungsi untuk mendapatkan catatan unik per hari
List<Map<String, dynamic>> _getUniqueDailyLogs(
    List<Map<String, dynamic>> logs) {
  Map<int, Map<String, dynamic>> uniqueLogs = {}; // Kunci adalah weekday

  for (var log in logs) {
    DateTime logDate = DateTime.parse(log['time']);
    int weekday = logDate.weekday;

    // Ambil catatan terakhir per hari
    if (!uniqueLogs.containsKey(weekday) ||
        DateTime.parse(uniqueLogs[weekday]!['time']).isBefore(logDate)) {
      uniqueLogs[weekday] = log;
    }
  }

  return uniqueLogs.values.toList();
}
