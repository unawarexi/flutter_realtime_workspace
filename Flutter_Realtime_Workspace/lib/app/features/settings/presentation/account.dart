import 'package:flutter_realtime_workspace/store/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/app/domain/models/user_model.dart';
import 'package:flutter_realtime_workspace/core/network/pull_refresh.dart';
import 'package:flutter_realtime_workspace/core/utils/helpers/helper_functions.dart';
import 'package:flutter_realtime_workspace/app/features/authentication/presentation/sign_out.dart';
import 'package:flutter_realtime_workspace/app/features/authentication/presentation/widgets/options_screen.dart';
import 'package:flutter_realtime_workspace/store/user_provider.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_realtime_workspace/app/features/settings/presentation/widgets/update_account.dart';
import 'package:flutter_realtime_workspace/app/features/settings/presentation/widgets/delete_account.dart';
import 'package:flutter_realtime_workspace/app/features/settings/presentation/settings.dart';
import 'package:flutter_realtime_workspace/app/features/settings/presentation/support.dart';

class AccountScreen extends ConsumerStatefulWidget {
  final String userId;

  const AccountScreen({
    super.key,
    required this.userId,
    UserModel? user,
  });

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _profileAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Color scheme
  static const Color primaryBlue = Color(0xFF1E40AF);
  static const Color lightBlue = Color(0xFF3B82F6);
  static const Color backgroundLight = Color(0xFFFAFBFC);
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1E293B);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF334155);

  String _bio = "";
  bool _editingBio = false;
  final TextEditingController _bioController = TextEditingController();

  // For delete account modal
  final TextEditingController _deleteConfirmController =
      TextEditingController();

  // Add this getter back for use in all widget methods
  bool get isDarkMode => THelperFunctions.isDarkMode(context);

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _profileAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _profileAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _profileAnimationController.dispose();
    _bioController.dispose();
    _deleteConfirmController.dispose();
    super.dispose();
  }

  // Add pull-to-refresh handler
  Future<void> _onRefresh() async {
    final userState = ref.read(currentUserProvider);
    final currentUid = userState.valueOrNull?.id ?? '';
    if (widget.userId == currentUid) {
      // Refresh current user info
      await ref.read(userRepositoryProvider).getProfile();
    } else {
      // Refresh other user's info
      ref.invalidate(userInfoByIdProvider(widget.userId));
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine if this is the current user
    final userState = ref.watch(currentUserProvider);
    final currentUid = userState.valueOrNull?.id ?? '';
    final isCurrentUser = widget.userId == currentUid;

    // Use userProvider for current user, userInfoByIdProvider for others
    final userInfoAsync = isCurrentUser
        ? AsyncValue.data(userState.valueOrNull?.toJson())
        : ref.watch(userInfoByIdProvider(widget.userId));

    return userInfoAsync.when(
      data: (user) {
        // Use fallback values for missing data
        final email = user?['email'] ?? 'Not available';
        final displayName = user?['displayName'] ?? 'Not available';
        final companyName = user?['companyName'] ?? 'Not available';
        final profilePicture = user?['profilePicture'] ?? '';
        final bio = user?['bio'] ??
            "This is your bio. Tap to edit and let your team know more about you!";
        final roleTitle = user?['roleTitle'] ?? 'Not available';
        final department = user?['department'] ?? 'Not available';
        final phoneNumber = user?['phoneNumber'] ?? 'Not available';
        final officeLocation = user?['officeLocation'] ?? 'Not available';
        final teamProjectName = user?['teamProjectName'] ?? 'Not available';
        final teamSize = user?['teamSize'] ?? 'Not available';
        final workType = user?['workType'] ?? 'Not available';
        final timezone = user?['timezone'] ?? 'Not available';
        final profileCompletion = user?['profileCompletion'] ?? 0;
        final inviteCode = user?['inviteCode'] ?? 'Not available';
        final invitePermissions = user?['invitePermissions'] ?? {};
        final socialLinks = user?['socialLinks'] ?? {};
        final industry = user?['industry'] ?? 'Not available';
        final companyWebsite = user?['companyWebsite'] ?? 'Not available';
        final interestsSkills = user?['interestsSkills'] ?? [];
        final workingHours = user?['workingHours'] ?? {};

        if (!_editingBio) {
          _bio = bio;
          _bioController.text = bio;
        }

        return Scaffold(
          backgroundColor:
              isDarkMode ? TColors.backgroundDarkAlt : TColors.backgroundLight,
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              // --- Wrap main scrollable content with AdvancedPullRefresh ---
              child: AdvancedPullRefresh(
                onRefresh: _onRefresh,
                child: Column(
                  children: [
                    // Fixed AppBar Row
                    Material(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                      color: isDarkMode ? backgroundDark : backgroundLight,
                      elevation: 0,
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.only(
                              top: 20, left: 0, right: 0, bottom: 20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Back Icon
                              IconButton(
                                icon: Icon(Icons.arrow_back_ios_new,
                                    color:
                                        isDarkMode ? Colors.white : textPrimary,
                                    size: 22),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              // Profile Picture
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 0, right: 14),
                                child: CircleAvatar(
                                  radius: 30,
                                  backgroundImage: profilePicture.isNotEmpty
                                      ? NetworkImage(profilePicture)
                                      : const AssetImage(
                                              "assets/images/avatar.png")
                                          as ImageProvider,
                                  backgroundColor: primaryBlue.withOpacity(0.1),
                                  child: profilePicture.isEmpty
                                      ? const Icon(
                                          Icons.person,
                                          color: primaryBlue,
                                          size: 40,
                                        )
                                      : null,
                                ),
                              ),
                              // Texts
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      top: 8.0, right: 8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 2),
                                      Text(
                                        displayName,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: isDarkMode
                                              ? lightBlue
                                              : primaryBlue,
                                        ),
                                      ),
                                      Text(
                                        roleTitle,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDarkMode
                                              ? Colors.white70
                                              : textSecondary,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Optionally, add a menu button here if needed
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Complete Your Profile Section
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      child:
                          _buildCompleteProfileCard(context, profileCompletion),
                    ),
                    // Main scrollable content
                    Expanded(
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 0),
                              child: Column(
                                children: [
                                  _buildProfileAndActionsCard(
                                      context,
                                      email,
                                      companyName,
                                      teamProjectName,
                                      teamSize,
                                      department,
                                      officeLocation,
                                      phoneNumber,
                                      workType,
                                      timezone,
                                      industry,
                                      companyWebsite,
                                      inviteCode,
                                      invitePermissions,
                                      socialLinks,
                                      interestsSkills,
                                      workingHours),
                                  const SizedBox(height: 18),
                                  _buildBioSection(context, isDarkMode),
                                  const SizedBox(height: 32),
                                  SettingsSection(isDarkMode: isDarkMode),
                                  const SizedBox(height: 32),
                                  SupportSection(isDarkMode: isDarkMode),
                                  const SizedBox(height: 32),
                                  SignOutSection(isDarkMode: isDarkMode),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) {
        // Show the screen with all fields as "Not available"
        const fallback = 'Not available';
        return Scaffold(
          backgroundColor:
              isDarkMode ? TColors.backgroundDarkAlt : TColors.backgroundLight,
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              // --- Wrap error state with AdvancedPullRefresh too ---
              child: AdvancedPullRefresh(
                onRefresh: _onRefresh,
                child: Column(
                  children: [
                    Material(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                      color: isDarkMode ? backgroundDark : backgroundLight,
                      elevation: 0,
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.only(
                              top: 20, left: 0, right: 0, bottom: 20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              IconButton(
                                icon: Icon(Icons.arrow_back_ios_new,
                                    color:
                                        isDarkMode ? Colors.white : textPrimary,
                                    size: 22),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 0, right: 14),
                                child: CircleAvatar(
                                  radius: 30,
                                  backgroundImage: const AssetImage(
                                      "assets/images/avatar.png"),
                                  backgroundColor: primaryBlue.withOpacity(0.1),
                                  child: const Icon(
                                    Icons.person,
                                    color: primaryBlue,
                                    size: 40,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      top: 8.0, right: 8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 2),
                                      Text(
                                        fallback,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: isDarkMode
                                              ? lightBlue
                                              : primaryBlue,
                                        ),
                                      ),
                                      Text(
                                        fallback,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDarkMode
                                              ? Colors.white70
                                              : textSecondary,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      child: _buildCompleteProfileCard(context, 0),
                    ),
                    Expanded(
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 0),
                              child: Column(
                                children: [
                                  _buildProfileAndActionsCard(
                                    context,
                                    fallback, // email
                                    fallback, // companyName
                                    fallback, // teamProjectName
                                    fallback, // teamSize
                                    fallback, // department
                                    fallback, // officeLocation
                                    fallback, // phoneNumber
                                    fallback, // workType
                                    fallback, // timezone
                                    fallback, // industry
                                    fallback, // companyWebsite
                                    fallback, // inviteCode
                                    <String,
                                        dynamic>{}, // invitePermissions (Map)
                                    <String, dynamic>{}, // socialLinks (Map)
                                    <dynamic>[], // interestsSkills (List)
                                    <String, dynamic>{}, // workingHours (Map)
                                  ),
                                  const SizedBox(height: 18),
                                  _buildBioSection(context, isDarkMode),
                                  const SizedBox(height: 32),
                                  SettingsSection(isDarkMode: isDarkMode),
                                  const SizedBox(height: 32),
                                  SupportSection(isDarkMode: isDarkMode),
                                  const SizedBox(height: 32),
                                  SignOutSection(isDarkMode: isDarkMode),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompleteProfileCard(
      BuildContext context, int profileCompletion) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: isDarkMode ? cardDark : cardLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDarkMode ? borderDark : borderLight,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.06)
                  : Colors.grey.withOpacity(0.03),
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.assignment_turned_in_rounded,
                color: Colors.orange, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Complete Your Profile",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: isDarkMode ? Colors.white : textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Profile completion: $profileCompletion%",
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white70 : textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: profileCompletion / 100.0,
                    backgroundColor: Colors.grey[300],
                    color: Colors.orange,
                    minHeight: 5,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 16, color: isDarkMode ? Colors.white54 : textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAndActionsCard(
    BuildContext context,
    String email,
    String companyName,
    String teamProjectName,
    String teamSize,
    String department,
    String officeLocation,
    String phoneNumber,
    String workType,
    String timezone,
    String industry,
    String companyWebsite,
    String inviteCode,
    Map invitePermissions,
    Map socialLinks,
    List interestsSkills,
    Map workingHours,
  ) {
    final userState = ref.watch(currentUserProvider);
    final displayName = userState.valueOrNull?.displayName ?? 'Not available';
    final confirmWord = "teamspot/$displayName";

    // --- Make the profile card slidable to left to update ---
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity! < -100) {
            // Slide left: open update screen with smooth animation
            Navigator.of(context).push(_slideLeftRoute(
              UpdateAccount(userInfo: userState.valueOrNull?.toJson() ?? {}),
            ));
          }
        },
        child: Stack(
          children: [
            // Slide background (optional, e.g. show update icon)
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: Icon(Icons.edit, color: Colors.blue[700], size: 28),
                ),
              ),
            ),
            // The actual card
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDarkMode ? cardDark : cardLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDarkMode ? borderDark : borderLight,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDarkMode
                          ? Colors.black.withOpacity(0.15)
                          : Colors.grey.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      _buildHeaderSection(email, companyName),
                      const SizedBox(height: 24),
                      // Profile Details Section
                      _buildProfileDetailsSection(
                        department,
                        workType,
                        teamProjectName,
                        teamSize,
                        officeLocation,
                        timezone,
                        phoneNumber,
                        industry,
                        companyWebsite,
                        inviteCode,
                      ),
                      const SizedBox(height: 32),
                      // Action Buttons Section
                      _buildActionButtonsSection(context, confirmWord),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Custom slide transition for update screen
  Route _slideLeftRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end)
            .chain(CurveTween(curve: Curves.easeInOutCubic));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }

  Widget _buildHeaderSection(String email, String companyName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Email
        Text(
          email,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.white.withOpacity(0.8) : textSecondary,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 12),

        // Company Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: primaryBlue.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Text(
            companyName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: primaryBlue,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileDetailsSection(
    String department,
    String workType,
    String teamProjectName,
    String teamSize,
    String officeLocation,
    String timezone,
    String phoneNumber,
    String industry,
    String companyWebsite,
    String inviteCode,
  ) {
    return Container(
      padding: const EdgeInsets.all(10), // reduced from 20
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withOpacity(0.03)
            : Colors.grey.withOpacity(0.02),
        borderRadius: BorderRadius.circular(10), // reduced from 16
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.05)
              : Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Work Information
          _buildInfoGroup(
              "Work Information",
              [
                _buildInfoRow(Icons.work_outline_rounded, "Role",
                    "$department • $workType",
                    fontSize: 11),
                _buildInfoRow(Icons.groups_outlined, "Team",
                    "$teamProjectName ($teamSize)",
                    fontSize: 11),
                _buildInfoRow(Icons.business_outlined, "Industry", industry,
                    fontSize: 11),
              ],
              groupFontSize: 12),

          const SizedBox(height: 10), // reduced from 20

          // Contact & Location
          _buildInfoGroup(
              "Contact & Location",
              [
                _buildInfoRow(Icons.location_on_outlined, "Location",
                    "$officeLocation • $timezone",
                    fontSize: 11),
                _buildInfoRow(Icons.phone_outlined, "Phone", phoneNumber,
                    fontSize: 11),
                _buildInfoRow(
                    Icons.language_outlined, "Website", companyWebsite,
                    fontSize: 11),
              ],
              groupFontSize: 12),

          const SizedBox(height: 10), // reduced from 20

          // Team Access
          _buildInfoGroup(
              "Team Access",
              [
                _buildInfoRow(Icons.key_outlined, "Invite Code", inviteCode,
                    fontSize: 11),
              ],
              groupFontSize: 12),
        ],
      ),
    );
  }

  // Modified to accept fontSize for group and row
  Widget _buildInfoGroup(String title, List<Widget> children,
      {double groupFontSize = 14}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: groupFontSize, // reduced
            fontWeight: FontWeight.w600,
            color:
                isDarkMode ? Colors.white.withOpacity(0.9) : Colors.grey[800],
          ),
        ),
        const SizedBox(height: 6), // reduced
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {double fontSize = 14}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4), // reduced from 8
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 13, // reduced from 16
            color:
                isDarkMode ? Colors.white.withOpacity(0.6) : Colors.grey[600],
          ),
          const SizedBox(width: 8), // reduced from 12
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: fontSize, // reduced
                fontWeight: FontWeight.w500,
                color: isDarkMode
                    ? Colors.white.withOpacity(0.7)
                    : Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(width: 6), // reduced from 8
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: fontSize, // reduced
                fontWeight: FontWeight.w400,
                color: isDarkMode
                    ? Colors.white.withOpacity(0.8)
                    : Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtonsSection(BuildContext context, String confirmWord) {
    return Column(
      children: [
        // Divider
        Container(
          height: 1,
          width: double.infinity,
          color: isDarkMode
              ? Colors.white.withOpacity(0.08)
              : Colors.grey.withOpacity(0.15),
        ),
        const SizedBox(height: 16), // reduced from 24

        // Action Buttons
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildModernActionButton(
                    icon: Icons.add_location_alt_rounded,
                    label: "Add Sites",
                    color: const Color(0xFF10B981),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OrganisationOptionsScreen(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10), // reduced from 12
                Expanded(
                  child: _buildModernActionButton(
                    icon: Icons.person_add_alt_1_rounded,
                    label: "Invite Team",
                    color: const Color(0xFF8B5CF6),
                    onTap: () => context.push('/account/invite'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10), // space between row and delete
            SizedBox(
              width: double.infinity,
              child: _buildModernActionButton(
                icon: Icons.delete_forever_rounded,
                label: "Delete Account",
                color: Colors.redAccent,
                onTap: () => _showDeleteAccountModal(context, confirmWord),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModernActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: color,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountModal(BuildContext context, String confirmWord) async {
    setState(() {
      _deleteConfirmController.clear();
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDarkMode ? cardDark : cardLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        // Use the DeleteAccount widget instead of inline modal code
        return DeleteAccount(
          confirmWord: confirmWord,
          isDarkMode: isDarkMode,
        );
      },
    );
  }

  Widget _buildBioSection(BuildContext context, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDarkMode ? cardDark : cardLight,
          borderRadius: BorderRadius.circular(14), // reduced
          border: Border.all(
            color: isDarkMode ? borderDark : borderLight,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.06)
                  : Colors.grey.withOpacity(0.03),
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              vertical: 10, horizontal: 10), // reduced
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline,
                      color: isDarkMode ? lightBlue : primaryBlue,
                      size: 14), // reduced
                  const SizedBox(width: 5), // reduced
                  Text(
                    "Bio",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12, // reduced
                      color: isDarkMode ? Colors.white : textPrimary,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _editingBio = !_editingBio;
                        _bioController.text = _bio;
                      });
                    },
                    child: Icon(
                      _editingBio ? Icons.close : Icons.edit,
                      color: isDarkMode ? lightBlue : primaryBlue,
                      size: 14, // reduced
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6), // reduced
              _editingBio
                  ? Column(
                      children: [
                        TextFormField(
                          controller: _bioController,
                          maxLines: 2, // reduced
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : textPrimary,
                            fontSize: 11, // reduced
                          ),
                          decoration: InputDecoration(
                            hintText: "Write something about yourself...",
                            hintStyle: TextStyle(
                              color:
                                  isDarkMode ? Colors.white54 : textSecondary,
                              fontSize: 11, // reduced
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8), // reduced
                              borderSide: BorderSide(
                                color: isDarkMode ? borderDark : borderLight,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8), // reduced
                              borderSide: BorderSide(
                                color: isDarkMode ? lightBlue : primaryBlue,
                                width: 1,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 7, horizontal: 8), // reduced
                          ),
                        ),
                        const SizedBox(height: 6), // reduced
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    isDarkMode ? lightBlue : primaryBlue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(6), // reduced
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 7), // reduced
                              ),
                              onPressed: () {
                                setState(() {
                                  _bio = _bioController.text.trim().isEmpty
                                      ? "This is your bio. Tap to edit and let your team know more about you!"
                                      : _bioController.text.trim();
                                  _editingBio = false;
                                });
                                // Optionally, update bio on backend here
                              },
                              child: const Text("Save",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11)), // reduced
                            ),
                          ],
                        ),
                      ],
                    )
                  : Padding(
                      padding: const EdgeInsets.only(top: 1, bottom: 1),
                      child: Text(
                        _bio,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDarkMode ? Colors.white70 : textSecondary,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
