import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../domain/models/cricket_match.dart';
import '../../../domain/models/innings.dart';
import '../scorecard_format.dart';
import 'player_of_match.dart';

// ---- Palette (print-friendly, brand-aligned) -------------------------------
final _band = PdfColor.fromInt(0xFF0E1B2B); // dark navy header
final _ink = PdfColor.fromInt(0xFF12243A); // body text
final _green = PdfColor.fromInt(0xFF10B981); // brand green (fill)
final _amber = PdfColor.fromInt(0xFFF59E0B);
final _muted = PdfColor.fromInt(0xFF6B7280); // secondary text
final _onBand = PdfColor.fromInt(0xFFAEB9C7); // soft text on dark band
final _line = PdfColor.fromInt(0xFFE5E7EB); // hairline borders
final _stripe = PdfColor.fromInt(0xFFF7FAF9); // zebra row
final _headFill = PdfColor.fromInt(0xFFEFF6F3); // table header / chips

const _cellPad = pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6);

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
  final doc = pw.Document(title: '${match.team1} vs ${match.team2} — Scorecard');
  final potm = playerOfTheMatch(match);

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(30, 30, 30, 28),
      footer: _footer,
      build: (context) => [
        _headerBand(match, potm),
        pw.SizedBox(height: 18),
        for (var i = 0; i < match.innings.length; i++) ...[
          // Wrap in a Stack so the engine treats the card as one atomic block
          // and moves it whole to the next page rather than splitting it.
          pw.Stack(children: [_inningsCard(match.innings[i], i + 1)]),
          pw.SizedBox(height: 14),
        ],
      ],
    ),
  );
  return doc.save();
}

String _ballLabel(CricketMatch match) {
  final n = match.ballType.name;
  return n[0].toUpperCase() + n.substring(1);
}

// ---- Header band -----------------------------------------------------------
pw.Widget _headerBand(CricketMatch match, PlayerImpact? potm) {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(20),
    decoration: pw.BoxDecoration(
      color: _band,
      borderRadius: pw.BorderRadius.circular(14),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Container(
              width: 9,
              height: 9,
              decoration: pw.BoxDecoration(color: _green, shape: pw.BoxShape.circle),
            ),
            pw.SizedBox(width: 7),
            pw.Text(
              'CRICLIVE',
              style: pw.TextStyle(
                color: _green,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 1.6,
              ),
            ),
            pw.Spacer(),
            pw.Text(
              DateFormat('d MMM yyyy').format(match.createdAt),
              style: pw.TextStyle(color: _onBand, fontSize: 9),
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Text(
          '${match.team1}  vs  ${match.team2}',
          style: pw.TextStyle(
            color: PdfColors.white,
            fontSize: 23,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          '${_ballLabel(match)} ball  -  ${match.overs} overs per side',
          style: pw.TextStyle(color: _onBand, fontSize: 10),
        ),
        if (match.resultText != null) ...[
          pw.SizedBox(height: 14),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: pw.BoxDecoration(
              color: _green,
              borderRadius: pw.BorderRadius.circular(20),
            ),
            child: pw.Text(
              match.resultText!,
              style: pw.TextStyle(
                color: _band,
                fontSize: 10.5,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
        if (potm != null) ...[
          pw.SizedBox(height: 12),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(
                width: 7,
                height: 7,
                decoration: pw.BoxDecoration(color: _amber, shape: pw.BoxShape.circle),
              ),
              pw.SizedBox(width: 7),
              pw.Text(
                'Player of the Match: ',
                style: pw.TextStyle(color: _onBand, fontSize: 10),
              ),
              pw.Text(
                potm.name,
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

// ---- Innings card ----------------------------------------------------------
pw.Widget _inningsCard(Innings inn, int index) {
  return pw.Container(
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: _line),
      borderRadius: pw.BorderRadius.circular(12),
    ),
    child: pw.Column(
      children: [
        // Title bar: team + score.
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: pw.BoxDecoration(
            color: _green,
            borderRadius: const pw.BorderRadius.only(
              topLeft: pw.Radius.circular(11),
              topRight: pw.Radius.circular(11),
            ),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Expanded(
                child: pw.Text(
                  inn.battingTeam,
                  style: pw.TextStyle(
                    color: _band,
                    fontSize: 13.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Text(
                '${inn.runs}/${inn.wickets}',
                style: pw.TextStyle(
                  color: _band,
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(width: 6),
              pw.Text(
                '(${inn.oversText} ov)',
                style: pw.TextStyle(color: _band, fontSize: 10),
              ),
            ],
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _battingTable(inn),
              pw.SizedBox(height: 8),
              _extrasTotal(inn),
              pw.SizedBox(height: 14),
              _sectionLabel('BOWLING'),
              pw.SizedBox(height: 6),
              _bowlingTable(inn),
            ],
          ),
        ),
      ],
    ),
  );
}

pw.Widget _sectionLabel(String text) => pw.Text(
      text,
      style: pw.TextStyle(
        color: _muted,
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        letterSpacing: 1,
      ),
    );

// ---- Batting table (Column of Rows, so the innings card never splits) ------
const _batFlex = [50, 12, 12, 12, 12, 18];
const _bowlFlex = [42, 12, 12, 12, 12, 18];

pw.Widget _battingTable(Innings inn) {
  final batsmen = inn.batsmenInOrder;
  return pw.Column(
    children: [
      _row(
        _batFlex,
        bg: _headFill,
        cells: [
          _headerCell('BATTER', left: true),
          _headerCell('R'),
          _headerCell('B'),
          _headerCell('4s'),
          _headerCell('6s'),
          _headerCell('SR'),
        ],
      ),
      for (var i = 0; i < batsmen.length; i++)
        _row(
          _batFlex,
          bg: i.isOdd ? _stripe : null,
          cells: [
            pw.Padding(
              padding: _cellPad,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    batsmen[i],
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _ink),
                  ),
                  pw.SizedBox(height: 1),
                  pw.Text(
                    dismissalText(inn, batsmen[i]),
                    style: pw.TextStyle(fontSize: 7.5, color: _muted, fontStyle: pw.FontStyle.italic),
                  ),
                ],
              ),
            ),
            _numCell('${inn.batStat(batsmen[i]).runs}', bold: true),
            _numCell('${inn.batStat(batsmen[i]).balls}'),
            _numCell('${inn.batStat(batsmen[i]).fours}'),
            _numCell('${inn.batStat(batsmen[i]).sixes}'),
            _numCell(inn.batStat(batsmen[i]).strikeRate.toStringAsFixed(1)),
          ],
        ),
    ],
  );
}

// ---- Bowling table ---------------------------------------------------------
pw.Widget _bowlingTable(Innings inn) {
  final bowlers = inn.bowlersUsed;
  return pw.Column(
    children: [
      _row(
        _bowlFlex,
        bg: _headFill,
        cells: [
          _headerCell('BOWLER', left: true),
          _headerCell('O'),
          _headerCell('M'),
          _headerCell('R'),
          _headerCell('W'),
          _headerCell('Econ'),
        ],
      ),
      for (var i = 0; i < bowlers.length; i++)
        _row(
          _bowlFlex,
          bg: i.isOdd ? _stripe : null,
          cells: [
            pw.Padding(
              padding: _cellPad,
              child: pw.Text(
                bowlers[i],
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _ink),
              ),
            ),
            _numCell(inn.bowlStat(bowlers[i]).oversText),
            _numCell('${inn.maidensFor(bowlers[i])}'),
            _numCell('${inn.bowlStat(bowlers[i]).runsConceded}'),
            _numCell('${inn.bowlStat(bowlers[i]).wickets}', bold: true),
            _numCell(inn.bowlStat(bowlers[i]).economy.toStringAsFixed(1)),
          ],
        ),
    ],
  );
}

/// One stat row: flex-weighted cells with an optional background tint.
pw.Widget _row(List<int> flex, {required List<pw.Widget> cells, PdfColor? bg}) {
  return pw.Container(
    color: bg,
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < cells.length; i++) pw.Expanded(flex: flex[i], child: cells[i]),
      ],
    ),
  );
}

// ---- Extras / total strip --------------------------------------------------
pw.Widget _extrasTotal(Innings inn) {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: pw.BoxDecoration(
      color: _headFill,
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Row(
      children: [
        pw.Text('EXTRAS',
            style: pw.TextStyle(fontSize: 8.5, color: _muted, fontWeight: pw.FontWeight.bold, letterSpacing: 0.5)),
        pw.SizedBox(width: 6),
        pw.Text('${inn.extras}',
            style: pw.TextStyle(fontSize: 10, color: _ink, fontWeight: pw.FontWeight.bold)),
        pw.Spacer(),
        pw.Text('TOTAL  ',
            style: pw.TextStyle(fontSize: 8.5, color: _muted, fontWeight: pw.FontWeight.bold, letterSpacing: 0.5)),
        pw.Text(
          '${inn.runs}/${inn.wickets}  (${inn.oversText} ov)',
          style: pw.TextStyle(fontSize: 11, color: _ink, fontWeight: pw.FontWeight.bold),
        ),
      ],
    ),
  );
}

// ---- Cell helpers ----------------------------------------------------------
pw.Widget _headerCell(String text, {bool left = false}) => pw.Padding(
      padding: _cellPad,
      child: pw.Text(
        text,
        textAlign: left ? pw.TextAlign.left : pw.TextAlign.right,
        style: pw.TextStyle(
          fontSize: 8.5,
          fontWeight: pw.FontWeight.bold,
          color: _muted,
          letterSpacing: 0.4,
        ),
      ),
    );

pw.Widget _numCell(String text, {bool bold = false}) => pw.Padding(
      padding: _cellPad,
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.right,
        style: pw.TextStyle(
          fontSize: 10,
          color: _ink,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );

// ---- Footer ----------------------------------------------------------------
pw.Widget _footer(pw.Context context) => pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        'Generated by CricLive     Page ${context.pageNumber} of ${context.pagesCount}',
        style: pw.TextStyle(fontSize: 8, color: _muted),
      ),
    );
