// datapath.v
module datapath (
    input         clk, reset,
    input [1:0]   ResultSrc,
    input         PCSrc, ALUSrc,
    input         RegWrite,
    input [2:0]   ImmSrc,
    input [3:0]   ALUControl,
    input         Jalr,
    input [2:0]   Funct3,    // for load/store size
    output        Zero,
    output        SLT,
    output        SLTU,
    output [31:0] PC,
    input  [31:0] Instr,
    output [31:0] Mem_WrAddr, Mem_WrData,
    input  [31:0] ReadData,
    output [31:0] Result
);

wire [31:0] PCPlus4, PCTarget, AuiPC, luiPC, PCJalr;
wire [31:0] ImmExt, SrcA, SrcB, WriteData, ALUResult;
reg  [31:0] LoadData;     // processed load data (byte/half/word, sign/zero extended)

// next PC logic
mux3 #(32) pcmux(PCPlus4, PCTarget, ALUResult, {Jalr, PCSrc}, PCJalr);

reset_ff #(32) pcreg(clk, reset, PCJalr, PC);
adder          pcadd4(PC, 32'd4, PCPlus4);
adder          pcaddbranch(PC, ImmExt, PCTarget);

// register file logic
reg_file       rf (clk, RegWrite, Instr[19:15], Instr[24:20], Instr[11:7], Result, SrcA, WriteData);
imm_extend     ext (Instr[31:7], ImmSrc, ImmExt);

// ALU logic
mux2 #(32)     srcbmux(WriteData, ImmExt, ALUSrc, SrcB);
alu            alu (SrcA, SrcB, ALUControl, ALUResult, Zero, SLT, SLTU);
mux2 #(32) a (AuiPC, ImmExt, Instr[5], luiPC);

// Optimized Load data processing - extract byte/halfword with shared sign/zero extension
wire [1:0]  byte_offset  = ALUResult[1:0];
reg  [7:0]  loaded_byte;
always @(*) begin
    case (byte_offset)
        2'b00:   loaded_byte = ReadData[7:0];
        2'b01:   loaded_byte = ReadData[15:8];
        2'b10:   loaded_byte = ReadData[23:16];
        default: loaded_byte = ReadData[31:24];
    endcase
end

wire [15:0] loaded_half  = byte_offset[1] ? ReadData[31:16] : ReadData[15:0];
wire        byte_sign    = ~Funct3[2] & loaded_byte[7];
wire        half_sign    = ~Funct3[2] & loaded_half[15];

always @(*) begin
    case (Funct3[1:0])
        2'b00:   LoadData = {{24{byte_sign}}, loaded_byte};  // LB / LBU
        2'b01:   LoadData = {{16{half_sign}}, loaded_half};  // LH / LHU
        default: LoadData = ReadData;                        // LW
    endcase
end

// Store data processing - read-modify-write for SB and SH
// Preserves existing memory contents for sub-word writes.
// When memory is uninitialized (X in simulation), unwritten bytes fall back to WriteData.
function [7:0] pick_byte;
    input [7:0] rd;
    input [7:0] wd;
    begin
        pick_byte = (^rd === 1'bx) ? wd : rd;
    end
endfunction

reg [31:0] StoreData;
always @(*) begin
    case (Funct3)
        3'b000: begin // SB - store byte
            case (byte_offset)
                2'b00: StoreData = {pick_byte(ReadData[31:24], WriteData[31:24]),
                                    pick_byte(ReadData[23:16], WriteData[23:16]),
                                    pick_byte(ReadData[15:8],  WriteData[15:8]),
                                    WriteData[7:0]};
                2'b01: StoreData = {pick_byte(ReadData[31:24], WriteData[31:24]),
                                    pick_byte(ReadData[23:16], WriteData[23:16]),
                                    WriteData[7:0],
                                    pick_byte(ReadData[7:0],   WriteData[7:0])};
                2'b10: StoreData = {pick_byte(ReadData[31:24], WriteData[31:24]),
                                    WriteData[7:0],
                                    pick_byte(ReadData[15:8],  WriteData[15:8]),
                                    pick_byte(ReadData[7:0],   WriteData[7:0])};
                2'b11: StoreData = {WriteData[7:0],
                                    pick_byte(ReadData[23:16], WriteData[23:16]),
                                    pick_byte(ReadData[15:8],  WriteData[15:8]),
                                    pick_byte(ReadData[7:0],   WriteData[7:0])};
            endcase
        end
        3'b001: begin // SH - store halfword
            case (byte_offset[1])
                1'b0: StoreData = {pick_byte(ReadData[31:24], WriteData[31:24]),
                                   pick_byte(ReadData[23:16], WriteData[23:16]),
                                   WriteData[15:0]};
                1'b1: StoreData = {WriteData[15:0],
                                   pick_byte(ReadData[15:8],  WriteData[15:8]),
                                   pick_byte(ReadData[7:0],   WriteData[7:0])};
            endcase
        end
        3'b010: begin // SW - store word
            StoreData = WriteData;
        end
        default: StoreData = WriteData;
    endcase
end

// Result Source
mux4 #(32)     resultmux(ALUResult, LoadData, PCPlus4, luiPC, ResultSrc, Result);

assign Mem_WrData = StoreData;
assign Mem_WrAddr = ALUResult;
assign AuiPC = PCTarget;

endmodule