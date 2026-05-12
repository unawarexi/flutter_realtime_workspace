import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/app/features/team/presentation/all_team.dart';
import 'package:flutter_realtime_workspace/app/features/team/presentation/all_users.dart';
import 'package:flutter_realtime_workspace/app/features/team/presentation/widgets/create_team_screen.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/utils/helpers/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/store/user_provider.dart';
import 'package:flutter_realtime_workspace/core/network/pull_refresh.dart';

class TeamScreen extends ConsumerStatefulWidget {
  const TeamScreen({super.key});

  @override
  ConsumerState<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends ConsumerState<TeamScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Fetch all users on init if admin
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userInfo = ref.read(userProvider).userInfo ?? {};
      final permissionsLevel = userInfo['permissionsLevel'] ?? '';
      if (permissionsLevel == "admin") {
        ref.read(userProvider.notifier).fetchAllUsers();
      }
    });
  }

  Future<void> _onRefresh() async {
    final userInfo = ref.read(userProvider).userInfo ?? {};
    final permissionsLevel = userInfo['permissionsLevel'] ?? '';
    if (permissionsLevel == "admin") {
      await ref.read(userProvider.notifier).fetchAllUsers();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = THelperFunctions.isDarkMode(context);
    final userState = ref.watch(userProvider);
    final userInfo = userState.userInfo ?? {};
    final permissionsLevel = userInfo['permissionsLevel'] ?? '';
    final isAdmin = permissionsLevel == "admin";
    final users = (userInfo['users'] as List?) ?? [];
    final isLoading = userState.isLoading;

    return Scaffold(
      backgroundColor:
          isDarkMode ? TColors.backgroundDarkAlt : TColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            _buildCustomHeader(isDarkMode, context),
            // Tab Bar
            _buildTabBar(isDarkMode),
            // Content
            Expanded(
              child: AdvancedPullRefresh(
                onRefresh: _onRefresh,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    const AllTeamScreen(),
                    AllUsersScreen(
                      users: users,
                      isLoading: isLoading,
                      isAdmin: isAdmin,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(isDarkMode, context),
    );
  }

  Widget _buildCustomHeader(bool isDarkMode, BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      decoration: BoxDecoration(
        color: isDarkMode ? TColors.backgroundDarkAlt : TColors.backgroundLight,
        boxShadow: [
          BoxShadow(
            color: (isDarkMode ? Colors.black : Colors.grey).withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back Button
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDarkMode ? TColors.cardColorDark : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDarkMode ? TColors.borderDark : TColors.borderLight,
                width: 0.8,
              ),
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: isDarkMode
                    ? TColors.textSecondaryDark
                    : TColors.textTertiaryLight,
              ),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(width: 12),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Team Management',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDarkMode ? Colors.white : TColors.backgroundDark,
                  ),
                ),
                Text(
                  'Manage your workspace teams',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDarkMode
                        ? TColors.textSecondaryDark
                        : TColors.textTertiaryLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Search Icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDarkMode ? TColors.cardColorDark : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDarkMode ? TColors.borderDark : TColors.borderLight,
                width: 0.8,
              ),
            ),
            child: Icon(
              Icons.search_rounded,
              size: 16,
              color:
                  isDarkMode ? TColors.lightBlue : TColors.buttonPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
          20, 40, 20, 12), // reduced margin
      decoration: BoxDecoration(
        color: isDarkMode ? TColors.cardColorDark : Colors.white,
        borderRadius: BorderRadius.circular(8), // smaller radius
        border: Border.all(
          color: isDarkMode ? TColors.borderDark : TColors.borderLight,
          width: 0.7,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDarkMode ? Colors.black : Colors.grey).withOpacity(0.02),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(6), // smaller indicator
          color:
              isDarkMode ? TColors.buttonPrimary : TColors.buttonPrimaryLight,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor:
            isDarkMode ? TColors.textSecondaryDark : TColors.textTertiaryLight,
        labelStyle: const TextStyle(
          fontSize: 10, // smaller font
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 10, // smaller font
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(
            icon: Icon(Icons.groups_rounded, size: 14), // smaller icon
            text: 'Teams',
            height: 32, // reduce tab height
          ),
          Tab(
            icon: Icon(Icons.people_alt_rounded, size: 14), // smaller icon
            text: 'Users',
            height: 32, // reduce tab height
          ),
        ],
      
        isScrollable: false,
        splashFactory: NoSplash.splashFactory,
        padding: EdgeInsets.zero,
        labelPadding: const EdgeInsets.symmetric(horizontal: 0),
      ),
    );
  }


  Widget _buildFloatingActionButton(bool isDarkMode, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: (isDarkMode
                    ? TColors.buttonPrimary
                    : TColors.buttonPrimaryLight)
                .withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateTeamScreen()),
          );
        },
        backgroundColor:
            isDarkMode ? TColors.buttonPrimary : TColors.buttonPrimaryLight,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.add_rounded, size: 22),
      ),
    );
  }
}
