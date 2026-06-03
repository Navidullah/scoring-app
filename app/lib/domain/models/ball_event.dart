import '../enums/cricket_enums.dart';

ExtraType? _extraFromName(String? n) =>
    n == null ? null : ExtraType.values.firstWhere((e) => e.name == n);

WicketType? _wicketFromName(String? n) =>
    n == null ? null : WicketType.values.firstWhere((e) => e.name == n);

/// A single recorded delivery. Position within the over is derived from the
/// ordered ball list (see [Innings]), so it is intentionally not stored here.
class BallEvent {
  const BallEvent({
    required this.id,
    required this.runs,
    required this.strikerName,
    required this.nonStrikerName,
    required this.bowlerName,
    this.extraType,
    this.extraRuns = 0,
    this.wicket,
    this.outBatsmanName,
    this.fielderName,
  });

  final String id;
  final int runs; // runs off the bat
  final ExtraType? extraType;
  final int extraRuns; // runs attributed to the extra (byes, the wide itself, etc.)
  final WicketType? wicket;
  final String strikerName;
  final String nonStrikerName;
  final String bowlerName;
  final String? outBatsmanName;
  final String? fielderName; // catcher / stumper / run-out fielder

  /// Wides and no-balls do not count toward the over.
  bool get isLegal => extraType != ExtraType.wide && extraType != ExtraType.noBall;

  /// Runs added to the team total for this delivery.
  int get totalRuns => runs + extraRuns;

  /// Runs charged to the bowler (byes/leg-byes are not the bowler's fault).
  int get bowlerConceded {
    if (extraType == ExtraType.bye || extraType == ExtraType.legBye) return runs;
    return totalRuns;
  }

  /// Whether the bowler is credited with this wicket (run-outs/retired are not).
  bool get isBowlerWicket =>
      wicket != null && wicket != WicketType.runOut && wicket != WicketType.retired;

  /// Short scorecard label, e.g. "4", "•", "W", "Wd", "B2".
  String get label {
    if (wicket != null) return runs > 0 ? '${runs}W' : 'W';
    switch (extraType) {
      case ExtraType.wide:
        return extraRuns > 1 ? 'Wd${extraRuns - 1}' : 'Wd';
      case ExtraType.noBall:
        return 'Nb';
      case ExtraType.bye:
        return 'B$extraRuns';
      case ExtraType.legBye:
        return 'Lb$extraRuns';
      case null:
        return runs == 0 ? '•' : '$runs';
    }
  }

  BallEvent copyWith({
    String? id,
    int? runs,
    ExtraType? extraType,
    int? extraRuns,
    WicketType? wicket,
    String? strikerName,
    String? nonStrikerName,
    String? bowlerName,
    String? outBatsmanName,
    String? fielderName,
  }) {
    return BallEvent(
      id: id ?? this.id,
      runs: runs ?? this.runs,
      extraType: extraType ?? this.extraType,
      extraRuns: extraRuns ?? this.extraRuns,
      wicket: wicket ?? this.wicket,
      strikerName: strikerName ?? this.strikerName,
      nonStrikerName: nonStrikerName ?? this.nonStrikerName,
      bowlerName: bowlerName ?? this.bowlerName,
      outBatsmanName: outBatsmanName ?? this.outBatsmanName,
      fielderName: fielderName ?? this.fielderName,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'runs': runs,
        'extraType': extraType?.name,
        'extraRuns': extraRuns,
        'wicket': wicket?.name,
        'strikerName': strikerName,
        'nonStrikerName': nonStrikerName,
        'bowlerName': bowlerName,
        'outBatsmanName': outBatsmanName,
        'fielderName': fielderName,
      };

  factory BallEvent.fromJson(Map<String, dynamic> json) => BallEvent(
        id: json['id'] as String,
        runs: json['runs'] as int,
        extraType: _extraFromName(json['extraType'] as String?),
        extraRuns: (json['extraRuns'] as int?) ?? 0,
        wicket: _wicketFromName(json['wicket'] as String?),
        strikerName: json['strikerName'] as String,
        nonStrikerName: json['nonStrikerName'] as String,
        bowlerName: json['bowlerName'] as String,
        outBatsmanName: json['outBatsmanName'] as String?,
        fielderName: json['fielderName'] as String?,
      );
}
