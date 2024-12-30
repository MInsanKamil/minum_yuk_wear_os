import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../utils/calculation.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int totalMinum = 0;
  int targetHarian = 0;
  int ml = 0;
  String jenisKelamin = '';
  int umur = 0;
  List<Map<String, dynamic>> _drinkLogs = [];
  List<Map<String, dynamic>> _drinkLog = [];
  bool isManualTargetEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadTotalMinum();
  }

  Future<void> _loadPreferences() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        targetHarian = prefs.getInt('targetHarian') ?? targetHarian;
        jenisKelamin = prefs.getString('jenisKelamin') ?? jenisKelamin;
        umur = prefs.getInt('umur') ?? umur;
        isManualTargetEnabled =
            prefs.getBool('isManual') ?? isManualTargetEnabled;
      });
    } catch (e) {
      // Opsional: Menampilkan pesan error kepada pengguna
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Gagal memuat preferensi"),
            backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _loadTotalMinum() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? drinkLog = prefs.getStringList('drinkLog');
    setState(() {
      _drinkLogs = drinkLog!
          .map((log) => jsonDecode(log) as Map<String, dynamic>)
          .toList();

// Update _ml dengan jumlah total minuman dalam semua log
      totalMinum =
          _drinkLogs.fold(0, (sum, log) => sum + (log['volume'] as int));

      _drinkLog = drinkLog
          .map((log) => jsonDecode(log) as Map<String, dynamic>)
          .where((log) {
        DateTime logDate = DateTime.parse(log['time']);
        return logDate.year == DateTime.now().year &&
            logDate.month == DateTime.now().month &&
            logDate.day == DateTime.now().day;
      }).toList();

      // Update _ml dengan jumlah total minuman pada hari tersebut
      ml = _drinkLog.isNotEmpty ? _drinkLog.last['ml'] ?? 0 : 0;
    });
  }

  Future<void> _savePreferences() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('targetHarian', targetHarian);
      await prefs.setString('jenisKelamin', jenisKelamin);
      await prefs.setInt('umur', umur);
      await prefs.setBool('isManual', isManualTargetEnabled);
    } catch (e) {
      // Opsional: Menampilkan pesan error kepada pengguna
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Gagal menyimpan preferensi"),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    if (!isManualTargetEnabled) {
      setState(() {
        targetHarian = calculateTargetHarian(umur, jenisKelamin);
      });
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 36, 109, 143),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(screenHeight * 0.25), // Tinggi AppBar
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(120),
            // Radius untuk bagian bawah AppBar
          ),
          child: AppBar(
            title: Center(
              child: Padding(
                padding: EdgeInsets.only(top: screenHeight * 0.1),
                child: Text(
                  'Profil',
                  style: TextStyle(
                    fontSize: screenWidth * 0.07,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            backgroundColor: const Color.fromARGB(255, 27, 87, 116),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
              right: screenWidth * 0.05, left: screenWidth * 0.05),
          child: Column(
            children: [
              // Title Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'Atur Manual',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: screenHeight * 0.05,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Target Minum Harian',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: screenHeight * 0.05,
                            fontWeight: FontWeight
                                .bold), // Font size relative to screen height
                      ),
                    ],
                  ),
                  Transform.scale(
                    scale: screenWidth *
                        0.15 /
                        60, // Adjust the scale factor (60 is the default size of the switch)
                    child: Switch(
                      value: isManualTargetEnabled,
                      onChanged: (value) {
                        setState(() async {
                          isManualTargetEnabled = value;
                          if (!isManualTargetEnabled) {
                            targetHarian =
                                calculateTargetHarian(umur, jenisKelamin);
                          }
                          await _savePreferences();
                          await _loadPreferences();
                        });
                      },
                      activeColor: Colors.white,
                      activeTrackColor: Colors.blue[500],
                      inactiveThumbColor: Colors.blue[300],
                      inactiveTrackColor: Colors.white,
                      trackOutlineColor: MaterialStateProperty.all(Colors.blue),
                    ),
                  )
                ],
              ),

              // Pengaturan lainnya
              Column(
                children: [
                  _buildSettingTile(
                    Icons.water_drop,
                    'Target harian',
                    screenWidth,
                    screenHeight,
                    subtitle: '$targetHarian ml',
                    onTap: isManualTargetEnabled
                        ? () => _showTargetHarianSliderModal(
                              context,
                              targetHarian,
                              (value) {
                                setState(() {
                                  targetHarian = value;
                                });
                              },
                              screenHeight,
                              screenWidth,
                            )
                        : () {}, // Fungsi kosong jika pengaturan manual tidak diaktifkan
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  _buildSettingTile(
                    Icons.person,
                    'Jenis kelamin',
                    screenWidth,
                    screenHeight,
                    subtitle: '$jenisKelamin',
                    onTap: () => _showGenderSelectionModal(
                        context, jenisKelamin, (value) {
                      setState(() {
                        jenisKelamin = value;
                        targetHarian = calculateTargetHarian(umur, value);
                      });
                    }, screenHeight, screenWidth),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  _buildSettingTile(
                    Icons.calendar_today,
                    'Umur',
                    screenWidth,
                    screenHeight,
                    subtitle: '$umur tahun',
                    onTap: () => _showAgeSliderModal(
                      context,
                      umur,
                      (value) {
                        setState(() {
                          umur = value;
                          targetHarian =
                              calculateTargetHarian(value, jenisKelamin);
                        });
                      },
                      screenHeight,
                      screenWidth,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.3),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile(
      IconData icon, String title, double screenWidth, double screenHeight,
      {String? subtitle, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title,
          style: TextStyle(color: Colors.white, fontSize: screenHeight * 0.06)),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: TextStyle(
                  color: Colors.white70, fontSize: screenHeight * 0.05))
          : null,
      trailing: title == 'Target harian' && !isManualTargetEnabled
          ? null // Trailing hilang jika Target harian dan isManualTargetEnabled == false
          : Icon(Icons.arrow_forward_ios,
              color: Colors
                  .white), // Menampilkan trailing yang diberikan kecuali untuk Target harian
      contentPadding:
          EdgeInsets.only(left: screenWidth * 0.05, right: screenWidth * 0.05),
      tileColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(35.0),
        side: BorderSide(
          color: Colors.white,
          width: 2.0,
        ),
      ),
      onTap: onTap,
      minTileHeight: screenHeight * 0.08,
    );
  }

  void _showGenderSelectionModal(
    BuildContext context,
    String currentValue,
    Function(String) onUpdate,
    double screenHeight,
    double screenWidth,
  ) {
    final List<String> genderOptions = ['Laki-laki', 'Perempuan'];
    String selectedValue = currentValue;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.blueGrey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(150), // Responsif dengan tinggi layar
        ),
      ),
      builder: (BuildContext context) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.only(top: screenHeight * 0.06),
                child: Text(
                  'Pilih Jenis Kelamin',
                  style: TextStyle(
                    fontSize: screenHeight * 0.05,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  left: screenWidth * 0.15,
                  right: screenWidth * 0.15,
                ),
                child: Column(
                  children: genderOptions.map((String value) {
                    return RadioListTile<String>(
                      dense: true,
                      title: Text(
                        value,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenHeight * 0.05,
                        ),
                      ),
                      value: value,
                      groupValue: selectedValue,
                      activeColor: Colors.blue[300],
                      onChanged: (String? newValue) async {
                        if (newValue != null) {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (BuildContext context) {
                              return Dialog(
                                child: Padding(
                                  padding: EdgeInsets.all(screenHeight * 0.02),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(width: screenWidth * 0.05),
                                      Text(
                                        "Menyimpan...",
                                        style: TextStyle(
                                          fontSize: screenHeight * 0.02,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                          setState(() {
                            selectedValue = newValue;
                            onUpdate(newValue); // Update the selected value
                          });

                          await _savePreferences();
                          await _loadPreferences();
                          Navigator.of(context).pop(); // Close the dialog
                          Navigator.of(context).pop(); // Close the modal
                        }
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTargetHarianSliderModal(
    BuildContext context,
    int currentValue,
    Function(int) onUpdate,
    double screenHeight,
    double screenWidth,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.blueGrey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(150),
        ),
      ),
      builder: (BuildContext context) {
        int selectedValue = currentValue;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: screenHeight * 0.06),
                  child: Text(
                    'Atur Target Harian',
                    style: TextStyle(
                      fontSize: screenHeight * 0.05,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                  child: Slider(
                    value: selectedValue.toDouble(),
                    min: 0,
                    max: 5000,
                    divisions: 100,
                    label: '$selectedValue ml',
                    onChanged: (value) {
                      setModalState(() {
                        selectedValue = value.toInt();
                      });
                    },
                    thumbColor: const Color.fromARGB(255, 27, 87, 116),
                    activeColor: const Color.fromARGB(255, 27, 87, 116),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return Dialog(
                          child: Padding(
                            padding: EdgeInsets.all(screenHeight * 0.02),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(width: screenWidth * 0.05),
                                Text(
                                  "Menyimpan...",
                                  style: TextStyle(
                                    fontSize: screenHeight * 0.02,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );

                    onUpdate(selectedValue);
                    await _savePreferences();
                    await _loadPreferences();
                    Navigator.of(context).pop(); // Close the dialog
                    Navigator.of(context).pop(); // Close the modal
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: screenHeight * 0.01,
                      horizontal: screenWidth * 0.02,
                    ),
                    backgroundColor: const Color.fromARGB(255, 27, 87, 116),
                  ),
                  child: Text(
                    'Simpan',
                    style: TextStyle(
                      fontSize: screenHeight * 0.05,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAgeSliderModal(
    BuildContext context,
    int currentValue,
    Function(int) onUpdate,
    double screenHeight,
    double screenWidth,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.blueGrey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(150),
        ),
      ),
      builder: (BuildContext context) {
        int selectedValue = currentValue;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: screenHeight * 0.06),
                  child: Text(
                    'Atur Umur',
                    style: TextStyle(
                      fontSize: screenHeight * 0.05,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                  child: Slider(
                    value: selectedValue.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 99,
                    label: '$selectedValue tahun',
                    onChanged: (value) {
                      setModalState(() {
                        selectedValue = value.toInt();
                      });
                    },
                    thumbColor: const Color.fromARGB(255, 27, 87, 116),
                    activeColor: const Color.fromARGB(255, 27, 87, 116),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return Dialog(
                          child: Padding(
                            padding: EdgeInsets.all(screenHeight * 0.02),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(width: screenWidth * 0.05),
                                Text(
                                  "Menyimpan...",
                                  style: TextStyle(
                                    fontSize: screenHeight * 0.02,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );

                    onUpdate(selectedValue);
                    await _savePreferences();
                    await _loadPreferences();
                    Navigator.of(context).pop(); // Close the dialog
                    Navigator.of(context).pop(); // Close the modal
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: screenHeight * 0.01, // Padding atas dan bawah
                      horizontal: screenWidth * 0.02, // Padding kiri dan kanan
                    ),
                    backgroundColor: const Color.fromARGB(255, 27, 87, 116),
                  ),
                  child: Text(
                    'Simpan',
                    style: TextStyle(
                        fontSize: screenHeight * 0.05, color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
