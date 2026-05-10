// import 'dart:async';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:flutter_realtime_workspace/core/utils/permission_handler.dart';

// /// Modern Permission Dialog similar to Instagram/Facebook
// class ModernPermissionDialog extends StatelessWidget {
//   final String title;
//   final String message;
//   final String iconPath;
//   final VoidCallback onGrantAccess;
//   final VoidCallback onDeclineAccess;
//   final IconData icon;

//   const ModernPermissionDialog({
//     super.key,
//     required this.title,
//     required this.message,
//     required this.onGrantAccess,
//     required this.onDeclineAccess,
//     required this.icon,
//     this.iconPath = '',
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       backgroundColor: Colors.transparent,
//       elevation: 0,
//       child: Container(
//         padding: const EdgeInsets.all(24),
//         decoration: BoxDecoration(
//           color: Theme.of(context).brightness == Brightness.dark
//               ? const Color(0xFF1E1E1E)
//               : Colors.white,
//           borderRadius: BorderRadius.circular(20),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.1),
//               blurRadius: 20,
//               offset: const Offset(0, 10),
//             ),
//           ],
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             // Icon with gradient background
//             Container(
//               width: 80,
//               height: 80,
//               decoration: BoxDecoration(
//                 gradient: const LinearGradient(
//                   colors: [Color(0xFF667eea), Color(0xFF764ba2)],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//                 borderRadius: BorderRadius.circular(40),
//               ),
//               child: Icon(
//                 icon,
//                 size: 40,
//                 color: Colors.white,
//               ),
//             ),
//             const SizedBox(height: 20),
//             Text(
//               title,
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.w600,
//                 color: Theme.of(context).brightness == Brightness.dark
//                     ? Colors.white
//                     : const Color(0xFF1A1A1A),
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 12),
//             Text(
//               message,
//               style: TextStyle(
//                 fontSize: 16,
//                 color: Theme.of(context).brightness == Brightness.dark
//                     ? Colors.white70
//                     : const Color(0xFF666666),
//                 height: 1.4,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 28),
//             Column(
//               children: [
//                 SizedBox(
//                   width: double.infinity,
//                   height: 50,
//                   child: ElevatedButton(
//                     onPressed: onGrantAccess,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF007AFF),
//                       foregroundColor: Colors.white,
//                       elevation: 0,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     child: const Text(
//                       'Grant Access',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 SizedBox(
//                   width: double.infinity,
//                   height: 50,
//                   child: TextButton(
//                     onPressed: onDeclineAccess,
//                     style: TextButton.styleFrom(
//                       foregroundColor:
//                           Theme.of(context).brightness == Brightness.dark
//                               ? Colors.white70
//                               : const Color(0xFF666666),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     child: const Text(
//                       'Not Now',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// /// Settings Dialog for permanently denied permissions
// class PermissionSettingsDialog extends StatelessWidget {
//   final String title;
//   final String message;
//   final IconData icon;

//   const PermissionSettingsDialog({
//     Key? key,
//     required this.title,
//     required this.message,
//     required this.icon,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       backgroundColor: Colors.transparent,
//       elevation: 0,
//       child: Container(
//         padding: const EdgeInsets.all(24),
//         decoration: BoxDecoration(
//           color: Theme.of(context).brightness == Brightness.dark
//               ? const Color(0xFF1E1E1E)
//               : Colors.white,
//           borderRadius: BorderRadius.circular(20),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.1),
//               blurRadius: 20,
//               offset: const Offset(0, 10),
//             ),
//           ],
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               width: 80,
//               height: 80,
//               decoration: BoxDecoration(
//                 gradient: const LinearGradient(
//                   colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//                 borderRadius: BorderRadius.circular(40),
//               ),
//               child: Icon(
//                 icon,
//                 size: 40,
//                 color: Colors.white,
//               ),
//             ),
//             const SizedBox(height: 20),
//             Text(
//               title,
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.w600,
//                 color: Theme.of(context).brightness == Brightness.dark
//                     ? Colors.white
//                     : const Color(0xFF1A1A1A),
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 12),
//             Text(
//               message,
//               style: TextStyle(
//                 fontSize: 16,
//                 color: Theme.of(context).brightness == Brightness.dark
//                     ? Colors.white70
//                     : const Color(0xFF666666),
//                 height: 1.4,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 28),
//             Column(
//               children: [
//                 SizedBox(
//                   width: double.infinity,
//                   height: 50,
//                   child: ElevatedButton(
//                     onPressed: () {
//                       Navigator.of(context).pop();
//                       openAppSettings();
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF007AFF),
//                       foregroundColor: Colors.white,
//                       elevation: 0,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     child: const Text(
//                       'Open Settings',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 SizedBox(
//                   width: double.infinity,
//                   height: 50,
//                   child: TextButton(
//                     onPressed: () => Navigator.of(context).pop(),
//                     style: TextButton.styleFrom(
//                       foregroundColor:
//                           Theme.of(context).brightness == Brightness.dark
//                               ? Colors.white70
//                               : const Color(0xFF666666),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     child: const Text(
//                       'Cancel',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// /// Enhanced Permission Manager with modern UI
// class EnhancedPermissionManager {
//   static Future<bool> _showModernPermissionDialog(
//     BuildContext context, {
//     required String title,
//     required String message,
//     required IconData icon,
//   }) async {
//     final completer = Completer<bool>();
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => ModernPermissionDialog(
//         title: title,
//         message: message,
//         icon: icon,
//         onGrantAccess: () {
//           Navigator.of(context).pop();
//           completer.complete(true);
//         },
//         onDeclineAccess: () {
//           Navigator.of(context).pop();
//           completer.complete(false);
//         },
//       ),
//     );
//     return completer.future;
//   }

//   static Future<void> _showSettingsDialog(
//     BuildContext context, {
//     required String title,
//     required String message,
//     required IconData icon,
//   }) async {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => PermissionSettingsDialog(
//         title: title,
//         message: message,
//         icon: icon,
//       ),
//     );
//   }

//   static Future<bool> requestPermissionWithModernUI(
//     BuildContext context, {
//     required Permission permission,
//     required String title,
//     required String message,
//     required IconData icon,
//   }) async {
//     final status = await permission.status;
//     if (status.isGranted) {
//       return true;
//     }
//     if (status.isPermanentlyDenied) {
//       await _showSettingsDialog(
//         context,
//         title: "Permission Required",
//         message:
//             "This permission has been permanently denied. Please enable it in app settings to continue.",
//         icon: Icons.settings,
//       );
//       return false;
//     }
//     final userGranted = await _showModernPermissionDialog(
//       context,
//       title: title,
//       message: message,
//       icon: icon,
//     );
//     if (!userGranted) {
//       return false;
//     }
//     final result = await permission.request();
//     if (result.isPermanentlyDenied) {
//       await _showSettingsDialog(
//         context,
//         title: "Permission Required",
//         message:
//             "This permission has been permanently denied. Please enable it in app settings to continue.",
//         icon: Icons.settings,
//       );
//       return false;
//     }
//     return result.isGranted;
//   }

//   /// Request storage/photos/videos permission with modern UI
//   static Future<bool> requestStoragePermission(BuildContext context) async {
//     if (Platform.isIOS) {
//       final alreadyGranted = await PermissionManager.isPermissionGranted(Permission.photos);
//       if (alreadyGranted) return true;
//     } else if (Platform.isAndroid) {
//       final androidVersion = await _getAndroidSdkInt();
//       if (androidVersion != null && androidVersion >= 33) {
//         final photosGranted = await PermissionManager.isPermissionGranted(Permission.photos);
//         final videosGranted = await PermissionManager.isPermissionGranted(Permission.videos);
//         if (photosGranted && videosGranted) return true;
//       } else if (androidVersion != null && androidVersion >= 30) {
//         final manageGranted = await PermissionManager.isPermissionGranted(Permission.manageExternalStorage);
//         if (manageGranted) return true;
//       } else {
//         final storageGranted = await PermissionManager.isPermissionGranted(Permission.storage);
//         if (storageGranted) return true;
//       }
//     }
//     final result = await PermissionManager.requestStorageSmart();
//     if (result.isGranted) {
//       return true;
//     }
//     await _showSettingsDialog(
//       context,
//       title: "Permission Required",
//       message: result.message,
//       icon: Icons.settings,
//     );
//     return false;
//   }

//   static Future<int?> _getAndroidSdkInt() async {
//     try {
//       // Use platform channel or device_info_plus for real implementation.
//       // Here, always return null to fallback (or implement as needed).
//       return null;
//     } catch (_) {
//       return null;
//     }
//   }

//   static Future<bool> requestCameraPermission(BuildContext context) async {
//     return await requestPermissionWithModernUI(
//       context,
//       permission: Permission.camera,
//       title: "Access Camera",
//       message:
//           "We need access to your camera to let you take photos and videos.",
//       icon: Icons.camera_alt,
//     );
//   }

//   static Future<bool> requestMicrophonePermission(BuildContext context) async {
//     return await requestPermissionWithModernUI(
//       context,
//       permission: Permission.microphone,
//       title: "Access Microphone",
//       message:
//           "We need access to your microphone to record audio and enable voice features.",
//       icon: Icons.mic,
//     );
//   }
// }
