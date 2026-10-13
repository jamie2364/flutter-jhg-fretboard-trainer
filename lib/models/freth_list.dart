import 'package:fretboard/utils/app_strings.dart';

import 'board_model.dart';

List<BoardModel> fretList = [
  BoardModel(
      id: 0, string: 6, fret: 0, note: "E", fretSound: AppStrings.str6Fr0),
  BoardModel(
      id: 1, string: 5, fret: 0, note: "A", fretSound: AppStrings.str5Fr0),
  BoardModel(
      id: 2, string: 4, fret: 0, note: "D", fretSound: AppStrings.str4Fr0),
  BoardModel(
      id: 3, string: 3, fret: 0, note: "G", fretSound: AppStrings.str3Fr0),
  BoardModel(
      id: 4, string: 2, fret: 0, note: "B", fretSound: AppStrings.str2Fr0),
  BoardModel(
      id: 5, string: 1, fret: 0, note: "E", fretSound: AppStrings.str1Fr0),
  BoardModel(
      id: 6, string: 6, fret: 1, note: "F", fretSound: AppStrings.str6Fr1),
  BoardModel(
      id: 7, string: 5, fret: 1, note: "A#", fretSound: AppStrings.str5Fr1),
  BoardModel(
      id: 8, string: 4, fret: 1, note: "D#", fretSound: AppStrings.str4Fr1),
  BoardModel(
      id: 9, string: 3, fret: 1, note: "G#", fretSound: AppStrings.str3Fr1),
  BoardModel(
      id: 10, string: 2, fret: 1, note: "C", fretSound: AppStrings.str2Fr1),
  BoardModel(
      id: 11, string: 1, fret: 1, note: "F", fretSound: AppStrings.str1Fr1),
  BoardModel(
      id: 12, string: 6, fret: 2, note: "F#", fretSound: AppStrings.str6Fr2),
  BoardModel(
      id: 13, string: 5, fret: 2, note: "B", fretSound: AppStrings.str5Fr2),
  BoardModel(
      id: 14, string: 4, fret: 2, note: "E", fretSound: AppStrings.str4Fr2),
  BoardModel(
      id: 15, string: 3, fret: 2, note: "A", fretSound: AppStrings.str3Fr2),
  BoardModel(
      id: 16, string: 2, fret: 2, note: "C#", fretSound: AppStrings.str2Fr2),
  BoardModel(
      id: 17, string: 1, fret: 2, note: "F#", fretSound: AppStrings.str1Fr2),
  BoardModel(
      id: 18, string: 6, fret: 3, note: "G", fretSound: AppStrings.str6Fr3),
  BoardModel(
      id: 19, string: 5, fret: 3, note: "C", fretSound: AppStrings.str5Fr3),
  BoardModel(
      id: 20, string: 4, fret: 3, note: "F", fretSound: AppStrings.str4Fr3),
  BoardModel(
      id: 21, string: 3, fret: 3, note: "A#", fretSound: AppStrings.str3Fr3),
  BoardModel(
      id: 22, string: 2, fret: 3, note: "D", fretSound: AppStrings.str2Fr3),
  BoardModel(
      id: 23, string: 1, fret: 3, note: "G", fretSound: AppStrings.str1Fr3),
  BoardModel(
      id: 24, string: 6, fret: 4, note: "G#", fretSound: AppStrings.str6Fr4),
  BoardModel(
      id: 25, string: 5, fret: 4, note: "C#", fretSound: AppStrings.str5Fr4),
  BoardModel(
      id: 26, string: 4, fret: 4, note: "F#", fretSound: AppStrings.str4Fr4),
  BoardModel(
      id: 27, string: 3, fret: 4, note: "B", fretSound: AppStrings.str3Fr4),
  BoardModel(
      id: 28, string: 2, fret: 4, note: "D#", fretSound: AppStrings.str2Fr4),
  BoardModel(
      id: 29, string: 1, fret: 4, note: "G#", fretSound: AppStrings.str1Fr4),
  BoardModel(
      id: 30, string: 6, fret: 5, note: "A", fretSound: AppStrings.str6Fr5),
  BoardModel(
      id: 31, string: 5, fret: 5, note: "D", fretSound: AppStrings.str5Fr5),
  BoardModel(
      id: 32, string: 4, fret: 5, note: "G", fretSound: AppStrings.str4Fr5),
  BoardModel(
      id: 33, string: 3, fret: 5, note: "C", fretSound: AppStrings.str3Fr5),
  BoardModel(
      id: 34, string: 2, fret: 5, note: "E", fretSound: AppStrings.str2Fr5),
  BoardModel(
      id: 35, string: 1, fret: 5, note: "A", fretSound: AppStrings.str1Fr5),
  BoardModel(
      id: 36, string: 6, fret: 6, note: "A#", fretSound: AppStrings.str6Fr6),
  BoardModel(
      id: 37, string: 5, fret: 6, note: "D#", fretSound: AppStrings.str5Fr6),
  BoardModel(
      id: 38, string: 4, fret: 6, note: "G#", fretSound: AppStrings.str4Fr6),
  BoardModel(
      id: 39, string: 3, fret: 6, note: "C#", fretSound: AppStrings.str3Fr6),
  BoardModel(
      id: 40, string: 2, fret: 6, note: "F", fretSound: AppStrings.str2Fr6),
  BoardModel(
      id: 41, string: 1, fret: 6, note: "A#", fretSound: AppStrings.str1Fr6),
  BoardModel(
      id: 42, string: 6, fret: 7, note: "B", fretSound: AppStrings.str6Fr7),
  BoardModel(
      id: 43, string: 5, fret: 7, note: "E", fretSound: AppStrings.str5Fr7),
  BoardModel(
      id: 44, string: 4, fret: 7, note: "A", fretSound: AppStrings.str4Fr7),
  BoardModel(
      id: 45, string: 3, fret: 7, note: "D", fretSound: AppStrings.str3Fr7),
  BoardModel(
      id: 46, string: 2, fret: 7, note: "F#", fretSound: AppStrings.str2Fr7),
  BoardModel(
      id: 47, string: 1, fret: 7, note: "B", fretSound: AppStrings.str1Fr7),
  BoardModel(
      id: 48, string: 6, fret: 8, note: "C", fretSound: AppStrings.str6Fr8),
  BoardModel(
      id: 49, string: 5, fret: 8, note: "F", fretSound: AppStrings.str5Fr8),
  BoardModel(
      id: 50, string: 4, fret: 8, note: "A#", fretSound: AppStrings.str4Fr8),
  BoardModel(
      id: 51, string: 3, fret: 8, note: "D#", fretSound: AppStrings.str3Fr8),
  BoardModel(
      id: 52, string: 2, fret: 8, note: "G", fretSound: AppStrings.str2Fr8),
  BoardModel(
      id: 53, string: 1, fret: 8, note: "C", fretSound: AppStrings.str1Fr8),
  BoardModel(
      id: 54, string: 6, fret: 9, note: "C#", fretSound: AppStrings.str6Fr9),
  BoardModel(
      id: 55, string: 5, fret: 9, note: "F#", fretSound: AppStrings.str5Fr9),
  BoardModel(
      id: 56, string: 4, fret: 9, note: "B", fretSound: AppStrings.str4Fr9),
  BoardModel(
      id: 57, string: 3, fret: 9, note: "E", fretSound: AppStrings.str3Fr9),
  BoardModel(
      id: 58, string: 2, fret: 9, note: "G#", fretSound: AppStrings.str2Fr9),
  BoardModel(
      id: 59, string: 1, fret: 9, note: "C#", fretSound: AppStrings.str1Fr9),
  BoardModel(
      id: 60, string: 6, fret: 10, note: "D", fretSound: AppStrings.str6Fr10),
  BoardModel(
      id: 61, string: 5, fret: 10, note: "G", fretSound: AppStrings.str5Fr10),
  BoardModel(
      id: 62, string: 4, fret: 10, note: "C", fretSound: AppStrings.str4Fr10),
  BoardModel(
      id: 63, string: 3, fret: 10, note: "F", fretSound: AppStrings.str3Fr10),
  BoardModel(
      id: 64, string: 2, fret: 10, note: "A", fretSound: AppStrings.str2Fr10),
  BoardModel(
      id: 65, string: 1, fret: 10, note: "D", fretSound: AppStrings.str1Fr10),
  BoardModel(
      id: 66, string: 6, fret: 11, note: "D#", fretSound: AppStrings.str6Fr11),
  BoardModel(
      id: 67, string: 5, fret: 11, note: "G#", fretSound: AppStrings.str5Fr11),
  BoardModel(
      id: 68, string: 4, fret: 11, note: "C#", fretSound: AppStrings.str4Fr11),
  BoardModel(
      id: 69, string: 3, fret: 11, note: "F#", fretSound: AppStrings.str3Fr11),
  BoardModel(
      id: 70, string: 2, fret: 11, note: "A#", fretSound: AppStrings.str2Fr11),
  BoardModel(
      id: 71, string: 1, fret: 11, note: "D#", fretSound: AppStrings.str1Fr11),
  BoardModel(
      id: 72, string: 6, fret: 12, note: "E", fretSound: AppStrings.str6Fr12),
  BoardModel(
      id: 73, string: 5, fret: 12, note: "A", fretSound: AppStrings.str5Fr12),
  BoardModel(
      id: 74, string: 4, fret: 12, note: "D", fretSound: AppStrings.str4Fr12),
  BoardModel(
      id: 75, string: 3, fret: 12, note: "G", fretSound: AppStrings.str3Fr12),
  BoardModel(
      id: 76, string: 2, fret: 12, note: "B", fretSound: AppStrings.str2Fr12),
  BoardModel(
      id: 77, string: 1, fret: 12, note: "E", fretSound: AppStrings.str1Fr12),
  BoardModel(
      id: 78, string: 6, fret: 13, note: "F", fretSound: AppStrings.str6Fr13),
  BoardModel(
      id: 79, string: 5, fret: 13, note: "A#", fretSound: AppStrings.str5Fr13),
  BoardModel(
      id: 80, string: 4, fret: 13, note: "D#", fretSound: AppStrings.str4Fr13),
  BoardModel(
      id: 81, string: 3, fret: 13, note: "G#", fretSound: AppStrings.str3Fr13),
  BoardModel(
      id: 82, string: 2, fret: 13, note: "C", fretSound: AppStrings.str2Fr13),
  BoardModel(
      id: 83, string: 1, fret: 13, note: "F", fretSound: AppStrings.str1Fr13),
  BoardModel(
      id: 84, string: 6, fret: 14, note: "F#", fretSound: AppStrings.str6Fr14),
  BoardModel(
      id: 85, string: 5, fret: 14, note: "B", fretSound: AppStrings.str5Fr14),
  BoardModel(
      id: 86, string: 4, fret: 14, note: "E", fretSound: AppStrings.str4Fr14),
  BoardModel(
      id: 87, string: 3, fret: 14, note: "A", fretSound: AppStrings.str3Fr14),
  BoardModel(
      id: 88, string: 2, fret: 14, note: "C#", fretSound: AppStrings.str2Fr14),
  BoardModel(
      id: 89, string: 1, fret: 14, note: "F#", fretSound: AppStrings.str1Fr14),
  BoardModel(
      id: 90, string: 6, fret: 15, note: "G", fretSound: AppStrings.str6Fr15),
  BoardModel(
      id: 91, string: 5, fret: 15, note: "C", fretSound: AppStrings.str5Fr15),
  BoardModel(
      id: 92, string: 4, fret: 15, note: "F", fretSound: AppStrings.str4Fr15),
  BoardModel(
      id: 93, string: 3, fret: 15, note: "A#", fretSound: AppStrings.str3Fr15),
  BoardModel(
      id: 94, string: 2, fret: 15, note: "D", fretSound: AppStrings.str2Fr15),
  BoardModel(
      id: 95, string: 1, fret: 15, note: "G", fretSound: AppStrings.str1Fr15)
];
