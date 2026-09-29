import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportExportService {
  ReportExportService(this.client);

  final SupabaseClient client;

  String reportName(Map<String, dynamic> report) {
    final company = _safeName((report['company_name'] ?? 'Firma').toString());
    final date = DateTime.tryParse(report['planned_date']?.toString() ?? '') ?? DateTime.now();
    return 'RS-$company-${DateFormat('yyyy-MM-dd').format(date)}';
  }

  Future<void> sharePdf(Map<String, dynamic> report, {String? handlerName}) async {
    final bytes = await _buildPdf(report, handlerName: handlerName);
    final name = '${reportName(report)}.pdf';
    final file = XFile.fromData(bytes, mimeType: 'application/pdf');
    await SharePlus.instance.share(
      ShareParams(
        files: [file],
        fileNameOverrides: [name],
        title: name,
      ),
    );
  }

  Future<void> shareDocx(Map<String, dynamic> report, {String? handlerName}) async {
    final bytes = await _buildDocx(report, handlerName: handlerName);
    final name = '${reportName(report)}.docx';
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document')],
        fileNameOverrides: [name],
        title: name,
      ),
    );
  }

  Future<Uint8List> _buildPdf(Map<String, dynamic> report, {String? handlerName}) async {
    final doc = pw.Document();
    final logo = (await rootBundle.load('assets/images/af_logo.png')).buffer.asUint8List();
    final areaPhotos = List<Map<String, dynamic>>.from(report['sokshund_search_photos'] ?? const []);
    final findings = List<Map<String, dynamic>>.from(report['sokshund_findings'] ?? const []);
    final weatherRows = List<Map<String, dynamic>>.from(report['sokshund_weather_snapshots'] ?? const []);
    final weather = weatherRows.isEmpty ? <String, dynamic>{} : weatherRows.first;

    final areaImages = <Uint8List>[];
    for (final p in areaPhotos) {
      final b = await _loadStorageBytes('sokshund-search-media', p['storage_path']?.toString());
      if (b != null) areaImages.add(b);
    }

    final findingImages = <String, List<Uint8List>>{};
    for (final f in findings) {
      final list = <Uint8List>[];
      for (final p in List<Map<String, dynamic>>.from(f['sokshund_finding_photos'] ?? const [])) {
        final b = await _loadStorageBytes('sokshund-search-media', p['storage_path']?.toString());
        if (b != null) list.add(b);
      }
      findingImages[f['id'].toString()] = list;
    }

    doc.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          margin: pw.EdgeInsets.all(34),
          pageFormat: PdfPageFormat.a4,
        ),
        header: (_) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(reportName(report), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.Image(pw.MemoryImage(logo), width: 60, height: 60),
          ],
        ),
        build: (_) => [
          pw.Text('Rapport etter søk', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 14),
          _pdfSection('Oppdrag', [
            _pdfLine('Firma', report['company_name']),
            _pdfLine('Organisasjonsnummer', report['organization_number']),
            _pdfLine('Kontaktperson', report['contact_name']),
            _pdfLine('E-post', report['contact_email']),
            _pdfLine('Telefon', report['contact_phone']),
          ]),
          _pdfSection('Gjennomføring', [
            _pdfLine('Hund', (report['sokshund_dogs'] as Map?)?['name']),
            _pdfLine('Fører', handlerName),
            _pdfLine('Planlagt dato', _dateOnly(report['planned_date'])),
            _pdfLine('Start', _dateTime(report['started_at'])),
            _pdfLine('Avsluttet', _dateTime(report['completed_at'])),
            _pdfLine('Beskrivelse', report['summary']),
            _pdfLine('Plan / notat', report['notes']),
          ]),
          _pdfSection('Vær ved oppstart', [
            _pdfLine('Temperatur', _unit(weather['temperature_c'], '°C')),
            _pdfLine('Vind', _unit(weather['wind_speed_ms'], 'm/s')),
            _pdfLine('Vindretning', _unit(weather['wind_direction_deg'], '°')),
            _pdfLine('Luftfuktighet', _unit(weather['humidity_percent'], '%')),
            _pdfLine('Lufttrykk', _unit(weather['air_pressure_hpa'], 'hPa')),
            _pdfLine('Nedbør', _unit(weather['precipitation_mm'], 'mm')),
          ]),
          if (areaImages.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text('Bilder fra søksområdet', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            ...areaImages.map((b) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 10),
                  child: pw.Image(pw.MemoryImage(b), fit: pw.BoxFit.contain, height: 280),
                )),
          ],
          pw.SizedBox(height: 8),
          pw.Text('Registrerte funn', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          if (findings.isEmpty) pw.Text('Ingen registrerte funn.'),
          ...findings.map((f) => pw.Container(
                margin: const pw.EdgeInsets.only(top: 10),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Funn ${findings.indexOf(f) + 1}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Tid: ${_dateTime(f['found_at'])}'),
                    pw.Text('Koordinat: ${f['latitude']}, ${f['longitude']}'),
                    pw.Text('Beskrivelse: ${_text(f['description'])}'),
                    pw.Text('Håndtering: ${_handling(f['handling'])}'),
                    ...?findingImages[f['id'].toString()]?.map((b) => pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 8),
                          child: pw.Image(pw.MemoryImage(b), height: 230, fit: pw.BoxFit.contain),
                        )),
                  ],
                ),
              )),
        ],
      ),
    );
    return doc.save();
  }

  pw.Widget _pdfSection(String title, List<pw.Widget> lines) => pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 12),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          border: pw.Border.all(color: PdfColors.grey300),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            ...lines,
          ],
        ),
      );

  pw.Widget _pdfLine(String label, Object? value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: pw.RichText(
          text: pw.TextSpan(
            children: [
              pw.TextSpan(text: '$label: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.TextSpan(text: _text(value)),
            ],
          ),
        ),
      );

  Future<Uint8List> _buildDocx(Map<String, dynamic> report, {String? handlerName}) async {
    final areaPhotos = List<Map<String, dynamic>>.from(report['sokshund_search_photos'] ?? const []);
    final findings = List<Map<String, dynamic>>.from(report['sokshund_findings'] ?? const []);
    final weatherRows = List<Map<String, dynamic>>.from(report['sokshund_weather_snapshots'] ?? const []);
    final weather = weatherRows.isEmpty ? <String, dynamic>{} : weatherRows.first;
    final afLogo = (await rootBundle.load('assets/images/af_logo.png')).buffer.asUint8List();

    final images = <_DocxImage>[];
    for (final p in areaPhotos) {
      final b = await _loadStorageBytes('sokshund-search-media', p['storage_path']?.toString());
      if (b != null) images.add(_DocxImage(bytes: b, section: 'Bilder fra søksområdet'));
    }
    for (final f in findings) {
      for (final p in List<Map<String, dynamic>>.from(f['sokshund_finding_photos'] ?? const [])) {
        final b = await _loadStorageBytes('sokshund-search-media', p['storage_path']?.toString());
        if (b != null) images.add(_DocxImage(bytes: b, section: 'Funn ${findings.indexOf(f) + 1}'));
      }
    }

    final body = StringBuffer();
    body.write(_docxImage('rId9', 1, cx: 1450000, cy: 1450000));
    body.write(_docxHeading('Rapport etter søk', 1));
    body.write(_docxParagraph(reportName(report), bold: true));
    body.write(_docxHeading('Oppdrag', 2));
    body.write(_docxLine('Firma', report['company_name']));
    body.write(_docxLine('Organisasjonsnummer', report['organization_number']));
    body.write(_docxLine('Kontaktperson', report['contact_name']));
    body.write(_docxLine('E-post', report['contact_email']));
    body.write(_docxLine('Telefon', report['contact_phone']));
    body.write(_docxHeading('Gjennomføring', 2));
    body.write(_docxLine('Hund', (report['sokshund_dogs'] as Map?)?['name']));
    body.write(_docxLine('Fører', handlerName));
    body.write(_docxLine('Planlagt dato', _dateOnly(report['planned_date'])));
    body.write(_docxLine('Start', _dateTime(report['started_at'])));
    body.write(_docxLine('Avsluttet', _dateTime(report['completed_at'])));
    body.write(_docxLine('Beskrivelse', report['summary']));
    body.write(_docxHeading('Vær ved oppstart', 2));
    body.write(_docxLine('Temperatur', _unit(weather['temperature_c'], '°C')));
    body.write(_docxLine('Vind', _unit(weather['wind_speed_ms'], 'm/s')));
    body.write(_docxLine('Luftfuktighet', _unit(weather['humidity_percent'], '%')));
    body.write(_docxHeading('Registrerte funn', 2));
    if (findings.isEmpty) body.write(_docxParagraph('Ingen registrerte funn.'));
    for (var i = 0; i < findings.length; i++) {
      final f = findings[i];
      body.write(_docxHeading('Funn ${i + 1}', 3));
      body.write(_docxLine('Tid', _dateTime(f['found_at'])));
      body.write(_docxLine('Koordinat', '${f['latitude']}, ${f['longitude']}'));
      body.write(_docxLine('Beskrivelse', f['description']));
      body.write(_docxLine('Håndtering', _handling(f['handling'])));
    }

    final rels = StringBuffer();
    final mediaArchive = <ArchiveFile>[];
    rels.write('<Relationship Id="rId9" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/af_logo.png"/>');
    mediaArchive.add(ArchiveFile('word/media/af_logo.png', afLogo.length, afLogo));
    var relId = 10;
    var imageNo = 2;
    String? currentSection;
    for (final img in images) {
      if (currentSection != img.section) {
        body.write(_docxHeading(img.section, 2));
        currentSection = img.section;
      }
      final rid = 'rId$relId';
      final filename = 'image$imageNo.jpg';
      rels.write('<Relationship Id="$rid" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/$filename"/>');
      body.write(_docxImage(rid, imageNo));
      mediaArchive.add(ArchiveFile('word/media/$filename', img.bytes.length, img.bytes));
      relId++;
      imageNo++;
    }

    final documentXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture"><w:body>${body.toString()}<w:sectPr><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="1000" w:right="1000" w:bottom="1000" w:left="1000"/></w:sectPr></w:body></w:document>''';

    final archive = Archive();
    void addText(String name, String value) {
      final b = utf8.encode(value);
      archive.addFile(ArchiveFile(name, b.length, b));
    }

    addText('[Content_Types].xml', '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Default Extension="jpg" ContentType="image/jpeg"/><Default Extension="png" ContentType="image/png"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/></Types>''');
    addText('_rels/.rels', '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/></Relationships>''');
    addText('word/document.xml', documentXml);
    addText('word/_rels/document.xml.rels', '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">${rels.toString()}</Relationships>''');
    for (final f in mediaArchive) {
      archive.addFile(f);
    }
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  String _docxHeading(String text, int level) => '<w:p><w:pPr><w:pStyle w:val="Heading$level"/></w:pPr><w:r><w:t>${_xml(text)}</w:t></w:r></w:p>';

  String _docxParagraph(String text, {bool bold = false}) => '<w:p><w:r>${bold ? '<w:rPr><w:b/></w:rPr>' : ''}<w:t xml:space="preserve">${_xml(text)}</w:t></w:r></w:p>';

  String _docxLine(String label, Object? value) => '<w:p><w:r><w:rPr><w:b/></w:rPr><w:t>${_xml('$label: ')}</w:t></w:r><w:r><w:t>${_xml(_text(value))}</w:t></w:r></w:p>';

  String _docxImage(String rid, int id, {int cx = 5000000, int cy = 3200000}) => '''<w:p><w:r><w:drawing><wp:inline distT="0" distB="0" distL="0" distR="0"><wp:extent cx="$cx" cy="$cy"/><wp:docPr id="$id" name="Bilde $id"/><a:graphic><a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture"><pic:pic><pic:nvPicPr><pic:cNvPr id="$id" name="Bilde $id"/><pic:cNvPicPr/></pic:nvPicPr><pic:blipFill><a:blip r:embed="$rid"/><a:stretch><a:fillRect/></a:stretch></pic:blipFill><pic:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="$cx" cy="$cy"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></pic:spPr></pic:pic></a:graphicData></a:graphic></wp:inline></w:drawing></w:r></w:p>''';

  Future<Uint8List?> _loadStorageBytes(String bucket, String? path) async {
    if (path == null || path.isEmpty) return null;
    try {
      final url = await client.storage.from(bucket).createSignedUrl(path, 300);
      final response = await http.get(Uri.parse(url));
      if (response.statusCode >= 200 && response.statusCode < 300) return response.bodyBytes;
    } catch (_) {}
    return null;
  }

  String _text(Object? value) => value == null || value.toString().trim().isEmpty ? '-' : value.toString();

  String _dateOnly(Object? value) {
    final d = DateTime.tryParse(value?.toString() ?? '');
    return d == null ? '-' : DateFormat('dd.MM.yyyy').format(d.toLocal());
  }

  String _dateTime(Object? value) {
    final d = DateTime.tryParse(value?.toString() ?? '');
    return d == null ? '-' : DateFormat('dd.MM.yyyy HH:mm').format(d.toLocal());
  }

  String _unit(Object? value, String unit) => value == null ? '-' : '$value $unit';

  String _handling(Object? value) {
    return switch (value?.toString()) {
      'tatt_med_for_destruering' => 'Tatt med for destruering',
      'destruert_pa_plass' => 'Destruert på plass',
      _ => _text(value),
    };
  }

  String _safeName(String input) => input.trim().replaceAll(RegExp(r'[^A-Za-z0-9ÆØÅæøå_-]+'), '_').replaceAll(RegExp(r'_+'), '_');

  String _xml(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}

class _DocxImage {
  const _DocxImage({required this.bytes, required this.section});
  final Uint8List bytes;
  final String section;
}
