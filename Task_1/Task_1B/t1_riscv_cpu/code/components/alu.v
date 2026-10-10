module alu #(parameter WIDTH = 32) (
    input       [WIDTH-1:0] a, b,
    input       [3:0]       alu_ctrl,
    output reg  [WIDTH-1:0] alu_out,
    output                  zero,
    output                  slt,
    output                  sltu
);

// Unified adder / subtractor
wire is_sub = alu_ctrl[0] | (alu_ctrl == 4'b0101) | (alu_ctrl == 4'b0110);
wire [WIDTH-1:0] b_inv = is_sub ? ~b : b;
wire [WIDTH:0]   sum_full = {1'b0, a} + {1'b0, b_inv} + {{WIDTH{1'b0}}, is_sub};
wire [WIDTH-1:0] add_sub_result = sum_full[WIDTH-1:0];

// SLT and SLTU derived directly from the unified adder/subtractor
assign sltu = ~sum_full[WIDTH]; // borrow is active when carry_out is 0
assign slt  = (a[WIDTH-1] != b[WIDTH-1]) ? a[WIDTH-1] : sum_full[WIDTH-1];

// Zero detection directly from subtraction result
assign zero = (add_sub_result == {WIDTH{1'b0}});

// Unified barrel shifter for SLL, SRL, and SRA
// Reverse bits function for SLL sharing
function [WIDTH-1:0] reverse32;
    input [WIDTH-1:0] in;
    integer k;
    begin
        for (k = 0; k < WIDTH; k = k + 1)
            reverse32[k] = in[WIDTH-1-k];
    end
endfunction

wire is_sll = (alu_ctrl == 4'b0111);
wire is_sra = (alu_ctrl == 4'b1001);

wire [WIDTH-1:0] shift_in_data = is_sll ? reverse32(a) : a;
wire [WIDTH-1:0] shift_fill    = (is_sra && a[WIDTH-1]) ? {WIDTH{1'b1}} : {WIDTH{1'b0}};
wire [2*WIDTH-1:0] shift_wide  = {shift_fill, shift_in_data} >> b[4:0];
wire [WIDTH-1:0] shift_right   = shift_wide[WIDTH-1:0];
wire [WIDTH-1:0] shift_result  = is_sll ? reverse32(shift_right) : shift_right;

always @(*) begin
    case (alu_ctrl)
        4'b0000: alu_out = add_sub_result;          // ADD
        4'b0001: alu_out = add_sub_result;          // SUB
        4'b0010: alu_out = a & b;                   // AND
        4'b0011: alu_out = a | b;                   // OR
        4'b0100: alu_out = a ^ b;                   // XOR
        4'b0101: alu_out = {{WIDTH-1{1'b0}}, slt};  // SLT
        4'b0110: alu_out = {{WIDTH-1{1'b0}}, sltu}; // SLTU
        4'b0111: alu_out = shift_result;            // SLL
        4'b1000: alu_out = shift_result;            // SRL
        4'b1001: alu_out = shift_result;            // SRA
        default: alu_out = {WIDTH{1'b0}};
    endcase
end

endmodule