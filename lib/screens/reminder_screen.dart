import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import '../services/notification_service.dart';
import 'package:flutter_time_picker_spinner/flutter_time_picker_spinner.dart';

class ReminderSettingsScreen extends StatefulWidget {
  @override
  _ReminderSettingsScreenState createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  late int selangWaktu;
  String errorMessageSelangWaktu = '';
  String errorMessageWaktuTidur = '';
  bool isStopReminder = false;
  late TimeOfDay waktuTidur;
  late TimeOfDay waktuBangun;
  int targetHarian = 0;
  int ml = 0;

  @override
  void initState() {
    super.initState();
    selangWaktu = 30;
    waktuTidur = TimeOfDay(hour: 22, minute: 0);
    waktuBangun = TimeOfDay(hour: 6, minute: 0);
  }

  Widget _buildTimePicker(
      BuildContext context,
      String title,
      TimeOfDay initialTime,
      Function(TimeOfDay?) onPicked,
      double Width,
      double Height) {
    TimeOfDay? selectedTime;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(35),
      ),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(color: Colors.white, fontSize: Width * 0.06),
        ),
        trailing: Icon(
          Icons.edit,
          color: Colors.white,
        ),
        onTap: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.blueGrey[900],
            isScrollControlled: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(120),
              ),
            ),
            builder: (BuildContext context) {
              return Container(
                height: Height * 0.6,
                child: Column(
                  children: [
                    Expanded(
                      child: TimePickerSpinner(
                        normalTextStyle: TextStyle(
                            fontSize: Width * 0.05, color: Colors.grey),
                        highlightedTextStyle: TextStyle(
                            fontSize: Width * 0.08, color: Colors.white),
                        spacing: 5,
                        itemHeight: 30,
                        isForce2Digits: true,
                        onTimeChange: (time) {
                          selectedTime =
                              TimeOfDay(hour: time.hour, minute: time.minute);
                        },
                        alignment: Alignment.center,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 5.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: Height * 0.01,
                            horizontal: Width * 0.02,
                          ),
                          backgroundColor:
                              const Color.fromARGB(255, 27, 87, 116),
                        ),
                        child: Text(
                          'Simpan',
                          style: TextStyle(
                            fontSize: Height * 0.05,
                            color: Colors.white,
                          ),
                        ),
                        onPressed: () {
                          onPicked(selectedTime);
                          Navigator.pop(context); // Menutup pop-up
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('selang_waktu', selangWaktu);
    prefs.setBool('is_stop_reminder', isStopReminder);
    prefs.setString('waktu_tidur', waktuTidur.format(context));
    prefs.setString('waktu_bangun', waktuBangun.format(context));
  }

  void _scheduleWaterReminders() async {
    // Hapus semua notifikasi lama
    await NotificationHelper.cancelAllNotifications();

    try {
      // Hitung waktu mulai (waktu bangun) dan waktu akhir (waktu tidur)
      final currentDate = DateTime.now();
      var startTime = tz.TZDateTime.from(
        DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day,
          waktuBangun.hour,
          waktuBangun.minute,
        ),
        tz.local,
      );
      var endTime = tz.TZDateTime.from(
        DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day,
          waktuTidur.hour,
          waktuTidur.minute,
        ),
        tz.local,
      );

      // Jika waktu tidur melintasi tengah malam, tambahkan satu hari ke endTime
      if (endTime.isBefore(startTime)) {
        endTime = endTime.add(const Duration(days: 1));
      }

      // Periksa apakah waktu saat ini sudah melewati waktu tidur
      final tzNow = tz.TZDateTime.now(tz.local);
      if (tzNow.isAfter(endTime)) {
        Navigator.pop(context); // Tutup dialog
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(
        //     content: Text('Saat ini sudah melewati waktu tidur.'),
        //     backgroundColor: Colors.red,
        //   ),
        // );
        return;
      }

      // Jika sekarang sebelum waktu bangun, mulai dari waktu bangun
      tz.TZDateTime nextNotificationTime =
          tzNow.isBefore(startTime) ? startTime : tzNow;

      // Jadwalkan notifikasi pada selang waktu tertentu di rentang waktu bangun dan tidur
      int notificationCount = 0;
      while (nextNotificationTime.isBefore(endTime)) {
        nextNotificationTime = nextNotificationTime.add(
          Duration(minutes: selangWaktu),
        );

        // Jadwalkan notifikasi
        await NotificationHelper.scheduleNotification(
          'Waktunya Minum Air',
          'Jaga kesehatan Anda dengan minum air sekarang!',
          nextNotificationTime,
        );

        notificationCount++;

        // Batasi jumlah notifikasi untuk menghindari batas maksimum sistem
        if (notificationCount > 480) {
          throw Exception('Maximum limit of concurrent alarms');
        }
      }

      // Tutup dialog dan tampilkan pesan sukses
      Navigator.pop(context);
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(
      //     content: Text('Pengingat telah dijadwalkan.'),
      //     backgroundColor: Colors.green,
      //   ),
      // );
    } catch (e) {
      // Tangani kesalahan dan tutup dialog
      Navigator.pop(context);
      // if (e.toString().contains('Maximum limit of concurrent alarms')) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(
      //       content: Text(
      //           'Terlalu banyak notifikasi yang dijadwalkan. Mohon selang waktu jangan terlau pendek'),
      //       backgroundColor: Colors.red,
      //     ),
      //   );
      // } else {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //       content: Text('Terjadi kesalahan: $e'),
      //       backgroundColor: Colors.red,
      //     ),
      //   );
      // }
      await NotificationHelper.cancelAllNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 36, 109, 143),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(size.height * 0.25), // Tinggi AppBar
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(120),
            // Radius untuk bagian bawah AppBar
          ),
          child: AppBar(
            title: Center(
              child: Padding(
                padding: EdgeInsets.only(top: size.height * 0.1),
                child: Text(
                  'Pengingat',
                  style: TextStyle(
                    fontSize: size.width * 0.07,
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
      body: Padding(
        padding: EdgeInsets.only(
            top: size.height * 0.05,
            bottom: size.height * 0.05,
            left: size.width * 0.1,
            right: size.width * 0.1),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selang Waktu (menit)',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: size.width * 0.05,
                    fontWeight: FontWeight.bold),
              ),
              Container(
                margin: EdgeInsets.only(top: size.height * 0.01),
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.03),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(35),
                ),
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                          color: Colors.white, fontSize: size.width * 0.045),
                      hintText: 'Masukkan selang waktu (contoh: 30)',
                      prefixIconColor: Colors.white),
                  style: TextStyle(color: Colors.white),
                  onChanged: (value) {
                    setState(() {
                      selangWaktu = int.tryParse(value) ?? selangWaktu;
                      if (selangWaktu <= 0) {
                        errorMessageSelangWaktu =
                            'Selang waktu harus lebih besar dari 0';
                      } else {
                        errorMessageSelangWaktu = '';
                      }
                    });
                  },
                ),
              ),
              if (errorMessageSelangWaktu.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: size.height * 0.005),
                  child: Text(
                    errorMessageSelangWaktu,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              SizedBox(height: size.height * 0.02),
              Text(
                'Waktu Tidur',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: size.width * 0.05,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: size.height * 0.01),
              _buildTimePicker(
                  context, 'Dari: ${waktuTidur.format(context)}', waktuTidur,
                  (picked) {
                if (picked != null) {
                  setState(() {
                    waktuTidur = picked;
                    if (waktuTidur != waktuBangun) {
                      errorMessageWaktuTidur = '';
                    }
                  });
                }
              }, size.width, size.height),
              SizedBox(height: size.height * 0.02),
              _buildTimePicker(
                  context,
                  'Hingga: ${waktuBangun.format(context)}',
                  waktuBangun, (picked) {
                if (picked != null) {
                  setState(() {
                    waktuBangun = picked;
                    if (waktuTidur != waktuBangun) {
                      errorMessageWaktuTidur = '';
                    }
                  });
                }
              }, size.width, size.height),
              if (errorMessageWaktuTidur.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: size.height * 0.005),
                  child: Text(
                    errorMessageWaktuTidur,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              SizedBox(height: size.height * 0.02),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Hentikan ketika target tercapai',
                      style: TextStyle(
                        color: Colors.blue[500],
                        fontSize: size.width * 0.045,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Switch(
                    value: isStopReminder,
                    activeColor: Colors.blue[300],
                    activeTrackColor: Colors.blue[700],
                    inactiveThumbColor: Colors.blue[300],
                    inactiveTrackColor: Colors.white70,
                    onChanged: (value) {
                      setState(() {
                        isStopReminder = value;
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: size.height * 0.03),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[500],
                    padding: EdgeInsets.symmetric(
                      vertical: size.height * 0.02,
                      horizontal: size.width * 0.3,
                    ),
                  ),
                  onPressed: () async {
                    if (waktuBangun == waktuTidur) {
                      setState(() {
                        errorMessageWaktuTidur =
                            'Waktu tidur dan waktu bangun harus berbeda';
                      });
                      return;
                    }
                    _scheduleWaterReminders();
                    await _savePreferences();
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Simpan',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: size.width * 0.045,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
