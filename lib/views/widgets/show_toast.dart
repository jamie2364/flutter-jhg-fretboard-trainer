import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:flutter_sizer/flutter_sizer.dart';

showCustomToast(
    {required BuildContext context,
    required String message,
    bool isError = true}) {
  ScaffoldMessenger.of(context).removeCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    width: kIsWeb
        ? MediaQuery.of(context).size.width * .65
        : MediaQuery.of(context).size.width * .90,
    content: Text(
      message,
      textAlign: TextAlign.center,
      style: JHGTextStyles.lrlabelStyle.copyWith(fontSize: 16),
    ),
    backgroundColor: isError ? JHGColors.primary : JHGColors.green,
    padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.02,
        vertical: MediaQuery.of(context).size.height * 0.02),
    elevation: 10,
    duration: const Duration(seconds: 3),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.dp)),
  ));
}
