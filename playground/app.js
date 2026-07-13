document.addEventListener('DOMContentLoaded', () => {
    const btnCompile = document.getElementById('btn-compile');
    const btnClear = document.getElementById('btn-clear');
    const codeEditor = document.getElementById('code-editor');
    const outputContainer = document.getElementById('output-container');
    const statusIndicator = document.getElementById('status-indicator');

    // Simple mock compiler function to simulate MLIR generation
    const compilePIRTM = async (code) => {
        if (!code.trim()) {
            throw new Error("No source code provided.");
        }

        // Simulate WASM/Network latency
        await new Promise(r => setTimeout(r, 600));

        // Basic syntax error simulation
        if (code.includes('sorry')) {
            throw new Error("Governance Violation: 'sorry' detected in formal proof layer.");
        }
        
        if (code.trim() === 'let strata = Ap(7) * Succ(Ap(3));') {
            return `module {
  func.func @main() -> !pirtm.stratum {
    %0 = pirtm.ap(7) : !pirtm.stratum
    %1 = pirtm.ap(3) : !pirtm.stratum
    %2 = pirtm.succ(%1) : !pirtm.stratum
    %3 = pirtm.mul %0, %2 : !pirtm.stratum
    return %3 : !pirtm.stratum
  }
}
// Contractivity check: PASS
// Bounds: λₚ · Lₚ < 1
// Governance Signature: verified`;
        }

        // Generic fallback MLIR
        return `module {
  // PIRTM Compiler Frontend (v0.9.0)
  // Auto-lowering generated MLIR dialect
  func.func @main() -> !pirtm.stratum {
    %0 = pirtm.eval_block() : !pirtm.stratum
    return %0 : !pirtm.stratum
  }
}
// Contractivity check: PASS`;
    };

    const setStatus = (type) => {
        statusIndicator.className = 'status-badge';
        if (type === 'ready') {
            statusIndicator.classList.add('status-ready');
            statusIndicator.innerHTML = '● Ready';
        } else if (type === 'compiling') {
            statusIndicator.classList.add('status-compiling');
            statusIndicator.innerHTML = '● Compiling...';
        } else if (type === 'error') {
            statusIndicator.classList.add('status-error');
            statusIndicator.innerHTML = '● Error';
        }
    };

    const handleCompile = async () => {
        const code = codeEditor.value;
        
        setStatus('compiling');
        btnCompile.disabled = true;
        
        try {
            const mlir = await compilePIRTM(code);
            
            // Clear placeholder if it's the first run
            const placeholder = outputContainer.querySelector('.output-placeholder');
            if (placeholder) {
                outputContainer.innerHTML = '';
            }

            const outBlock = document.createElement('div');
            outBlock.className = 'output-block output-success';
            outBlock.textContent = mlir;
            outputContainer.prepend(outBlock);
            
            setStatus('ready');
        } catch (err) {
            const outBlock = document.createElement('div');
            outBlock.className = 'output-block output-error';
            outBlock.textContent = `Error: ${err.message}`;
            outputContainer.prepend(outBlock);
            
            setStatus('error');
            setTimeout(() => setStatus('ready'), 3000);
        } finally {
            btnCompile.disabled = false;
        }
    };

    btnCompile.addEventListener('click', handleCompile);

    btnClear.addEventListener('click', () => {
        outputContainer.innerHTML = `
            <div class="output-placeholder">
                <p>Enter PIRTM code on the left and click <strong>Compile & Run</strong> to generate MLIR.</p>
            </div>
        `;
    });

    // Keyboard shortcut for Cmd/Ctrl + Enter
    document.addEventListener('keydown', (e) => {
        if ((e.metaKey || e.ctrlKey) && e.key === 'Enter') {
            handleCompile();
        }
    });

    // Simple Tab indentation support
    codeEditor.addEventListener('keydown', function(e) {
        if (e.key === 'Tab') {
            e.preventDefault();
            const start = this.selectionStart;
            const end = this.selectionEnd;
            this.value = this.value.substring(0, start) + "    " + this.value.substring(end);
            this.selectionStart = this.selectionEnd = start + 4;
        }
    });
});
