import 'package:dio/dio.dart';
import 'package:ustadia_user_app/features/assignments/data/models/assignment_model.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';

class AssignmentsRemoteDataSource {
  final Dio dio;

  AssignmentsRemoteDataSource({required this.dio});

  Future<List<AssignmentModel>> fetchAssignments() async {
    final response = await dio.get('/student/assignments');
    final data = response.data;
    final items =
        data is List ? data : (data as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
    return items.whereType<Map<String, dynamic>>().map(AssignmentModel.fromJson).toList();
  }

  Future<SectionModel> fetchAssignmentSectionDetail({required String sectionId}) async {
    final response = await dio.get('/student/assignments/sections/$sectionId');
    final data = response.data as Map<String, dynamic>;
    return SectionModel.fromJson(data);
  }

  Future<List<SectionModel>> fetchAssignmentSections({required String assignmentId}) async {
    final response = await dio.get('/student/assignments/$assignmentId/sections');
    final data = response.data;
    final items =
        data is List ? data : (data as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
    return items.whereType<Map<String, dynamic>>().map(SectionModel.fromJson).toList();
  }

  Future<bool> submitAssignmentAnswers(
      {required String assignmentId,
      required List<Map<String, dynamic>> answers}) async {
    final response =
        await dio.post('/student/assignments/$assignmentId/submit', data: {'answers': answers});
    final data = response.data;
    if (data is Map<String, dynamic>) return data['success'] == true;
    return false;
  }
}
