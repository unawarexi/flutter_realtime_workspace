// List of all 27 fields to check for completion
const PROFILE_FIELDS = [
  'fullName',
  'displayName',
  'profilePicture',
  'email',
  'phoneNumber',
  'roleTitle',
  'department',
  'workType',
  'timezone',
  'workingHours.start',
  'workingHours.end',
  'companyName',
  'companyWebsite',
  'industry',
  'teamSize',
  'officeLocation',
  'inviteCode',
  'teamProjectName',
  'permissionsLevel',
  'interestsSkills',
  'bio',
  'socialLinks.linkedIn',
  'socialLinks.github',
  'deviceInfo',
  'authProvider',
  'signupTimestamp',
  'ipAddress',
  'isVerified'
];

export function calculateProfileCompletion(userInfo) {
  let completed = 0;
  PROFILE_FIELDS.forEach((field) => {
    // Support nested fields (e.g., workingHours.start)
    const value = field.split('.').reduce((obj, key) => obj && obj[key], userInfo);
    if (value !== undefined && value !== null && !(Array.isArray(value) && value.length === 0) && value !== '') {
      completed += 1;
    }
  });
  // Each field is worth ~3.7% (100/27)
  return Math.round((completed / PROFILE_FIELDS.length) * 100);
}
