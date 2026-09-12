// ZM Certification Gate: Pipelined Reduction & Violation Detection
// Target: 400 MHz (2.5ns) on UltraScale+ RFSoC
module zm_certifier #(
    parameter int PRIME_COUNT = 8,
    parameter int FW = 32,    // Fixed-point total width
    parameter int Q = 24      // Fractional bits
)(
    input  logic clk,
    input  logic rst_n,
    input  logic [FW-1:0] lambda_weights [PRIME_COUNT], // |lambda_p(t)|
    input  logic [FW-1:0] xi_magnitude,                // |Xi(t)|
    input  logic [FW-1:0] lipschitz_t,                 // L_T
    output logic          rho_violation,               // Physical L0_HALT
    output logic [FW-1:0] rho_out
);

    // Stage 1: Pipelined Reduction Tree for sum_lambda
    logic [FW-1:0] sum_l1 [PRIME_COUNT/2];
    logic [FW-1:0] sum_l2 [PRIME_COUNT/4];
    logic [FW-1:0] sum_l3;

    always_ff @(posedge clk) begin
        // Reduction tree stage 1
        for (int i=0; i<PRIME_COUNT/2; i++) 
            sum_l1[i] <= lambda_weights[2*i] + lambda_weights[2*i+1];
        
        // Stage 2: Reduction tree stage 2 + Multiplier Pre-pipe
        for (int i=0; i<PRIME_COUNT/4; i++)
            sum_l2[i] <= sum_l1[2*i] + sum_l1[2*i+1];
            
        sum_l3 <= sum_l2[0] + sum_l2[1];
    end

    // Stage 3: Gain calculation (L_T * sum_lambda) and Final Rho
    logic [FW-1:0] gain_term;
    // Multiplier must be DSP-registered
    always_ff @(posedge clk) begin
        gain_term <= (lipschitz_t * sum_l3) >> Q; 
        rho_out   <= xi_magnitude + gain_term;
        
        // L0_HALT gate: SEDONA_MARGIN = 1.0 - 1e-6 
        // 1.0 in Q8.24 is 1 << 24
        rho_violation <= (rho_out >= ( (1<<Q) - (1<<(Q-20)) )); // Approximate margin
    end

endmodule
