// ============================================================
// InputPort.v
// Input Port Module for ELC3030 Processor
// Handles reading from external pins
// ============================================================

module InputPort (
    input wire [7:0]  pins_in,        // Physical input pins
    input wire        enable,         // Read enable (IOR)
    output reg [7:0]  data_out        // Data to bus
);

    always @(*) begin
        if (enable) begin
            data_out = pins_in;
            $display("T=%t [INPUT_PORT] Read: 0x%h", $time, pins_in);
        end
        else
            data_out = 8'h00;     // Tri-state or zero (simplified to zero)
    end

endmodule
