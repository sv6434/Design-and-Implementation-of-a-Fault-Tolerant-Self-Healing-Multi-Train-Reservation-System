`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:    09:40:03 10/20/25
// Design Name:    
// Module Name:    self_healing_controller
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
module self_healing_controller (
    input clk,
    input rst,
    input fault_flag,
    input predict_flag,
    output reg heal_trigger,
    output reg [1:0] heal_mode
);
    reg prev_fault_flag, prev_predict_flag;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            heal_trigger <= 0;
            heal_mode <= 2'b00;
            prev_fault_flag <= 0;
            prev_predict_flag <= 0;
        end else begin
            // Default
            heal_trigger <= 0;
            heal_mode <= 2'b00;

            // Fault has HIGHER priority — always trigger seat correction
            if (fault_flag && !prev_fault_flag) begin
                heal_trigger <= 1;
                heal_mode <= 2'b10;
            end
            // Only trigger compensation if NO fault this cycle
            else if (predict_flag && !prev_predict_flag && !fault_flag) begin
                heal_trigger <= 1;
                heal_mode <= 2'b01;
            end

            // Update history
            prev_fault_flag <= fault_flag;
            prev_predict_flag <= predict_flag;
        end
    end
endmodule
