// ============================================================================
// TeamSpot — Model Fallback Chain
// Priority: OpenRouter → OpenAI → Anthropic → Google → HuggingFace
//
// OpenRouter (https://openrouter.ai) is a unified gateway to 200+ models
// (GPT-4o, Claude, Gemini, Llama, Mistral, …) via a single OpenAI-compatible
// API. Set OPENROUTER_API_KEY to use it; set OPENROUTER_MODEL to pick a
// specific model (defaults to the free openai/gpt-4o).
// ============================================================================

import { createLogger } from "../../observability/logger.js";
import { env } from "../../config/env.config.js";
const log = createLogger("ModelFallback");

export class ModelFallback {
  async getModel() {
    // ── 1. OpenRouter (unified gateway — preferred if key is set) ──────────
    if (env.OPENROUTER_API_KEY) {
      try {
        const { ChatOpenAI } = await import("@langchain/openai");
        const model = env.OPENROUTER_MODEL || "openai/gpt-4o";
        log.info("Using OpenRouter", { model });
        return new ChatOpenAI({
          model,
          temperature: 0.3,
          apiKey: env.OPENROUTER_API_KEY,
          configuration: {
            baseURL: "https://openrouter.ai/api/v1",
            defaultHeaders: {
              "HTTP-Referer": env.BASE_URL || "https://teamspot.app",
              "X-Title": "TeamSpot",
            },
          },
        });
      } catch (e) { log.warn("OpenRouter init failed", { error: e.message }); }
    }

    // ── 2. OpenAI direct ──────────────────────────────────────────────────
    if (env.OPENAI_API_KEY) {
      try {
        const { ChatOpenAI } = await import("@langchain/openai");
        log.info("Using OpenAI direct");
        return new ChatOpenAI({ model: "gpt-4o", temperature: 0.3, apiKey: env.OPENAI_API_KEY });
      } catch (e) { log.warn("OpenAI init failed", { error: e.message }); }
    }

    // ── 3. Anthropic direct ───────────────────────────────────────────────
    if (env.ANTHROPIC_API_KEY) {
      try {
        const { ChatAnthropic } = await import("@langchain/anthropic");
        log.info("Using Anthropic direct");
        return new ChatAnthropic({ model: "claude-sonnet-4-20250514", temperature: 0.3, apiKey: env.ANTHROPIC_API_KEY });
      } catch (e) { log.warn("Anthropic init failed", { error: e.message }); }
    }

    // ── 4. Google Gemini direct ───────────────────────────────────────────
    if (env.GOOGLE_AI_API_KEY) {
      try {
        const { ChatGoogleGenerativeAI } = await import("@langchain/google-genai");
        log.info("Using Google Gemini direct");
        return new ChatGoogleGenerativeAI({ model: "gemini-2.0-flash", temperature: 0.3, apiKey: env.GOOGLE_AI_API_KEY });
      } catch (e) { log.warn("Google AI init failed", { error: e.message }); }
    }

    // ── 5. HuggingFace (last resort) ──────────────────────────────────────
    if (env.HUGGINGFACE_API_KEY) {
      try {
        const { HuggingFaceInference } = await import("@langchain/community/llms/hf.js");
        log.info("Using HuggingFace (last fallback)");
        return new HuggingFaceInference({
          model: "mistralai/Mistral-7B-Instruct-v0.3",
          apiKey: env.HUGGINGFACE_API_KEY,
          temperature: 0.3,
        });
      } catch (e) { log.warn("HuggingFace init failed", { error: e.message }); }
    }

    throw new Error(
      "No LLM provider configured. Set OPENROUTER_API_KEY (recommended), " +
      "OPENAI_API_KEY, ANTHROPIC_API_KEY, GOOGLE_AI_API_KEY, or HUGGINGFACE_API_KEY."
    );
  }
}

export default ModelFallback;
