import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_realtime_workspace/shared/styles/colors.dart';
import 'package:flutter_realtime_workspace/core/utils/helpers/helper_functions.dart';

class ViewUserDetail extends StatelessWidget {
  final Map<String, dynamic> user;
  const ViewUserDetail({super.key, required this.user});

  void _copyToClipboard(BuildContext context, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 16),
            const SizedBox(width: 8),
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

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value, {bool copy = false}) {
    final isDarkMode = THelperFunctions.isDarkMode(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: isDarkMode ? TColors.buttonPrimary : TColors.buttonPrimaryLight),
          const SizedBox(width: 8),
          Text(
            "$label:",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 11,
              color: isDarkMode ? Colors.white : TColors.backgroundDark,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                color: isDarkMode ? Colors.white70 : TColors.textSecondaryDark,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          if (copy)
            GestureDetector(
              onTap: () => _copyToClipboard(context, value),
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(Icons.copy_rounded, size: 12, color: isDarkMode ? TColors.buttonPrimary : TColors.buttonPrimaryLight),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = THelperFunctions.isDarkMode(context);
    final profilePicture = user['profilePicture'] ?? '';
    final name = user['displayName'] ?? '';
    final fullName = user['fullName'] ?? '';
    final email = user['email'] ?? '';
    final phone = user['phoneNumber'] ?? '';
    final inviteCode = user['inviteCode'] ?? '';
    final company = user['companyName'] ?? '';
    final department = user['department'] ?? '';
    final role = user['roleTitle'] ?? '';
    final team = user['teamProjectName'] ?? '';
    final teamSize = user['teamSize'] ?? '';
    final industry = user['industry'] ?? '';
    final location = user['officeLocation'] ?? '';
    final workType = user['workType'] ?? '';
    final timezone = user['timezone'] ?? '';
    final website = user['companyWebsite'] ?? '';
    final bio = user['bio'] ?? '';
    final profileCompletion = user['profileCompletion']?.toString() ?? '0';
    final permissionLevel = user['permissionsLevel'] ?? '';
    final socialLinks = user['socialLinks'] ?? {};
    final interestsSkills = user['interestsSkills'] ?? [];
    final workingHours = user['workingHours'] ?? {};
    final createdAt = user['createdAt']?.toString() ?? '';
    final updatedAt = user['updatedAt']?.toString() ?? '';

    return Scaffold(
      backgroundColor: isDarkMode ? TColors.backgroundDarkAlt : TColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDarkMode ? TColors.backgroundDarkAlt : TColors.backgroundLight,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : TColors.backgroundDark,
        ),
        title: Text(
          'User Detail',
          style: TextStyle(
            color: isDarkMode ? Colors.white : TColors.backgroundDark,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Picture
            Center(
              child: CircleAvatar(
                radius: 38,
                backgroundImage: profilePicture.isNotEmpty
                    ? NetworkImage(profilePicture)
                    : const AssetImage("assets/images/avatar.png") as ImageProvider,
                backgroundColor: isDarkMode ? TColors.cardColorDark : Colors.grey[100],
              ),
            ),
            const SizedBox(height: 10),
            // Name and Role
            Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: isDarkMode ? Colors.white : TColors.backgroundDark,
              ),
              textAlign: TextAlign.center,
            ),
            if (role.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  role,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDarkMode ? TColors.lightBlue : TColors.buttonPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            if (department.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text(
                  department,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDarkMode ? TColors.textSecondaryDark : TColors.textTertiaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 14),
            // Info rows
            _buildInfoRow(context, Icons.person_outline, "Full Name", fullName),
            _buildInfoRow(context, Icons.email_outlined, "Email", email, copy: true),
            _buildInfoRow(context, Icons.phone_outlined, "Phone", phone, copy: true),
            _buildInfoRow(context, Icons.qr_code_rounded, "Invite Code", inviteCode, copy: true),
            _buildInfoRow(context, Icons.business_outlined, "Company", company),
            _buildInfoRow(context, Icons.groups_rounded, "Team", team),
            _buildInfoRow(context, Icons.people_alt_rounded, "Team Size", teamSize),
            _buildInfoRow(context, Icons.work_outline_rounded, "Industry", industry),
            _buildInfoRow(context, Icons.location_on_outlined, "Location", location),
            _buildInfoRow(context, Icons.access_time_rounded, "Working Hours",
              workingHours is Map && workingHours.isNotEmpty
                ? "Start: ${workingHours['start'] ?? ''}, End: ${workingHours['end'] ?? ''}"
                : "Not set"
            ),
            _buildInfoRow(context, Icons.laptop_mac_rounded, "Work Type", workType),
            _buildInfoRow(context, Icons.language_rounded, "Timezone", timezone),
            _buildInfoRow(context, Icons.link_rounded, "Website", website),
            _buildInfoRow(context, Icons.info_outline_rounded, "Bio", bio),
            _buildInfoRow(context, Icons.percent_rounded, "Profile Completion", "$profileCompletion%"),
            _buildInfoRow(context, Icons.security_rounded, "Permission Level", permissionLevel),
            // Social links
            if (socialLinks is Map && socialLinks.isNotEmpty)
              ...socialLinks.entries.map((e) =>
                _buildInfoRow(context, Icons.link, "Social (${e.key})", e.value?.toString() ?? '')
              ),
            // Interests/Skills
            if (interestsSkills is List && interestsSkills.isNotEmpty)
              _buildInfoRow(context, Icons.star_rounded, "Interests/Skills", interestsSkills.join(', ')),
            // Created/Updated
            _buildInfoRow(context, Icons.calendar_today_rounded, "Created At", createdAt),
            _buildInfoRow(context, Icons.update_rounded, "Updated At", updatedAt),
          ],
        ),
      ),
    );
  }
}
