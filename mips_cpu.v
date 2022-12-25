`include "util.v"

module mips_cpu(clk, pc, pc_new, instruction_memory_a, instruction_memory_rd, data_memory_a, data_memory_rd, data_memory_we, data_memory_wd,
                register_a1, register_a2, register_a3, register_we3, register_wd3, register_rd1, register_rd2);
  // сигнал синхронизации
  input clk;
  // текущее значение регистра PC
  inout [31:0] pc;
  // новое значение регистра PC (адрес следующей команды)
  output [31:0] pc_new;
  // we для памяти данных
  output data_memory_we;
  // адреса памяти и данные для записи памяти данных
  output [31:0] instruction_memory_a, data_memory_a, data_memory_wd;
  // данные, полученные в результате чтения из памяти
  inout [31:0] instruction_memory_rd, data_memory_rd;
  // we3 для регистрового файла
  output register_we3;
  // номера регистров
  output [4:0] register_a1, register_a2, register_a3;
  // данные для записи в регистровый файл
  output [31:0] register_wd3;
  // данные, полученные в результате чтения из регистрового файла
  inout [31:0] register_rd1, register_rd2;

  // TODO: implementation

// Специальный код для сохранения сигналов в файл
 
//    initial begin 
//   $monitor(clk, pc, pc_new, instruction_memory_a, instruction_memory_rd, data_memory_a, data_memory_rd, data_memory_we, data_memory_wd,
//                 register_a1, register_a2, register_a3, register_we3, register_wd3, register_rd1, register_rd2);
// end
initial begin
    $dumpfile("./dump.vcd");
    $dumpvars;
  end
 
// 00100000000100000000000000000111
// 00100000000100010000000000001000
// 00000010001100001001000000100000
// 00000010001100001001100000100010
// 00000010001100001010000000100100
// 00000010001100001010100000100101
// 00000010001100001011000000101010

  wire [31:0] pc_plus_4;
  adder adder_1(pc,32'b00000000000000000000000000000100,pc_plus_4); 
  assign instruction_memory_a = pc;

 wire [5:0]	opCode = instruction_memory_rd[31:26];
//  wire [1:0] regDst, ALUSrc, memToReg;
 wire [1:0] regDst, ALUSrc;
 wire [1:0] ALUOp;
 wire regWrite, branch, brchne, memWrite, jump, jal,memToReg;
 main_decoder main_decoder_1(opCode, regWrite, regDst, ALUSrc, branch, brchne, memWrite, memToReg, jump, jal, ALUOp);
 wire [5:0] funct =instruction_memory_rd[5:0] ;
 wire [2:0] ALUControl;
 alu_decoder alu_decoder_1(funct,ALUOp,ALUControl);
 four_to_one_mux_5bits four_to_one_mux_5bits_1(instruction_memory_rd[20:16],instruction_memory_rd[15:11],5'b11111,5'bzzzzz,regDst[0],regDst[1],register_a3);

 assign register_a1 = instruction_memory_rd[25:21];
 assign register_a2 = instruction_memory_rd[20:16];
 wire [31:0] signExtend; 
 wire [31:0] zeroExtend; 

 sign_extend sign_extend_1(instruction_memory_rd[15:0],signExtend);
 zero_extend zero_extend_1(instruction_memory_rd[15:0],zeroExtend);
  wire[31:0] signExtended_shift;

 shl_2 shl_2_1(signExtend,signExtended_shift);
  wire [31:0] PCBranch;
 adder adder_2(signExtended_shift,pc_plus_4,PCBranch);

  wire[27:0] jumpForPC;
 shl_2_26but shl_2_26but_1(instruction_memory_rd[25:0],jumpForPC);

 wire [31:0] srcA;
 wire [31:0] srcB;
 assign srcA = register_rd1;
 four_to_one_mux four_to_one_mux_1(register_rd2,signExtend,zeroExtend,32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz,ALUSrc[0],ALUSrc[1],srcB);
 wire [31:0] ALUOut;
 wire zero;
 alu alu(srcA, srcB, ALUControl, ALUOut, zero);

 assign data_memory_a = ALUOut;
 assign data_memory_we = memWrite;
 assign data_memory_wd = register_rd2;

 assign register_we3 = regWrite;
  wire[31:0]res;
 two_to_one_mux two_to_one_mux_1(ALUOut,data_memory_rd,memToReg,res);

//это уже до начала
wire [31:0]pc_new_beforeJump;
two_to_one_mux two_to_one_mux_2(pc_plus_4,PCBranch,PCSrc,pc_new_beforeJump);

two_to_one_mux two_to_one_mux_3(pc_new_beforeJump,{4'b0000,jumpForPC},jump,pc_new);
//после pc 4
// two_to_one_mux two_to_one_mux_4(pc_plus_4,res,jal,register_wd3);
two_to_one_mux two_to_one_mux_4(res,pc_plus_4,jal,register_wd3);

wire not_zero;
wire w1,w2;
not_gate not_gate_1(zero,not_zero);
and_gate and_gate_1(branch, zero,w1);
and_gate and_gate_2(not_zero, brchne,w2);

or_gate or_gate_1(w1,w2,PCSrc);

endmodule
