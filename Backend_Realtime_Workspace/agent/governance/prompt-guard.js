// ============================================================================
// TeamSpot — Prompt Guard
// Detects prompt injection, jailbreak attempts, and policy violations
// ============================================================================

import { createLogger } from "../../observability/logger.js";
const log = createLogger("PromptGuard");

const INJECTION_PATTERNS = [
  /ignore\s+(all\s+)?previous\s+instructions/i,
  /forget\s+(all\s+)?previous/i,
  /you\s+are\s+now\s+/i,
  /act\s+as\s+(if\s+you\s+are\s+)?a\s+different/i,
  /override\s+system\s+prompt/i,
  /reveal\s+(your\s+)?(system\s+)?prompt/i,
  /print\s+(your\s+)?instructions/i,
  /what\s+are\s+your\s+(system\s+)?instructions/i,
  /bypass\s+(safety|filter|guard)/i,
  /DAN\s+mode/i,
  /jailbreak/i,
];

const DATA_EXFIL_PATTERNS = [
  /list\s+all\s+users/i,
  /dump\s+(the\s+)?database/i,
  /show\s+all\s+passwords/i,
  /export\s+all\s+data/i,
  /give\s+me\s+api\s+keys/i,
  /show\s+environment\s+variables/i,
];

export class PromptGuard {
  async check(input) {
    // Injection detection
    for (const pattern of INJECTION_PATTERNS) {
      if (pattern.test(input)) {
        log.warn("Prompt injection detected", { pattern: pattern.source });
        return { blocked: true, reason: "prompt_injection", pattern: pattern.source };
      }
    }

    // Data exfiltration detection
    for (const pattern of DATA_EXFIL_PATTERNS) {
      if (pattern.test(input)) {
        log.warn("Data exfiltration attempt", { pattern: pattern.source });
        return { blocked: true, reason: "data_exfiltration", pattern: pattern.source };
      }
    }

    // Length check
    if (input.length > 50000) {
      return { blocked: true, reason: "input_too_long" };
    }

    return { blocked: false };
  }
}

export default PromptGuard;
