// ============================================================
// OutputPort.v
// Output Port Module for ELC3030 Processor
// Handles writing to external pins with latching
// ============================================================

module OutputPort (
    input wire        clk,
    input wire        rst_n,
    input wire        enable,         // Write enable (IOW)
    input wire [7:0]  data_in,        // Data from bus
    output reg [7:0]  pins_out        // Physical output pins
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pins_out <= 8'h00;
        end else if (enable) begin
            pins_out <= data_in;
            $display("T=%t [OUTPUT_PORT] Write: 0x%h", $time, data_in);
        end
    end

endmodule
