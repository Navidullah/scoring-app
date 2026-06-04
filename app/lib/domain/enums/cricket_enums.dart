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

/// Ball used for the match. Tennis/rubber-ball cricket is hugely popular in
/// South Asia and is usually scored without LBW.
enum BallType {
  leather,
  tennis,
}

/// Lifecycle states for a match.
enum MatchStatus {
  scheduled,
  inProgress,
  completed,
  abandoned,
}
