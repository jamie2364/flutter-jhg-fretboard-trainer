// utils/routes.dart
//
// Shared route names. Kept in one place so the launch site and the navigation
// that returns to it can't drift apart.

/// Tagged onto the training board when it's launched so the Practice (Train)
/// tab can pop straight back to it from any secondary screen.
const kBoardRoute = '/board';

/// Names for the nav-bar destinations. They exist so the Home tab can tell
/// whether the route it popped back to really is the landing screen: if one of
/// these ended up at the bottom of the stack, something replaced the landing
/// screen and it has to be put back.
const kSavedRoute = '/saved';
const kStatsRoute = '/stats';
const kSettingsRoute = '/settings';
const kLeaderboardRoute = '/leaderboard';

/// Every route that is pushed *over* the landing screen. The landing screen is
/// the only screen that is legitimately first.
const Set<String> kPushedRoutes = {
  kBoardRoute,
  kSavedRoute,
  kStatsRoute,
  kSettingsRoute,
  kLeaderboardRoute,
};
