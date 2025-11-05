import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:flutter_sizer/flutter_sizer.dart';

class CustomSwitch extends StatelessWidget {
  const CustomSwitch({super.key, required this.value, required this.onChange});

  final bool value;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return InkWell(
      onTap: onChange,
      child: Container(
        height: height * 0.036,
        width: width * 0.15,
        alignment: Alignment.center,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: value == true ? JHGColors.green : JHGColors.charcolGray,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Padding(
          padding: EdgeInsets.all(height * 0.0050),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: height * 0.028,
                width: height * 0.028,
                decoration: BoxDecoration(
                    color: value == true
                        ? Colors.transparent
                        : JHGColors.secondryBlack,
                    shape: BoxShape.circle),
              ),
              Container(
                height: height * 0.028,
                width: height * 0.028,
                decoration: BoxDecoration(
                    color: value == true
                        ? JHGColors.secondryBlack
                        : Colors.transparent,
                    shape: BoxShape.circle),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class WebCustomSwitch extends StatelessWidget {
  const WebCustomSwitch(
      {super.key, required this.value, required this.onChange});

  final bool value;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onChange,
      child: Container(
        height: 2.5.w,
        width: 4.2.w,
        alignment: Alignment.center,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: value == true ? JHGColors.green : JHGColors.charcolGray,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Padding(
          padding: EdgeInsets.all(0.2.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 1.9.w,
                width: 1.9.w,
                decoration: BoxDecoration(
                    color: value == true
                        ? Colors.transparent
                        : JHGColors.secondryBlack,
                    shape: BoxShape.circle),
              ),
              Container(
                height: 1.9.w,
                width: 1.9.w,
                decoration: BoxDecoration(
                    color: value == true
                        ? JHGColors.secondryBlack
                        : Colors.transparent,
                    shape: BoxShape.circle),
              )
            ],
          ),
        ),
      ),
    );
  }
}
