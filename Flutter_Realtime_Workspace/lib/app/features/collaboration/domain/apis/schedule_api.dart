import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_realtime_workspace/core/config/environment.dart';

class ScheduleApi {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: '${Environment.baseUrl}schedule-meet',
      connectTimeout: const Duration(minutes: 2),
      receiveTimeout: const Duration(minutes: 2),
      sendTimeout: const Duration(minutes: 2),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  static Future<String> _getToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Not authenticated");
    final token = await user.getIdToken(true);
    if (token == null) throw Exception("Failed to retrieve ID token");
    print('[ScheduleApi] Firebase ID token: $token');
    return token;
  }

  // CREATE
  static Future<dynamic> createMeeting(dynamic data) async {
    print('[ScheduleApi] createMeeting called with data: $data');
    final idToken = await _getToken();
    try {
      final response = await _dio.post(
        "/",
        data: data,
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[ScheduleApi] createMeeting response: ${response.data}');
      return response.data;
    } catch (e) {
      print('[ScheduleApi][ERROR] createMeeting: $e');
      rethrow;
    }
  }

  static Future<dynamic> createMeetingTemplate(dynamic data) async {
    print('[ScheduleApi] createMeetingTemplate called with data: $data');
    final idToken = await _getToken();
    try {
      final response = await _dio.post(
        "/template",
        data: data,
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[ScheduleApi] createMeetingTemplate response: ${response.data}');
      return response.data;
    } catch (e) {
      print('[ScheduleApi][ERROR] createMeetingTemplate: $e');
      rethrow;
    }
  }

  static Future<dynamic> createFromTemplate(String templateId, dynamic data) async {
    print('[ScheduleApi] createFromTemplate called with templateId: $templateId, data: $data');
    final idToken = await _getToken();
    try {
      final response = await _dio.post(
        "/from-template/$templateId",
        data: data,
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[ScheduleApi] createFromTemplate response: ${response.data}');
      return response.data;
    } catch (e) {
      print('[ScheduleApi][ERROR] createFromTemplate: $e');
      rethrow;
    }
  }

  // READ
  static Future<dynamic> getAllMeetings({Map<String, dynamic>? params}) async {
    print('[ScheduleApi] getAllMeetings called with params: $params');
    final idToken = await _getToken();
    try {
      final response = await _dio.get(
        "/",
        queryParameters: params,
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[ScheduleApi] getAllMeetings response: ${response.data}');
      return response.data;
    } catch (e) {
      print('[ScheduleApi][ERROR] getAllMeetings: $e');
      rethrow;
    }
  }

  static Future<dynamic> getMeetingById(String id) async {
    print('[ScheduleApi] getMeetingById called with id: $id');
    final idToken = await _getToken();
    try {
      final response = await _dio.get(
        "/$id",
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[ScheduleApi] getMeetingById response: ${response.data}');
      return response.data;
    } catch (e) {
      print('[ScheduleApi][ERROR] getMeetingById: $e');
      rethrow;
    }
  }

  static Future<dynamic> getUserMeetings(String userId, {Map<String, dynamic>? params}) async {
    print('[ScheduleApi] getUserMeetings called with userId: $userId, params: $params');
    final idToken = await _getToken();
    try {
      final response = await _dio.get(
        "/user/$userId",
        queryParameters: params,
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[ScheduleApi] getUserMeetings response: ${response.data}');
      return response.data;
    } catch (e) {
      print('[ScheduleApi][ERROR] getUserMeetings: $e');
      rethrow;
    }
  }

  static Future<dynamic> getTodaysMeetings(String userId) async {
    print('[ScheduleApi] getTodaysMeetings called with userId: $userId');
    final idToken = await _getToken();
    try {
      final response = await _dio.get(
        "/user/$userId/today",
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[ScheduleApi] getTodaysMeetings response: ${response.data}');
      return response.data;
    } catch (e) {
      print('[ScheduleApi][ERROR] getTodaysMeetings: $e');
      rethrow;
    }
  }

  static Future<dynamic> getUpcomingMeetings(String userId, {int limit = 10}) async {
    print('[ScheduleApi] getUpcomingMeetings called with userId: $userId, limit: $limit');
    final idToken = await _getToken();
    try {
      final response = await _dio.get(
        "/user/$userId/upcoming",
        queryParameters: {"limit": limit},
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[ScheduleApi] getUpcomingMeetings response: ${response.data}');
      return response.data;
    } catch (e) {
      print('[ScheduleApi][ERROR] getUpcomingMeetings: $e');
      rethrow;
    }
  }

  static Future<dynamic> getUserInvitations(String userId, {Map<String, dynamic>? params}) async {
    print('[ScheduleApi] getUserInvitations called with userId: $userId, params: $params');
    final idToken = await _getToken();
    try {
      final response = await _dio.get(
        "/user/$userId/invitations",
        queryParameters: params,
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[ScheduleApi] getUserInvitations response: ${response.data}');
      return response.data;
    } catch (e) {
      print('[ScheduleApi][ERROR] getUserInvitations: $e');
      rethrow;
    }
  }

  static Future<dynamic> getUserConflicts(String userId, {Map<String, dynamic>? params}) async {
    print('[ScheduleApi] getUserConflicts called with userId: $userId, params: $params');
    final idToken = await _getToken();
    try {
      final response = await _dio.get(
        "/user/$userId/conflicts",
        queryParameters: params,
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[ScheduleApi] getUserConflicts response: ${response.data}');
      return response.data;
    } catch (e) {
      print('[ScheduleApi][ERROR] getUserConflicts: $e');
      rethrow;
    }
  }

  static Future<dynamic> getCalendarView(String userId, {Map<String, dynamic>? params}) async {
    print('[ScheduleApi] getCalendarView called with userId: $userId, params: $params');
    final idToken = await _getToken();
    try {
      final response = await _dio.get(
        "/user/$userId/calendar",
        queryParameters: params,
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[ScheduleApi] getCalendarView response: ${response.data}');
      return response.data;
    } catch (e) {
      print('[ScheduleApi][ERROR] getCalendarView: $e');
      rethrow;
    }
  }

  static Future<dynamic> getUserMeetingStats(String userId, {Map<String, dynamic>? params}) async {
    print('[ScheduleApi] getUserMeetingStats called with userId: $userId, params: $params');
    final idToken = await _getToken();
    try {
      final response = await _dio.get(
        "/user/$userId/stats",
        queryParameters: params,
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[ScheduleApi] getUserMeetingStats response: ${response.data}');
      return response.data;
    } catch (e) {
      print('[ScheduleApi][ERROR] getUserMeetingStats: $e');
      rethrow;
    }
  }

  static Future<dynamic> getMeetingAnalytics(String companyName, {Map<String, dynamic>? params}) async {
    print('[ScheduleApi] getMeetingAnalytics called with companyName: $companyName, params: $params');
    final idToken = await _getToken();
    try {
      final response = await _dio.get(
        "/analytics/$companyName",
        queryParameters: params,
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[ScheduleApi] getMeetingAnalytics response: ${response.data}');
      return response.data;
    } catch (e) {
      print('[ScheduleApi][ERROR] getMeetingAnalytics: $e');
      rethrow;
    }
  }

  static Future<dynamic> getMeetingTemplates({Map<String, dynamic>? params}) async {
    print('[ScheduleApi] getMeetingTemplates called with params: $params');
    final idToken = await _getToken();
    try {
      final response = await _dio.get(
        "/templates",
        queryParameters: params,
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[ScheduleApi] getMeetingTemplates response: ${response.data}');
      return response.data;
    } catch (e) {
      print('[ScheduleApi][ERROR] getMeetingTemplates: $e');
      rethrow;
    }
  }

  static Future<dynamic> searchMeetings({Map<String, dynamic>? params}) async {
    print('[ScheduleApi] searchMeetings called with params: $params');
    final idToken = await _getToken();
    try {
      final response = await _dio.get(
        "/search",
        queryParameters: params,
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[ScheduleApi] searchMeetings response: ${response.data}');
      return response.data;
    } catch (e) {
      print('[ScheduleApi][ERROR] searchMeetings: $e');
      rethrow;
    }
  }

  static Future<dynamic> exportMeetingData({Map<String, dynamic>? params}) async {
    print('[ScheduleApi] exportMeetingData called with params: $params');
    final idToken = await _getToken();
    try {
      final response = await _dio.get(
        "/export",
        queryParameters: params,
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[ScheduleApi] exportMeetingData response: ${response.data}');
      return response.data;
    } catch (e) {
      print('[ScheduleApi][ERROR] exportMeetingData: $e');
      rethrow;
    }
  }

  // UPDATE
  static Future<dynamic> updateMeeting(String id, dynamic data) async {
    print('[ScheduleApi] updateMeeting called with id: $id, data: $data');
    final idToken = await _getToken();
    try {
      final response = await _dio.put(
        "/$id",
        data: data,
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[ScheduleApi] updateMeeting response: ${response.data}');
      return response.data;
    } catch (e) {
      print('[ScheduleApi][ERROR] updateMeeting: $e');
      rethrow;
    }
  }

  static Future<dynamic> updateMeetingStatus(String id, dynamic data) async {
    print('[ScheduleApi] updateMeetingStatus called with id: $id, data: $data');
    final idToken = await _getToken();
    try {
      final response = await _dio.patch(
        "/$id/status",
        data: data,
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[ScheduleApi] updateMeetingStatus response: ${response.data}');
      return response.data;
    } catch (e) {
      print('[ScheduleApi][ERROR] updateMeetingStatus: $e');
      rethrow;
    }
  }

  static Future<dynamic> postponeMeeting(String id, dynamic data) async {
    print('[ScheduleApi] postponeMeeting called with id: $id, data: $data');
    final idToken = await _getToken();
    try {
      final response = await _dio.patch(
        "/$id/postpone",
        data: data,
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[ScheduleApi] postponeMeeting response: ${response.data}');
      return response.data;
    } catch (e) {
      print('[ScheduleApi][ERROR] postponeMeeting: $e');
      rethrow;
    }
  }

  static Future<dynamic> updateReminderSettings(String id, dynamic data) async {
    print('[ScheduleApi] updateReminderSettings called with id: $id, data: $data');
    final idToken = await _getToken();
    try {
      final response = await _dio.patch(
        "/$id/reminder",
        data: data,
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[ScheduleApi] updateReminderSettings response: ${response.data}');
      return response.data;
    } catch (e) {
      print('[ScheduleApi][ERROR] updateReminderSettings: $e');
      rethrow;
    }
  }

  static Future<dynamic> updateMeetingNotes(String id, String noteId, dynamic data) async {
    print('[ScheduleApi] updateMeetingNotes called with id: $id, noteId: $noteId, data: $data');
    final idToken = await _getToken();
    try {
      final response = await _dio.patch(
        "/$id/notes/$noteId",
        data: data,
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[ScheduleApi] updateMeetingNotes response: ${response.data}');
      return response.data;
    } catch (e) {
      print('[ScheduleApi][ERROR] updateMeetingNotes: $e');
      rethrow;
    }
  }

  static Future<dynamic> convertMeetingTimezone(String id, {Map<String, dynamic>? params}) async {
    print('[ScheduleApi] convertMeetingTimezone called with id: $id, params: $params');
    final idToken = await _getToken();
    try {
      final response = await _dio.patch(
        "/$id/convert-timezone",
        queryParameters: params,
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[ScheduleApi] convertMeetingTimezone response: ${response.data}');
      return response.data;
    } catch (e) {
      print('[ScheduleApi][ERROR] convertMeetingTimezone: $e');
      rethrow;
    }
  }

  static Future<dynamic> updateRecurringSeries(String id, dynamic data) async {
    print('[ScheduleApi] updateRecurringSeries called with id: $id, data: $data');
    final idToken = await _getToken();
    try {
      final response = await _dio.patch(
        "/$id/recurring",
        data: data,
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[ScheduleApi] updateRecurringSeries response: ${response.data}');
      return response.data;
    } catch (e) {
      print('[ScheduleApi][ERROR] updateRecurringSeries: $e');
      rethrow;
    }
  }

  static Future<dynamic> cancelRecurringSeries(String id, dynamic data) async {
    print('[ScheduleApi] cancelRecurringSeries called with id: $id, data: $data');
    final idToken = await _getToken();
    try {
      final response = await _dio.patch(
        "/$id/cancel-recurring",
        data: data,
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[ScheduleApi] cancelRecurringSeries response: ${response.data}');
      return response.data;
    } catch (e) {
      print('[ScheduleApi][ERROR] cancelRecurringSeries: $e');
      rethrow;
    }
  }

  static Future<dynamic> updateFollowUpStatus(String id, String actionId, dynamic data) async {
    print('[ScheduleApi] updateFollowUpStatus called with id: $id, actionId: $actionId, data: $data');
    final idToken = await _getToken();
    try {
      final response = await _dio.patch(
        "/$id/followup/$actionId",
        data: data,
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[ScheduleApi] updateFollowUpStatus response: ${response.data}');
      return response.data;
    } catch (e) {
      print('[ScheduleApi][ERROR] updateFollowUpStatus: $e');
      rethrow;
    }
  }

  // PARTICIPANT MANAGEMENT
  static Future<dynamic> addParticipant(String id, dynamic data) async {
    print('[ScheduleApi] addParticipant called with id: $id, data: $data');
    final idToken = await _getToken();
    try {
      final response = await _dio.post(
        "/$id/participants",
        data: data,
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[ScheduleApi] addParticipant response: ${response.data}');
      return response.data;
    } catch (e) {
      print('[ScheduleApi][ERROR] addParticipant: $e');
      rethrow;
    }
  }

  static Future<dynamic> removeParticipant(String id, String userId) async {
    print('[ScheduleApi] removeParticipant called with id: $id, userId: $userId');
    final idToken = await _getToken();
    try {
      final response = await _dio.delete(
        "/$id/participants/$userId",
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[ScheduleApi] removeParticipant response: ${response.data}');
      return response.data;
    } catch (e) {
      print('[ScheduleApi][ERROR] removeParticipant: $e');
      rethrow;
    }
  }

  static Future<dynamic> updateParticipantStatus(String id, String userId, dynamic data) async {
    print('[ScheduleApi] updateParticipantStatus called with id: $id, userId: $userId, data: $data');
    final idToken = await _getToken();
    try {
      final response = await _dio.patch(
        "/$id/participants/$userId/status",
        data: data,
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[ScheduleApi] updateParticipantStatus response: ${response.data}');
      return response.data;
    } catch (e) {
      print('[ScheduleApi][ERROR] updateParticipantStatus: $e');
      rethrow;
    }
  }

  static Future<dynamic> recordParticipantJoin(String id, String userId) async {
    print('[ScheduleApi] recordParticipantJoin called with id: $id, userId: $userId');
    final idToken = await _getToken();
    try {
      final response = await _dio.patch(
        "/$id/participants/$userId/join",
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[ScheduleApi] recordParticipantJoin response: ${response.data}');
      return response.data;
    } catch (e) {
      print('[ScheduleApi][ERROR] recordParticipantJoin: $e');
      rethrow;
    }
  }

  static Future<dynamic> recordParticipantLeave(String id, String userId) async {
    print('[ScheduleApi] recordParticipantLeave called with id: $id, userId: $userId');
    final idToken = await _getToken();
    try {
      final response = await _dio.patch(
        "/$id/participants/$userId/leave",
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[ScheduleApi] recordParticipantLeave response: ${response.data}');
      return response.data;
    } catch (e) {
      print('[ScheduleApi][ERROR] recordParticipantLeave: $e');
      rethrow;
    }
  }

  // ATTACHMENTS
  static Future<dynamic> addAttachment(String id, dynamic data) async {
    print('[ScheduleApi] addAttachment called with id: $id, data: $data');
    final idToken = await _getToken();
    try {
      final response = await _dio.post(
        "/$id/attachments",
        data: data,
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[ScheduleApi] addAttachment response: ${response.data}');
      return response.data;
    } catch (e) {
      print('[ScheduleApi][ERROR] addAttachment: $e');
      rethrow;
    }
  }

  static Future<dynamic> removeAttachment(String id, String attachmentId) async {
    print('[ScheduleApi] removeAttachment called with id: $id, attachmentId: $attachmentId');
    final idToken = await _getToken();
    try {
      final response = await _dio.delete(
        "/$id/attachments/$attachmentId",
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[ScheduleApi] removeAttachment response: ${response.data}');
      return response.data;
    } catch (e) {
      print('[ScheduleApi][ERROR] removeAttachment: $e');
      rethrow;
    }
  }

  // NOTES
  static Future<dynamic> addMeetingNotes(String id, dynamic data) async {
    print('[ScheduleApi] addMeetingNotes called with id: $id, data: $data');
    final idToken = await _getToken();
    try {
      final response = await _dio.post(
        "/$id/notes",
        data: data,
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[ScheduleApi] addMeetingNotes response: ${response.data}');
      return response.data;
    } catch (e) {
      print('[ScheduleApi][ERROR] addMeetingNotes: $e');
      rethrow;
    }
  }

  // RECORDINGS
  static Future<dynamic> addRecording(String id, dynamic data) async {
    print('[ScheduleApi] addRecording called with id: $id, data: $data');
    final idToken = await _getToken();
    try {
      final response = await _dio.post(
        "/$id/recordings",
        data: data,
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[ScheduleApi] addRecording response: ${response.data}');
      return response.data;
    } catch (e) {
      print('[ScheduleApi][ERROR] addRecording: $e');
      rethrow;
    }
  }

  // FOLLOW-UPS
  static Future<dynamic> addFollowUpAction(String id, dynamic data) async {
    print('[ScheduleApi] addFollowUpAction called with id: $id, data: $data');
    final idToken = await _getToken();
    try {
      final response = await _dio.post(
        "/$id/followup",
        data: data,
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[ScheduleApi] addFollowUpAction response: ${response.data}');
      return response.data;
    } catch (e) {
      print('[ScheduleApi][ERROR] addFollowUpAction: $e');
      rethrow;
    }
  }

  // BULK
  static Future<dynamic> bulkUpdateMeetings(dynamic data) async {
    print('[ScheduleApi] bulkUpdateMeetings called with data: $data');
    final idToken = await _getToken();
    try {
      final response = await _dio.patch(
        "/bulk-update",
        data: data,
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[ScheduleApi] bulkUpdateMeetings response: ${response.data}');
      return response.data;
    } catch (e) {
      print('[ScheduleApi][ERROR] bulkUpdateMeetings: $e');
      rethrow;
    }
  }

  static Future<dynamic> bulkDeleteMeetings(dynamic data) async {
    print('[ScheduleApi] bulkDeleteMeetings called with data: $data');
    final idToken = await _getToken();
    try {
      final response = await _dio.patch(
        "/bulk-delete",
        data: data,
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[ScheduleApi] bulkDeleteMeetings response: ${response.data}');
      return response.data;
    } catch (e) {
      print('[ScheduleApi][ERROR] bulkDeleteMeetings: $e');
      rethrow;
    }
  }

  // CONFLICTS
  static Future<dynamic> checkConflicts(String id) async {
    print('[ScheduleApi] checkConflicts called with id: $id');
    final idToken = await _getToken();
    try {
      final response = await _dio.get(
        "/$id/conflicts",
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[ScheduleApi] checkConflicts response: ${response.data}');
      return response.data;
    } catch (e) {
      print('[ScheduleApi][ERROR] checkConflicts: $e');
      rethrow;
    }
  }

  // AVAILABILITY
  static Future<dynamic> checkParticipantAvailability({Map<String, dynamic>? params}) async {
    print('[ScheduleApi] checkParticipantAvailability called with params: $params');
    final idToken = await _getToken();
    try {
      final response = await _dio.get(
        "/availability",
        queryParameters: params,
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[ScheduleApi] checkParticipantAvailability response: ${response.data}');
      return response.data;
    } catch (e) {
      print('[ScheduleApi][ERROR] checkParticipantAvailability: $e');
      rethrow;
    }
  }

  // INVITATIONS
  static Future<dynamic> sendInvitations(String id, dynamic data) async {
    print('[ScheduleApi] sendInvitations called with id: $id, data: $data');
    final idToken = await _getToken();
    try {
      final response = await _dio.post(
        "/$id/invitations",
        data: data,
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[ScheduleApi] sendInvitations response: ${response.data}');
      return response.data;
    } catch (e) {
      print('[ScheduleApi][ERROR] sendInvitations: $e');
      rethrow;
    }
  }

  // DELETE/RESTORE
  static Future<dynamic> deleteMeeting(String id, {dynamic data}) async {
    print('[ScheduleApi] deleteMeeting called with id: $id, data: $data');
    final idToken = await _getToken();
    try {
      final response = await _dio.delete(
        "/$id",
        data: data,
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[ScheduleApi] deleteMeeting response: ${response.data}');
      return response.data;
    } catch (e) {
      print('[ScheduleApi][ERROR] deleteMeeting: $e');
      rethrow;
    }
  }

  static Future<dynamic> permanentlyDeleteMeeting(String id) async {
    print('[ScheduleApi] permanentlyDeleteMeeting called with id: $id');
    final idToken = await _getToken();
    try {
      final response = await _dio.delete(
        "/$id/permanent",
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[ScheduleApi] permanentlyDeleteMeeting response: ${response.data}');
      return response.data;
    } catch (e) {
      print('[ScheduleApi][ERROR] permanentlyDeleteMeeting: $e');
      rethrow;
    }
  }

  static Future<dynamic> restoreMeeting(String id) async {
    print('[ScheduleApi] restoreMeeting called with id: $id');
    final idToken = await _getToken();
    try {
      final response = await _dio.patch(
        "/$id/restore",
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[ScheduleApi] restoreMeeting response: ${response.data}');
      return response.data;
    } catch (e) {
      print('[ScheduleApi][ERROR] restoreMeeting: $e');
      rethrow;
    }
  }
}
