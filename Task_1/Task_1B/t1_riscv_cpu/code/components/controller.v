// controller.v - controller for RISC-V CPU

module controller (
    input [6:0]  op,
    input [2:0]  funct3,
    input        funct7b5,
    input        Zero,
    input        SLT,
    input        SLTU,
    output       [1:0] ResultSrc,
    output       MemWrite,
    output       PCSrc, ALUSrc,
    output       RegWrite, Jump, Jalr,
    output [2:0] ImmSrc,
    output [3:0] ALUControl,
    output [2:0] Funct3Out
);

wire [1:0] ALUOp;
wire       Branch;
reg        BranchCondMet;

main_decoder    md (op, ResultSrc, MemWrite, Branch,
                    ALUSrc, RegWrite, Jump, Jalr, ImmSrc, ALUOp);

alu_decoder     ad (op[5], funct3, funct7b5, ALUOp, ALUControl);

// Branch condition evaluation directly from ALU condition flags
always @(*) begin
    case (funct3)
        3'b000:  BranchCondMet = Zero;          // BEQ
        3'b001:  BranchCondMet = ~Zero;         // BNE
        3'b100:  BranchCondMet = SLT;           // BLT
        3'b101:  BranchCondMet = ~SLT;          // BGE
        3'b110:  BranchCondMet = SLTU;          // BLTU
        3'b111:  BranchCondMet = ~SLTU;         // BGEU
        default: BranchCondMet = 1'b0;
    endcase
end

// for jump and branch
assign PCSrc = (Branch & BranchCondMet) | Jump;
assign Funct3Out = funct3;

endmodule
