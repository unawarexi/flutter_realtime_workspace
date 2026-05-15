import admin from "firebase-admin";
import { env } from "./env.config.js";

/**
 * Load Firebase service account credentials from env.config.js.
 * FIREBASE_SERVICE_ACCOUNT must be the full service-account JSON as a single-line string.
 */
function getServiceAccount() {
  if (!env.FIREBASE_SERVICE_ACCOUNT) {
    throw new Error(
      "FIREBASE_SERVICE_ACCOUNT is not set. " +
        "Add the full service-account JSON as a single-line string in .env.",
    );
  }
  try {
    return JSON.parse(env.FIREBASE_SERVICE_ACCOUNT);
  } catch (err) {
    console.error(
      "[Firebase Admin] Failed to parse FIREBASE_SERVICE_ACCOUNT:",
      err.message,
    );
    throw new Error(
      "FIREBASE_SERVICE_ACCOUNT is not valid JSON. " +
        "Make sure you pasted the entire service account JSON as a single line.",
    );
  }
}

const serviceAccount = getServiceAccount();

// Only initialize if not already initialized
let adminApp;
if (!admin.apps.length) {
  adminApp = admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: serviceAccount.project_id,
  });
  console.log(
    `[Firebase Admin] Initialized with project: ${serviceAccount.project_id}`,
  );
} else {
  adminApp = admin.app();
}

export { adminApp };
export default admin;