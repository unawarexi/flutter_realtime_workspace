// ============================================================================
// TeamSpot — MCP Server
// Model Context Protocol server for external tool integrations
// ============================================================================

import { createLogger } from "../../observability/logger.js";
import { mcpTools } from "./mcp-tools.js";
import { mcpResources } from "./mcp-resources.js";
const log = createLogger("MCP");

export class MCPServer {
  constructor() {
    this.tools = mcpTools;
    this.resources = mcpResources;
  }

  /** Handle incoming MCP request */
  async handleRequest(request) {
    const { method, params } = request;

    switch (method) {
      case "tools/list":
        return { tools: this.tools.map((t) => ({ name: t.name, description: t.description, inputSchema: t.schema })) };

      case "tools/call":
        return this._callTool(params.name, params.arguments);

      case "resources/list":
        return { resources: this.resources.map((r) => ({ uri: r.uri, name: r.name, mimeType: r.mimeType })) };

      case "resources/read":
        return this._readResource(params.uri);

      default:
        return { error: { code: -32601, message: `Method not found: ${method}` } };
    }
  }

  async _callTool(name, args) {
    const tool = this.tools.find((t) => t.name === name);
    if (!tool) return { error: { code: -32602, message: `Unknown tool: ${name}` } };
    try {
      const result = await tool.handler(args);
      return { content: [{ type: "text", text: JSON.stringify(result) }] };
    } catch (err) {
      log.error("MCP tool error", { tool: name, error: err.message });
      return { error: { code: -32000, message: err.message } };
    }
  }

  async _readResource(uri) {
    const resource = this.resources.find((r) => r.uri === uri);
    if (!resource) return { error: { code: -32602, message: `Unknown resource: ${uri}` } };
    try {
      const content = await resource.read();
      return { contents: [{ uri, mimeType: resource.mimeType, text: content }] };
    } catch (err) {
      return { error: { code: -32000, message: err.message } };
    }
  }
}

export default MCPServer;
