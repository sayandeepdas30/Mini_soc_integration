// ahb_default_slave.v - answers unmapped addresses with a 2-cycle ERROR response
module ahb_default_slave (
    input         HCLK, HRESETn,
    input         HSEL,
    input  [1:0]  HTRANS,
    input         HREADY,
    output        HREADYOUT,
    output        HRESP,
    output [31:0] HRDATA
);
reg [1:0] st;   // 0 = idle/ok, 1 = error cycle 1, 2 = error cycle 2
wire hit = HSEL & HTRANS[1] & HREADY;

always @(posedge HCLK or negedge HRESETn) begin
    if (!HRESETn) st <= 2'd0;
    else case (st)
        2'd0: st <= hit ? 2'd1 : 2'd0;
        2'd1: st <= 2'd2;
        default: st <= hit ? 2'd1 : 2'd0;
    endcase
end

assign HREADYOUT = (st != 2'd1);   // low only in the first error cycle
assign HRESP     = (st != 2'd0);   // high in both error cycles
assign HRDATA    = 32'd0;
endmodule