import '../enums/cricket_enums.dart';
import 'innings.dart';

MatchStatus _statusFromName(String? n) =>
    n == null ? MatchStatus.inProgress : MatchStatus.values.firstWhere((e) => e.name == n);

BallType _ballTypeFromName(String? n) => n == null
    ? BallType.leather
    : BallType.values.firstWhere((e) => e.name == n, orElse: () => BallType.leather);

TossDecision? _tossDecisionFromName(String? n) => n == null
    ? null
    : TossDecision.values.firstWhere((e) => e.name == n, orElse: () => TossDecision.bat);

/// A full match: two teams, overs limit, and one or two innings.
class CricketMatch {
  const CricketMatch({
    required this.id,
    required this.team1,
    required this.team2,
    required this.overs,
    required this.battingFirst,
    required this.innings,
    required this.createdAt,
    this.status = MatchStatus.inProgress,
    this.resultText,
    this.ballType = BallType.leather,
    this.lbwAllowed = true,
    this.tossWinner,
    this.tossDecision,
    this.playersPerSide = 11,
  });

  final String id;
  final String team1;
  final String team2;
  final int overs;
  final String battingFirst;
  final List<Innings> innings;
  final MatchStatus status;
  final String? resultText;
  final DateTime createdAt;
  final BallType ballType;
  final bool lbwAllowed;

  /// Team that won the toss, and what they chose. Null for matches created
  /// before tosses were recorded.
  final String? tossWinner;
  final TossDecision? tossDecision;

  /// Players per team. Drives the all-out threshold (squadSize - 1 wickets).
  /// Defaults to 11 for full-side cricket; smaller for street/tennis games.
  final int playersPerSide;

  /// Wickets that end an innings (all out) for this match's squad size.
  int get maxWickets => playersPerSide - 1;

  /// Human-readable toss summary, e.g. "Lions won the toss and chose to bat".
  String? get tossText {
    if (tossWinner == null || tossDecision == null) return null;
    final choice = tossDecision == TossDecision.bat ? 'bat' : 'bowl';
    return '$tossWinner won the toss and chose to $choice';
  }

  Innings get currentInnings => innings.last;
  bool get isSecondInnings => innings.length == 2;
  bool get isComplete => status == MatchStatus.completed;

  /// Winning team name for a completed match, or null if tied / not finished.
  String? get winnerTeam {
    if (status != MatchStatus.completed || innings.length < 2) return null;
    final first = innings[0];
    final second = innings[1];
    if (second.runs > first.runs) return second.battingTeam;
    if (first.runs > second.runs) return first.battingTeam;
    return null; // tie
  }

  String teamBowlingFirst() => battingFirst == team1 ? team2 : team1;

  CricketMatch copyWith({
    List<Innings>? innings,
    MatchStatus? status,
    String? resultText,
    bool clearResultText = false,
  }) {
    return CricketMatch(
      id: id,
      team1: team1,
      team2: team2,
      overs: overs,
      battingFirst: battingFirst,
      innings: innings ?? this.innings,
      status: status ?? this.status,
      resultText: clearResultText ? null : (resultText ?? this.resultText),
      createdAt: createdAt,
      ballType: ballType,
      lbwAllowed: lbwAllowed,
      tossWinner: tossWinner,
      tossDecision: tossDecision,
      playersPerSide: playersPerSide,
    );
  }

  /// Replace the in-progress (last) innings with an updated copy.
  CricketMatch withCurrentInnings(Innings updated) {
    final list = [...innings];
    list[list.length - 1] = updated;
    return copyWith(innings: list);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'team1': team1,
        'team2': team2,
        'overs': overs,
        'battingFirst': battingFirst,
        'innings': innings.map((i) => i.toJson()).toList(),
        'status': status.name,
        'resultText': resultText,
        'createdAt': createdAt.toIso8601String(),
        'ballType': ballType.name,
        'lbwAllowed': lbwAllowed,
        'tossWinner': tossWinner,
        'tossDecision': tossDecision?.name,
        'playersPerSide': playersPerSide,
      };

  factory CricketMatch.fromJson(Map<String, dynamic> json) => CricketMatch(
        id: json['id'] as String,
        team1: json['team1'] as String,
        team2: json['team2'] as String,
        overs: json['overs'] as int,
        battingFirst: json['battingFirst'] as String,
        innings: (json['innings'] as List<dynamic>)
            .map((i) => Innings.fromJson(i as Map<String, dynamic>))
            .toList(),
        status: _statusFromName(json['status'] as String?),
        resultText: json['resultText'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        ballType: _ballTypeFromName(json['ballType'] as String?),
        lbwAllowed: (json['lbwAllowed'] as bool?) ?? true,
        tossWinner: json['tossWinner'] as String?,
        tossDecision: _tossDecisionFromName(json['tossDecision'] as String?),
        playersPerSide: (json['playersPerSide'] as int?) ?? 11,
      );
}
