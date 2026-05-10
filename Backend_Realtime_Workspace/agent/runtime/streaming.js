// ============================================================================
// TeamSpot — Streaming Responses
// Handles both LangChain model streams and LangGraph graph streamEvents.
// ============================================================================

import { createLogger } from "../../observability/logger.js";

const log = createLogger("Streaming");

// ── SSE helpers ──────────────────────────────────────────────────────────────

function sseHeaders(res) {
  res.writeHead(200, {
    "Content-Type":    "text/event-stream",
    "Cache-Control":   "no-cache",
    Connection:        "keep-alive",
    "X-Accel-Buffering": "no",
  });
}

function writeSSE(res, payload) {
  res.write(`data: ${JSON.stringify(payload)}\n\n`);
}

// ── LangGraph graph.streamEvents ─────────────────────────────────────────────

/**
 * Stream a LangGraph compiled graph via Server-Sent Events.
 * Uses the LangGraph v2 event stream to surface token chunks, tool starts, and tool ends.
 *
 * @param {CompiledGraph} graph  — Compiled LangGraph StateGraph
 * @param {Object}        input  — Graph input (e.g. { messages: [...] })
 * @param {Response}      res    — Express response
 * @param {Object}        [config] — LangGraph run config (e.g. thread_id for checkpointing)
 */
export async function streamGraphResponse(graph, input, res, config = {}) {
  sseHeaders(res);

  let fullContent = "";

  try {
    const eventStream = await graph.streamEvents(input, { version: "v2", ...config });

    for await (const event of eventStream) {
      switch (event.event) {
        case "on_chat_model_stream": {
          const chunk = event.data?.chunk;
          const content = chunk?.content || "";
          if (content) {
            fullContent += content;
            writeSSE(res, { type: "token", content });
          }
          break;
        }
        case "on_tool_start":
          writeSSE(res, { type: "tool_start", name: event.name, input: event.data?.input });
          break;
        case "on_tool_end":
          writeSSE(res, { type: "tool_end", name: event.name });
          break;
        case "on_chain_end":
          // Final output of a node — no-op, we collect from token stream
          break;
        default:
          break;
      }
    }

    writeSSE(res, { type: "done", content: fullContent });
  } catch (err) {
    log.error("Graph stream error", { error: err.message });
    writeSSE(res, { type: "error", error: err.message });
  } finally {
    res.end();
  }

  return { content: fullContent };
}

// ── Raw LangChain model stream (fast-path) ────────────────────────────────────

/**
 * Stream a plain LangChain chat model response via SSE.
 * Used when durable=false (fast-path, no tool calls expected).
 *
 * @param {BaseChatModel} model
 * @param {BaseMessage[]} messages
 * @param {Response}      res
 */
export async function streamResponse(model, messages, res) {
  sseHeaders(res);

  let fullContent = "";

  try {
    const stream = await model.stream(messages);
    for await (const chunk of stream) {
      const content = chunk.content || "";
      if (content) {
        fullContent += content;
        writeSSE(res, { type: "token", content });
      }
      if (chunk.tool_calls?.length) {
        writeSSE(res, { type: "tool_call", calls: chunk.tool_calls });
      }
    }
    writeSSE(res, { type: "done", content: fullContent });
  } catch (err) {
    log.error("Stream error", { error: err.message });
    writeSSE(res, { type: "error", error: err.message });
  } finally {
    res.end();
  }

  return { content: fullContent };
}

export default { streamGraphResponse, streamResponse };
