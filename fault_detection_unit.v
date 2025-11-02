`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:    09:23:25 10/20/25
// Design Name:    
// Module Name:    fault_detection_unit
// Project Name:   
// Target Device:  
// Tool versions:  
// Description:
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////
module fault_detection_unit (
    input clk,
    input rst,
    input [3:0] booked_count,
    input [9:0] fare,
    output reg fault_flag
);
    always @(posedge clk or posedge rst) begin
        if (rst)
            fault_flag <= 0;
        else if (booked_count > 9 || fare > 900)
            fault_flag <= 1;  // Fault condition example
        else
            fault_flag <= 0;
    end
endmodule