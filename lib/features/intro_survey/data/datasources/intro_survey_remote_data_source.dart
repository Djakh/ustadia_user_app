import 'package:dio/dio.dart';
import 'package:ustadia_user_app/features/intro_survey/data/intro_survey_models.dart';

class IntroSurveyRemoteDataSource {
  final Dio dio;

  IntroSurveyRemoteDataSource({required this.dio});

  Future<List<IntroSurveyQuestionModel>> fetchQuestions({int page = 1, int limit = 10}) async {
    final response = await dio.get('/intro/questions', queryParameters: {'page': page, 'limit': limit});
    final data = response.data as Map<String, dynamic>;
    final items = data['data'] as List<dynamic>? ?? [];
    final questions = items
        .whereType<Map<String, dynamic>>()
        .map(IntroSurveyQuestionModel.fromJson)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return questions;
  }

  Future<bool> submitAnswers({required String questionId, required List<String> answerIds}) async {
    final response = await dio.post('/intro/answers/submit',
        data: {'questionId': questionId, 'answerIds': answerIds});
    final data = response.data as Map<String, dynamic>;
    return data['submitted'] == true;
  }
}
