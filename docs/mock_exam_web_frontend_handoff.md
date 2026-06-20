# Mock Exam Web Frontend Handoff

This document describes the mock exam behavior currently implemented by the Flutter student app. It is intended as an implementation handoff for the web frontend.

Last verified against:

- `lib/features/mock_exam`
- `lib/features/common/data/models/section_model`
- shared section pages and quiz components
- `lib/router.dart`
- mock exam unit, live API, and integration tests

This document is the source of truth for matching the current mobile behavior. `docs/mock_exam_tor.md` contains broader product requirements, but some parts of that file are not implemented by the current mobile client. See **Known differences from the ToR**.

## 1. Feature Scope

The student mock exam flow contains:

1. Paginated mock exam list
2. Start or continue an attempt
3. Attempt overview with IELTS components and sub-sections
4. Server-controlled locking and timers
5. Listening, reading, writing, and speaking section experiences
6. Per-question answer submission
7. Section completion
8. Whole-exam completion
9. Result view
10. Global attempt history

The current mobile implementation does not have a separate domain/use-case layer. Presentation state calls the mock exam API client directly.

## 2. Authentication and API Configuration

Development base URL:

```text
https://dev.backend.ustadia.findecor.io/student/ielts-mocks
```

All requests require the authenticated student's bearer token:

```http
Authorization: Bearer <access-token>
```

The mobile client disables response caching for list, attempt start/read, section start, and result reads. The web client should also bypass browser/query caching for attempt-sensitive calls.

Recommended web behavior:

```ts
fetch(url, {
  method,
  headers: {
    Authorization: `Bearer ${accessToken}`,
    "Content-Type": "application/json",
    "Cache-Control": "no-cache"
  },
  cache: "no-store"
});
```

Do not treat client timers as authoritative. The backend remains authoritative for expiration, locking, completion, and late submissions.

## 3. Web Routes

The current mobile equivalents are:

| Screen | Suggested web route |
|---|---|
| Mock exam list | `/mock-exam` |
| History | `/mock-exam/history` |
| Attempt overview | `/mock-exam/:mockExamId` |
| Result | `/mock-exam/:mockExamId/result/:attemptId` |

Section pages may be nested under the attempt route or shown in a dedicated exam workspace. The route structure is less important than preserving `mockExamId`, `attemptId`, and `sectionId` through every section request.

## 4. Endpoint Summary

| Purpose | Method | Path |
|---|---|---|
| List assigned mock exams | `GET` | `/student/ielts-mocks?page=1&limit=10` |
| Start or continue attempt | `POST` | `/student/ielts-mocks/{mockExamId}/attempts/start` |
| Fetch attempt by ID | `GET` | `/student/ielts-mocks/{mockExamId}/attempts/{attemptId}` |
| Start/open section detail | `POST` | `/student/ielts-mocks/{mockExamId}/attempts/{attemptId}/sections/{sectionId}/start` |
| Submit answers | `POST` | `/student/ielts-mocks/{mockExamId}/attempts/{attemptId}/sections/{sectionId}/submit` |
| Finish section | `POST` | `/student/ielts-mocks/{mockExamId}/attempts/{attemptId}/sections/{sectionId}/finish` |
| Finish whole exam | `POST` | `/student/ielts-mocks/{mockExamId}/attempts/{attemptId}/finish` |
| Fetch result | `GET` | `/student/ielts-mocks/{mockExamId}/attempts/{attemptId}/result` |
| Fetch all history | `GET` | `/student/ielts-mocks/results/all` |
| Upload speaking/writing file | `POST multipart` | `/uploads` |

Important: opening a section uses `POST .../sections/{sectionId}/start`, not `GET`.

## 5. TypeScript Data Contracts

These interfaces describe fields consumed by the mobile client. Backend responses may contain additional fields.

```ts
type MockStatus = "locked" | "available" | "in_progress" | "completed" | "expired" | string;
type SectionType =
  | "listening"
  | "reading"
  | "writing"
  | "writing_task1"
  | "writing_task2"
  | "speaking"
  | "speaking_part1"
  | "speaking_part2"
  | "speaking_part3"
  | string;

interface PaginationMeta {
  page: number;
  limit: number;
  total: number;
  totalPages: number;
}

interface MockExamListResponse extends PaginationMeta {
  items: MockExam[];
}

interface MockExam {
  id: string;
  title: string;
  description: string;
  status: string;
  teacher_id?: string;
  time_limit?: number;
  time_limit_minutes?: number;
  time_remaining_seconds?: number;
  created_at?: string;
  updated_at?: string;
  assign?: LegacyAssign | null;
  assignment?: MockAssignment | null;
  assignments?: MockAssignment[];
}

interface LegacyAssign {
  assign_id: string;
  started_at?: string | null;
  finished_at?: string | null;
  is_finished: boolean;
  time_limit_minutes?: number;
  time_remaining_seconds?: number;
  overall_band?: number | null;
  listening_band?: number | null;
  reading_band?: number | null;
  writing_band?: number | null;
  speaking_band?: number | null;
}

interface MockAssignment {
  id: string;
  class_id?: string;
  start_time?: string | null;
  end_time?: string | null;
  is_active?: boolean;
  status?: string;
  finished?: boolean;
  attempt?: AssignmentAttempt | null;
  class?: { id: string; name: string; description?: string } | null;
}

interface AssignmentAttempt {
  id: string;
  attempt_id?: string;
  status: string;
  is_started: boolean;
  is_finished: boolean;
  started_at?: string | null;
  finished_at?: string | null;
  current_component_id?: string;
  current_sub_section_id?: string;
}
```

### Attempt and component contracts

```ts
interface MockAttemptResponse {
  attempt?: MockAttempt;
  attempt_id?: string;
  id?: string;
  mock_exam_id?: string;
  status?: string;
  is_finished?: boolean;
  started_at?: string | null;
  finished_at?: string | null;
  time_limit_minutes?: number;
  time_remaining_seconds?: number;
  current_component?: string;
  current_sub_section_id?: string;
  components?: MockComponent[];
}

interface MockAttempt {
  attempt_id?: string;
  id?: string;
  mock_exam_id?: string;
  status: string;
  is_finished: boolean;
  started_at?: string | null;
  finished_at?: string | null;
  time_limit_minutes?: number;
  time_remaining_seconds?: number;
  current_component?: string;
  current_sub_section_id?: string;
  components?: MockComponent[];
}

interface MockComponent {
  id: string;
  type: SectionType;
  title?: string;
  order_index?: number;
  status: MockStatus;
  is_available?: boolean;
  is_completed?: boolean;
  time_limit_seconds?: number | null;
  time_remaining_seconds?: number | null;
  band_score?: number | null;
  sub_sections?: MockSectionSummary[];
}

interface MockSectionSummary {
  id: string;
  section_id?: string;
  sub_section_id?: string;
  type: SectionType;
  title?: string;
  content?: string;
  order_index?: number;
  status: MockStatus;
  is_available?: boolean;
  is_completed?: boolean;
  isLocked?: boolean;
  time_limit_seconds?: number | null;
  time_remaining_seconds?: number | null;
  deadline_at?: string | null;
  questions_count?: number;
  answered_questions_count?: number;
}
```

Sort components and `sub_sections` ascending by `order_index`.

For components without `sub_sections`, the component object itself is treated as the direct section. Its `id`, `type`, status, availability, timer, and question metadata must therefore be section-compatible.

### Section detail and question contracts

The section-start endpoint is currently tolerant of multiple wrappers. Normalize the response in this order:

```ts
const payload = response.data ?? response;
const section =
  payload.section ??
  payload.sub_section ??
  payload.subSection ??
  payload.current_section ??
  payload.currentSection ??
  payload.section_detail ??
  payload.sectionDetail ??
  payload;
```

Merge these wrapper fields into the normalized section when they are absent on `section`:

- `questions`
- `time_remaining_seconds` / `timeRemainingSeconds`
- `time_limit_seconds` / `timeLimitSeconds`
- `deadline_at` / `deadlineAt`
- `status`
- audio fields listed below

```ts
interface MockSectionDetail extends MockSectionSummary {
  unit_id?: string;
  lesson_id?: string;
  questions: MockQuestion[];
  audio_file_id?: string | null;
  audio_file?: AudioFile | string | null;
  audio?: AudioFile | string | null;
  audio_url?: string | null;
  flashcard_set_id?: string | null;
  flashcard_set?: unknown;
}

interface AudioFile {
  id?: string;
  filename?: string;
  path?: string;
  mimetype?: string;
  url?: string;
  audio_url?: string;
  file_url?: string;
  created_at?: string;
  file?: AudioFile | string;
  audio_file?: AudioFile | string;
}

interface MockQuestion {
  id: string;
  section_id?: string;
  sub_section_id?: string;
  type: string;
  title?: string;
  content?: string;
  description?: string;
  difficulty?: string;
  order_index?: number;
  xp?: number;
  is_answered?: boolean;
  isAnswered?: boolean;
  number_of_blanks?: number;
  max_selections?: number;
  answers?: MockAnswerOption[] | null;
  answer_options?: MockAnswerOption[] | null;
  blank_answers?: MockBlankAnswer[] | null;
  user_blank_answers?: MockBlankAnswer[] | null;
  studentAnswer?: StudentAnswer | null;
}

interface MockAnswerOption {
  id: string;
  question_id?: string;
  answer_text: string;
  order_index?: number;
  is_correct?: boolean;
  user_selected?: boolean;
  transcript?: string | null;
  positions?: EvidencePosition[] | null;
  audio_start_time?: number | null;
  audio_end_time?: number | null;
}

interface MockBlankAnswer {
  position: number;
  answer?: string | null;
  transcript?: string | null;
  positions?: EvidencePosition[] | null;
  audio_start_time?: number | null;
  audio_end_time?: number | null;
}

interface EvidencePosition {
  start: number;
  end: number;
}

interface StudentAnswer {
  selected_answer_id?: string | null;
  answer_text?: string | null;
  blank_answers?: MockBlankAnswer[] | null;
  audio_file_id?: string | null;
  user_file_id?: string | null;
  is_correct?: boolean | null;
}
```

Question types handled by the shared mobile quiz:

- `single-choice`
- `multiple-choice`
- `fill-blank`
- `fill_blank`
- `fill-in-blank`
- `short-answer`

Unknown non-blank/non-short types with answer options behave like single choice.

### Result and history contracts

```ts
interface MockResult {
  attempt_id: string;
  mock_exam_id: string;
  status?: string;
  grading_status?: string;
  started_at?: string | null;
  finished_at?: string | null;
  overall_band?: number | null;
  total_band_score?: number | null;
  listening_band?: number | null;
  reading_band?: number | null;
  writing_band?: number | null;
  speaking_band?: number | null;
  component_scores?: Record<string, number | { band_score?: number | null }>;
  feedback?: string;
  components?: Array<{
    type: string;
    band_score?: number | null;
    total_questions?: number;
  }>;
}

interface MockHistoryItem {
  attempt_id: string;
  mock_exam_id?: string;
  attempt_number?: number;
  started_at?: string | null;
  finished_at?: string | null;
  is_finished?: boolean;
  overall_band?: number | null;
  total_band_score?: number | null;
  listening_band?: number | null;
  reading_band?: number | null;
  writing_band?: number | null;
  speaking_band?: number | null;
  mock_exam?: {
    id: string;
    title: string;
    description?: string;
    time_limit_minutes?: number;
  };
}
```

The history endpoint may return:

- a top-level array
- `{ "items": [...] }`
- `{ "attempts": [...] }`

## 6. End-to-End State Flow

### 6.1 List page

1. Request page 1 with limit 10.
2. Show loading skeleton on first load.
3. Preserve current data during silent refresh.
4. Load more when pagination says `page < totalPages`.
5. Refresh when returning to the list route.
6. Refresh when a locally displayed attempt timer expires, throttled to avoid request loops.

Card status rules used by mobile:

- `Completed` when `assignment.finished`, `assignment.attempt.is_finished`, or legacy `assign.is_finished` is true.
- `In Progress` when an attempt exists or legacy `assign.started_at` exists.
- Otherwise use assignment status or exam status.
- Show a countdown only for a started, unfinished exam with `time_remaining_seconds`.

Click behavior:

- Finished exam: open result using `assignment.attempt.id`.
- Unfinished exam: open/start attempt overview.
- If a finished item has no attempt ID, show `Result is not available yet`.

### 6.2 Start or continue attempt

Call:

```http
POST /student/ielts-mocks/{mockExamId}/attempts/start
```

The endpoint is expected to be idempotent for an unfinished attempt: return the existing attempt instead of creating duplicates.

After receiving the attempt:

1. Resolve `attemptId` from `attempt.attempt_id`, `attempt.id`, top-level `attempt_id`, or top-level `id`.
2. Sort components by `order_index`.
3. Render component cards in backend order.
4. Disable components where `status == "locked"` or `is_available == false`.
5. For the selected component, render `sub_sections`; if empty, render the component as one direct section.
6. Do not infer unlock order locally.

### 6.3 Open a section

Only open when all are true:

```ts
!section.isLocked &&
section.is_available !== false &&
section.status !== "completed" &&
section.status !== "expired"
```

Call the section start endpoint when the section workspace opens:

```http
POST /student/ielts-mocks/{mockExamId}/attempts/{attemptId}/sections/{sectionId}/start
```

Do not rely only on the summary from `attempts/start`; section-start detail supplies current questions, timer, content, and listening audio.

When the section workspace closes, refresh the attempt through `POST .../attempts/start` to obtain updated completion/locking state.

### 6.4 Submit an answer

The mobile client submits one answer per request:

```http
POST /student/ielts-mocks/{mockExamId}/attempts/{attemptId}/sections/{sectionId}/submit
Content-Type: application/json

{
  "answers": [<answer>]
}
```

Payload by answer type:

Choice:

```json
{
  "question_id": "question-id",
  "selected_answer_id": "answer-option-id"
}
```

Fill blank:

```json
{
  "question_id": "question-id",
  "blank_answers": ["first value", "second value"]
}
```

Writing text:

```json
{
  "question_id": "question-id",
  "answer_text": "Student response"
}
```

Speaking audio:

```json
{
  "question_id": "question-id",
  "audio_file_id": "uploaded-file-id"
}
```

Writing file:

```json
{
  "question_id": "question-id",
  "user_file_id": "uploaded-file-id"
}
```

Do not send multiple-choice IDs as multiple answer objects. The current mobile mock payload sends the first selected ID as `selected_answer_id`, even though the shared UI can collect multiple IDs. Confirm backend expectations before expanding this behavior on web.

The submit response parser accepts:

- `{ "data": { ...result } }`
- `{ "result": { ...result } }`
- `{ "results": [{ ...result }] }`
- a direct object containing `question_id` or `is_correct`

### 6.5 Finish a section

When all required questions are submitted, call:

```http
POST /student/ielts-mocks/{mockExamId}/attempts/{attemptId}/sections/{sectionId}/finish
```

Then close the section workspace and refresh the attempt overview.

The current mobile quiz does not finish while unanswered questions remain. It opens a question overview so the student can navigate to missing answers.

### 6.6 Finish the whole exam

The overview exposes `Finish exam` after an attempt is available. Call:

```http
POST /student/ielts-mocks/{mockExamId}/attempts/{attemptId}/finish
```

On success, replace the overview with the result route using the response `attempt_id`.

The backend is responsible for deciding whether an incomplete exam can be finished and for calculating/grading results.

## 7. Timer Rules

Use `time_remaining_seconds` received from the backend to establish a local display deadline:

```ts
const deadline = Date.now() + timeRemainingSeconds * 1000;
const remaining = Math.max(0, deadline - Date.now());
```

Rules:

- Do not start a timer from `time_limit_minutes` alone.
- No `time_remaining_seconds` means no countdown is shown.
- A value of `0` is immediately expired.
- Attempt overview timer reaching zero returns the user to the mock exam list.
- Section timer reaching zero closes the section and refreshes attempt state.
- The mobile UI does not automatically call section finish when its local timer expires; it trusts the next backend refresh to resolve status.
- Re-sync from the backend after tab visibility changes, navigation return, and section completion.
- Use `document.visibilitychange` on web to re-fetch instead of trusting a timer that was throttled in a background tab.

Format:

- under one hour: `MM:SS`
- one hour or more: `H:MM:SS`

## 8. Section-Specific UX

### Listening

1. Start section and wait for detail.
2. Show section timer when provided.
3. Resolve audio from any supported field:
   - `audio_file`
   - `audioFile`
   - `audio`
   - `audio_url`
   - `audioUrl`
   - `audio_file_url`
   - `audioFileUrl`
4. Audio may be a string URL, direct object, or nested under `file`/`audio_file`.
5. Resolve relative audio URLs against the API origin, for example `/uploads/...`.
6. Show audio before the quiz and keep it available while answering.
7. Complete all questions, finish section, return to overview.

### Reading

1. Start section and render `content` as HTML.
2. Show an intro/passage view before questions.
3. Keep passage accessible from the quiz, currently via a sheet.
4. Show section timer when provided.
5. Complete all questions, finish section, return to overview.

### Writing

1. Start section and show instructions/content.
2. Student chooses typed response or file upload.
3. Typed response sends `answer_text`.
4. Upload uses multipart `POST /uploads` with form field `file`, then sends returned file ID as `user_file_id`.
5. On successful answer submission, finish section and return to overview.

### Speaking

1. Start section and show one prompt at a time.
2. Record microphone audio, maximum two minutes per prompt in the current app.
3. Upload recording through multipart `POST /uploads` with form field `file`.
4. Submit returned upload ID as `audio_file_id`.
5. Advance to the next prompt after submission.
6. After the final prompt, finish section and return to overview.

For browser implementation, use `MediaRecorder`, request microphone permission only when needed, stop tracks during cleanup, and choose a MIME type supported by both browser and backend.

## 9. Result Screen

Fetch:

```http
GET /student/ielts-mocks/{mockExamId}/attempts/{attemptId}/result
```

Display:

- exam title
- overall band, or `Pending`
- elapsed time from `finished_at - started_at`
- grading status, or `Pending`
- started/finished timestamps in local time
- Listening band
- Reading band
- Writing band
- Speaking band
- feedback when non-empty

Score fallback rules:

- Overall: `overall_band ?? total_band_score`
- Skill: prefer `component_scores[type].band_score`, then top-level `{type}_band`
- Missing score: `Pending`

The result page supports pull-to-refresh because writing/speaking grading may remain pending.

## 10. History Screen

Fetch all history:

```http
GET /student/ielts-mocks/results/all
```

The current mobile implementation shows a dedicated global history page, not a per-exam bottom sheet.

Each row displays:

- mock exam title
- started and finished local timestamps
- overall band or `Pending`
- compact L/R/W/S scores

Clicking a row opens the immutable result route using `mockExamId` and `attemptId`.

## 11. UI State Requirements

Every screen should implement:

- initial loading state
- empty state
- blocking error state when no data exists
- non-blocking refresh error when stale data exists
- pull/manual refresh
- disabled duplicate actions while a request is active
- server error message display

Attempt overview should additionally implement:

- selected component state
- locked component styling
- completed component styling
- available/in-progress component styling
- component and section remaining time
- pending/completed band score
- section list empty state
- finish-exam loading state

Do not optimistically unlock components. Refresh from the backend after section completion.

## 12. Error and Race Handling

- Guard against double start, submit, section finish, and exam finish requests.
- Treat HTTP `409` as a likely already-finished/expired conflict and refresh attempt state.
- On `401`, use the application's normal session/logout flow.
- Keep prior list/attempt data visible during silent refresh failures.
- Ignore stale responses when route IDs or selected attempt IDs have changed.
- Abort in-flight section requests when leaving the workspace where possible.
- Never create a new local attempt ID.
- Do not infer lock state from array order.

## 13. Known Differences from `mock_exam_tor.md`

The web developer should not assume every ToR item exists in mobile today:

1. Section detail currently uses `POST .../sections/{sectionId}/start`, not the ToR's suggested `GET` detail endpoint.
2. History is currently a dedicated global page using `/results/all`, not a per-exam bottom sheet.
3. Retake is not implemented in the current mobile feature.
4. Completed sections are not reopenable from the attempt overview; they are disabled.
5. Timer expiration closes/refreshes UI but does not explicitly finish the section from the timer callback.
6. The overview shows `Finish exam` whenever an attempt is loaded; backend validation determines whether finishing is allowed.
7. The current list page routes a finished exam directly to its result instead of opening a retake flow.

If web must match mobile exactly, follow this document. If product wants the broader ToR behavior, align mobile, web, and backend before implementation.

## 14. Suggested Web State Shape

```ts
interface MockExamStore {
  list: {
    status: "idle" | "loading" | "success" | "error";
    items: MockExam[];
    pagination: PaginationMeta;
    loadingMore: boolean;
    error?: string;
  };
  attempt: {
    status: "idle" | "loading" | "success" | "error";
    data?: MockAttemptResponse;
    selectedComponentId?: string;
    refreshing: boolean;
    finishing: boolean;
    error?: string;
  };
  section: {
    status: "idle" | "loading" | "success" | "error";
    data?: MockSectionDetail;
    currentQuestionIndex: number;
    draftsByQuestionId: Record<string, unknown>;
    submittingQuestionId?: string;
    finishing: boolean;
    error?: string;
  };
}
```

Use server-state tooling such as TanStack Query for remote data and local component/store state for selected component, current question, drafts, recorder, and countdown display.

## 15. Acceptance Checklist

- [ ] Authenticated, non-cached exam list with pagination
- [ ] Correct completed/in-progress/status card rendering
- [ ] Start/continue endpoint is idempotently called
- [ ] Components and sub-sections sorted by `order_index`
- [ ] Backend lock/availability rules respected
- [ ] Direct-section components supported when `sub_sections` is empty
- [ ] Section detail loaded through POST `/start`
- [ ] Server timer displayed and re-synced after visibility/navigation changes
- [ ] Listening audio handles wrapper and URL variants
- [ ] Reading HTML passage remains accessible during questions
- [ ] Choice, fill-blank, writing text/file, and speaking audio submissions work
- [ ] Missing questions prevent accidental section finish
- [ ] Section finish refreshes attempt and unlock state
- [ ] Whole-exam finish opens result
- [ ] Pending grading is represented without fake zero scores
- [ ] Result refresh works
- [ ] Global history works and opens result detail
- [ ] Empty, loading, error, refresh, and conflict states are implemented
- [ ] Late/expired submissions are rejected by backend and recovered via refresh

## 16. Reference Files

Primary implementation:

- `lib/features/mock_exam/data/datasources/mock_exam_remote_data_source.dart`
- `lib/features/mock_exam/data/models/mock_exam_model.dart`
- `lib/features/mock_exam/data/models/mock_exam_attempt_model.dart`
- `lib/features/mock_exam/presentation/bloc`
- `lib/features/mock_exam/presentation/pages`
- `lib/features/mock_exam/presentation/widgets/mock_exam_card.dart`

Shared section behavior:

- `lib/features/common/data/models/section_model`
- `lib/features/common/presentation/bloc/section_detail_bloc`
- `lib/features/common/presentation/bloc/section_question_answer_bloc`
- `lib/features/common/presentation/widgets/components/section_quiz_component.dart`
- `lib/features/common/presentation/pages/sections_types`

Verification:

- `test/mock_exam/mock_exam_timer_test.dart`
- `test/mock_exam/mock_exam_section_start_response_test.dart`
- `test/mock_exam/mock_exam_live_completion_test.dart`
- `integration_test/mock_exam_ui_completion_test.dart`
