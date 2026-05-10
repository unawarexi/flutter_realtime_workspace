// ============================================================================
// TeamSpot — MCP Resources
// Resource providers exposed via MCP protocol
// ============================================================================

export const mcpResources = [
  {
    uri: "teamspot://schemas/task",
    name: "Task Schema",
    mimeType: "application/json",
    read: async () => JSON.stringify({
      title: "string (required)", description: "string", projectId: "ObjectId (required)",
      status: "backlog|todo|in_progress|in_review|done|blocked|cancelled",
      priority: "lowest|low|medium|high|critical", assignedTo: "ObjectId", dueDate: "Date",
    }),
  },
  {
    uri: "teamspot://schemas/issue",
    name: "Issue Schema",
    mimeType: "application/json",
    read: async () => JSON.stringify({
      title: "string (required)", description: "string", projectId: "ObjectId (required)",
      type: "bug|feature|improvement|task|epic|story",
      severity: "trivial|minor|major|blocker", status: "open|in_progress|resolved|closed",
    }),
  },
  {
    uri: "teamspot://schemas/project",
    name: "Project Schema",
    mimeType: "application/json",
    read: async () => JSON.stringify({
      name: "string (required)", description: "string",
      template: "Kanban|Scrum|Blank Project", status: "active|archived|completed",
      priority: "low|medium|high|critical",
    }),
  },
];

export default mcpResources;
