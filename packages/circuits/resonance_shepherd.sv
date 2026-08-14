module resonance_shepherd #(
    parameter int FW = 32, // Fixed-point width
    parameter int Q = 24   // Fractional bits
)(
    input  logic clk,              // 400 MHz fabric clock
    input  logic rst_n,
    input  logic [FW-1:0] measured_phase, // From RF-ADC monitoring Rydberg state
    input  logic [FW-1:0] target_phase,   // Phase associated with 108-cycle lock
    output logic [FW-1:0] phase_offset,   // Correction signal to pulse generator
    output logic          drift_warning
);

    // PI Controller coefficients (calibrated for Rydberg gate times)
    localparam [FW-1:0] Kp = 32'h00100000; // Proportional gain (Q8.24)
    localparam [FW-1:0] Ki = 32'h00001000; // Integral gain (Q8.24)
    
    logic [FW-1:0] error;
    logic [FW-1:0] integral;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            integral <= 0;
            phase_offset <= 0;
        end else begin
            error <= target_phase - measured_phase;
            integral <= integral + (error * Ki);
            // PI control output:
            phase_offset <= (error * Kp) + integral;
        end
    end

    // Safety threshold: halt if phase error exceeds 0.05 radians
    assign drift_warning = (error > 32'h00050000 || error < -32'h00050000);

endmodule
