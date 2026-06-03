import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../domain/models/cricket_match.dart';
import '../../../domain/models/innings.dart';
import '../scorecard_format.dart';
import 'player_of_match.dart';

/// Builds a printable scorecard PDF for [match] and opens the system
/// share/save sheet, so players can save it to the device or share it.
Future<void> shareScorecardPdf(CricketMatch match) async {
  final bytes = await buildScorecardPdf(match);
  final safeName = '${match.team1}_vs_${match.team2}'
      .replaceAll(RegExp(r'[^A-Za-z0-9_]+'), '_');
  await Printing.sharePdf(bytes: bytes, filename: '$safeName.pdf');
}

/// Renders the scorecard PDF to bytes (separated for testability).
Future<Uint8List> buildScorecardPdf(CricketMatch match) async {
  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (context) => [
        pw.Text(
          '${match.team1} vs ${match.team2}',
          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text('${match.overs} overs per side'),
        if (match.resultText != null)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4),
            child: pw.Text(
              match.resultText!,
              style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
            ),
          ),
        if (playerOfTheMatch(match) != null)
          pw.Text(
            'Player of the Match: ${playerOfTheMatch(match)!.name}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        pw.Divider(),
        for (final inn in match.innings) ..._inningsSection(inn),
      ],
    ),
  );
  return doc.save();
}

List<pw.Widget> _inningsSection(Innings inn) {
  final bold = pw.TextStyle(fontWeight: pw.FontWeight.bold);
  return [
    pw.SizedBox(height: 10),
    pw.Text(
      '${inn.battingTeam}   ${inn.runs}/${inn.wickets}  (${inn.oversText} ov)',
      style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
    ),
    pw.SizedBox(height: 4),
    pw.TableHelper.fromTextArray(
      headerStyle: bold,
      cellAlignment: pw.Alignment.centerRight,
      cellAlignments: {0: pw.Alignment.centerLeft},
      headers: ['Batsman', 'R', 'B', '4s', '6s', 'SR'],
      data: [
        for (final b in inn.batsmenInOrder)
          [
            '$b\n${dismissalText(inn, b)}',
            '${inn.batStat(b).runs}',
            '${inn.batStat(b).balls}',
            '${inn.batStat(b).fours}',
            '${inn.batStat(b).sixes}',
            inn.batStat(b).strikeRate.toStringAsFixed(1),
          ],
      ],
    ),
    pw.SizedBox(height: 4),
    pw.Text('Extras ${inn.extras}      Total ${inn.runs}/${inn.wickets} (${inn.oversText} ov)'),
    pw.SizedBox(height: 8),
    pw.TableHelper.fromTextArray(
      headerStyle: bold,
      cellAlignment: pw.Alignment.centerRight,
      cellAlignments: {0: pw.Alignment.centerLeft},
      headers: ['Bowler', 'O', 'M', 'R', 'W', 'Econ'],
      data: [
        for (final bw in inn.bowlersUsed)
          [
            bw,
            inn.bowlStat(bw).oversText,
            '${inn.maidensFor(bw)}',
            '${inn.bowlStat(bw).runsConceded}',
            '${inn.bowlStat(bw).wickets}',
            inn.bowlStat(bw).economy.toStringAsFixed(1),
          ],
      ],
    ),
  ];
}
