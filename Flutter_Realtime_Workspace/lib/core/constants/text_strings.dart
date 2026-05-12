/// Centralised static UI strings — never hardcode text in widgets.
class TTexts {
  TTexts._();

  // ── App ──────────────────────────────────────────────────────
  static const String appName = 'Teamspot';
  static const String appTagline = 'Collaborate. Create. Conquer.';

  // ── Onboarding ───────────────────────────────────────────────
  static const String onboardingTitle1 = 'Manage Projects Effortlessly';
  static const String onboardingSubtitle1 =
      'Create, assign, and track tasks across your entire team in real time.';
  static const String onboardingTitle2 = 'Real-time Collaboration';
  static const String onboardingSubtitle2 =
      'Chat, call, and co-edit documents — all in one workspace.';
  static const String onboardingTitle3 = 'Powerful Dashboards';
  static const String onboardingSubtitle3 =
      'Visualise progress with Gantt charts, analytics, and financial overviews.';
  static const String onboardingTitle4 = 'Smart Notifications';
  static const String onboardingSubtitle4 =
      'Never miss a deadline — get alerts for tasks, meetings, and mentions.';
  static const String onboardingTitle5 = 'Secure by Design';
  static const String onboardingSubtitle5 =
      'Two-factor auth and biometric login keep your workspace safe.';
  static const String getStarted = 'Get Started';
  static const String skip = 'Skip';
  static const String next = 'Next';

  // ── Auth ─────────────────────────────────────────────────────
  static const String login = 'Log In';
  static const String signup = 'Sign Up';
  static const String signOut = 'Sign Out';
  static const String forgotPassword = 'Forgot Password?';
  static const String createAccount = 'Create an Account';
  static const String welcomeBack = 'Welcome Back';
  static const String loginSubtitle = 'Sign in to continue to Teamspot.';
  static const String signupSubtitle = 'Join thousands of teams building together.';
  static const String email = 'Email Address';
  static const String emailHint = 'you@example.com';
  static const String password = 'Password';
  static const String passwordHint = 'Min. 8 characters';
  static const String confirmPassword = 'Confirm Password';
  static const String fullName = 'Full Name';
  static const String fullNameHint = 'Your full name';
  static const String continueWithGoogle = 'Continue with Google';
  static const String continueWithGithub = 'Continue with GitHub';
  static const String continueWithMicrosoft = 'Continue with Microsoft';
  static const String continueWithBiometric = 'Use Biometrics';
  static const String orDivider = 'or';
  static const String alreadyHaveAccount = 'Already have an account? ';
  static const String dontHaveAccount = "Don't have an account? ";
  static const String verifyOtp = 'Verify OTP';
  static const String otpSent = 'A verification code was sent to your email.';
  static const String resendOtp = 'Resend Code';

  // ── Navigation Labels ────────────────────────────────────────
  static const String navHome = 'Home';
  static const String navProjects = 'Projects';
  static const String navTeams = 'Teams';
  static const String navDashboard = 'Dashboard';
  static const String navProfile = 'Profile';

  // ── Home ─────────────────────────────────────────────────────
  static const String goodMorning = 'Good Morning';
  static const String goodAfternoon = 'Good Afternoon';
  static const String goodEvening = 'Good Evening';
  static const String recentActivity = 'Recent Activity';
  static const String quickActions = 'Quick Actions';
  static const String myTasks = 'My Tasks';
  static const String upcomingMeetings = 'Upcoming Meetings';

  // ── Projects ─────────────────────────────────────────────────
  static const String projects = 'Projects';
  static const String createProject = 'Create Project';
  static const String projectName = 'Project Name';
  static const String projectDescription = 'Description';
  static const String noProjects = 'No projects yet. Create your first one!';
  static const String tasks = 'Tasks';
  static const String createTask = 'Create Task';
  static const String taskTitle = 'Task Title';
  static const String taskDescription = 'Task Description';
  static const String dueDate = 'Due Date';
  static const String assignee = 'Assignee';
  static const String priority = 'Priority';
  static const String status = 'Status';
  static const String timeline = 'Timeline';
  static const String issues = 'Issues';
  static const String createIssue = 'Create Issue';
  static const String noIssues = 'No issues reported.';

  // ── Team ─────────────────────────────────────────────────────
  static const String teams = 'Teams';
  static const String createTeam = 'Create Team';
  static const String teamName = 'Team Name';
  static const String teamMembers = 'Members';
  static const String inviteMember = 'Invite Member';
  static const String noTeams = 'No teams yet.';

  // ── Notifications ────────────────────────────────────────────
  static const String notifications = 'Notifications';
  static const String noNotifications = 'You\'re all caught up!';
  static const String markAllRead = 'Mark All Read';

  // ── Settings / Account ───────────────────────────────────────
  static const String settings = 'Settings';
  static const String account = 'Account';
  static const String profile = 'Profile';
  static const String appearance = 'Appearance';
  static const String darkMode = 'Dark Mode';
  static const String lightMode = 'Light Mode';
  static const String systemDefault = 'System Default';
  static const String privacy = 'Privacy & Security';
  static const String inviteFriends = 'Invite Friends';
  static const String support = 'Support';
  static const String feedback = 'Send Feedback';
  static const String rateApp = 'Rate Teamspot';
  static const String whatsNew = "What's New";
  static const String moreApps = 'More Apps';
  static const String deleteAccount = 'Delete Account';
  static const String deleteAccountConfirm =
      'Are you sure? This action cannot be undone.';

  // ── Common ───────────────────────────────────────────────────
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String search = 'Search';
  static const String searchHint = 'Search\u2026';
  static const String loading = 'Loading\u2026';
  static const String retry = 'Retry';
  static const String done = 'Done';
  static const String yes = 'Yes';
  static const String no = 'No';
  static const String ok = 'OK';
  static const String genericError = 'Something went wrong.';
  static const String networkError = 'No internet connection.';
  static const String serverError = 'Server error. Please try again.';
  static const String noData = 'No data available.';
  static const String comingSoon = 'Coming Soon';

  // Onboarding Subtitles
  static const String subOnboardingTitle1 =
      'Join your team in real-time collaboration, streamline communication, and boost productivity.';
  static const String subOnboardingTitle2 =
      'Create, assign, and manage tasks efficiently with powerful project management tools.';
  static const String subOnboardingTitle3 =
      'Work seamlessly across all devices, keeping your team connected and in sync, no matter the distance.';

  // Home
  static const String homeAppBarTitle = 'Team Workspace';
  static const String homeAppBarSubtitle =
      'Collaborate and Achieve Goals Together, welcome back Andrew!';
}
