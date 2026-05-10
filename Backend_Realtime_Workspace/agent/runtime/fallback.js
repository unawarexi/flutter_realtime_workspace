// ============================================================================
// TeamSpot — Model Fallback Chain
// Tries models in priority order: OpenAI → Anthropic → Google
// ============================================================================

import { createLogger } from "../../observability/logger.js";
import { env } from "../../config/env.config.js";
const log = createLogger("ModelFallback");

export class ModelFallback {
  async getModel() {
    // Try OpenAI
    if (env.OPENAI_API_KEY) {
      try {
        const { ChatOpenAI } = await import("@langchain/openai");
        log.info("Using OpenAI model");
        return new ChatOpenAI({ model: "gpt-4o", temperature: 0.3, apiKey: env.OPENAI_API_KEY });
      } catch (e) { log.warn("OpenAI init failed", { error: e.message }); }
    }
    // Try Anthropic
    if (env.ANTHROPIC_API_KEY) {
      try {
        const { ChatAnthropic } = await import("@langchain/anthropic");
        log.info("Using Anthropic model");
        return new ChatAnthropic({ model: "claude-sonnet-4-20250514", temperature: 0.3, apiKey: env.ANTHROPIC_API_KEY });
      } catch (e) { log.warn("Anthropic init failed", { error: e.message }); }
    }
    // Try Google
    if (env.GOOGLE_AI_API_KEY) {
      try {
        const { ChatGoogleGenerativeAI } = await import("@langchain/google-genai");
        log.info("Using Google Gemini model");
        return new ChatGoogleGenerativeAI({ model: "gemini-2.0-flash", temperature: 0.3, apiKey: env.GOOGLE_AI_API_KEY });
      } catch (e) { log.warn("Google AI init failed", { error: e.message }); }
    }
    // Try HuggingFace (last fallback)
    if (env.HUGGINGFACE_API_KEY) {
      try {
        const { HuggingFaceInference } = await import("@langchain/community/llms/hf.js");
        log.info("Using HuggingFace model (last fallback)");
        return new HuggingFaceInference({
          model: "mistralai/Mistral-7B-Instruct-v0.3",
          apiKey: env.HUGGINGFACE_API_KEY,
          temperature: 0.3,
        });
      } catch (e) { log.warn("HuggingFace init failed", { error: e.message }); }
    }
    throw new Error("No LLM provider configured. Set OPENAI_API_KEY, ANTHROPIC_API_KEY, GOOGLE_AI_API_KEY, or HUGGINGFACE_API_KEY.");
  }
}

export default ModelFallback;
