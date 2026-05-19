// ============================================================================
// TeamSpot — Legal Service
// Business logic for serving legal documents
// ============================================================================

import { termsOfService } from "../../core/data/terms-of-service.js";
import { privacyPolicy } from "../../core/data/privacy.js";

function mapSections(sections = []) {
  return sections.map((s) => ({
    title: s.heading ?? s.title ?? "",
    content: s.body ?? s.content ?? "",
  }));
}

export function getTermsOfService() {
  return {
    title: termsOfService.title,
    effectiveDate: termsOfService.effectiveDate,
    lastUpdated: termsOfService.lastUpdated,
    version: termsOfService.version,
    sections: mapSections(termsOfService.sections),
  };
}

export function getPrivacyPolicy() {
  return {
    title: privacyPolicy.title,
    effectiveDate: privacyPolicy.effectiveDate,
    lastUpdated: privacyPolicy.lastUpdated,
    version: privacyPolicy.version,
    sections: mapSections(privacyPolicy.sections),
  };
}

export function getAllLegalDocuments() {
  return {
    termsOfService: getTermsOfService(),
    privacyPolicy: getPrivacyPolicy(),
  };
}
