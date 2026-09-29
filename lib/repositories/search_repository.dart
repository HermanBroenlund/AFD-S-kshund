import 'dart:typed_data';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/search_models.dart';

class SearchRepository {
  SearchRepository(this.client);
  final SupabaseClient client;

  String get userId => client.auth.currentUser!.id;

  Future<List<Map<String, dynamic>>> plannedSearches() async {
    final data = await client
        .from('sokshund_searches')
        .select('*, sokshund_dogs(name)')
        .eq('status', 'planned')
        .order('planned_date');
    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>> getSearch(String id) async {
    return await client.from('sokshund_searches').select('*, sokshund_dogs(name)').eq('id', id).single();
  }

  Future<String> savePlanned(SearchDraft draft) async {
    final values = {
      'company_name': draft.companyName,
      'organization_number': draft.organizationNumber,
      'contact_name': draft.contactName,
      'contact_email': draft.contactEmail,
      'contact_phone': draft.contactPhone,
      'dog_id': draft.dogId,
      'handler_id': draft.handlerId,
      'planned_date': draft.plannedDate.toIso8601String(),
      'search_area': draft.area.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
      'notes': draft.notes,
      'status': 'planned',
      'created_by': userId,
    };
    Map<String, dynamic> data;
    if (draft.id == null) {
      data = await client.from('sokshund_searches').insert(values).select('id').single();
    } else {
      data = await client.from('sokshund_searches').update(values).eq('id', draft.id!).select('id').single();
    }
    final id = data['id'] as String;
    await client.from('sokshund_calendar_events').delete().eq('linked_table', 'sokshund_searches').eq('linked_id', id).eq('event_type', 'planned_search');
    await client.from('sokshund_calendar_events').insert({
      'event_type': 'planned_search',
      'title': 'Planlagt søk: ${draft.companyName}',
      'starts_at': draft.plannedDate.toIso8601String(),
      'linked_table': 'sokshund_searches',
      'linked_id': id,
      'created_by': userId,
    });
    return id;
  }

  Future<String> startSearch({required SearchDraft draft, required WeatherSnapshot weather}) async {
    final base = _safeName(draft.companyName);
    final date = '${draft.plannedDate.year.toString().padLeft(4, '0')}-${draft.plannedDate.month.toString().padLeft(2, '0')}-${draft.plannedDate.day.toString().padLeft(2, '0')}';
    final prefix = 'RS-$base-$date';
    final existing = await client.from('sokshund_searches').select('search_name').like('search_name', '$prefix%');
    var searchName = prefix;
    if ((existing as List).isNotEmpty) searchName = '$prefix-${((existing).length + 1).toString().padLeft(2, '0')}';

    final payload = {
      'search_name': searchName,
      'company_name': draft.companyName,
      'organization_number': draft.organizationNumber,
      'contact_name': draft.contactName,
      'contact_email': draft.contactEmail,
      'contact_phone': draft.contactPhone,
      'dog_id': draft.dogId,
      'handler_id': draft.handlerId,
      'planned_date': draft.plannedDate.toIso8601String(),
      'search_area': draft.area.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
      'notes': draft.notes,
      'status': 'active',
      'started_at': DateTime.now().toIso8601String(),
      'created_by': userId,
    };

    Map<String, dynamic> row;
    if (draft.id != null) {
      row = await client.from('sokshund_searches').update(payload).eq('id', draft.id!).select().single();
    } else {
      row = await client.from('sokshund_searches').insert(payload).select().single();
    }
    final searchId = row['id'] as String;
    await client.from('sokshund_weather_snapshots').insert({
      'search_id': searchId,
      'temperature_c': weather.temperatureC,
      'wind_speed_ms': weather.windSpeedMs,
      'wind_direction_deg': weather.windDirectionDeg,
      'humidity_percent': weather.humidityPercent,
      'air_pressure_hpa': weather.airPressureHpa,
      'precipitation_mm': weather.precipitationMm,
      'fetched_at': weather.fetchedAt.toIso8601String(),
    });
    return searchId;
  }

  Future<void> addTrackPoint(String searchId, {required double lat, required double lng, double? accuracy, String source = 'handler'}) async {
    await client.from('sokshund_search_track_points').insert({
      'search_id': searchId,
      'source': source,
      'latitude': lat,
      'longitude': lng,
      'accuracy_m': accuracy,
      'recorded_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> pause(String searchId) async {
    await client.from('sokshund_searches').update({'status': 'paused'}).eq('id', searchId);
    await client.from('sokshund_search_pauses').insert({'search_id': searchId, 'paused_at': DateTime.now().toIso8601String()});
  }

  Future<void> resume(String searchId) async {
    await client.from('sokshund_searches').update({'status': 'active'}).eq('id', searchId);
    final open = await client.from('sokshund_search_pauses').select('id').eq('search_id', searchId).isFilter('resumed_at', null).order('paused_at', ascending: false).limit(1);
    if ((open as List).isNotEmpty) {
      await client.from('sokshund_search_pauses').update({'resumed_at': DateTime.now().toIso8601String()}).eq('id', open.first['id']);
    }
  }

  Future<void> complete(String searchId, String summary) async {
    await client.from('sokshund_searches').update({
      'status': 'completed',
      'completed_at': DateTime.now().toIso8601String(),
      'summary': summary,
    }).eq('id', searchId);
  }

  Future<String> uploadSearchAreaPhoto(String searchId, Uint8List bytes, String extension, {double? lat, double? lng}) async {
    final path = '$searchId/area/${DateTime.now().millisecondsSinceEpoch}.$extension';
    await client.storage.from('sokshund-search-media').uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: false));
    await client.from('sokshund_search_photos').insert({
      'search_id': searchId,
      'storage_path': path,
      'photo_type': 'search_area',
      'latitude': lat,
      'longitude': lng,
      'taken_at': DateTime.now().toIso8601String(),
      'created_by': userId,
    });
    return path;
  }

  Future<String> registerFinding({
    required String searchId,
    required String description,
    required String handling,
    required double latitude,
    required double longitude,
  }) async {
    final row = await client.from('sokshund_findings').insert({
      'search_id': searchId,
      'description': description,
      'handling': handling,
      'latitude': latitude,
      'longitude': longitude,
      'found_at': DateTime.now().toIso8601String(),
      'created_by': userId,
    }).select('id').single();
    return row['id'] as String;
  }

  Future<void> uploadFindingPhoto(String searchId, String findingId, Uint8List bytes, String extension) async {
    final path = '$searchId/findings/$findingId/${DateTime.now().millisecondsSinceEpoch}.$extension';
    await client.storage.from('sokshund-search-media').uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: false));
    await client.from('sokshund_finding_photos').insert({
      'finding_id': findingId,
      'storage_path': path,
      'taken_at': DateTime.now().toIso8601String(),
      'created_by': userId,
    });
  }

  String _safeName(String input) => input.trim().replaceAll(RegExp(r'[^A-Za-z0-9ÆØÅæøå_-]+'), '_').replaceAll(RegExp(r'_+'), '_');
}
