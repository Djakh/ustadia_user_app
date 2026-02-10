import 'package:ustadia_user_app/features/assignments/data/datasources/assignments_remote_data_source.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';

class AssignmentSectionsStore {
  final AssignmentsRemoteDataSource remoteDataSource;
  final Map<String, List<SectionModel>> cache = {};

  AssignmentSectionsStore({required this.remoteDataSource});

  Future<List<SectionModel>> loadSections(String assignmentId, {bool forceRefresh = false}) async {
    if (!forceRefresh && cache.containsKey(assignmentId)) {
      return cache[assignmentId] ?? [];
    }
    final list = await remoteDataSource.fetchAssignmentSections(assignmentId: assignmentId);
    cache[assignmentId] = list;
    return list;
  }
}
