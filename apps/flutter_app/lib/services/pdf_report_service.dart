import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/analytics_report.dart';

/// Сервис для генерации PDF отчётов аналитики
class PdfReportService {
  pw.Font? _fontRegular;
  pw.Font? _fontBold;
  pw.Font? _fontEmoji;

  Future<void> _loadFonts() async {
    if (_fontRegular != null) return;
    try {
      final regularBytes = await rootBundle.load('assets/fonts/arial.ttf');
      final boldBytes = await rootBundle.load('assets/fonts/arial_bold.ttf');
      final emojiBytes = await rootBundle.load('assets/fonts/NotoEmoji-Regular.ttf');
      _fontRegular = pw.Font.ttf(regularBytes);
      _fontBold = pw.Font.ttf(boldBytes);
      _fontEmoji = pw.Font.ttf(emojiBytes);
      debugPrint('PDF: Arial + NotoEmoji загружены');
    } catch (e) {
      debugPrint('PDF: Ошибка шрифтов: $e, используем Helvetica');
      _fontRegular = pw.Font.helvetica();
      _fontBold = pw.Font.helveticaBold();
      _fontEmoji = pw.Font.helvetica();
    }
  }

  pw.TextStyle _st({double size = 12, bool b = false, PdfColor? c}) {
    return pw.TextStyle(font: b ? _fontBold : _fontRegular, fontSize: size, color: c ?? PdfColors.black);
  }

  Future<pw.Document> generateReport(AnalyticsReport report) async {
    await _loadFonts();
    final doc = pw.Document();
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      maxPages: 50,
      header: (ctx) => pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 10),
        decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.orange, width: 2))),
        child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('Отчёт аналитики Цитрус', style: _st(size: 18, b: true, c: PdfColors.orange)),
          pw.Text(report.period.label, style: _st(size: 10, c: PdfColors.grey700)),
        ]),
      ),
      footer: (ctx) => pw.Container(
        padding: const pw.EdgeInsets.only(top: 10),
        decoration: pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400, width: 0.5))),
        child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('© 2026 Цитрус', style: _st(size: 8, c: PdfColors.grey600)),
          pw.Text('Стр. ${ctx.pageNumber}', style: _st(size: 8, c: PdfColors.grey600)),
        ]),
      ),
      build: (ctx) => [
        _metrics(report.metrics),
        pw.SizedBox(height: 20),
        _moodChart(report.moodByDay),
        pw.SizedBox(height: 20),
        _moodDist(report.moodDistribution),
        pw.SizedBox(height: 20),
        _insightsList(report.insights),
        pw.SizedBox(height: 20),
        _activityStats(report.activity),
      ],
    ));
    return doc;
  }

  pw.Widget _metrics(ReportMetrics m) {
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text('Обзор', style: _st(size: 18, b: true)),
      pw.SizedBox(height: 10),
      pw.Wrap(spacing: 10, runSpacing: 10, children: [
        _mBox('Дней', m.totalDays.toString(), PdfColors.blue),
        _mBox('Хороших дней', '${m.goodDaysPercent.toStringAsFixed(0)}%', PdfColors.green),
        _mBox('Улучшение', '+${m.improvementPercent.toStringAsFixed(0)}%', PdfColors.orange),
        _mBox('Серия дней', m.streakDays.toString(), PdfColors.purple),
      ]),
    ]);
  }

  pw.Widget _mBox(String label, String value, PdfColor color) {
    return pw.Container(width: 150, padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(8), border: pw.Border.all(color: PdfColors.grey300)),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(value, style: _st(size: 20, b: true, c: color)),
        pw.SizedBox(height: 4),
        pw.Text(label, style: _st(size: 9, c: PdfColors.grey600)),
      ]),
    );
  }

  pw.Widget _moodChart(List<MoodDayData> data) {
    final ld = data.length > 14 ? data.sublist(0, 14) : data;
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text('График настроения', style: _st(size: 18, b: true)),
      pw.SizedBox(height: 10),
      pw.Container(padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(8)),
        child: pw.Column(children: ld.map((d) => pw.Padding(padding: const pw.EdgeInsets.only(bottom: 4),
          child: pw.Row(children: [
            pw.SizedBox(width: 30, child: pw.Text(d.dayName, style: _st(size: 10))),
            pw.SizedBox(width: 8),
            pw.Container(height: 12, width: (d.value / 5 * 200).clamp(0.0, 200.0),
              decoration: pw.BoxDecoration(color: d.value > 0 ? _moodCol(d.value) : PdfColors.grey300, borderRadius: pw.BorderRadius.circular(4))),
            pw.SizedBox(width: 8),
            pw.Text(d.value.toStringAsFixed(1), style: _st(size: 10)),
          ]),
        )).toList()),
      ),
    ]);
  }

  pw.Widget _moodDist(List<MoodDistribution> dist) {
    final valid = dist.where((d) => d.count > 0).toList();
    if (valid.isEmpty) return pw.Text('Нет данных', style: _st(size: 12, c: PdfColors.grey600));
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text('Распределение настроения', style: _st(size: 18, b: true)),
      pw.SizedBox(height: 10),
      ...valid.map((d) => pw.Padding(padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Row(children: [
            pw.Text(d.emoji, style: pw.TextStyle(font: _fontEmoji, fontSize: 14)),
            pw.SizedBox(width: 6),
            pw.Text(d.label, style: _st(size: 11, b: true)),
            pw.Spacer(),
            pw.Text('${d.count} (${d.percent.toStringAsFixed(0)}%)', style: _st(size: 10, c: PdfColors.grey700)),
          ]),
          pw.SizedBox(height: 4),
          pw.Container(height: 10, width: (d.percent / 100 * 300).clamp(0.0, 300.0),
            decoration: pw.BoxDecoration(color: PdfColor.fromInt(d.colorValue), borderRadius: pw.BorderRadius.circular(4))),
        ]),
      )),
    ]);
  }

  pw.Widget _insightsList(List<String> insights) {
    if (insights.isEmpty) return pw.SizedBox.shrink();
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text('Инсайты', style: _st(size: 18, b: true)),
      pw.SizedBox(height: 10),
      pw.Container(padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(color: PdfColors.orange50, borderRadius: pw.BorderRadius.circular(8), border: pw.Border.all(color: PdfColors.orange200)),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: insights.map((i) => pw.Padding(padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('\u{1F4A1}', style: pw.TextStyle(font: _fontEmoji, fontSize: 14)),
              pw.SizedBox(width: 8),
              pw.Expanded(child: pw.Text(i, style: _st(size: 10))),
            ]),
          )).toList(),
        ),
      ),
    ]);
  }

  pw.Widget _activityStats(ActivityStats a) {
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text('Активность', style: _st(size: 18, b: true)),
      pw.SizedBox(height: 10),
      _aBar('Записи настроения', a.moodRecords, 30, PdfColors.orange),
      _aBar('Сообщения в чате', a.chatMessages, 30, PdfColors.amber),
      _aBar('Упражнения', a.exercises, 30, PdfColors.green),
      _aBar('Тесты', a.tests, 30, PdfColors.red),
    ]);
  }

  pw.Widget _aBar(String label, int value, int max, PdfColor color) {
    final pct = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;
    return pw.Padding(padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Row(children: [
          pw.Text(label, style: _st(size: 10, c: PdfColors.grey700)),
          pw.Spacer(),
          pw.Text(value.toString(), style: _st(size: 12, b: true, c: color)),
        ]),
        pw.SizedBox(height: 4),
        pw.Container(height: 8, width: (pct * 300).clamp(0.0, 300.0),
          decoration: pw.BoxDecoration(color: color, borderRadius: pw.BorderRadius.circular(4))),
      ]),
    );
  }

  PdfColor _moodCol(double v) {
    if (v >= 5) return PdfColors.green;
    if (v >= 4) return PdfColors.lightGreen;
    if (v >= 3) return PdfColors.orange;
    if (v >= 2) return PdfColors.orangeAccent;
    return PdfColors.redAccent;
  }
}
