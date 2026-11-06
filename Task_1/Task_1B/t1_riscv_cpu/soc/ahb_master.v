// ahb_master.v - core memory port -> AHB-Lite master (one transfer at a time)
module ahb_master (
    input         HCLK, HRESETn,
    // core side
    input         req_rd, req_wr,
    input  [31:0] addr, wdata,
    input  [3:0]  byte_en,
    output [31:0] rdata,
    output        ready,
    // AHB-Lite side
    output [31:0] HADDR, HWDATA,
    output        HWRITE,
    output [2:0]  HSIZE,
    output [1:0]  HTRANS,
    input  [31:0] HRDATA,
    input         HREADY,
    input         HRESP
);
localparam IDLE = 1'b0, DATA = 1'b1;
reg  state;
wire req = req_rd | req_wr;

always @(posedge HCLK or negedge HRESETn) begin
    if (!HRESETn) state <= IDLE;
    else case (state)
        IDLE: if (req && HREADY) state <= DATA;   // address phase accepted
        DATA: if (HREADY)        state <= IDLE;   // data phase finished
    endcase
end

assign HTRANS = (state == IDLE && req) ? 2'b10 : 2'b00;   // NONSEQ or IDLE
assign HADDR  = addr;
assign HWRITE = req_wr;
assign HWDATA = wdata;
assign HSIZE  = (byte_en == 4'b1111) ? 3'd2 :
                (byte_en == 4'b0011 || byte_en == 4'b1100) ? 3'd1 : 3'd0;

assign rdata  = HRDATA;
assign ready  = (state == DATA) ? HREADY : ~req;   // core waits during address phase
endmodule