import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/core/db/hive.dart';
import 'package:flutter_realtime_workspace/core/services/storage_service.dart';

// ============================================================================
// SETTINGS STATE
// ============================================================================

class AppSettings {
  // AI Features
  final bool aiCopilotEnabled;
  final bool aiTranscriptionEnabled;
  final bool aiCoachingEnabled;
  final bool aiVoiceAssistantEnabled;

  // General
  final bool notificationsEnabled;
  final bool darkMode;
  final bool compactMode;
  final bool autoSync;
  final bool enableAnimations;
  final bool showAvatars;

  // Notification channels
  final bool pushNotifications;
  final bool emailNotifications;
  final bool mentionNotifications;
  final bool taskUpdates;
  final bool sound;
  final bool vibrate;

  // Meeting Defaults
  final bool cameraOnByDefault;
  final bool micOnByDefault;
  final bool autoRecordEnabled;

  // Privacy & security
  final bool biometricLogin;
  final bool twoFactorAuth;
  final bool allowSearch;
  final bool showOnlineStatus;
  final bool dataCollection;
  final String locale;

  const AppSettings({
    this.aiCopilotEnabled = true,
    this.aiTranscriptionEnabled = true,
    this.aiCoachingEnabled = false,
    this.aiVoiceAssistantEnabled = true,
    this.notificationsEnabled = true,
    this.darkMode = false,
    this.compactMode = false,
    this.autoSync = true,
    this.enableAnimations = true,
    this.showAvatars = true,
    this.pushNotifications = true,
    this.emailNotifications = false,
    this.mentionNotifications = true,
    this.taskUpdates = true,
    this.sound = true,
    this.vibrate = false,
    this.cameraOnByDefault = true,
    this.micOnByDefault = true,
    this.autoRecordEnabled = false,
    this.biometricLogin = false,
    this.twoFactorAuth = false,
    this.allowSearch = true,
    this.showOnlineStatus = true,
    this.dataCollection = false,
    this.locale = 'en',
  });

  AppSettings copyWith({
    bool? aiCopilotEnabled,
    bool? aiTranscriptionEnabled,
    bool? aiCoachingEnabled,
    bool? aiVoiceAssistantEnabled,
    bool? notificationsEnabled,
    bool? darkMode,
    bool? compactMode,
    bool? autoSync,
    bool? enableAnimations,
    bool? showAvatars,
    bool? pushNotifications,
    bool? emailNotifications,
    bool? mentionNotifications,
    bool? taskUpdates,
    bool? sound,
    bool? vibrate,
    bool? cameraOnByDefault,
    bool? micOnByDefault,
    bool? autoRecordEnabled,
    bool? biometricLogin,
    bool? twoFactorAuth,
    bool? allowSearch,
    bool? showOnlineStatus,
    bool? dataCollection,
    String? locale,
  }) =>
      AppSettings(
        aiCopilotEnabled: aiCopilotEnabled ?? this.aiCopilotEnabled,
        aiTranscriptionEnabled: aiTranscriptionEnabled ?? this.aiTranscriptionEnabled,
        aiCoachingEnabled: aiCoachingEnabled ?? this.aiCoachingEnabled,
        aiVoiceAssistantEnabled: aiVoiceAssistantEnabled ?? this.aiVoiceAssistantEnabled,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        darkMode: darkMode ?? this.darkMode,
        compactMode: compactMode ?? this.compactMode,
        autoSync: autoSync ?? this.autoSync,
        enableAnimations: enableAnimations ?? this.enableAnimations,
        showAvatars: showAvatars ?? this.showAvatars,
        pushNotifications: pushNotifications ?? this.pushNotifications,
        emailNotifications: emailNotifications ?? this.emailNotifications,
        mentionNotifications: mentionNotifications ?? this.mentionNotifications,
        taskUpdates: taskUpdates ?? this.taskUpdates,
        sound: sound ?? this.sound,
        vibrate: vibrate ?? this.vibrate,
        cameraOnByDefault: cameraOnByDefault ?? this.cameraOnByDefault,
        micOnByDefault: micOnByDefault ?? this.micOnByDefault,
        autoRecordEnabled: autoRecordEnabled ?? this.autoRecordEnabled,
        biometricLogin: biometricLogin ?? this.biometricLogin,
        twoFactorAuth: twoFactorAuth ?? this.twoFactorAuth,
        allowSearch: allowSearch ?? this.allowSearch,
        showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
        dataCollection: dataCollection ?? this.dataCollection,
        locale: locale ?? this.locale,
      );

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        aiCopilotEnabled: json['aiCopilotEnabled'] ?? true,
        aiTranscriptionEnabled: json['aiTranscriptionEnabled'] ?? true,
        aiCoachingEnabled: json['aiCoachingEnabled'] ?? false,
        aiVoiceAssistantEnabled: json['aiVoiceAssistantEnabled'] ?? true,
        notificationsEnabled: json['notificationsEnabled'] ?? true,
        darkMode: json['darkMode'] ?? false,
        compactMode: json['compactMode'] ?? false,
        autoSync: json['autoSync'] ?? true,
        enableAnimations: json['enableAnimations'] ?? true,
        showAvatars: json['showAvatars'] ?? true,
        pushNotifications: json['pushNotifications'] ?? true,
        emailNotifications: json['emailNotifications'] ?? false,
        mentionNotifications: json['mentionNotifications'] ?? true,
        taskUpdates: json['taskUpdates'] ?? true,
        sound: json['sound'] ?? true,
        vibrate: json['vibrate'] ?? false,
        cameraOnByDefault: json['cameraOnByDefault'] ?? true,
        micOnByDefault: json['micOnByDefault'] ?? true,
        autoRecordEnabled: json['autoRecordEnabled'] ?? false,
        biometricLogin: json['biometricLogin'] ?? false,
        twoFactorAuth: json['twoFactorAuth'] ?? false,
        allowSearch: json['allowSearch'] ?? true,
        showOnlineStatus: json['showOnlineStatus'] ?? true,
        dataCollection: json['dataCollection'] ?? false,
        locale: json['locale'] ?? 'en',
      );

  Map<String, dynamic> toJson() => {
        'aiCopilotEnabled': aiCopilotEnabled,
        'aiTranscriptionEnabled': aiTranscriptionEnabled,
        'aiCoachingEnabled': aiCoachingEnabled,
        'aiVoiceAssistantEnabled': aiVoiceAssistantEnabled,
        'notificationsEnabled': notificationsEnabled,
        'darkMode': darkMode,
        'compactMode': compactMode,
        'autoSync': autoSync,
        'enableAnimations': enableAnimations,
        'showAvatars': showAvatars,
        'pushNotifications': pushNotifications,
        'emailNotifications': emailNotifications,
        'mentionNotifications': mentionNotifications,
        'taskUpdates': taskUpdates,
        'sound': sound,
        'vibrate': vibrate,
        'cameraOnByDefault': cameraOnByDefault,
        'micOnByDefault': micOnByDefault,
        'autoRecordEnabled': autoRecordEnabled,
        'biometricLogin': biometricLogin,
        'twoFactorAuth': twoFactorAuth,
        'allowSearch': allowSearch,
        'showOnlineStatus': showOnlineStatus,
        'dataCollection': dataCollection,
        'locale': locale,
      };
}

// ============================================================================
// SETTINGS NOTIFIER
// ============================================================================

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(_loadFromStorage());

  static AppSettings _loadFromStorage() {
    final cached = HiveService.read<Map>(HiveService.settings, 'app_settings');
    if (cached != null) {
      return AppSettings.fromJson(Map<String, dynamic>.from(cached));
    }

    return AppSettings(
      aiCopilotEnabled: LocalStorageService.aiCopilotEnabled,
      aiTranscriptionEnabled: LocalStorageService.aiTranscriptionEnabled,
      aiCoachingEnabled: LocalStorageService.aiCoachingEnabled,
      aiVoiceAssistantEnabled: LocalStorageService.aiVoiceAssistantEnabled,
      notificationsEnabled: LocalStorageService.notificationsEnabled,
      cameraOnByDefault: LocalStorageService.cameraOnByDefault,
      micOnByDefault: LocalStorageService.micOnByDefault,
      autoRecordEnabled: LocalStorageService.autoRecordEnabled,
      biometricLogin: LocalStorageService.biometricEnabled,
      darkMode: LocalStorageService.themeMode == 'dark',
    );
  }

  void _set(AppSettings next) {
    state = next;
    HiveService.write(
      HiveService.settings,
      'app_settings',
      state.toJson(),
      ttl: const Duration(days: 365),
    );
  }

  // ── AI Features ──

  void toggleAiCopilot() {
    final v = !state.aiCopilotEnabled;
    _set(state.copyWith(aiCopilotEnabled: v));
    LocalStorageService.setAiCopilotEnabled(v);
  }

  void toggleAiTranscription() {
    final v = !state.aiTranscriptionEnabled;
    _set(state.copyWith(aiTranscriptionEnabled: v));
    LocalStorageService.setAiTranscriptionEnabled(v);
  }

  void toggleAiCoaching() {
    final v = !state.aiCoachingEnabled;
    _set(state.copyWith(aiCoachingEnabled: v));
    LocalStorageService.setAiCoachingEnabled(v);
  }

  void toggleAiVoiceAssistant() {
    final v = !state.aiVoiceAssistantEnabled;
    _set(state.copyWith(aiVoiceAssistantEnabled: v));
    LocalStorageService.setAiVoiceAssistantEnabled(v);
  }

  // ── General ──

  void toggleNotifications() {
    final v = !state.notificationsEnabled;
    _set(state.copyWith(notificationsEnabled: v));
    LocalStorageService.setNotificationsEnabled(v);
  }

  void setNotificationsEnabled(bool value) {
    _set(state.copyWith(notificationsEnabled: value));
    LocalStorageService.setNotificationsEnabled(value);
  }

  void setDarkMode(bool value) {
    _set(state.copyWith(darkMode: value));
    LocalStorageService.setThemeMode(value ? 'dark' : 'light');
  }

  void setCompactMode(bool value) => _set(state.copyWith(compactMode: value));
  void setAutoSync(bool value) => _set(state.copyWith(autoSync: value));
  void setEnableAnimations(bool value) => _set(state.copyWith(enableAnimations: value));
  void setShowAvatars(bool value) => _set(state.copyWith(showAvatars: value));

  void setPushNotifications(bool value) => _set(state.copyWith(pushNotifications: value));
  void setEmailNotifications(bool value) => _set(state.copyWith(emailNotifications: value));
  void setMentionNotifications(bool value) => _set(state.copyWith(mentionNotifications: value));
  void setTaskUpdates(bool value) => _set(state.copyWith(taskUpdates: value));
  void setSound(bool value) => _set(state.copyWith(sound: value));
  void setVibrate(bool value) => _set(state.copyWith(vibrate: value));

  // ── Meeting Defaults ──

  void toggleCameraDefault() {
    final v = !state.cameraOnByDefault;
    _set(state.copyWith(cameraOnByDefault: v));
    LocalStorageService.setCameraOnByDefault(v);
  }

  void toggleMicDefault() {
    final v = !state.micOnByDefault;
    _set(state.copyWith(micOnByDefault: v));
    LocalStorageService.setMicOnByDefault(v);
  }

  void toggleAutoRecord() {
    final v = !state.autoRecordEnabled;
    _set(state.copyWith(autoRecordEnabled: v));
    LocalStorageService.setAutoRecordEnabled(v);
  }

  void setBiometricLogin(bool value) {
    _set(state.copyWith(biometricLogin: value));
    LocalStorageService.setBiometricEnabled(value);
  }

  void setTwoFactorAuth(bool value) => _set(state.copyWith(twoFactorAuth: value));
  void setAllowSearch(bool value) => _set(state.copyWith(allowSearch: value));
  void setShowOnlineStatus(bool value) => _set(state.copyWith(showOnlineStatus: value));
  void setDataCollection(bool value) => _set(state.copyWith(dataCollection: value));
  void setLocale(String value) => _set(state.copyWith(locale: value));
}
