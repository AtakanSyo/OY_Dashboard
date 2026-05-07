import 'package:oy_site/models/parsed_scan_report.dart';
import 'package:oy_site/models/session_scan_assets.dart';
import 'package:oy_site/models/session_scan_file_model.dart';
import 'package:oy_site/models/session_scan_report_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseSessionScanRepository {
  SupabaseClient get _client => Supabase.instance.client;

  Future<SessionScanReportModel?> getReportBySessionId({
    required int sessionId,
  }) async {
    final response = await _client
        .from('session_scan_reports')
        .select()
        .eq('session_id', sessionId)
        .maybeSingle();

    if (response == null) return null;

    return SessionScanReportModel.fromMap(
      Map<String, dynamic>.from(response as Map),
    );
  }

  Future<List<SessionScanFileModel>> getFilesBySessionId({
    required int sessionId,
  }) async {
    final response = await _client
        .from('session_scan_files')
        .select()
        .eq('session_id', sessionId)
        .order('file_type');

    return (response as List<dynamic>)
        .map(
          (item) => SessionScanFileModel.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<void> saveParsedReport({
    required int sessionId,
    required int patientId,
    required int expertUserId,
    required ParsedScanReport report,
  }) async {
    final model = SessionScanReportModel.fromParsedReport(
      sessionId: sessionId,
      patientId: patientId,
      expertUserId: expertUserId,
      report: report,
    );

    await _client.from('session_scan_reports').upsert(
          model.toUpsertMap(),
          onConflict: 'session_id',
        );
  }

  Future<void> saveScanFiles({
    required int sessionId,
    required int patientId,
    required int expertUserId,
    required SessionScanAssets assets,
    String? detectedPdfPath,
  }) async {
    final files = <SessionScanFileModel>[
      SessionScanFileModel.local(
        sessionId: sessionId,
        patientId: patientId,
        expertUserId: expertUserId,
        fileType: SessionScanFileTypes.pdfReport,
        path: detectedPdfPath,
      ),
      SessionScanFileModel.local(
        sessionId: sessionId,
        patientId: patientId,
        expertUserId: expertUserId,
        fileType: SessionScanFileTypes.archLeftImage,
        path: assets.archLeftPath,
      ),
      SessionScanFileModel.local(
        sessionId: sessionId,
        patientId: patientId,
        expertUserId: expertUserId,
        fileType: SessionScanFileTypes.archRightImage,
        path: assets.archRightPath,
      ),
      SessionScanFileModel.local(
        sessionId: sessionId,
        patientId: patientId,
        expertUserId: expertUserId,
        fileType: SessionScanFileTypes.archSectionLeft,
        path: assets.archSectionLeftPath,
      ),
      SessionScanFileModel.local(
        sessionId: sessionId,
        patientId: patientId,
        expertUserId: expertUserId,
        fileType: SessionScanFileTypes.archSectionRight,
        path: assets.archSectionRightPath,
      ),
      SessionScanFileModel.local(
        sessionId: sessionId,
        patientId: patientId,
        expertUserId: expertUserId,
        fileType: SessionScanFileTypes.foot2dLeft,
        path: assets.foot2dLeftPath,
      ),
      SessionScanFileModel.local(
        sessionId: sessionId,
        patientId: patientId,
        expertUserId: expertUserId,
        fileType: SessionScanFileTypes.foot2dRight,
        path: assets.foot2dRightPath,
      ),
      SessionScanFileModel.local(
        sessionId: sessionId,
        patientId: patientId,
        expertUserId: expertUserId,
        fileType: SessionScanFileTypes.pronatorLeft,
        path: assets.pronatorLeftPath,
      ),
      SessionScanFileModel.local(
        sessionId: sessionId,
        patientId: patientId,
        expertUserId: expertUserId,
        fileType: SessionScanFileTypes.pronatorRight,
        path: assets.pronatorRightPath,
      ),
      SessionScanFileModel.local(
        sessionId: sessionId,
        patientId: patientId,
        expertUserId: expertUserId,
        fileType: SessionScanFileTypes.stlLeft,
        path: assets.stlLeftPath,
      ),
      SessionScanFileModel.local(
        sessionId: sessionId,
        patientId: patientId,
        expertUserId: expertUserId,
        fileType: SessionScanFileTypes.stlRight,
        path: assets.stlRightPath,
      ),
    ].where((file) {
      return file.localFilePath != null && file.localFilePath!.trim().isNotEmpty;
    }).toList();

    if (files.isEmpty) return;

    await _client.from('session_scan_files').upsert(
          files.map((file) => file.toUpsertMap()).toList(),
          onConflict: 'session_id,file_type',
        );
  }

  Future<void> saveScanData({
    required int sessionId,
    required int patientId,
    required int expertUserId,
    required ParsedScanReport? parsedReport,
    required SessionScanAssets? assets,
    String? detectedPdfPath,
  }) async {
    if (parsedReport != null) {
      await saveParsedReport(
        sessionId: sessionId,
        patientId: patientId,
        expertUserId: expertUserId,
        report: parsedReport,
      );
    }

    if (assets != null) {
      await saveScanFiles(
        sessionId: sessionId,
        patientId: patientId,
        expertUserId: expertUserId,
        assets: assets,
        detectedPdfPath: detectedPdfPath,
      );
    }
  }
}