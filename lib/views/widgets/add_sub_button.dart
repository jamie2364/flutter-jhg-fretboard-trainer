import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:flutter_sizer/flutter_sizer.dart';

class AddAndSubtractButton extends StatelessWidget {
  const AddAndSubtractButton(
      {super.key, required this.onTap, required this.isAdd});

  final VoidCallback onTap;
  final bool isAdd;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: (onTap),
      child: Container(
        height: height * 0.030,
        width: height * 0.030,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: JHGColors.primary,
        ),
        child: Center(
            child: isAdd == true
                ? Icon(
                    LucideIcons.plus300,
                    color: JHGColors.white,
                    size: height * 0.025,
                  )
                : Icon(
                    LucideIcons.minus300,
                    color: JHGColors.white,
                    size: height * 0.025,
                  )),
      ),
    );
  }
}

class WebAddAndSubtractButton extends StatelessWidget {
  const WebAddAndSubtractButton(
      {super.key, required this.onTap, required this.isAdd});

  final VoidCallback onTap;
  final bool isAdd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (onTap),
      child: Container(
        height: 2.5.w,
        width: 2.5.w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: JHGColors.primary,
        ),
        child: Center(
            child: isAdd == true
                ? Icon(
                    LucideIcons.plus300,
                    color: JHGColors.white,
                    size: 2.w,
                  )
                : Icon(
                    LucideIcons.plus300,
                    color: JHGColors.white,
                    size: 2.w,
                  )),
      ),
    );
  }
}
