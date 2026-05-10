// ============================================================================
// TeamSpot — MCP Tools
// Tool definitions exposed via MCP protocol
// ============================================================================

export const mcpTools = [
  {
    name: "teamspot_search",
    description: "Search across workspace documents, tasks, issues, and messages",
    schema: { type: "object", properties: { query: { type: "string" }, scope: { type: "string", enum: ["all", "tasks", "issues", "documents", "messages"] } }, required: ["query"] },
    handler: async ({ query, scope = "all" }) => ({ results: [], query, scope, message: "Connect vector DB to enable search" }),
  },
  {
    name: "teamspot_create_task",
    description: "Create a new task in a TeamSpot project",
    schema: { type: "object", properties: { title: { type: "string" }, projectId: { type: "string" }, priority: { type: "string" }, assignee: { type: "string" } }, required: ["title", "projectId"] },
    handler: async (args) => ({ created: true, ...args }),
  },
  {
    name: "teamspot_project_status",
    description: "Get current status and progress of a project",
    schema: { type: "object", properties: { projectId: { type: "string" } }, required: ["projectId"] },
    handler: async ({ projectId }) => ({ projectId, status: "active", progress: 0 }),
  },
];

export default mcpTools;
