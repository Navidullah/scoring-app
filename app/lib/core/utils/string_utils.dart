/// Capitalizes the first letter of every word, collapsing extra whitespace.
/// e.g. "naveed ullah" -> "Naveed Ullah", "  team a " -> "Team A".
/// The rest of each word is left as typed, so intentional caps (e.g. "MS")
/// are preserved.
String titleCase(String input) {
  final words = input.trim().split(RegExp(r'\s+'));
  return words
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');
}
