# QuizMe Application - Detailed User Flow Documentation

## 🎯 Application Overview
QuizMe is an educational platform that connects teachers and students for managing courses, assignments, exams, and learning materials.

---

## 👨‍🏫 TEACHER FLOW - DETAILED

### 1. Welcome & Authentication

#### **Step 1.1: Welcome Screen**
- Screen shows: "Welcome! Let's get started"
- Two buttons:
  - 🎓 STUDENT
  - 👨‍🏫 TEACHER
- **Action:** Teacher clicks "TEACHER" button

#### **Step 1.2: Teacher Login Screen**
- Input fields:
  - 📧 Email (with email icon)
  - 🔒 Password (with lock icon)
- Buttons:
  - "Login" (primary blue button)
  - "Sign in with Google" (secondary blue button)
- Link at bottom: "Create Account Sign Up"
- **Action:** Teacher enters credentials and clicks "Login"
  - **OR** clicks "Sign Up" to register

#### **Step 1.3: Teacher Registration (if new user)**
- Screen title: "Create Account"
- Input fields:
  - 👤 Full Name
  - 📧 Email
  - 🔒 Password
  - 🔒 Confirm Password
- Button: "Sign Up" (primary blue button)
- Link at bottom: "Login Instead"
- **Action:** Teacher fills form and clicks "Sign Up"

---

### 2. Teacher Dashboard (Main Screen)

#### **Step 2.1: Dashboard View**
- Screen title: "QuizMe" at top
- Subtitle: "Dashboard"
- **Main Content:**
  - List of class cards (gradient colored boxes)
    - Example: "AR 101" with "Software Engineering" subtitle
    - Each card has 3-dot menu (⋮) in top-right corner
  - If link is copied, shows "Link copied" notification
- **Bottom:** Large ➕ (Plus) button centered at bottom
- **Action Options:**
  - Click on a class card → Go to Subject View (Step 3)
  - Click ➕ button → Create a new class (Step 2.2)
  - Click 3-dot menu → Options like "Share Link", "Edit Class", "Delete Class"

#### **Step 2.2: Create a Class**
- Screen title: "Create a Class"
- Input fields:
  - Class Subject: (text input)
  - Class Code: (text input)
  - Instructor: (text input)
- Button: "Create" (primary blue button)
- **Action:** Teacher fills form and clicks "Create"
  - Returns to Dashboard with new class card added

---

### 3. Subject/Class View

#### **Step 3.1: Subject Main Menu**
- Screen shows:
  - Back arrow (←) and subject code "SE 101" at top
  - Title: "Software Engineering"
- **Three Main Options:**
  - 📄 **Assignments** → Go to Step 4
  - 📚 **Modules** → Go to Step 5
  - 👥 **People** → Go to Step 6
- **Bottom Buttons:**
  - "Upload" (light blue button)
  - "Create" (primary blue button)

---

### 4. Assignments Section

#### **Step 4.1: Assignments List View**
- Screen shows:
  - Back arrow (←) and "SE101" at top
  - Title: "Assignments"
- **Content:** List of existing assignments (blue rounded cards)
  - "Exam— QuizMe (Due Aug 14, 11:59 PM)"
  - "SE 101 Essay — Modern Software Analysis (Due Aug 11, 11:59 PM)"
  - "Math 102 — Trigonometry Practice Quiz (Due Aug 15, 9:00 PM)"
- **Bottom Buttons:**
  - "Upload" (light blue)
  - "Create" (primary blue)
- **Action Options:**
  - Click assignment card → View/Edit assignment details
  - Click "Create" → Go to Step 4.2

#### **Step 4.2: Choose Assignment Type**
- Screen shows:
  - Back arrow (←) and "SE 101" at top
  - Title: "CHOOSE"
- **Four Options (teal buttons with icons):**
  - 📝 **EXAM**
  - 📝 **ACTIVITY**
  - 📝 **QUIZ**
  - 📝 **ASSIGNMENT**
- **Action:** Teacher selects type (e.g., EXAM) → Go to Step 4.3

#### **Step 4.3: Choose Exam Types**
- Screen shows:
  - Back arrow (←) and "SE 101" at top
  - Title: "CHOOSE A TYPE OF EXAM"
- **Exam Type Options (teal toggle buttons with checkmarks):**
  - ✓ **MULTIPLE CHOICE**
  - ✓ **IDENTIFICATION**
  - ✓ **ENUMERATION**
  - ✓ **TRUE OR FALSE**
- **Number of Items Selection:**
  - Label: "NO. OF ITEMS"
  - Three pill buttons:
    - "1-10"
    - "1-20"
    - "1-50"
- **Bottom Button:** "Create" (primary blue)
- **Action:** 
  - Teacher selects exam types (can select multiple)
  - Selects number range
  - Clicks "Create" → Go to Step 4.4

#### **Step 4.4: Create Exam Details**
- Screen shows:
  - Back arrow (←) and "SE 101" at top
  - Title: "Create a Title and Name of your exam:"
- **Input Fields:**
  - Title: (text input)
  - Name: (text input)
- **Section:** "Add the due date of the exam"
  - Enter date: (date picker input)
- **Bottom Button:** "Done" (primary blue)
- **Action:** Teacher fills details and clicks "Done" → Go to Step 4.5

#### **Step 4.5: Generated Exam Preview**
- Screen shows:
  - Back arrow (←) and "SE 101" at top
  - Title: "Exam Type:"
- **Preview of Generated Questions:**
  - **Multiple Choice Section:**
    - Visual card showing sample question with options
    - Example: "What is the largest planet in the solar system?"
      - Options: Venus, Mercury, Jupiter, Saturn
  - **Example question input:**
    - "Who is the most handsome instructor?"
    - Answer field showing: "Iratus Glenn Cruz"
  
  - **Identification Section:**
    - Button: "List all CCIT instructors"
    - Multiple blank lines for answers
  
  - **Enumeration Section:**
    - (Shows blank area for listing items)
  
  - **TRUE or FALSE Section:**
    - Question: "IS THE SUN RED?"
    - Two buttons: "TRUE" | "FALSE"
  
  - **Essay Section:**
    - Question: "Explain why you should take Bachelor of Science in Computer Science"
    - Large text area for answer

- **Bottom Button:** "Save as document" (green button)
- **Action:** Teacher reviews and clicks "Save as document"
  - Exam is created and added to assignments list
  - Returns to Assignments List (Step 4.1)

---

### 5. Modules Section

#### **Step 5.1: Modules List View**
- Screen shows:
  - Back arrow (←) and "SE 101" at top
  - Title: "Modules"
- **Content:** List of lesson files (teal rounded cards with PowerPoint icons)
  - 📊 "Lesson 1: Fundamentals of SE"
  - 📊 "Lesson 2: Software Development Lifecycle Overview"
  - 📊 "Lesson 3: Agile vs Waterfall"
  - 📊 "Scrum Workflow Diagram"
- **Bottom Buttons:**
  - "Upload" (light blue)
  - "Create" (primary blue)
- **Action Options:**
  - Click module card → View/Download module
  - Click "Upload" → Go to Step 5.2
  - Click "Create" → Create new module content

#### **Step 5.2: Choose a File to Upload**
- Screen shows:
  - Back arrow (←) and "SE 101" at top
  - Title: "Choose a File"
- **Content:** Shows existing modules list (same as 5.1)
- **Bottom Buttons:**
  - "Upload" (light blue)
  - "Create" (primary blue)
- **Action:** Click "Upload" → Go to Step 5.3

#### **Step 5.3: Upload Source Selection**
- Screen shows:
  - Back arrow (←) and "SE 101" at top
  - Title: "Upload a file"
- **Two Options:**
  - 📄 **File Manager** (browse device files)
  - 📁 **Drive** (browse Google Drive)
- **Bottom Buttons:**
  - "Upload" (light blue) - confirms selection
  - "Create" (primary blue)
- **Action:** 
  - Teacher selects source
  - Browses and selects file
  - Clicks "Upload"
  - Returns to Modules List with new file added

---

### 6. People Section (Student Management)

#### **Step 6.1: People List View - Version 1**
- Screen shows:
  - Back arrow (←) and "SE 101" at top
  - Title: "People"
- **Content:** List of enrolled people with avatars
  - 👤 **Jeanne Mhikaela S. Linan** - Student (● online status)
  - 👤 **Mark Anthony F. Araracap** - Student (● online status)
  - 👤 **Iratus Glenn Cruz** - Teacher
- Each person has:
  - Gray circular avatar placeholder
  - Name
  - Role (Student/Teacher)
  - Online status indicator (colored dot)

#### **Step 6.2: People List View - Version 2 (More Students)**
- Same as Version 1, but shows more students:
  - 👤 **Julia Lyde Q. Dulog** - Student (● ○ status)
  - 👤 **Jeanne Mhikaela S. Linan** - Student (● ○ status)
  - 👤 **Mark Anthony F. Araracap** - Student (● ○ status)
  - 👤 **Iratus Glenn Cruz** - Teacher
- **Note:** Some students have multiple status dots (● ○) possibly indicating different session states

---

## 🎓 STUDENT FLOW - DETAILED

### 1. Welcome & Authentication

#### **Step 1.1: Welcome Screen**
- Screen shows: "Welcome! Let's get started"
- Two buttons:
  - 🎓 **STUDENT**
  - 👨‍🏫 TEACHER
- **Action:** Student clicks "STUDENT" button

#### **Step 1.2: Student Login Screen**
- Input fields:
  - 📧 Email (with email icon)
  - 🔒 Password (with lock icon)
- Buttons:
  - "Login" (primary blue button)
  - "Sign in with Google" (secondary blue button)
- Link at bottom: "Create Account Sign Up"
- **Action:** Student enters credentials and clicks "Login"
  - **OR** clicks "Sign Up" to register

#### **Step 1.3: Student Registration (if new user)**
- Screen title: "Create Account"
- Input fields:
  - 👤 Full Name
  - 📧 Email
  - 🔒 Password
  - 🔒 Confirm Password
- Button: "Sign Up" (primary blue button)
- Link at bottom: "Login Instead"
- **Action:** Student fills form and clicks "Sign Up"

---

### 2. Student Dashboard (Main Screen)

#### **Step 2.1: Dashboard View - Empty State**
- Screen shows:
  - "QuizMe" logo/title at top
  - Title: "Dashboard"
- **Main Content:**
  - Empty area (no classes enrolled yet)
  - Input field: "Paste the link" (with rounded corners)
  - "ENROLL" button (primary blue) next to input
- **Bottom Navigation Bar:**
  - 🏠 **Dashboard** (active/selected)
  - 📋 **To-do**
  - 🔔 **Notification**
  - 👤 **Profile**

#### **Step 2.2: Dashboard View - With Enrolled Class**
- Same as empty state, but shows:
  - Class card with gradient background
  - "SE 101: Software Programmi..." (title truncated)
  - Word cloud design in background showing programming terms
  - "Iratus Glenn Cruz" (instructor name)
  - Has menu button (⋮) on card
- Still shows enrollment area at bottom
- **Action Options:**
  - Click class card → Go to Subject View (Step 3)
  - Paste new class link and click "ENROLL" → Join another class

---

### 3. Subject/Class View

#### **Step 3.1: Subject Main Menu**
- Screen shows:
  - Back arrow (←) and "SE 101" at top
  - Title: "Software Engineering"
- **Three Navigation Options:**
  - 📄 **School Works** → Go to Step 4
  - 📚 **Modules** → Go to Step 5
  - 👥 **People** → Go to Step 6
- **Bottom Navigation:** Same as dashboard

---

### 4. School Works Section (Assignments & Exams)

#### **Step 4.1: School Works List**
- Screen shows:
  - Back arrow (←) and "SE 101" at top
  - Title: "School Works"
- **Content:** List of assignments (gray rounded cards with icons)
  - 📝 **Midterm Exam** (Due: Aug 30 2025)
  - 📝 **Activity 1** (Due: Aug 22, 11:59 PM)
  - 📝 **Long Quiz 1** (Due: Aug 20, 11:59 PM)
  - 📝 **Chapter 1- Quiz 1** (Due: Aug 14, 11:59 PM)
- Each card shows:
  - Icon representing type
  - Assignment name
  - Due date and time
- **Bottom Navigation:** Standard nav bar
- **Action:** Click on any assignment card → Go to Step 4.2

#### **Step 4.2: Taking an Exam/Quiz**
- Screen shows:
  - Back arrow (←) and "QuizMe" at top
  - Assignment name: "Midterm Exam"
  - Title: "Exam Type:"
- **Question Sections Displayed:**

  **1. Multiple Choice:**
  - Visual card showing question with options
  - Example: "What is the largest planet in the solar system?"
    - Radio buttons: Venus, Mercury, **Jupiter** (selected/highlighted), Saturn
  
  **2. Multiple Choice Question Input:**
  - Blue pill-shaped question: "Who is the most handsome instructor?"
  - Text input field below
  - Sample answer: "Iratus Glenn Cruz"
  
  **3. Identification:**
  - Blue button question: "List all CCIT instructors"
  - Multiple horizontal line text inputs below for listing answers
  
  **4. Enumeration:**
  - Section header shown
  - (Space for listing multiple items)
  
  **5. Essay:**
  - Question: "Explain why you should take Bachelor of Science in Computer Science"
  - Large text area for long-form answer

- **Bottom Section:**
  - ✓ Checkmark icon with text: "You've completed your exam!"
  - **"Turn in your answers"** button (green)
  - Check icon at bottom

- **Action:** 
  - Student answers all questions
  - Clicks "Turn in your answers"
  - Confirmation: Exam submitted
  - Returns to School Works list

---

### 5. Modules Section

#### **Step 5.1: Modules List View**
- Screen shows:
  - Back arrow (←) and "SE 101" at top
  - Title: "Modules"
- **Content:** List of lessons (teal rounded cards with PowerPoint icons)
  - 📊 "Lesson 1: Fundamentals of SE"
  - 📊 "Lesson 2: Software Development Lifecycle Overview"
  - 📊 "Lesson 3: Agile vs Waterfall"
  - 📊 "Scrum Workflow Diagram"
- **Bottom Navigation:** Standard nav bar
- **Action:** Click on module card → Opens/downloads the lesson file (PowerPoint)

---

### 6. People Section

#### **Step 6.1: People List View**
- Screen shows:
  - Back arrow (←) and "SE 101" at top
  - Title: "People"
- **Content:** List of classmates and teacher
  - 👤 **Julia Lyde Q. Dulog** - Student
  - 👤 **Jeanne Mhikaela S. Linan** - Student
  - 👤 **Mark Anthony F. Araracap** - Student
  - 👤 **Iratus Glenn Cruz** - Teacher
- Each person shows:
  - Gray circular avatar placeholder
  - Full name
  - Role designation (Student/Teacher)
- **Bottom Navigation:** Standard nav bar
- **Action:** View only (students can see who's in their class)

---

### 7. To-do Lists (Task Management)

#### **Step 7.1: To-do List View - Version 1**
- Screen shows:
  - Back arrow (←) at top
  - Title: "To-do lists"
- **Content:** Pending tasks (blue rounded cards with checkboxes)
  - ☐ **SE 101 Essay — Modern Software Analysis** (Due Aug 11, 11:59 PM)
  - ☐ **Math 102 — Trigonometry Practice Quiz** (Due Aug 15, 9:00 PM)
- Each task shows:
  - Empty checkbox
  - Subject code and assignment name
  - Due date and time
- **Bottom Navigation:** Standard nav bar (To-do is active)

#### **Step 7.2: To-do List View - Version 2**
- Same layout, but shows more tasks:
  - ☐ **Chapter 5 Quiz — QuizMe** (Due Aug 14, 11:59 PM)
  - ☐ **SE 101 Essay — Modern Software Analysis** (Due Aug 11, 11:59 PM)
  - ☐ **Math 102 — Trigonometry Practice Quiz** (Due Aug 15, 9:00 PM)
- **Action:** 
  - Check off completed tasks
  - Click task → Goes to that assignment

---

### 8. Notifications

#### **Step 8.1: Notifications View**
- Screen shows:
  - Back arrow (←) at top
  - Title: "Notifications"
  - Subtitle: "Software Engineering"
- **Content:** Chronological notification list

  **1. Assignment Due Soon** 🔔
  - Icon: Books/stack
  - Title: "Assignment Due Soon"
  - Text: "Reminder: Your essay for SE 101 — 'QuizMe' is due tomorrow at 11:59 PM."
  
  **2. Module Uploaded** 📤
  - Icon: Upload/folder
  - Title: "Module Uploaded"
  - Text: "New file uploaded: 'Week 6 Lecture Slides' in Marketing 302."
  
  **3. New Quiz Available** 📝
  - Icon: Quiz/clipboard
  - Title: "New Quiz Available"
  - Text: "A new quiz, 'Chapter 1 — Introduction to Software Engineering,' has been posted for SE 101. Due: Aug 14, 11:59 PM."

- **Bottom Navigation:** Standard nav bar (Notification is active)
- **Action:** Click notification → Goes to relevant content

---

### 9. Profile & Settings

#### **Step 9.1: Profile View**
- Screen shows:
  - Back arrow (←) and "Profile" at top
- **Profile Information:**
  - Large circular avatar placeholder (gray)
  - **Mark Anthony F. Angsikip**
  - "20 years old"
  - "Bachelor of Science in Computer Science"
- **Menu Options:**
  - ⚙️ **Settings** → Go to Step 9.2
  - 👥 **Change User**
  - **Log Out**
- **Bottom Navigation:** Standard nav bar (Profile is active)

#### **Step 9.2: Settings**
- Screen shows:
  - Back arrow (←) and "Settings" at top
- **Settings Options:**
  
  **Change your name**
  - Text input: "Enter your name here"
  
  **Change your age**
  - Text input: "Enter your age here"
  
  **Upload your picture**
  - (Button/link to upload photo)
  
  **Change password**
  - (Link to password change screen)

- **Action:** Click "Change password" → Go to Step 9.3

#### **Step 9.3: Change Password**
- Screen shows:
  - Back arrow (←) and "Change password" at top
  - Title: "Change your password"
- **Input Fields:**
  - "Enter your old password here"
    - Link: "forgot password?"
  - "Enter your new password"
  - "Verify your new password"
- **Action:** 
  - Student enters passwords
  - Submits change
  - Returns to Settings

---

## 🔄 Key Differences Between Teacher & Student

| Feature | Teacher | Student |
|---------|---------|---------|
| **Dashboard** | Shows all classes they teach<br>Can create new classes | Shows enrolled classes<br>Can join classes via link |
| **Assignments** | Can create, edit, manage assignments<br>Can generate exams | Can view and complete assignments<br>Can submit answers |
| **Modules** | Can upload/create lesson materials | Can view/download lesson materials (read-only) |
| **People** | Can see all students with online status<br>Can manage enrollment | Can see classmates and teacher (view-only) |
| **To-do** | Not shown in teacher interface | Shows pending assignments and deadlines |
| **Notifications** | Not shown in provided screens | Receives assignment reminders, module updates |
| **Class Management** | Creates classes with codes<br>Shares class links | Joins classes using teacher-provided links |

---

## 📊 Navigation Structure

### Bottom Navigation (Student Only):
1. **🏠 Dashboard** - Main screen showing enrolled classes
2. **📋 To-do** - Pending assignments and tasks
3. **🔔 Notification** - Updates and reminders
4. **👤 Profile** - User settings and account management

### Teacher Navigation:
- Teachers navigate from Dashboard → Class → Sections (Assignments/Modules/People)
- No bottom navigation bar shown
- Uses back arrows and hierarchical navigation

---

## 🎨 Design Patterns

### Color Scheme:
- **Primary Blue:** `#3DA9FC` (buttons, accents)
- **Teal/Cyan:** `#14D4C4` (selection toggles, cards)
- **Green:** `#90EE90` (submit/complete buttons)
- **Light Blue Background:** `#E8F4F8` (login/register screens)
- **Gray:** `#E0E0E0` (cards, avatars)
- **Gradient:** Green to Blue (class cards)

### Button States:
- **Primary:** Filled blue button
- **Secondary:** Outlined or light blue
- **Toggle Selected:** Teal with checkmark
- **Toggle Unselected:** Teal without checkmark

### Card Design:
- Rounded corners (20-30px radius)
- Shadow/elevation for depth
- Icon on left side
- Text content right-aligned

---

## ✅ User Flow Summary

**Teacher Journey:**
1. Login/Register → 2. Dashboard (see classes) → 3. Click class → 4. Manage Assignments/Modules/People → 5. Create content → 6. Students access content

**Student Journey:**
1. Login/Register → 2. Dashboard (enroll in class) → 3. Click class → 4. View School Works/Modules/People → 5. Complete assignments → 6. Submit work → 7. Check To-do list and Notifications

---

**End of Detailed Flow Documentation**
