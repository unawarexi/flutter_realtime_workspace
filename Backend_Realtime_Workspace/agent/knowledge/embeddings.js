// ============================================================================
// TeamSpot — Embeddings Generator
// Generates vector embeddings via OpenAI or fallback providers
// ============================================================================

import { env } from "../../config/env.config.js";
import { createLogger } from "../../observability/logger.js";
const log = createLogger("Embeddings");

export async function generateEmbeddings(texts) {
  // OpenAI (preferred)
  if (env.OPENAI_API_KEY) {
    try { return await generateOpenAIEmbeddings(texts); } catch (e) { log.warn("OpenAI embeddings failed, trying Cohere", { error: e.message }); }
  }
  // Cohere fallback
  if (env.COHERE_API_KEY) {
    try { return await generateCohereEmbeddings(texts); } catch (e) { log.warn("Cohere embeddings failed, trying HuggingFace", { error: e.message }); }
  }
  // HuggingFace fallback
  if (env.HUGGINGFACE_API_KEY) {
    try { return await generateHuggingFaceEmbeddings(texts); } catch (e) { log.warn("HuggingFace embeddings failed, using dev fallback", { error: e.message }); }
  }
  // Dev hash fallback
  log.warn("No embedding provider configured — using dev hash fallback");
  return texts.map((t) => hashEmbed(t));
}

async function generateOpenAIEmbeddings(texts) {
  const { OpenAIEmbeddings } = await import("@langchain/openai");
  const embeddings = new OpenAIEmbeddings({ model: "text-embedding-3-small", apiKey: env.OPENAI_API_KEY });
  return embeddings.embedDocuments(texts);
}

async function generateCohereEmbeddings(texts) {
  const { CohereEmbeddings } = await import("@langchain/cohere");
  const embeddings = new CohereEmbeddings({ model: "embed-multilingual-v3.0", apiKey: env.COHERE_API_KEY });
  return embeddings.embedDocuments(texts);
}

async function generateHuggingFaceEmbeddings(texts) {
  const { HuggingFaceInferenceEmbeddings } = await import("@langchain/community/embeddings/hf.js");
  const embeddings = new HuggingFaceInferenceEmbeddings({
    model: "sentence-transformers/all-MiniLM-L6-v2",
    apiKey: env.HUGGINGFACE_API_KEY,
  });
  return embeddings.embedDocuments(texts);
}

/** Dev fallback: deterministic pseudo-embedding from text hash */
function hashEmbed(text, dims = 256) {
  const vec = new Float32Array(dims);
  for (let i = 0; i < text.length; i++) {
    vec[i % dims] += text.charCodeAt(i) / 255;
  }
  const mag = Math.sqrt(vec.reduce((s, v) => s + v * v, 0)) || 1;
  return Array.from(vec.map((v) => v / mag));
}

export default { generateEmbeddings };
