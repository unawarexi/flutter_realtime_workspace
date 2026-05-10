// ============================================================================
// TeamSpot — Document Chunking
// Smart chunking strategies for RAG ingestion
// ============================================================================

/** Chunk a document using the specified strategy */
export function chunkDocument(text, options = {}) {
  const { strategy = "recursive", chunkSize = 1000, overlap = 200 } = options;

  switch (strategy) {
    case "paragraph": return chunkByParagraph(text, chunkSize);
    case "sentence": return chunkBySentence(text, chunkSize);
    case "recursive":
    default: return chunkRecursive(text, chunkSize, overlap);
  }
}

function chunkRecursive(text, chunkSize, overlap) {
  const chunks = [];
  const separators = ["\n\n", "\n", ". ", " "];

  function split(content, seps) {
    if (content.length <= chunkSize) {
      chunks.push({ text: content.trim(), metadata: { strategy: "recursive" } });
      return;
    }
    const sep = seps[0] || " ";
    const parts = content.split(sep);
    let current = "";
    for (const part of parts) {
      if ((current + sep + part).length > chunkSize && current) {
        chunks.push({ text: current.trim(), metadata: { strategy: "recursive" } });
        const overlapText = current.slice(-overlap);
        current = overlapText + sep + part;
      } else {
        current = current ? current + sep + part : part;
      }
    }
    if (current.trim()) chunks.push({ text: current.trim(), metadata: { strategy: "recursive" } });
  }

  split(text, separators);
  return chunks;
}

function chunkByParagraph(text, maxSize) {
  return text.split(/\n\n+/).filter(Boolean).map((p) => ({
    text: p.trim().slice(0, maxSize), metadata: { strategy: "paragraph" },
  }));
}

function chunkBySentence(text, maxSize) {
  const sentences = text.match(/[^.!?]+[.!?]+/g) || [text];
  const chunks = [];
  let current = "";
  for (const s of sentences) {
    if ((current + s).length > maxSize && current) {
      chunks.push({ text: current.trim(), metadata: { strategy: "sentence" } });
      current = s;
    } else { current += s; }
  }
  if (current.trim()) chunks.push({ text: current.trim(), metadata: { strategy: "sentence" } });
  return chunks;
}

export default { chunkDocument };
