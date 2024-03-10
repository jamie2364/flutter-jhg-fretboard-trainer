import 'package:flutter/cupertino.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:flutter_sizer/flutter_sizer.dart';


class ButtonDecorations {
  static BoxDecoration returnButton() {
    return BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(10.dp)),
        color: JHGColors.charcolGray,
        shape: BoxShape.rectangle,
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xffFE5D43),
            Color(0xffFE5D43),
          ],
        ));
  }

   static BoxDecoration loadButton() {
    return BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(10.dp)),
        color: JHGColors.charcolGray,
        shape: BoxShape.rectangle,
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            JHGColors.charcolGray,
            JHGColors.charcolGray,
          ],
        ));
  }

}
