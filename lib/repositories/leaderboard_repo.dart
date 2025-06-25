import 'package:fretboard/models/leaderboard.dart';
import 'package:fretboard/services/base_service.dart';
import 'package:fretboard/utils/app_urls.dart';
import 'package:reg_page/reg_page.dart';

import '../services/base_controller.dart';

class LeaderboardRepo extends BaseService with BaseController {
  Future<dynamic> updateLeaderboardData(LeaderboardData leaderboard) async {
    try {
      final res = await post(AppUrls.leaderboard, {
        'game': 'fretboardtrainer',
        'leaderboard': [leaderboard.toMap()]
      });
      return res;
    } catch (e) {
      exceptionLog(e, name: 'getLeaderboardData');
      return null;
    }
  }

  Future<List<LeaderboardData>> getLeaderboardData() async {
    try {
      final res = await get(AppUrls.getleaderboard);
      if (res == null) return [];
      if (res['leaderboard'] == null) return [];
      return Leaderboard.fromMap(res).leaderboard ?? [];
    } catch (e) {
      return [];
    }
  }
}
