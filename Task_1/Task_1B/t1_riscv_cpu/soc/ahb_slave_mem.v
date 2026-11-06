// ahb_slave_mem.v - simple AHB-Lite memory slave with configurable wait states
module ahb_slave_mem #(parameter WAIT = 0, DEPTH = 4096) (
    input         HCLK, HRESETn,
    input         HSEL,
    input  [31:0] HADDR,
    input  [1:0]  HTRANS,
    input         HWRITE,
    input  [2:0]  HSIZE,
    input  [31:0] HWDATA,
    input         HREADY,        // bus ready (= HREADYOUT with one slave)
    output        HREADYOUT,
    output [31:0] HRDATA,
    output        HRESP
);
reg [31:0] data_ram [0:DEPTH-1];

reg        d_valid, d_write;
reg [31:0] d_addr;
reg [2:0]  d_size;
reg [3:0]  cnt;

assign HREADYOUT = ~d_valid | (cnt >= WAIT);
assign HRESP     = 1'b0;

always @(posedge HCLK or negedge HRESETn) begin
    if (!HRESETn) begin d_valid <= 1'b0; cnt <= 4'd0; end
    else if (HREADY) begin                       // capture address phase
        d_valid <= HSEL & HTRANS[1];
        d_write <= HWRITE;
        d_addr  <= HADDR;
        d_size  <= HSIZE;
        cnt     <= 4'd0;
    end else cnt <= cnt + 4'd1;                  // counting wait cycles
end

wire [31:0] idx = d_addr[31:2] % DEPTH;
wire [3:0]  be  = (d_size == 3'd0) ? (4'b0001 << d_addr[1:0]) :
                  (d_size == 3'd1) ? (d_addr[1] ? 4'b1100 : 4'b0011) : 4'b1111;

assign HRDATA = data_ram[idx];

always @(posedge HCLK) begin
    if (HREADY && d_valid && d_write) begin      // write completes with data phase
        if (be[0]) data_ram[idx][7:0]   <= HWDATA[7:0];
        if (be[1]) data_ram[idx][15:8]  <= HWDATA[15:8];
        if (be[2]) data_ram[idx][23:16] <= HWDATA[23:16];
        if (be[3]) data_ram[idx][31:24] <= HWDATA[31:24];
    end
end
endmodule