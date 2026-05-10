import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_realtime_workspace/app/features/authentication/presentation/widgets/options_screen.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_realtime_workspace/app/features/authentication/data/2fa_logic.dart';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:flutter_realtime_workspace/core/utils/helpers/helper_functions.dart';
import 'package:flutter_realtime_workspace/shared/styles/colors.dart';
import 'user_information.dart';

class TwoFAScreen extends StatefulWidget {
  const TwoFAScreen({super.key});

  @override
  State<TwoFAScreen> createState() => _TwoFAScreenState();
}

class _TwoFAScreenState extends State<TwoFAScreen> {
  String _code = '';
  final _formKey = GlobalKey<FormState>();
  Timer? _timer;
  int _secondsLeft = 300;
  DateTime? _expiry;
  bool _isVerifying = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    // _initCountdown();
  }

  // Future<void> _initCountdown() async {
  //   final uid = FirebaseAuth.instance.currentUser?.uid;
  //   if (uid == null) return;
  //   _expiry = await TwoFALogic.getExpiry(uid);
  //   if (_expiry == null) {
  //     setState(() => _secondsLeft = 0);
  //     return;
  //   }
  //   final diff = _expiry!.difference(DateTime.now()).inSeconds;
  //   setState(() => _secondsLeft = diff > 0 ? diff : 0);
  //   _timer?.cancel();
  //   _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
  //     if (_secondsLeft <= 0) {
  //       timer.cancel();
  //     } else {
  //       setState(() => _secondsLeft--);
  //     }
  //   });
  // }

  @override
  void dispose() {
    _timer?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  // Future<void> _resendCode() async {
  //   final uid = FirebaseAuth.instance.currentUser?.uid;
  //   if (uid == null) return;
  //   await TwoFALogic.generateAndSend2FACode(uid);
  //   await _initCountdown();
  //   setState(() {
  //     _errorText = null;
  //     _code = '';
  //   });
  // }

  // Future<void> _verifyCode() async {
  //   setState(() {
  //     _isVerifying = true;
  //     _errorText = null;
  //   });
  //   final uid = FirebaseAuth.instance.currentUser?.uid;
  //   if (uid == null) return;
  //   final valid = await TwoFALogic.verifyCode(uid, _code);
  //   if (!mounted) return;
  //   setState(() => _isVerifying = false);
  //   if (valid) {
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(
  //         builder: (context) => const OrganisationOptionsScreen(),
  //       ),
  //     );
  //   } else {
  //     setState(() {
  //       _errorText = "Invalid or expired code";
  //     });
  //   }
  // }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: isDarkMode ? TColors.backgroundDarkAlt : TColors.backgroundLight,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 32.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 48, color: isDarkMode ? TColors.buttonPrimary : TColors.buttonPrimaryLight),
                  const SizedBox(height: 18),
                  Text(
                    "Two-Factor Authentication",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: isDarkMode ? Colors.white : TColors.backgroundDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Enter the 6-digit code sent to your email or authenticator app.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDarkMode ? TColors.textSecondaryDark : TColors.textTertiaryLight,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    "Expires in: ${_formatTime(_secondsLeft)}",
                    style: TextStyle(
                      color: _secondsLeft > 0
                          ? (isDarkMode ? Colors.white : Colors.black)
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_errorText != null)
                    Text(
                      _errorText!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  const SizedBox(height: 28),
                  PinCodeTextField(
                    appContext: context,
                    length: 6,
                    obscureText: false,
                    animationType: AnimationType.fade,
                    keyboardType: TextInputType.number,
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(8),
                      fieldHeight: 48,
                      fieldWidth: 40,
                      activeFillColor: isDarkMode ? TColors.cardColorDark : Colors.white,
                      inactiveFillColor: isDarkMode ? TColors.backgroundDarkAlt : const Color(0xFFF8FAFC),
                      selectedFillColor: isDarkMode ? TColors.buttonPrimary : TColors.buttonPrimaryLight.withOpacity(0.1),
                      activeColor: isDarkMode ? TColors.buttonPrimary : TColors.buttonPrimaryLight,
                      selectedColor: isDarkMode ? TColors.buttonPrimary : TColors.buttonPrimaryLight,
                      inactiveColor: isDarkMode ? TColors.borderDark : TColors.borderLight,
                    ),
                    animationDuration: const Duration(milliseconds: 200),
                    backgroundColor: Colors.transparent,
                    enableActiveFill: true,
                    onChanged: (value) {
                      setState(() {
                        _code = value;
                        _errorText = null;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.length != 6) {
                        return "Enter 6 digits";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: (){},    // _secondsLeft == 0 ? _resendCode : null,
                    child: const Text("Send Again"),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:(){
                         Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const OrganisationOptionsScreen(),
                                    ),
                                  );
                      },
                      
                      // //_isVerifying
                      //     ? null
                      //     : () {
                      //         if (_formKey.currentState?.validate() ?? false) {
                      //           _verifyCode();
                      //         }
                      //       },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDarkMode ? TColors.buttonPrimary : TColors.buttonPrimaryLight,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isVerifying
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              "Verify",
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
