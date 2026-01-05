class LearnQuizModel {
  final String prompt;
  final List<String> options;
  final int correctIndex;

  const LearnQuizModel({required this.prompt, required this.options, required this.correctIndex});

  static const List<LearnQuizModel> listeningSampleQuestions = [
    LearnQuizModel(
        prompt: 'Which sentence is correct?',
        options: ['I wake up at 7.', 'I waking up at 7.', 'I wakes up at 7.'],
        correctIndex: 0),
    LearnQuizModel(
        prompt: "The past tense of 'go' is 'went'.", options: ['True', 'False'], correctIndex: 0),
    LearnQuizModel(
        prompt: 'Complete: She ___ breakfast.', options: ['eats', 'eat', 'eating'], correctIndex: 0)
  ];

  static const List<LearnQuizModel> readingSampleQuestions = [
    LearnQuizModel(
      prompt: 'Read: Tom goes to school every day. What does Tom do every day?',
      options: ['He stays at home.', 'He goes to school.', 'He works at night.'],
      correctIndex: 1,
    ),
    LearnQuizModel(
      prompt: 'Read: Anna likes apples and bananas. What fruit does Anna like?',
      options: ['Only apples.', 'Only bananas.', 'Apples and bananas.'],
      correctIndex: 2,
    ),
    LearnQuizModel(
      prompt: 'Read: The store opens at 9 a.m. When does the store open?',
      options: ['At 7 a.m.', 'At 9 a.m.', 'At 12 p.m.'],
      correctIndex: 1,
    ),
    LearnQuizModel(
      prompt: 'Read: John is tired because he worked late. Why is John tired?',
      options: ['He woke up early.', 'He worked late.', 'He played games.'],
      correctIndex: 1,
    ),
    LearnQuizModel(
      prompt: 'Read: Sarah has a dog and a cat. What pets does Sarah have?',
      options: ['Two dogs.', 'A dog and a cat.', 'One cat.'],
      correctIndex: 1,
    ),
  ];
  
  static const List<LearnQuizModel> grammarSampleQuestions = [
    LearnQuizModel(
      prompt: 'Choose the correct sentence.',
      options: ['He play football.', 'He plays football.', 'He playing football.'],
      correctIndex: 1,
    ),
    LearnQuizModel(
      prompt: 'She ___ to work every day.',
      options: ['go', 'going', 'goes'],
      correctIndex: 2,
    ),
    LearnQuizModel(
      prompt: 'We ___ dinner at 8 yesterday.',
      options: ['have', 'had', 'has'],
      correctIndex: 1,
    ),
    LearnQuizModel(
      prompt: 'Choose the correct form: I am ___ now.',
      options: ['study', 'studying', 'studies'],
      correctIndex: 1,
    ),
    LearnQuizModel(
      prompt: 'There ___ two books on the table.',
      options: ['is', 'are', 'be'],
      correctIndex: 1,
    ),
    LearnQuizModel(
      prompt: 'He was born ___ 2001.',
      options: ['on', 'at', 'in'],
      correctIndex: 2,
    ),
    LearnQuizModel(
      prompt: 'Choose the correct question.',
      options: ['Where you are going?', 'Where are you going?', 'Where going you?'],
      correctIndex: 1,
    ),
  ];
}
