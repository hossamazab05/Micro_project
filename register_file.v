// regfile.v
// 4 x 8-bit register file for ELC3030 project
// - 2 asynchronous read ports
// - 1 synchronous write port (posedge clk)
// - R3 (index 2'b11) initialized to 8'hFF on reset
// - If write occurs same cycle as read and addresses match, read returns wr_data (write-first behavior)

module regfile (
    input  wire        clk,
    input  wire        rst_n,       // active-low reset

    // Read port A (ID stage)
    input  wire [1:0]  rd_addr1,
    output wire [7:0]  rd_data1,

    // Read port B (ID stage)
    input  wire [1:0]  rd_addr2,
    output wire [7:0]  rd_data2,

    // Write port (WB stage)
    input  wire        wr_en,
    input  wire [1:0]  wr_addr,
    input  wire [7:0]  wr_data,

    // Convenience output: current SP value (R3)
    output wire [7:0]  sp_out
);

    // 4 registers
    reg [7:0] regs [0:3];

    integer i;

    // reset: initialize registers; set SP (R3) to 255 per spec
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            regs[0] <= 8'h00;
            regs[1] <= 8'h00;
            regs[2] <= 8'h00;
            regs[3] <= 8'hFF; // SP initial value
        end else begin
            if (wr_en) begin
                regs[wr_addr] <= wr_data;
            end
        end
    end

    // Read logic (combinational)
    // Write-first behavior: if (wr_en & wr_addr == rd_addr) => return wr_data
    // else return stored regs value

    assign rd_data1 = (wr_en && (wr_addr == rd_addr1)) ? wr_data : regs[rd_addr1];
    assign rd_data2 = (wr_en && (wr_addr == rd_addr2)) ? wr_data : regs[rd_addr2];

    assign sp_out = regs[3];

endmodule

