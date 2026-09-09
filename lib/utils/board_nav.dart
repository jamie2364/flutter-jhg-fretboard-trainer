// utils/board_nav.dart
//
// One way in and out of the training board.
//
// The board and the landing screen both carry the bottom nav bar, and GetX pops
// a route with the same transition it was pushed with. So an animated push here
// makes the bar slide on the way IN *and* again on the way back out when the
// Home tab pops to the landing screen. Every board launch therefore goes
// through here with no transition, and the bar stays put.

import 'package:fretboard/utils/routes.dart';
import 'package:fretboard/views/screens/home/home_screen.dart';
import 'package:get/get.dart';

/// Opens the training board.
///
/// Pass [replace] from a screen that should not stay in the stack (a wizard
/// step, the saved-sessions library). The landing screen always stays at the
/// bottom either way, which is what the Home tab pops back to.
void openBoard({bool replace = false}) {
  if (replace) {
    Get.off(
      () => const HomeScreen(),
      routeName: kBoardRoute,
      transition: Transition.noTransition,
      duration: Duration.zero,
    );
  } else {
    Get.to(
      () => const HomeScreen(),
      routeName: kBoardRoute,
      transition: Transition.noTransition,
      duration: Duration.zero,
    );
  }
}
