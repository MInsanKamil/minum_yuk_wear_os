import 'package:flutter/material.dart';

class IntakeRecord extends StatelessWidget {
  final String intake;
  final String time;
  final double screenHeight;
  final double screenWidth;

  IntakeRecord({
    required this.intake,
    required this.time,
    required this.screenHeight,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.02),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 36, 109, 143),
        borderRadius: BorderRadius.circular(screenWidth * 0.02),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            intake,
            style: TextStyle(
              fontSize: screenHeight * 0.04,
              color: Colors.white,
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: screenHeight * 0.04,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
