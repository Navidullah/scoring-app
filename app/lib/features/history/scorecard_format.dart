import '../../domain/enums/cricket_enums.dart';
import '../../domain/models/innings.dart';

/// Human-readable dismissal for a batsman, shared by the on-screen scorecard
/// and the exported PDF. e.g. "c Jadeja b Bumrah", "run out (Gill)", "not out".
String dismissalText(Innings innings, String batsman) {
  final ball = innings.dismissalOf(batsman);
  if (ball == null) return 'not out';

  final bowler = ball.bowlerName;
  final fielder = ball.fielderName;
  switch (ball.wicket!) {
    case WicketType.bowled:
      return 'b $bowler';
    case WicketType.lbw:
      return 'lbw b $bowler';
    case WicketType.caught:
      return fielder != null ? 'c $fielder b $bowler' : 'c b $bowler';
    case WicketType.stumped:
      return fielder != null ? 'st $fielder b $bowler' : 'st b $bowler';
    case WicketType.hitWicket:
      return 'hit wicket b $bowler';
    case WicketType.runOut:
      return fielder != null ? 'run out ($fielder)' : 'run out';
    case WicketType.retired:
      return 'retired';
  }
}
