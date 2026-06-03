/// How a batsman was dismissed.
enum WicketType {
  bowled,
  caught,
  lbw,
  runOut,
  stumped,
  hitWicket,
  retired,
}

/// Types of extra deliveries.
enum ExtraType {
  wide,
  noBall,
  bye,
  legBye,
}

/// Tournament formats supported in V1.
enum TournamentFormat {
  roundRobin,
  knockout,
}

/// Lifecycle states for a match.
enum MatchStatus {
  scheduled,
  inProgress,
  completed,
  abandoned,
}
