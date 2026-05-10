import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/core/utils/constants/image_strings.dart';
import 'package:flutter_realtime_workspace/shared/styles/colors.dart';
import 'package:flutter_realtime_workspace/core/utils/helpers/helper_functions.dart';
import 'package:flutter_realtime_workspace/app/features/authentication/presentation/user_information.dart';

class OrganisationOptionsScreen extends StatelessWidget {
  const OrganisationOptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: isDarkMode ? TColors.backgroundDarkAlt : TColors.backgroundLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header
                Text(
                  "Welcome!",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: isDarkMode ? Colors.white : TColors.backgroundDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                // Description
                Text(
                  "Get started by creating a new organisation or joining an existing one. Collaborate, manage projects, and connect with your team.",
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode ? TColors.textSecondaryDark : TColors.textTertiaryLight,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                // Asset Image
                Image.asset(
                  TImages.lightAppLogo,
                  height: 120,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 36),
                // Create New Organisation Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserInformationScreen(mode: UserInfoMode.create),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ? TColors.buttonPrimary : TColors.buttonPrimaryLight,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      "Create New Organisation",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Join Existing Organisation Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserInformationScreen(mode: UserInfoMode.join),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: isDarkMode ? TColors.buttonPrimary : TColors.buttonPrimaryLight,
                        width: 1.2,
                      ),
                      foregroundColor: isDarkMode ? TColors.buttonPrimary : TColors.buttonPrimaryLight,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      "Join an Existing Organisation",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDarkMode ? TColors.buttonPrimary : TColors.buttonPrimaryLight,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
