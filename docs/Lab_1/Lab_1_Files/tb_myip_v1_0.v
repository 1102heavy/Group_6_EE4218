`timescale 1ns / 1ps
module tb_myip_v1_0;

//Clock /Reset
reg ACLK;
reg ARESETN;

//AXIS slave (data going to DUT)
wire S_AXIS_TREADY;
reg [31:0] S_AXIS_TDATA;
reg S_AXIS_TLAST;
reg S_AXIS_TVALID;

//AXIS MASTER (Data going to master)
wire        M_AXIS_TVALID;
wire [31:0] M_AXIS_TDATA;
wire        M_AXIS_TLAST;
reg         M_AXIS_TREADY;

wire [3:0] STATE;
wire [3:0] TEST;


  // Instantiate DUT
  myip_v1_0 dut (
    .ACLK(ACLK),
    .ARESETN(ARESETN),
    .S_AXIS_TREADY(S_AXIS_TREADY),
    .S_AXIS_TDATA(S_AXIS_TDATA),
    .S_AXIS_TLAST(S_AXIS_TLAST),
    .S_AXIS_TVALID(S_AXIS_TVALID),
    .M_AXIS_TVALID(M_AXIS_TVALID),
    .M_AXIS_TDATA(M_AXIS_TDATA),
    .M_AXIS_TLAST(M_AXIS_TLAST),
    .M_AXIS_TREADY(M_AXIS_TREADY),
    .STATE(STATE),
    .TEST(TEST)
  );
  
  //Clock generation
  initial begin
    //100mhz
    ACLK = 1'b0;
    forever #5 ACLK = ~ACLK; 
  end
  
  //Simple axis send task
    task automatic axis_send_word;
      input [31:0] w;
      input        last;
      begin
        S_AXIS_TDATA  = w;
        S_AXIS_TLAST  = last;
        S_AXIS_TVALID = 1'b1;
    
        while (S_AXIS_TREADY !== 1'b1) begin
          @(posedge ACLK);
        end
    
        @(posedge ACLK);
    
        S_AXIS_TVALID = 1'b0;
        S_AXIS_TLAST  = 1'b0;
        S_AXIS_TDATA  = 32'h0;
      end
    endtask
    
integer i;

reg [7:0] vecA [0:7];
reg [7:0] vecB [0:7];

 initial begin
    // Example contents (pick any values you want)
    vecA[0]=8'h01; vecA[1]=8'h02; vecA[2]=8'h03; vecA[3]=8'h04;
    vecA[4]=8'h05; vecA[5]=8'h06; vecA[6]=8'h07; vecA[7]=8'h08;

    vecB[0]=8'h01; vecB[1]=8'h01; vecB[2]=8'h01; vecB[3]=8'h01;
  end
  
  
 initial begin
    // Defaults
    ARESETN      = 1'b0;
    S_AXIS_TDATA = 32'h0;
    S_AXIS_TLAST = 1'b0;
    S_AXIS_TVALID= 1'b0;
    M_AXIS_TREADY= 1'b1; // keep ready high
    
    
    // Reset for a few cycles
    repeat (5) @(posedge ACLK);
    ARESETN = 1'b1;
    repeat (2) @(posedge ACLK);
    
      // Send A (8 beats)
    for (i = 0; i < 8; i = i + 1) begin
      axis_send_word({24'h0, vecA[i]}, 1'b0);
    end

    // Send B (4 beats), TLAST optional; can assert on last beat if you like
    for (i = 0; i < 4; i = i + 1) begin
      axis_send_word({24'h0, vecB[i]}, (i==3));
    end

    // Wait a few cycles for writes to settle
    repeat (5) @(posedge ACLK);

    // --- CHECKS ---
    // 1) Check the actual RAM contents by hierarchical access (works in behavioral sim)
    for (i = 0; i < 8; i = i + 1) begin
      if (dut.A_RAM.RAM[i] !== vecA[i]) begin
        $display("FAIL: A_RAM[%0d]=%02h expected=%02h", i, dut.A_RAM.RAM[i], vecA[i]);
      end
    end

    for (i = 0; i < 4; i = i + 1) begin
      if (dut.B_RAM.RAM[i] !== vecB[i]) begin
        $display("FAIL: B_RAM[%0d]=%02h expected=%02h", i, dut.B_RAM.RAM[i], vecB[i]);
      end
    end
    
    for (i = 0; i < 2; i = i + 1) begin
      if (dut.RES_RAM.RAM[i] !== vecB[i]) begin
        $display("FAIL: RES_RAM[%0d]=%02h expected=%02h", i, dut.RES_RAM.RAM[i], vecB[i]);
      end
    end

    $display("PASS: A and B were written into RAM correctly.");
    $finish;
  end
    
  
endmodule
