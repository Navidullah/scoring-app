import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/string_utils.dart';
import '../../../data/repositories/match_repository.dart';
import '../../../domain/enums/cricket_enums.dart';
import '../../../domain/models/ball_event.dart';
import '../../../domain/models/cricket_match.dart';
import '../../../domain/models/innings.dart';
import '../../../shared/providers/repository_providers.dart';

const _uuid = Uuid();

/// Standard limit of wickets before an innings ends (no squad size in V1).
const int _maxWickets = 10;

/// Drives a single live match. Holds the [CricketMatch] as state, applies
/// scoring rules (strike rotation, over/innings transitions), and persists
/// every change to the repository (offline-first).
class LiveScoringController extends StateNotifier<CricketMatch> {
  LiveScoringController(this._repo, CricketMatch initial) : super(initial);

  final MatchRepository _repo;

  Innings get _inn => state.currentInnings;

  bool get needsOpeners => _inn.striker == null || _inn.nonStriker == null;
  bool get needsBowler => _inn.bowler == null;

  /// Distinct bowlers already used this innings, in first-used order.
  List<String> get priorBowlers => _inn.bowlersUsed;

  /// Bowler of the over just completed — ineligible to bowl the next over.
  String? get lastOverBowler => _inn.balls.isEmpty ? null : _inn.balls.last.bowlerName;
  bool get canScore =>
      !state.isComplete && !needsOpeners && !needsBowler && !_inn.isComplete;

  void _commit(CricketMatch match) {
    state = match;
    _repo.saveMatch(match);
  }

  // --- Player setup ---------------------------------------------------------

  void setOpeners({required String striker, required String nonStriker}) {
    _commit(state.withCurrentInnings(
      _inn.copyWith(striker: titleCase(striker), nonStriker: titleCase(nonStriker)),
    ));
  }

  void setBowler(String name) {
    _commit(state.withCurrentInnings(_inn.copyWith(bowler: titleCase(name))));
  }

  // --- Scoring --------------------------------------------------------------

  void scoreRuns(int runs) {
    if (!canScore) return;
    _applyBall(runs: runs, ranBetweenWickets: runs);
  }

  void scoreExtra(ExtraType type, {int runs = 1}) {
    if (!canScore) return;
    switch (type) {
      case ExtraType.wide:
      case ExtraType.noBall:
        // Penalty delivery: not a legal ball, strike unchanged in V1.
        _applyBall(runs: 0, extraType: type, extraRuns: runs, ranBetweenWickets: 0);
        break;
      case ExtraType.bye:
      case ExtraType.legBye:
        // Legal ball; the runs were physically run, so rotate on odd.
        _applyBall(runs: 0, extraType: type, extraRuns: runs, ranBetweenWickets: runs);
        break;
    }
  }

  void scoreWicket(
    WicketType type, {
    required String newBatsman,
    String? fielder,
    bool nonStrikerOut = false,
  }) {
    if (!canScore) return;
    // Only a run-out can dismiss the non-striker; everything else is the striker.
    final out = nonStrikerOut ? _inn.nonStriker : _inn.striker;
    _applyBall(
      runs: 0,
      wicket: type,
      outBatsman: out,
      fielder: (fielder == null || fielder.trim().isEmpty) ? null : titleCase(fielder),
      ranBetweenWickets: 0,
      incomingBatsman: titleCase(newBatsman),
      nonStrikerOut: nonStrikerOut,
    );
  }

  /// Retires a batsman (e.g. retired hurt). Not a dismissal: no ball is bowled
  /// and no wicket is recorded — the named end simply gets a new batsman. The
  /// retired player keeps their figures and may return later under the same name.
  void retire({required bool nonStriker, required String replacement}) {
    if (state.isComplete || _inn.isComplete) return;
    if (replacement.trim().isEmpty) return;
    final name = titleCase(replacement);
    _commit(state.withCurrentInnings(
      nonStriker ? _inn.copyWith(nonStriker: name) : _inn.copyWith(striker: name),
    ));
  }

  void _applyBall({
    required int runs,
    required int ranBetweenWickets,
    ExtraType? extraType,
    int extraRuns = 0,
    WicketType? wicket,
    String? outBatsman,
    String? fielder,
    String? incomingBatsman,
    bool nonStrikerOut = false,
  }) {
    final ball = BallEvent(
      id: _uuid.v4(),
      runs: runs,
      extraType: extraType,
      extraRuns: extraRuns,
      wicket: wicket,
      strikerName: _inn.striker!,
      nonStrikerName: _inn.nonStriker!,
      bowlerName: _inn.bowler!,
      outBatsmanName: outBatsman,
      fielderName: fielder,
    );

    var striker = _inn.striker!;
    var nonStriker = _inn.nonStriker!;

    // The dismissed batsman is replaced; a run-out can take the non-striker.
    if (wicket != null) {
      if (nonStrikerOut) {
        nonStriker = incomingBatsman ?? nonStriker;
      } else {
        striker = incomingBatsman ?? striker;
      }
    }

    // Rotate strike on odd runs run between the wickets.
    if (ranBetweenWickets.isOdd) {
      final tmp = striker;
      striker = nonStriker;
      nonStriker = tmp;
    }

    var updated = _inn.copyWith(
      balls: [..._inn.balls, ball],
      striker: striker,
      nonStriker: nonStriker,
    );

    // Over complete → swap strike, clear bowler so a new one must be chosen.
    // Only the legal delivery that completes the over triggers this; wides and
    // no-balls don't advance the over, so they must never re-prompt.
    final overJustCompleted =
        ball.isLegal && updated.legalBalls % AppConstants.ballsPerOver == 0;
    if (overJustCompleted) {
      updated = updated.copyWith(
        striker: nonStriker,
        nonStriker: striker,
        clearBowler: true,
      );
    }

    final inningsEnded = updated.wickets >= _maxWickets ||
        updated.legalBalls >= state.overs * AppConstants.ballsPerOver ||
        (updated.target != null && updated.runs >= updated.target!);

    if (inningsEnded) {
      _finishInnings(updated);
    } else {
      _commit(state.withCurrentInnings(updated));
    }
  }

  void _finishInnings(Innings finished) {
    final completed = finished.copyWith(isComplete: true);

    if (state.isSecondInnings) {
      _commit(state.withCurrentInnings(completed).copyWith(
        status: MatchStatus.completed,
        resultText: _resultText(completed),
      ));
      return;
    }

    // Start the second innings with the chase target.
    final target = completed.runs + 1;
    final second = Innings(
      battingTeam: completed.bowlingTeam,
      bowlingTeam: completed.battingTeam,
      target: target,
    );
    _commit(state.copyWith(innings: [completed, second]));
  }

  String _resultText(Innings second) {
    final first = state.innings.first;
    final firstRuns = first.runs;
    final secondRuns = second.runs;
    if (secondRuns >= first.runs + 1) {
      final wktsLeft = _maxWickets - second.wickets;
      return '${second.battingTeam} won by $wktsLeft wicket${wktsLeft == 1 ? '' : 's'}';
    }
    if (secondRuns == firstRuns) return 'Match tied';
    final margin = firstRuns - secondRuns;
    return '${first.battingTeam} won by $margin run${margin == 1 ? '' : 's'}';
  }

  // --- Undo -----------------------------------------------------------------

  /// Removes the last ball of the current innings and rebuilds derived state.
  /// Simple and correct: replays striker/non-striker/bowler is non-trivial, so
  /// V1 restores the previous ball's batsmen/bowler and clears completion.
  void undo() {
    if (_inn.balls.isEmpty) return;
    final balls = [..._inn.balls]..removeLast();

    String? striker = _inn.striker;
    String? nonStriker = _inn.nonStriker;
    String? bowler = _inn.bowler;
    if (balls.isNotEmpty) {
      final prev = balls.last;
      striker = prev.strikerName;
      nonStriker = prev.nonStrikerName;
      bowler = prev.bowlerName;
    }

    final restored = Innings(
      battingTeam: _inn.battingTeam,
      bowlingTeam: _inn.bowlingTeam,
      balls: balls,
      striker: striker,
      nonStriker: nonStriker,
      bowler: bowler,
      target: _inn.target,
    );
    _commit(state.withCurrentInnings(restored).copyWith(
      status: MatchStatus.inProgress,
      clearResultText: true,
    ));
  }
}

/// One controller per match id. Reads the match synchronously from Hive.
final liveScoringControllerProvider = StateNotifierProvider.autoDispose
    .family<LiveScoringController, CricketMatch, String>((ref, matchId) {
  final repo = ref.watch(matchRepositoryProvider);
  final match = repo.getMatch(matchId);
  if (match == null) {
    throw StateError('Match $matchId not found in local store');
  }
  return LiveScoringController(repo, match);
});
