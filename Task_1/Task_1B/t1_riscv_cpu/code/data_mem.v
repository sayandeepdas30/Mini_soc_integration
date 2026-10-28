
// data_mem.v - data memory

module data_mem #(parameter DATA_WIDTH = 32, ADDR_WIDTH = 32, MEM_SIZE = 4096) (
    input       clk, wr_en,
    input       [ADDR_WIDTH-1:0] wr_addr, wr_data,
    output      [DATA_WIDTH-1:0] rd_data_mem,
    input       [3:0] be
);

// array of 64 32-bit words or data
reg [DATA_WIDTH-1:0] data_ram [0:MEM_SIZE-1];
wire [31:0] idx = wr_addr[DATA_WIDTH-1:2]%MEM_SIZE;

// combinational read logic
// word-aligned memory access
assign rd_data_mem = data_ram[idx];

// synchronous write logic
always @(posedge clk) begin
    if (wr_en) begin
        if(be[0]) data_ram[idx][7:0] <= wr_data[7:0];
        if(be[1]) data_ram[idx][15:8]<= wr_data[15:8];
        if(be[2]) data_ram[idx][23:16]<=wr_data[23:16];
        if(be[3]) data_ram[idx][31:24]<=wr_data[31:24]; 
    end
end

endmodule

