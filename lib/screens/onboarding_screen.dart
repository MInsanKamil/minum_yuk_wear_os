import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app.dart';
import '../utils/calculation.dart';

class OnboardingScreenManager extends StatefulWidget {
  @override
  _OnboardingScreenManagerState createState() =>
      _OnboardingScreenManagerState();
}

class _OnboardingScreenManagerState extends State<OnboardingScreenManager> {
  String? jenisKelamin;
  int? umur;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPreferences();
  }

  Future<void> _checkPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      jenisKelamin = prefs.getString('jenisKelamin');
      umur = prefs.getInt('umur');
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.lightBlueAccent,
      );
    }

    if (jenisKelamin != null || umur != null) {
      return MainNavigation();
    } else {
      return GenderAndAgeOnboardingScreen(
        onComplete: _saveUserData,
        screenHeight: screenHeight,
        screenWidth: screenWidth,
      );
    }
  }

  Future<void> _saveUserData(String gender, int age) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('jenisKelamin', gender);
    await prefs.setInt('umur', age);
    await prefs.setInt('targetHarian', calculateTargetHarian(age, gender));
  }
}

class GenderAndAgeOnboardingScreen extends StatefulWidget {
  final Function(String, int) onComplete;
  final double screenHeight;
  final double screenWidth;

  GenderAndAgeOnboardingScreen({
    required this.onComplete,
    required this.screenHeight,
    required this.screenWidth,
  });

  @override
  _GenderAndAgeOnboardingScreenState createState() =>
      _GenderAndAgeOnboardingScreenState();
}

class _GenderAndAgeOnboardingScreenState
    extends State<GenderAndAgeOnboardingScreen> {
  String? selectedGender;
  int? selectedAge;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlueAccent,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Center(
                child: Padding(
                  padding:
                      const EdgeInsets.only(top: 50, left: 16.0, right: 16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSettingTile(
                        Icons.person,
                        'Jenis kelamin',
                        widget.screenWidth,
                        widget.screenHeight,
                        subtitle: selectedGender ?? 'Pilih jenis kelamin',
                        onTap: () => _showGenderSelectionModal(
                          context,
                          selectedGender ?? '',
                          (value) {
                            setState(() {
                              selectedGender = value;
                            });
                          },
                          widget.screenHeight,
                          widget.screenWidth,
                        ),
                      ),
                      SizedBox(height: 10),
                      _buildSettingTile(
                        Icons.calendar_today,
                        'Umur',
                        widget.screenWidth,
                        widget.screenHeight,
                        subtitle: selectedAge != null
                            ? '${selectedAge!} tahun'
                            : 'Masukkan umur',
                        onTap: () => _showAgeSliderModal(
                          context,
                          selectedAge ?? 0,
                          (value) {
                            setState(() {
                              selectedAge = value;
                            });
                          },
                          widget.screenHeight,
                          widget.screenWidth,
                        ),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[500],
                        ),
                        onPressed: () {
                          if (selectedGender != null && selectedAge != null) {
                            widget.onComplete(selectedGender!, selectedAge!);
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MainNavigation(),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Pilih semua data!'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        child: Text(
                          'Lanjut',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    IconData icon,
    String title,
    double screenWidth,
    double screenHeight, {
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: TextStyle(color: Colors.white, fontSize: screenHeight * 0.05),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                  color: Colors.white70, fontSize: screenHeight * 0.045),
            )
          : null,
      trailing: Icon(Icons.arrow_forward_ios, color: Colors.white),
      contentPadding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
      ),
      tileColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(35.0),
        side: BorderSide(color: Colors.white, width: 2.0),
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
          top: Radius.circular(150),
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
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.15),
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
                            onUpdate(newValue);
                          });
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
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

  void _showAgeSliderModal(
    BuildContext context,
    int currentValue,
    Function(int) onUpdate,
    double screenHeight,
    double screenWidth,
  ) {
    int tempAge = currentValue;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.blueGrey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(150), // Responsif dengan tinggi layar
        ),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: screenHeight * 0.06),
                  child: Text(
                    'Pilih Umur',
                    style: TextStyle(
                      fontSize: screenHeight * 0.05,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.1,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                  child: Slider(
                    value: tempAge.toDouble(),
                    min: 0,
                    max: 100,
                    label: '${tempAge.toString()} tahun',
                    divisions: 99,
                    onChanged: (double value) {
                      setModalState(() {
                        tempAge = value.round();
                      });
                    },
                    thumbColor: const Color.fromARGB(255, 27, 87, 116),
                    activeColor: const Color.fromARGB(255, 27, 87, 116),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: screenHeight * 0.01, // Padding atas dan bawah
                      horizontal: screenWidth * 0.02, // Padding kiri dan kanan
                    ),
                    backgroundColor: const Color.fromARGB(255, 27, 87, 116),
                  ),
                  onPressed: () {
                    onUpdate(tempAge);
                    Navigator.of(context).pop();
                  },
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
