# Mock Exam ToR

## Goal

Build a full IELTS mock exam flow where a student can start, continue, finish, retake, and review history for assigned mock exams.

The mock exam contains 4 component sections:

- Speaking
- Listening
- Reading
- Writing

Each component section can contain one or more sub sections. Examples:

- Speaking Part 1
- Speaking Part 2
- Speaking Part 3
- Writing Task 1
- Writing Task 2

Some component sections do not require sub sections and can start directly, for example Listening and Reading.

## Mobile ToR

### Mock Exam List

- Show assigned mock exams from the existing mock exam list API.
- Each item opens the mock exam overview screen.
- If a mock exam is finished, show finished status and allow opening result/retake flow.
- If a mock exam is started but not finished, allow continuing from the current available component/sub section.

### Mock Exam Overview Screen

- After selecting a mock exam, open an overview screen similar to the provided design.
- Show 4 component section cards:
  - Speaking
  - Listening
  - Reading
  - Writing
- Show cards in backend-provided order.
- If backend order is missing, default order must be agreed and kept consistent. Current requested preferred flow is:
  - Speaking
  - Listening
  - Reading
  - Writing
- Each component card must show:
  - component name
  - status: locked, available, in progress, completed
  - remaining time if running
  - score/band if completed and available
- Top right should have a history icon.
- Tapping history icon opens a bottom sheet with all finished attempt history for this mock exam.
- Bottom area should contain a `Finish exam` button.
- `Finish exam` should be available anytime after the exam is started.
- Tapping `Finish exam` calls backend finish API and then opens result screen.

### Locking and Availability Rules

- Only the first available component can be started initially.
- Components must unlock in order.
- A student cannot start the second component before finishing the first.
- The same rule applies to sub sections:
  - Speaking Part 2 cannot start before Speaking Part 1 is finished.
  - Writing Task 2 cannot start before Writing Task 1 is finished.
- Finished components/sub sections can be opened in result/review mode.
- Current component can be resumed while time remains and it is not finished.

### Timers

- Mobile must not calculate authoritative deadlines by itself.
- Backend must return:
  - started time
  - finish/deadline time
  - remaining seconds or enough data to calculate remaining time
- Mobile shows countdown using backend time values.
- If countdown reaches zero:
  - mobile automatically calls finish endpoint for the current component/sub section or whole mock exam, depending on backend contract.
  - UI must move to the next allowed state.
- Backend must still be authoritative and reject/ignore late submissions.

### Answering Questions

- Questions should use existing lesson/assignment section UI where possible.
- Student can change answers inside the current component section until that component section is finished or time expires.
- Mobile must allow navigating back to already answered questions in the current unfinished component section.
- If question is already answered and component section is still in progress:
  - answer should be editable.
  - submit should update the answer, not create duplicate answer rows.
- If component section is finished:
  - questions open in review/result mode.
  - answers cannot be changed.
- Mobile should avoid sending submit requests for locked or finished sections.

### Result Screen

- After finishing the whole mock exam, show result screen.
- Result screen must display band scores:
  - Overall
  - Listening
  - Reading
  - Writing
  - Speaking
- Result screen must have `Retake exam` button.
- `Retake exam` sends request to backend and starts a fresh attempt.
- Previous attempts must remain available in history.

### History Bottom Sheet

- Opened by icon on mock exam overview/result screen.
- Shows all finished attempts for this mock exam.
- Each item should show:
  - attempt number
  - started date/time
  - finished date/time
  - overall band
  - component bands
- Tapping a history item can open a read-only result detail if backend supports it.

## Backend ToR

### Data Model Requirements

Backend should support these main entities:

- MockExam
- MockExamAssignment
- MockExamAttempt
- MockExamComponent
- MockExamSubSection
- MockExamQuestion
- MockExamAnswerOption
- MockExamStudentAnswer
- MockExamAttemptResult

### Mock Exam Structure

Mock exam detail should return component sections grouped by IELTS component:

```json
{
  "mockExam": {
    "id": "mock-id",
    "title": "Full IELTS Mock Test",
    "description": "Simulate the full exam before test day"
  },
  "attempt": {
    "id": "attempt-id",
    "is_started": true,
    "is_finished": false,
    "started_at": "2026-05-05T12:23:00+05:00",
    "finished_at": null,
    "current_component": "speaking",
    "current_sub_section_id": "speaking-part-1-id"
  },
  "components": [
    {
      "id": "component-id",
      "type": "speaking",
      "title": "Speaking",
      "order_index": 0,
      "status": "in_progress",
      "is_available": true,
      "is_completed": false,
      "started_at": "2026-05-05T12:23:00+05:00",
      "deadline_at": "2026-05-05T12:38:00+05:00",
      "time_limit_seconds": 900,
      "time_remaining_seconds": 650,
      "band_score": null,
      "sub_sections": [
        {
          "id": "sub-section-id",
          "type": "speaking_part1",
          "title": "Speaking Part 1",
          "order_index": 0,
          "status": "in_progress",
          "is_available": true,
          "is_completed": false,
          "started_at": "2026-05-05T12:23:00+05:00",
          "deadline_at": "2026-05-05T12:28:00+05:00",
          "time_limit_seconds": 300,
          "time_remaining_seconds": 120,
          "questions_count": 5,
          "answered_questions_count": 2
        }
      ]
    }
  ]
}
```

### Component Types

Backend should use stable type values:

- `speaking`
- `listening`
- `reading`
- `writing`

Sub section type values:

- `speaking_part1`
- `speaking_part2`
- `speaking_part3`
- `writing_task1`
- `writing_task2`
- `listening`
- `reading`

### Status Values

Use stable status values for components and sub sections:

- `locked`
- `available`
- `in_progress`
- `completed`
- `expired`

Backend must calculate these statuses. Mobile should not infer lock state only from local order.

### Start / Continue Flow

Backend should provide endpoint to start or continue a mock exam attempt.

Suggested endpoint:

```http
POST /student/ielts-mocks/{mockExamId}/attempts/start
```

Response:

```json
{
  "attempt_id": "attempt-id",
  "is_finished": false,
  "current_component": "speaking",
  "current_sub_section_id": "speaking-part-1-id",
  "components": []
}
```

If unfinished attempt already exists, return existing attempt instead of creating duplicate.

### Section Detail API

Backend should return section/sub section detail with questions and existing student answers.

```http
GET /student/ielts-mocks/{mockExamId}/attempts/{attemptId}/sections/{sectionId}
```

Response should include:

- section id
- type
- title
- content
- order index
- time fields
- is available
- is completed
- questions
- student answers if present

Question object should include:

```json
{
  "id": "question-id",
  "type": "multiple-choice",
  "title": "Questions 1-4",
  "description": "Question text",
  "order_index": 0,
  "isAnswered": true,
  "studentAnswer": {
    "id": "student-answer-id",
    "selected_answer_id": "answer-id",
    "answer_text": null,
    "blank_answers": null,
    "audio_file_id": null,
    "is_correct": null
  },
  "answers": [
    {
      "id": "answer-id",
      "answer_text": "A - Example",
      "order_index": 0,
      "is_correct": null
    }
  ]
}
```

For unfinished sections, backend may hide `is_correct`.
For finished/review sections, backend can return correctness and correct answers if desired.

### Submit / Update Answers

Backend should allow answer updates while the component/sub section is not finished and time has not expired.

Suggested endpoint:

```http
POST /student/ielts-mocks/{mockExamId}/attempts/{attemptId}/sections/{sectionId}/submit
```

Payload:

```json
{
  "answers": [
    {
      "questionId": "question-id",
      "selected_answer_id": "answer-id"
    }
  ]
}
```

Only relevant fields should be sent:

- Choice question:
  - `questionId`
  - `selected_answer_id`
- Fill blank:
  - `questionId`
  - `blank_answers`
- Writing:
  - `questionId`
  - `answer_text`
- Speaking:
  - `questionId`
  - `audio_file_id`

Backend rules:

- If answer already exists and section is still active, update it.
- Do not return 409 for updating answer during active section.
- Return 409 only if section/component/exam is finished or expired.
- Return clear error body:

```json
{
  "message": "Section is already finished.",
  "code": "SECTION_FINISHED"
}
```

### Finish Component / Sub Section

Backend should provide endpoint to finish current component or sub section.

Suggested endpoint:

```http
POST /student/ielts-mocks/{mockExamId}/attempts/{attemptId}/sections/{sectionId}/finish
```

Behavior:

- Marks section as completed.
- Calculates raw score for the section.
- Unlocks next sub section or next component.
- If all components are completed, marks mock exam attempt as ready to finish or auto-finished based on backend policy.

### Finish Whole Mock Exam

Backend should provide endpoint to finish exam anytime.

Suggested endpoint:

```http
POST /student/ielts-mocks/{mockExamId}/attempts/{attemptId}/finish
```

Behavior:

- Marks attempt as finished.
- Stops all timers.
- Locks all answer editing.
- Calculates component scores and overall IELTS band.
- Creates immutable result history row.

Response:

```json
{
  "attempt_id": "attempt-id",
  "is_finished": true,
  "overall_band": 6.5,
  "listening_band": 6.0,
  "reading_band": 7.0,
  "writing_band": 5.5,
  "speaking_band": 6.0
}
```

### Result API

```http
GET /student/ielts-mocks/{mockExamId}/attempts/{attemptId}/result
```

Response:

```json
{
  "attempt_id": "attempt-id",
  "mock_exam_id": "mock-id",
  "started_at": "2026-05-05T12:23:00+05:00",
  "finished_at": "2026-05-05T14:23:00+05:00",
  "overall_band": 6.5,
  "listening_band": 6.0,
  "reading_band": 7.0,
  "writing_band": 5.5,
  "speaking_band": 6.0,
  "components": [
    {
      "type": "listening",
      "band_score": 6.0,
      "total_questions": 40,
      "correct": 23
    }
  ]
}
```

### Retake Exam

Backend should provide retake endpoint.

```http
POST /student/ielts-mocks/{mockExamId}/retake
```

Behavior:

- Creates new attempt or resets current active attempt.
- Must not delete previous finished attempts.
- Sets new attempt `is_finished` to false.
- Clears previous answers for the new attempt.
- Returns new attempt detail.

### Results History API

Backend should return all finished attempts for current user and mock exam.

```http
GET /student/ielts-mocks/{mockExamId}/results/history
```

Response:

```json
{
  "items": [
    {
      "attempt_id": "attempt-id",
      "attempt_number": 1,
      "started_at": "2026-05-05T12:23:00+05:00",
      "finished_at": "2026-05-05T14:23:00+05:00",
      "overall_band": 6.5,
      "listening_band": 6.0,
      "reading_band": 7.0,
      "writing_band": 5.5,
      "speaking_band": 6.0
    }
  ],
  "total": 1
}
```

### Timing Rules

Backend must be authoritative for time.

Required backend behavior:

- Return server-based `deadline_at` and/or `time_remaining_seconds`.
- Reject submissions after deadline.
- Auto-finish expired section/component when requested after deadline.
- Allow mobile to resume active attempt using remaining backend time.
- Never rely only on client-side timer for grading or locking.

### Grading Rules

Backend should calculate IELTS-style bands:

- Listening band
- Reading band
- Writing band
- Speaking band
- Overall band

Writing and speaking may require teacher/AI/manual grading. Backend should support pending score state:

- `pending`
- numeric band score when graded

If score is pending, result API should still return the attempt and mark pending components clearly.

### Relations

Recommended relations:

- User has many MockExamAttempts.
- MockExam has many MockExamComponents.
- MockExamComponent has many MockExamSubSections.
- MockExamSubSection has many MockExamQuestions.
- MockExamQuestion has many MockExamAnswerOptions.
- MockExamAttempt has many MockExamStudentAnswers.
- MockExamAttempt has one MockExamAttemptResult after finish.
- Finished results must be immutable for history.

## Acceptance Criteria

- Mobile can show full mock exam overview with 4 ordered component sections.
- Locked sections cannot be opened.
- Sub sections unlock in order.
- Active section answers can be changed before finish/time expiry.
- Expired or finished sections cannot be edited.
- User can leave and return to continue an active attempt.
- User can finish exam anytime.
- Backend returns final IELTS band scores.
- User can retake finished mock exam.
- History API returns all previous finished attempts.
- Mobile can show history in bottom sheet.
