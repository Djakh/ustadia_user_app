

enum LearnWritingMethodType { upload, inApp }

class LearnWritingLessonModel {
  final String title;
  final String subtitle;
  final String topicTitle;
  final List<String> paragraphs;
  final int minWords;
  final String inputPlaceholder;

  const LearnWritingLessonModel({
    required this.title,
    required this.subtitle,
    required this.topicTitle,
    required this.paragraphs,
    required this.minWords,
    required this.inputPlaceholder,
  });

  static const LearnWritingLessonModel sample = LearnWritingLessonModel(
    title: 'Writing',
    subtitle: 'Reading • Beginner',
    topicTitle: 'Short messages',
    paragraphs: [
      'Short messages are a common way to communicate with friends. People use them to share information, ask questions, and stay in touch during the day. Short messages are usually sent through messaging apps on a phone.',
      'When people write short messages, they often use simple and clear language. Messages are usually short and direct because people want quick answers. For example, someone might write “Are you free today?” or “I’m on my way.”',
      'In friendly messages, people often use informal words, emojis, or abbreviations. This makes the message sound more relaxed and personal. However, it is still important to be polite and clear, even in casual conversations.',
      'Short messages are often used for making plans. Friends send messages to choose a time, place, or activity. They can also use messages to say hello, thank someone, or apologize.',
      'Writing good short messages helps people communicate faster and avoid misunderstandings.'
    ],
    minWords: 20,
    inputPlaceholder: 'Start writing here',

  );
}
