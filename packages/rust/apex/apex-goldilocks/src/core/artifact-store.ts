import * as crypto from 'crypto';
import * as fs from 'fs';
import * as path from 'path';

export class ArtifactStore {
  private artifactDir: string;
  private artifacts: Map<string, any> = new Map();

  constructor(artifactDir: string = path.join(process.cwd(), '.artifacts')) {
    this.artifactDir = artifactDir;
    this.ensureArtifactDir();
  }

  /**
   * Ensure artifact directory exists
   */
  private ensureArtifactDir(): void {
    if (!fs.existsSync(this.artifactDir)) {
      fs.mkdirSync(this.artifactDir, { recursive: true });
    }
  }

  /**
   * Generate CID for content using SHA256
   */
  public generateCID(content: any): string {
    // Canonical JSON encoding with recursively sorted keys
    const canonical = this.canonicalizeJSON(content);
    const hash = crypto.createHash('sha256');
    hash.update(canonical);
    return `cid:${hash.digest('hex')}`;
  }

  /**
   * Recursively sort object keys for canonical JSON
   */
  private canonicalizeJSON(obj: any): string {
    if (obj === null || obj === undefined) {
      return JSON.stringify(obj);
    }

    if (typeof obj !== 'object') {
      return JSON.stringify(obj);
    }

    if (Array.isArray(obj)) {
      return '[' + obj.map(item => this.canonicalizeJSON(item)).join(',') + ']';
    }

    // Object: sort keys recursively
    const sortedKeys = Object.keys(obj).sort();
    const pairs = sortedKeys.map(key => {
      const value = this.canonicalizeJSON(obj[key]);
      return `${JSON.stringify(key)}:${value}`;
    });

    return '{' + pairs.join(',') + '}';
  }

  /**
   * Store artifact with CID
   */
  public storeArtifact(content: any): string {
    const cid = this.generateCID(content);
    const artifactPath = path.join(this.artifactDir, cid);

    // Store in memory
    this.artifacts.set(cid, content);

    // Store on disk
    fs.writeFileSync(artifactPath, JSON.stringify(content, null, 2));

    return cid;
  }

  /**
   * Retrieve artifact by CID
   */
  public getArtifact(cid: string): any | null {
    // Check memory first
    if (this.artifacts.has(cid)) {
      return this.artifacts.get(cid);
    }

    // Check disk
    const artifactPath = path.join(this.artifactDir, cid);
    if (fs.existsSync(artifactPath)) {
      const content = JSON.parse(fs.readFileSync(artifactPath, 'utf-8'));
      this.artifacts.set(cid, content);
      return content;
    }

    return null;
  }

}