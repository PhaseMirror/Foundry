module uac_safety_interlock (
    input  logic clk,
    input  logic rst_n,

    // Inputs from monitors
    input  logic rho_violation,    // From zm_certifier
    input  logic drift_warning,    // From resonance_shepherd

    // AXI-Stream interface to Rust engine for telemetry/status
    output logic [31:0] tdata,
    output logic        tvalid,
    
    // Global Hard-wired Safety Halt
    output logic L0_HALT
);

    // Latched fault signal: once triggered, system must reset
    logic fault_latched;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fault_latched <= 1'b0;
        end else if (rho_violation || drift_warning) begin
            fault_latched <= 1'b1;
        end
    end

    assign L0_HALT = fault_latched;

    // AXI-Stream status transmission
    assign tdata = {30'b0, drift_warning, rho_violation};
    assign tvalid = 1'b1; // Always stream current safety state to Rust

endmodule
