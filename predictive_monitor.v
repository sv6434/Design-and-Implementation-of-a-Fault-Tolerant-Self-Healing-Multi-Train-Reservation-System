`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:    23:46:16 10/23/25
// Design Name:    
// Module Name:    predictive_monitor
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
module predictive_monitor (
    input clk, rst, fault_flag,
    output reg predict_flag
);
    reg [3:0] fault_count;
    reg prev_fault_flag;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            fault_count <= 0;
            predict_flag <= 0;
            prev_fault_flag <= 0;
        end else begin
            // Count only rising edges of fault_flag
            if (fault_flag && !prev_fault_flag)
                fault_count <= fault_count + 1;

            // Trigger prediction when threshold reached (3 faults)
            if (fault_count >= 3)
                predict_flag <= 1;

            prev_fault_flag <= fault_flag;
        end
    end
endmodule
