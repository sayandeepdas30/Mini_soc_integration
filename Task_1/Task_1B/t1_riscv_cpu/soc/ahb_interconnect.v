// ahb_interconnect.v - address decoder + return mux (1 master, 2 slaves + default)
module ahb_interconnect (
    input         HCLK, HRESETn,
    input  [31:0] HADDR,
    input  [1:0]  HTRANS,
    // back to master
    output [31:0] HRDATA,
    output        HREADY,
    output        HRESP,
    // slave 0, slave 1, default slave
    output        HSEL0, HSEL1, HSELD,
    input  [31:0] HRDATA0, HRDATA1, HRDATAD,
    input         HREADYOUT0, HREADYOUT1, HREADYOUTD,
    input         HRESP0, HRESP1, HRESPD
);
// address phase: decode
wire hit0 = (HADDR[31:16] == 16'h0000);
wire hit1 = (HADDR[31:16] == 16'h1000);
assign HSEL0 = hit0;
assign HSEL1 = hit1;
assign HSELD = ~(hit0 | hit1);

wire [1:0] sel_a = !HTRANS[1] ? 2'd2 : hit0 ? 2'd0 : hit1 ? 2'd1 : 2'd2;

// data phase: remember who was selected
reg [1:0] sel_d;
always @(posedge HCLK or negedge HRESETn) begin
    if (!HRESETn)    sel_d <= 2'd2;
    else if (HREADY) sel_d <= sel_a;
end

// return mux
assign HRDATA = (sel_d == 2'd0) ? HRDATA0 : (sel_d == 2'd1) ? HRDATA1 : HRDATAD;
assign HREADY = (sel_d == 2'd0) ? HREADYOUT0 : (sel_d == 2'd1) ? HREADYOUT1 : HREADYOUTD;
assign HRESP  = (sel_d == 2'd0) ? HRESP0 : (sel_d == 2'd1) ? HRESP1 : HRESPD;
endmodule