// ============================================================================
// TeamSpot — Data Structures
// High-performance structures for caching, search, rate limiting, scheduling
// ============================================================================

// ── LRU Cache ────────────────────────────────────────────────────────────────
export class LRUCache {
  /** @param {number} capacity */
  constructor(capacity) {
    this.capacity = capacity;
    this.cache = new Map();
  }

  get(key) {
    if (!this.cache.has(key)) return undefined;
    const value = this.cache.get(key);
    this.cache.delete(key);
    this.cache.set(key, value);
    return value;
  }

  set(key, value) {
    if (this.cache.has(key)) this.cache.delete(key);
    else if (this.cache.size >= this.capacity) {
      const oldest = this.cache.keys().next().value;
      this.cache.delete(oldest);
    }
    this.cache.set(key, value);
  }

  has(key) { return this.cache.has(key); }
  delete(key) { return this.cache.delete(key); }
  clear() { this.cache.clear(); }
  get size() { return this.cache.size; }
}

// ── Priority Queue (Min-Heap) ────────────────────────────────────────────────
export class PriorityQueue {
  constructor(compareFn = (a, b) => a.priority - b.priority) {
    /** @type {Array} */ this.heap = [];
    this.compare = compareFn;
  }

  enqueue(item) {
    this.heap.push(item);
    this._bubbleUp(this.heap.length - 1);
  }

  dequeue() {
    if (this.heap.length === 0) return undefined;
    const top = this.heap[0];
    const last = this.heap.pop();
    if (this.heap.length > 0) {
      this.heap[0] = last;
      this._sinkDown(0);
    }
    return top;
  }

  peek() { return this.heap[0]; }
  get size() { return this.heap.length; }
  isEmpty() { return this.heap.length === 0; }

  _bubbleUp(i) {
    while (i > 0) {
      const parent = Math.floor((i - 1) / 2);
      if (this.compare(this.heap[i], this.heap[parent]) >= 0) break;
      [this.heap[i], this.heap[parent]] = [this.heap[parent], this.heap[i]];
      i = parent;
    }
  }

  _sinkDown(i) {
    const n = this.heap.length;
    while (true) {
      let smallest = i;
      const left = 2 * i + 1;
      const right = 2 * i + 2;
      if (left < n && this.compare(this.heap[left], this.heap[smallest]) < 0) smallest = left;
      if (right < n && this.compare(this.heap[right], this.heap[smallest]) < 0) smallest = right;
      if (smallest === i) break;
      [this.heap[i], this.heap[smallest]] = [this.heap[smallest], this.heap[i]];
      i = smallest;
    }
  }
}

// ── Sliding Window Counter ───────────────────────────────────────────────────
export class SlidingWindow {
  /** @param {number} windowMs — Window size in milliseconds */
  constructor(windowMs) {
    this.windowMs = windowMs;
    /** @type {number[]} */ this.timestamps = [];
  }

  add(timestamp = Date.now()) {
    this.timestamps.push(timestamp);
    this._prune(timestamp);
  }

  count(now = Date.now()) {
    this._prune(now);
    return this.timestamps.length;
  }

  _prune(now = Date.now()) {
    const cutoff = now - this.windowMs;
    while (this.timestamps.length > 0 && this.timestamps[0] < cutoff) {
      this.timestamps.shift();
    }
  }

  reset() { this.timestamps = []; }
}

// ── Bloom Filter ─────────────────────────────────────────────────────────────
export class BloomFilter {
  /**
   * @param {number} size — Bit array size
   * @param {number} hashCount — Number of hash functions
   */
  constructor(size = 1024, hashCount = 3) {
    this.size = size;
    this.hashCount = hashCount;
    this.bits = new Uint8Array(Math.ceil(size / 8));
  }

  _hash(value, seed) {
    let hash = seed;
    const str = String(value);
    for (let i = 0; i < str.length; i++) {
      hash = ((hash << 5) + hash + str.charCodeAt(i)) >>> 0;
    }
    return hash % this.size;
  }

  add(value) {
    for (let i = 0; i < this.hashCount; i++) {
      const bit = this._hash(value, i * 0x9e3779b9);
      this.bits[Math.floor(bit / 8)] |= (1 << (bit % 8));
    }
  }

  mightContain(value) {
    for (let i = 0; i < this.hashCount; i++) {
      const bit = this._hash(value, i * 0x9e3779b9);
      if (!(this.bits[Math.floor(bit / 8)] & (1 << (bit % 8)))) return false;
    }
    return true;
  }
}

// ── Trie (Prefix Tree) ──────────────────────────────────────────────────────
export class Trie {
  constructor() {
    this.root = { children: new Map(), isEnd: false, data: null };
  }

  insert(word, data = null) {
    let node = this.root;
    for (const ch of word.toLowerCase()) {
      if (!node.children.has(ch)) node.children.set(ch, { children: new Map(), isEnd: false, data: null });
      node = node.children.get(ch);
    }
    node.isEnd = true;
    node.data = data;
  }

  search(word) {
    let node = this.root;
    for (const ch of word.toLowerCase()) {
      if (!node.children.has(ch)) return null;
      node = node.children.get(ch);
    }
    return node.isEnd ? node.data : null;
  }

  startsWith(prefix, limit = 10) {
    let node = this.root;
    for (const ch of prefix.toLowerCase()) {
      if (!node.children.has(ch)) return [];
      node = node.children.get(ch);
    }
    const results = [];
    this._collect(node, prefix.toLowerCase(), results, limit);
    return results;
  }

  _collect(node, prefix, results, limit) {
    if (results.length >= limit) return;
    if (node.isEnd) results.push({ word: prefix, data: node.data });
    for (const [ch, child] of node.children) {
      this._collect(child, prefix + ch, results, limit);
    }
  }
}

// ── Circuit Breaker ──────────────────────────────────────────────────────────
/**
 * Circuit Breaker — prevents cascading failures when a dependency degrades.
 *
 * States:
 *   CLOSED   → normal; requests flow through; failures are counted
 *   OPEN     → dependency is down; requests fail fast without calling fn
 *   HALF_OPEN → probe state; one request allowed through to test recovery
 *
 * @example
 *   const breaker = new CircuitBreaker({ failureThreshold: 5, recoveryMs: 10000 });
 *   const result  = await breaker.call(() => kafkaProducer.send(...));
 */
export class CircuitBreaker {
  /**
   * @param {Object} opts
   * @param {number} [opts.failureThreshold=5]  — consecutive failures to open
   * @param {number} [opts.successThreshold=2]  — consecutive successes to close from half-open
   * @param {number} [opts.recoveryMs=10000]    — ms to wait in OPEN before probing
   * @param {string} [opts.name="service"]
   */
  constructor({ failureThreshold = 5, successThreshold = 2, recoveryMs = 10000, name = "service" } = {}) {
    this.failureThreshold = failureThreshold;
    this.successThreshold = successThreshold;
    this.recoveryMs = recoveryMs;
    this.name = name;

    this._state = "CLOSED"; // CLOSED | OPEN | HALF_OPEN
    this._failureCount = 0;
    this._successCount = 0;
    this._openedAt = null;
  }

  get state() { return this._state; }

  /**
   * Execute fn through the circuit breaker.
   * @param {Function} fn — async function to protect
   * @returns {Promise<*>}
   * @throws {Error} immediately when circuit is OPEN
   */
  async call(fn) {
    if (this._state === "OPEN") {
      const elapsed = Date.now() - this._openedAt;
      if (elapsed >= this.recoveryMs) {
        this._state = "HALF_OPEN";
        this._successCount = 0;
      } else {
        throw new Error(`CircuitBreaker[${this.name}] is OPEN — failing fast (recovers in ${Math.round((this.recoveryMs - elapsed) / 1000)}s)`);
      }
    }

    try {
      const result = await fn();
      this._onSuccess();
      return result;
    } catch (err) {
      this._onFailure();
      throw err;
    }
  }

  _onSuccess() {
    this._failureCount = 0;
    if (this._state === "HALF_OPEN") {
      this._successCount++;
      if (this._successCount >= this.successThreshold) {
        this._state = "CLOSED";
        this._successCount = 0;
      }
    }
  }

  _onFailure() {
    this._failureCount++;
    if (this._state === "HALF_OPEN" || this._failureCount >= this.failureThreshold) {
      this._state = "OPEN";
      this._openedAt = Date.now();
      this._failureCount = 0;
    }
  }

  reset() {
    this._state = "CLOSED";
    this._failureCount = 0;
    this._successCount = 0;
    this._openedAt = null;
  }
}

export default { LRUCache, PriorityQueue, SlidingWindow, BloomFilter, Trie, CircuitBreaker };
