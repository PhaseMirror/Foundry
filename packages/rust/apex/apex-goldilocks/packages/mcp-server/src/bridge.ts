import { execFile } from "child_process";  
import { promisify } from "util";

const execFileAsync = promisify(execFile);  
// Path points to the compiled target output of multiplicity_core_rs/src/lib.rs pipeline wrapper  
const RUST_BINARY_PATH = process.env.MULTIPLICITY_CORE_BIN || "./target/release/multiplicity-core-cli";

export async function callRustEngine(action: string, payload: object): Promise<string> {  
  try {  
    const { stdout } = await execFileAsync(RUST_BINARY_PATH, [action, JSON.stringify(payload)]);  
    return stdout.trim();  
  } catch (error: any) {  
    throw new Error(`Rust Kernel Enforcement Violation: ${error.stderr || error.message}`);  
  }  
}
