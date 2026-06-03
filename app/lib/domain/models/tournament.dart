import '../enums/cricket_enums.dart';

TournamentFormat _formatFromName(String? n) => n == null
    ? TournamentFormat.roundRobin
    : TournamentFormat.values.firstWhere((e) => e.name == n);

/// A team entered in a tournament. Players are stored as names for V1.
class TournamentTeam {
  const TournamentTeam({required this.name, this.players = const []});

  final String name;
  final List<String> players;

  Map<String, dynamic> toJson() => {'name': name, 'players': players};

  factory TournamentTeam.fromJson(Map<String, dynamic> json) => TournamentTeam(
        name: json['name'] as String,
        players: (json['players'] as List<dynamic>? ?? []).cast<String>(),
      );
}

/// A scheduled match between two teams. The actual scoring lives in a
/// [CricketMatch]; [matchId] links to it once the fixture is played.
class Fixture {
  const Fixture({
    required this.id,
    required this.round,
    required this.teamA,
    required this.teamB,
    this.matchId,
  });

  final String id;
  final int round; // 1 for round-robin; round number for knockout
  final String teamA;
  final String teamB;
  final String? matchId;

  bool get isBye => teamB == byeMarker || teamA == byeMarker;

  static const String byeMarker = 'BYE';

  Fixture copyWith({String? matchId}) => Fixture(
        id: id,
        round: round,
        teamA: teamA,
        teamB: teamB,
        matchId: matchId ?? this.matchId,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'round': round,
        'teamA': teamA,
        'teamB': teamB,
        'matchId': matchId,
      };

  factory Fixture.fromJson(Map<String, dynamic> json) => Fixture(
        id: json['id'] as String,
        round: (json['round'] as int?) ?? 1,
        teamA: json['teamA'] as String,
        teamB: json['teamB'] as String,
        matchId: json['matchId'] as String?,
      );
}

/// A tournament: teams, format, and generated fixtures.
class Tournament {
  const Tournament({
    required this.id,
    required this.name,
    required this.format,
    required this.overs,
    required this.teams,
    required this.fixtures,
    required this.createdAt,
  });

  final String id;
  final String name;
  final TournamentFormat format;
  final int overs;
  final List<TournamentTeam> teams;
  final List<Fixture> fixtures;
  final DateTime createdAt;

  int get currentRound =>
      fixtures.isEmpty ? 1 : fixtures.map((f) => f.round).reduce((a, b) => a > b ? a : b);

  Tournament copyWith({List<Fixture>? fixtures}) => Tournament(
        id: id,
        name: name,
        format: format,
        overs: overs,
        teams: teams,
        fixtures: fixtures ?? this.fixtures,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'format': format.name,
        'overs': overs,
        'teams': teams.map((t) => t.toJson()).toList(),
        'fixtures': fixtures.map((f) => f.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Tournament.fromJson(Map<String, dynamic> json) => Tournament(
        id: json['id'] as String,
        name: json['name'] as String,
        format: _formatFromName(json['format'] as String?),
        overs: (json['overs'] as int?) ?? 20,
        teams: (json['teams'] as List<dynamic>)
            .map((t) => TournamentTeam.fromJson(t as Map<String, dynamic>))
            .toList(),
        fixtures: (json['fixtures'] as List<dynamic>)
            .map((f) => Fixture.fromJson(f as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
