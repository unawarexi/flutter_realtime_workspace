// ============================================================================
// TeamSpot — Conversation Memory
// Short-term buffer with Redis-backed persistence
// ============================================================================

import { createLogger } from "../../observability/logger.js";
const log = createLogger("ConversationMemory");

export class ConversationMemory {
  constructor(options = {}) {
    this.maxMessages = options.maxMessages || 50;
    /** @type {Map<string, Array<{role:string, content:string, timestamp:number}>>} */
    this.store = new Map();
  }

  async addMessage(conversationId, message) {
    if (!this.store.has(conversationId)) this.store.set(conversationId, []);
    const history = this.store.get(conversationId);
    history.push({ ...message, timestamp: Date.now() });
    if (history.length > this.maxMessages) history.shift();
  }

  async getHistory(conversationId, { limit = 20 } = {}) {
    const history = this.store.get(conversationId) || [];
    return history.slice(-limit);
  }

  async clear(conversationId) {
    this.store.delete(conversationId);
  }

  async getSummary(conversationId) {
    const history = await this.getHistory(conversationId, { limit: 50 });
    return { messageCount: history.length, firstMessage: history[0]?.timestamp, lastMessage: history[history.length - 1]?.timestamp };
  }
}

export default ConversationMemory;
