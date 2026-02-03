`timescale 1ns / 1ps

/* 
----------------------------------------------------------------------------------
--	(c) Rajesh C Panicker, NUS
--  Description : Template for the Matrix Multiply unit for the AXI Stream Coprocessor
--	License terms :
--	You are free to use this code as long as you
--		(i) DO NOT post a modified version of this on any public repository;
--		(ii) use it only for educational purposes;
--		(iii) accept the responsibility to ensure that your implementation does not violate any intellectual property of any entity.
--		(iv) accept that the program is provided "as is" without warranty of any kind or assurance regarding its suitability for any particular purpose;
--		(v) send an email to rajesh.panicker@ieee.org briefly mentioning its use (except when used for the course EE4218 at the National University of Singapore);
--		(vi) retain this notice in this file or any files derived from this.
----------------------------------------------------------------------------------
*/

// those outputs which are assigned in an always block of matrix_multiply shoud be changes to reg (such as output reg Done).

module matrix_multiply
	#(	parameter width = 8, 			// width is the number of bits per location
		parameter A_depth_bits = 3, 	// depth is the number of locations (2^number of address bits)
		parameter B_depth_bits = 2, 
		parameter RES_depth_bits = 1
	) 
	(
		input clk,										
		input Start,									// myip_v1_0 -> matrix_multiply_0.
		output reg Done = 0,									// matrix_multiply_0 -> myip_v1_0. Possibly reg.
		
		output reg A_read_en = 0,  								// matrix_multiply_0 -> A_RAM. Possibly reg.
		output reg [A_depth_bits-1:0] A_read_address = 0, 		// matrix_multiply_0 -> A_RAM. Possibly reg.
		input [width-1:0] A_read_data_out,				// A_RAM -> matrix_multiply_0.
		
		output reg B_read_en = 0, 								// matrix_multiply_0 -> B_RAM. Possibly reg.
		output reg [B_depth_bits-1:0] B_read_address = 0, 		// matrix_multiply_0 -> B_RAM. Possibly reg.
		input [width-1:0] B_read_data_out,				// B_RAM -> matrix_multiply_0.
		
		output reg RES_write_en = 0, 							// matrix_multiply_0 -> RES_RAM. Possibly reg.
		output reg [RES_depth_bits-1:0] RES_write_address = 0, 	// matrix_multiply_0 -> RES_RAM. Possibly reg.
		output reg [width-1:0] RES_write_data_in = 0			// matrix_multiply_0 -> RES_RAM. Possibly reg.
	);
	
	// implement the logic to read A_RAM, read B_RAM, do the multiplication and write the results to RES_RAM
	// Note: A_RAM and B_RAM are to be read synchronously. Read the wiki for more details.

    //Define the number of elements and deduce the rows and columns
    localparam integer A_ELEMS   = (1 << A_depth_bits);
    localparam integer B_ELEMS   = (1 << B_depth_bits);
    localparam integer RES_ELEMS = (1 << RES_depth_bits);
    
    localparam integer N = 1;              // fixed: B is Kx1
    localparam integer K = B_ELEMS / N;    // = B_ELEMS
    localparam integer R = RES_ELEMS / N;  // = RES_ELEMS
    
    localparam integer A_ROWS = R;
    localparam integer A_COLS = K;         // “rowsize/stride” for row-major  
    
    //Define counters and their sizes
    localparam ROWSIZE = (1 << B_depth_bits); //Logic: Column number for B matrix is 1. This is the ROWSIZE OF B
    reg [$clog2(A_COLS) - 1:0] k = 0; //Row of B = Column of A
    reg [$clog2(A_ROWS) - 1:0] r = 0;
    reg [17:0 ]accumulator;
    
	// Define the states of state machine (one hot encoding)
	localparam Idle  = 6'b100000;
	localparam Read_Inputs = 6'b010000;
	localparam Send_Address = 6'b001000;
	localparam Compute = 6'b000100;
	localparam Write_Outputs  = 6'b000010;
	localparam DONE = 6'b000001;
	
    reg [5:0] state = 6'b100000;
    
    
    always @(posedge clk) begin
            
        case (state)        
            Idle: begin
                A_read_en <= 0;
                B_read_en <= 0;
                A_read_address <= 0;
                B_read_address <= 0;
                Done <= 0;
                RES_write_en <= 0;
                RES_write_address <= 0;
                RES_write_data_in <= 0;
                
                k <= 0;
                r <= 0;
                accumulator <= 0;
                
                
                if (!Start) begin
                    state <= Idle;
                end
                else begin
                    state <= Read_Inputs;
                end
            end
            
            Read_Inputs: begin
            
               //Reset RES parameters
               RES_write_en <= 0;
               RES_write_address <= 0;
               RES_write_data_in <= 0;
                
               A_read_address <= A_COLS * r + k;
               B_read_address <= k;
               A_read_en <= 1;
               B_read_en <= 1;
              
               state <= Send_Address;
            end
            
            Send_Address: begin
                //Address is being sent
                state <= Compute;
                A_read_en <= 1;
                B_read_en <= 1;
            end
            
            Compute: begin
                accumulator <= accumulator + (A_read_data_out * B_read_data_out);
                
                state <= Write_Outputs;
            end
            
            Write_Outputs: begin
            
                // update k and r
                if (k < A_COLS - 1) begin
                    k <= k + 1;
                    r <= r;
                end
                else begin
                    k <= 0;
                    r <= r + 1;
                end
                
                
                
                //Check if one row of calculation is done
                if (k == A_COLS - 1) begin
                
                    RES_write_address <= r;
                    RES_write_en <= 1;
                    RES_write_data_in <= accumulator >> 8;
                    accumulator <= 0;
                end //Else process onto deciding whcih state to go to
                
                
                if (r < A_ROWS - 1) begin
                    state <= Read_Inputs;
                end 
                else begin
                    Done <= 1;
                end                
            end
            
            DONE: begin
                state <= Idle;
            end
            
        endcase

    
    end

endmodule


