import '../../core/constants/app_constants.dart';
import '../enums/cricket_enums.dart';
import 'ball_event.dart';

/// Aggregated batting figures for one player in an innings.
class BatStat {
  const BatStat(this.runs, this.balls, this.fours, this.sixes);
  final int runs;
  final int balls;
  final int fours;
  final int sixes;

  double get strikeRate => balls == 0 ? 0 : (runs * 100) / balls;
}

/// Aggregated bowling figures for one player in an innings.
class BowlStat {
  const BowlStat(this.legalBalls, this.runsConceded, this.wickets);
  final int legalBalls;
  final int runsConceded;
  final int wickets;

  String get oversText => '${legalBalls ~/ AppConstants.ballsPerOver}.${legalBalls % AppConstants.ballsPerOver}';
  double get economy =>
      legalBalls == 0 ? 0 : (runsConceded * AppConstants.ballsPerOver) / legalBalls;
}

/// One innings: who is batting/bowling, the recorded balls, and the live
/// striker/non-striker/bowler. Score-related values are derived, never stored.
class Innings {
  const Innings({
    required this.battingTeam,
    required this.bowlingTeam,
    this.balls = const [],
    this.striker,
    this.nonStriker,
    this.bowler,
    this.isComplete = false,
    this.target,
  });

  final String battingTeam;
  final String bowlingTeam;
  final List<BallEvent> balls;
  final String? striker;
  final String? nonStriker;
  final String? bowler;
  final bool isComplete;
  final int? target; // set for the chasing innings

  int get runs => balls.fold(0, (sum, b) => sum + b.totalRuns);
  int get wickets => balls.where((b) => b.wicket != null).length;
  int get legalBalls => balls.where((b) => b.isLegal).length;

  String get oversText =>
      '${legalBalls ~/ AppConstants.ballsPerOver}.${legalBalls % AppConstants.ballsPerOver}';

  bool get isOverComplete =>
      legalBalls > 0 && legalBalls % AppConstants.ballsPerOver == 0;

  /// Current run rate (runs per over).
  double get runRate =>
      legalBalls == 0 ? 0 : (runs * AppConstants.ballsPerOver) / legalBalls;

  /// Deliveries belonging to the over currently in progress (includes extras).
  List<BallEvent> get currentOverBalls {
    final result = <BallEvent>[];
    var legal = 0;
    for (final b in balls) {
      result.add(b);
      if (b.isLegal) {
        legal++;
        if (legal % AppConstants.ballsPerOver == 0) result.clear();
      }
    }
    return result;
  }

  BatStat batStat(String name) {
    var runs = 0, faced = 0, fours = 0, sixes = 0;
    for (final b in balls) {
      if (b.strikerName != name) continue;
      runs += b.runs;
      // A ball faced counts unless it was a wide.
      if (b.extraType != ExtraType.wide) faced++;
      if (b.runs == 4) fours++;
      if (b.runs == 6) sixes++;
    }
    return BatStat(runs, faced, fours, sixes);
  }

  BowlStat bowlStat(String name) {
    var legal = 0, conceded = 0, wkts = 0;
    for (final b in balls) {
      if (b.bowlerName != name) continue;
      if (b.isLegal) legal++;
      conceded += b.bowlerConceded;
      if (b.isBowlerWicket) wkts++;
    }
    return BowlStat(legal, conceded, wkts);
  }

  /// Total extras conceded (wides, no-balls, byes, leg-byes).
  int get extras => balls.fold(0, (s, b) => s + b.extraRuns);

  /// Batsmen in the order they came to the crease.
  List<String> get batsmenInOrder {
    final seen = <String>{};
    final order = <String>[];
    for (final b in balls) {
      for (final n in [b.strikerName, b.nonStrikerName]) {
        if (seen.add(n)) order.add(n);
      }
    }
    // Catch any not-out batsman who never faced a ball.
    for (final n in [striker, nonStriker]) {
      if (n != null && seen.add(n)) order.add(n);
    }
    return order;
  }

  /// Distinct bowlers used, in first-used order.
  List<String> get bowlersUsed {
    final seen = <String>{};
    final order = <String>[];
    for (final b in balls) {
      if (seen.add(b.bowlerName)) order.add(b.bowlerName);
    }
    return order;
  }

  /// Maiden overs bowled by [bowler] (an over with zero runs charged to them).
  int maidensFor(String bowler) {
    var legalInOver = 0, concededInOver = 0, maidens = 0;
    for (final b in balls) {
      if (b.bowlerName != bowler) continue;
      concededInOver += b.bowlerConceded;
      if (b.isLegal) legalInOver++;
      if (legalInOver == AppConstants.ballsPerOver) {
        if (concededInOver == 0) maidens++;
        legalInOver = 0;
        concededInOver = 0;
      }
    }
    return maidens;
  }

  /// The delivery that dismissed [batsman], if any.
  BallEvent? dismissalOf(String batsman) {
    for (final b in balls) {
      if (b.wicket != null && b.outBatsmanName == batsman) return b;
    }
    return null;
  }

  Innings copyWith({
    String? battingTeam,
    String? bowlingTeam,
    List<BallEvent>? balls,
    String? striker,
    String? nonStriker,
    String? bowler,
    bool? isComplete,
    int? target,
    bool clearStriker = false,
    bool clearNonStriker = false,
    bool clearBowler = false,
  }) {
    return Innings(
      battingTeam: battingTeam ?? this.battingTeam,
      bowlingTeam: bowlingTeam ?? this.bowlingTeam,
      balls: balls ?? this.balls,
      striker: clearStriker ? null : (striker ?? this.striker),
      nonStriker: clearNonStriker ? null : (nonStriker ?? this.nonStriker),
      bowler: clearBowler ? null : (bowler ?? this.bowler),
      isComplete: isComplete ?? this.isComplete,
      target: target ?? this.target,
    );
  }

  Map<String, dynamic> toJson() => {
        'battingTeam': battingTeam,
        'bowlingTeam': bowlingTeam,
        'balls': balls.map((b) => b.toJson()).toList(),
        'striker': striker,
        'nonStriker': nonStriker,
        'bowler': bowler,
        'isComplete': isComplete,
        'target': target,
      };

  factory Innings.fromJson(Map<String, dynamic> json) => Innings(
        battingTeam: json['battingTeam'] as String,
        bowlingTeam: json['bowlingTeam'] as String,
        balls: (json['balls'] as List<dynamic>)
            .map((b) => BallEvent.fromJson(b as Map<String, dynamic>))
            .toList(),
        striker: json['striker'] as String?,
        nonStriker: json['nonStriker'] as String?,
        bowler: json['bowler'] as String?,
        isComplete: (json['isComplete'] as bool?) ?? false,
        target: json['target'] as int?,
      );
}
