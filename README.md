# QuizMe - Smart Educational Management System

QuizMe is a modern, AI-powered mobile application designed to bridge the gap between teachers and students. It streamlines classroom management, material distribution, and assessment creation through an intuitive interface and advanced AI capabilities.

## 🚀 Key Features

- **AI-Powered Assessment Generation**: Effortlessly create exams, quizzes, and activities by uploading lecture notes (PDF, PPTX, DOCX).
- **Class Management**: Teachers can create virtual classrooms with unique enrollment codes.
- **Role-Based Access**: Specialized interfaces for both Teachers and Students.
- **Real-Time Notifications**: Instant alerts for students when new materials or assignments are published.
- **Automated Grading**: Instant results for students and comprehensive submission tracking for teachers.
- **Secure Authentication**: Firebase-powered login and signup with profile management.

---

## 🛠️ Technical Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase Firestore (NoSQL Database)
- **Storage**: Firebase Storage (File Hosting)
- **Authentication**: Firebase Auth
- **AI Engine**: Google Gemini AI (for intelligent question extraction and generation)
- **Documentation**: Markdown-based README and Walkthroughs

---

## 📖 System Flow

### 1. Onboarding
- **Role Selection**: Upon first sign-up, users choose between being a **Teacher** or a **Student**.
- **Profile Setup**: Users can set up their profiles, including name, course, and profile picture.

### 2. Teacher Workflow
- **Create a Class**: Teachers create a class, which generates a 6-digit **Class Code**. They share this code with their students.
- **Upload Modules**: Teachers can upload educational materials (PDFs, PowerPoints) to the "Modules" section for student reference.
- **Create Assessments (Exams/Quizzes)**:
    - **Manual**: Create questions one by one.
    - **Magic AI**: Upload a lecture file -> Specify question types (Multiple Choice, TRUE/FALSE, etc.) -> Specify number of questions -> AI generates a full exam/quiz.
- **Publish (Upload)**: Once an item is ready, the teacher selects it and clicks "Upload" to publish it to the class. This triggers a **push notification** to all enrolled students.
- **Review Submissions**: Teachers can view a list of students who have submitted, along with their **scores and profile pictures**.

### 3. Student Workflow
- **Enrollment**: Students join a class by entering the teacher's unique **Class Code**.
- **Learning**: Access the "Modules" section to view and download study materials.
- **Assessment**: Take published exams and quizzes within the app. The system supports various question types:
    - **Multiple Choice**
    - **Identification**
    - **Enumeration**
    - **True or False**
- **Instant Results**: After submission, students can immediately see their scores.

---

## 💡 Examples & Use Cases

### Example 1: Creating an AI Exam
1. Teacher selects "Create Exam".
2. Selects "Magic AI" and uploads "Chapter 1 - Intro to SE.pdf".
3. Requests "10 Multiple Choice" and "5 Identification" questions.
4. AI extracts the core concepts and formats them into a ready-to-use exam.
5. Teacher reviews the generated questions and saves the exam.

### Example 2: Student Enrollment & Notification
1. Teacher shares code `QX72B1`.
2. Student enters the code in their dashboard and is instantly added to the class.
3. Teacher publishes a new Quiz.
4. Student receives a notification: *"New activities available: "Unit 1 Quiz" in QX72B1."*
5. Student taps the notification and takes the quiz within the app.

---

## 🏗️ Project Structure

- `lib/screens/`: Contains all UI screens categorized by feature (auth, dashboard, assignments, modules, etc.).
- `lib/services/`: Core logic for AI generation and Notifications.
- `lib/widgets/`: Reusable UI components.
- `lib/secrets.dart`: (Sensitive) Stores API keys for third-party services like Google Gemini.

---

## 🔧 Installation & Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/JanreyDev/quizMe.git
   ```
2. **Setup Firebase**:
   - Create a project on the [Firebase Console](https://console.firebase.google.com/).
   - Add Android/iOS apps and download `google-services.json` / `GoogleService-Info.plist`.
   - Run `flutterfire configure`.
3. **API Keys**:
   - Create a `lib/secrets.dart` file and add your `geminiApiKey`.
4. **Run the App**:
   ```bash
   flutter pub get
   flutter run
   ```

---

© 2026 QuizMe Development Team. Empowering education through technology.
