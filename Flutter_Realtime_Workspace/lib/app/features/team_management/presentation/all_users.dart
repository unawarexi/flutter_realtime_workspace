import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_realtime_workspace/app/features/team_management/presentation/widgets/view_user_detail.dart';
import 'package:flutter_realtime_workspace/shared/styles/colors.dart';
import 'package:flutter_realtime_workspace/core/utils/helpers/helper_functions.dart';

class AllUsersScreen extends StatelessWidget {
  final List users;
  final bool isLoading;
  final bool isAdmin;

  const AllUsersScreen({
    super.key,
    required this.users,
    required this.isLoading,
    required this.isAdmin,
  });

  void _copyToClipboard(BuildContext context, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text('Copied to clipboard', style: TextStyle(fontSize: 12)),
          ],
        ),
        backgroundColor: TColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = THelperFunctions.isDarkMode(context);

    if (!isAdmin) {
      return _buildAccessDeniedView(isDarkMode);
    }

    if (isLoading) {
      return _buildLoadingView(isDarkMode);
    }

    if (users.isEmpty) {
      return _buildEmptyView(isDarkMode);
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        itemCount: users.length,
        itemBuilder: (context, idx) {
          final user = users[idx] as Map<String, dynamic>;
          return _buildUserCard(context, user, isDarkMode);
        },
      ),
    );
  }

  Widget _buildAccessDeniedView(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: TColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.block_rounded,
              color: TColors.error,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Access Denied',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDarkMode ? Colors.white : TColors.backgroundDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You don\'t have permission to view all users.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? TColors.textSecondaryDark : TColors.textTertiaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: isDarkMode ? TColors.buttonPrimary : TColors.buttonPrimaryLight,
            strokeWidth: 2,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading users...',
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? TColors.textSecondaryDark : TColors.textTertiaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: (isDarkMode ? TColors.buttonPrimary : TColors.buttonPrimaryLight)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.people_alt_outlined,
              color: isDarkMode ? TColors.buttonPrimary : TColors.buttonPrimaryLight,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Users Found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDarkMode ? Colors.white : TColors.backgroundDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start by inviting team members to your workspace.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? TColors.textSecondaryDark : TColors.textTertiaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, Map<String, dynamic> user, bool isDarkMode) {
    final name = user['displayName'] ?? 'Unknown User';
    final email = user['email'] ?? '';
    final phone = user['phoneNumber'] ?? '';
    final inviteCode = user['inviteCode'] ?? '';
    final profilePicture = user['profilePicture'] ?? '';
    final position = user['roleTitle'] ?? 'No Position';
    final department = user['department'] ?? 'No Department';
    final isOnline = user['isOnline'] ?? false;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? TColors.cardColorDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDarkMode ? TColors.borderDark : TColors.borderLight,
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDarkMode ? Colors.black : Colors.grey).withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Picture with Status
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDarkMode ? TColors.buttonPrimary : TColors.buttonPrimaryLight,
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundImage: profilePicture.isNotEmpty
                        ? NetworkImage(profilePicture)
                        : const AssetImage("assets/images/avatar.png") as ImageProvider,
                    backgroundColor: isDarkMode ? TColors.cardColorDark : Colors.grey[100],
                  ),
                ),
                if (isOnline)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: TColors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDarkMode ? TColors.cardColorDark : Colors.white,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            
            // Name with Copy
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: isDarkMode ? Colors.white : TColors.backgroundDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _copyToClipboard(context, name),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: (isDarkMode ? TColors.buttonPrimary : TColors.buttonPrimaryLight)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.copy_rounded,
                      size: 10,
                      color: isDarkMode ? TColors.buttonPrimary : TColors.buttonPrimaryLight,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            
            // Position & Department
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (isDarkMode ? TColors.buttonPrimary : TColors.buttonPrimaryLight)
                    .withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                position,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? TColors.lightBlue : TColors.buttonPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              department,
              style: TextStyle(
                fontSize: 8,
                color: isDarkMode ? TColors.textSecondaryDark : TColors.textTertiaryLight,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // Contact Info
            _buildContactRow(
              icon: Icons.email_outlined,
              value: email,
              onCopy: () => _copyToClipboard(context, email),
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 4),
            _buildContactRow(
              icon: Icons.phone_outlined,
              value: phone.isNotEmpty ? phone : 'No phone',
              onCopy: phone.isNotEmpty ? () => _copyToClipboard(context, phone) : null,
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 4),
            _buildContactRow(
              icon: Icons.qr_code_rounded,
              value: inviteCode.isNotEmpty ? inviteCode : 'No code',
              onCopy: inviteCode.isNotEmpty ? () => _copyToClipboard(context, inviteCode) : null,
              isDarkMode: isDarkMode,
            ),
            const Spacer(),
            
            // View Detail Button
            Flexible(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode ? TColors.buttonPrimary : TColors.buttonPrimaryLight,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.visibility_rounded, size: 13),
                      SizedBox(width: 5),
                      Text(
                        'View Detail',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ViewUserDetail(user: user),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow({
    required IconData icon,
    required String value,
    required VoidCallback? onCopy,
    required bool isDarkMode,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 10, color: isDarkMode ? TColors.lightBlue : TColors.buttonPrimaryLight),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 9,
              color: isDarkMode ? Colors.white70 : TColors.textSecondaryDark,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        if (onCopy != null)
          GestureDetector(
            onTap: onCopy,
            child: Padding(
              padding: const EdgeInsets.only(left: 3),
              child: Icon(
                Icons.copy_rounded,
                size: 9,
                color: isDarkMode ? TColors.buttonPrimary : TColors.buttonPrimaryLight,
              ),
            ),
          ),
      ],
    );
  }
}