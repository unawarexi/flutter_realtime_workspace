// ============================================================================
// TeamSpot — Module Registry
// Auto-discovers and registers all module routes
// ============================================================================

import { createLogger } from "../observability/logger.js";

const log = createLogger("ModuleRegistry");

/**
 * Register all module routes on the Express app.
 * Each module exports a default Router from its routes file.
 */
export async function registerModules(app, apiPrefix) {
  // Each entry: { path, prefix, routeFile? }
  // routeFile overrides the auto-detection for modules with non-standard naming
  const modules = [
    { path: "auth", prefix: "/auth" },
    { path: "users", prefix: "/users" },
    { path: "organizations", prefix: "/organizations" },
    { path: "workspaces", prefix: "/workspaces" },
    { path: "teams", prefix: "/teams" },
    { path: "projects", prefix: "/projects" },
    { path: "tasks", prefix: "/tasks" },
    { path: "issues", prefix: "/issues" },
    { path: "tickets", prefix: "/tickets" },
    { path: "channels", prefix: "/channels" },
    { path: "communication", prefix: "/communication" },
    { path: "meetings", prefix: "/meetings" },
    { path: "notifications", prefix: "/notifications", routeFile: "fcm.routes.js" },
    { path: "documents", prefix: "/documents" },
    { path: "storage", prefix: "/storage" },
    { path: "search", prefix: "/search" },
    { path: "audit", prefix: "/audit" },
    { path: "analytics", prefix: "/analytics" },
    { path: "admin", prefix: "/admin" },
    { path: "billing", prefix: "/billing" },
    { path: "integrations", prefix: "/integrations" },
    { path: "workflows", prefix: "/workflows" },
    { path: "templates", prefix: "/templates" },
    { path: "feedback", prefix: "/feedback" },
    { path: "ai", prefix: "/ai" },
    { path: "identity", prefix: "/identity" },
    { path: "legal", prefix: "/legal" },
  ];

  const registered = [];

  for (const mod of modules) {
    try {
      let routeModule = null;

      if (mod.routeFile) {
        // Explicit route file override
        routeModule = await import(`../modules/${mod.path}/${mod.routeFile}`).catch(() => null);
      }

      if (!routeModule) {
        // Auto-detect: try singular, then plural, then path name
        const singular = mod.path.replace(/s$/, "");
        routeModule = await import(`../modules/${mod.path}/${singular}.routes.js`)
          .catch(() => import(`../modules/${mod.path}/${mod.path}.routes.js`))
          .catch(() => null);
      }

      if (routeModule?.default) {
        app.use(`${apiPrefix}${mod.prefix}`, routeModule.default);
        registered.push(mod.prefix);
        log.debug(`Module registered: ${mod.prefix}`);
      } else {
        log.debug(`Module skipped (no routes): ${mod.path}`);
      }
    } catch (err) {
      log.warn(`Failed to load module: ${mod.path}`, { error: err.message });
    }
  }

  log.info(`${registered.length} modules registered`, { routes: registered });
  return registered;
}

export default registerModules;
