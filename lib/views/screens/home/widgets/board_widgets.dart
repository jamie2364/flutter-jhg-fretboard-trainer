import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fretboard/controllers/home_controller.dart';

Widget buildStringCharWeb(String text1, int i, HomeController controller) {
  return Row(
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 0.0, right: 0),
        child: SizedBox(
          height: controller.isPortrait == true ? 42 : 20,
          width: controller.isPortrait == true ? 42 : 20,
          child: Center(
            child: Text(
              text1,
              style: const TextStyle(color: Colors.red, fontSize: 20),
            ),
          ),
        ),
      ),
    ],
  );
}

Widget buildStringChar(String text1, int i) {
  return Row(
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 0.0, right: 10.0),
        child: SizedBox(
          height: 23,
          width: 23,
          child: Center(
            child: Text(
              text1,
              style: const TextStyle(color: Colors.red, fontSize: 20),
            ),
          ),
        ),
      ),
    ],
  );
}
