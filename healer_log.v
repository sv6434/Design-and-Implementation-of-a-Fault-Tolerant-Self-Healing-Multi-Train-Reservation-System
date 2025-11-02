`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:    07:12:18 10/25/25
// Design Name:    
// Module Name:    healer_log
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
module healer_log (
    input            clk,
    input            rst,
    input            book_req,
    input            success,
    input            fault_flag,
    input            predict_flag,
    input            heal_trigger,
    input  [1:0]     heal_mode,
    input  [9:0]     booked_count,
    input  [9:0]     fare,
	 input [63:0] test_case,
    input            close_log
);
    integer  log_file;
    reg      file_opened = 0;
    reg [31:0] cycle_count;
    reg [31:0] fault_history [0:2];
    reg [159:0] event_str;
    integer i;

    initial begin
        log_file = $fopen("healer_log.csv", "w");
        if (!file_opened) begin
            $fwrite(log_file, 
                "Cycle,Book_Req,Success,Fault,Pred_Heal,Trigger,Mode,Booked_Count,Fare,Event,Test_Case,Fault0,Fault1,Fault2\n"
            );
            file_opened = 1;
        end
        cycle_count = 0;
        for (i = 0; i < 3; i = i + 1)
            fault_history[i] = 0;
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // DO NOT RESET cycle_count ? keep global timeline
            for (i = 0; i < 3; i = i + 1)
                fault_history[i] <= 0;
        end
        else begin
            cycle_count <= cycle_count + 1;

            if (fault_flag) begin
                fault_history[2] <= fault_history[1];
                fault_history[1] <= fault_history[0];
                fault_history[0] <= cycle_count;
            end

            event_str = "IDLE";
            if (book_req && success)           event_str = "BOOKING_SUCCESS";
            else if (book_req && !success)     event_str = "BOOKING_FAILED";
            else if (fault_flag && !heal_trigger) event_str = "FAULT_DETECTED";
            else if (heal_trigger && heal_mode == 2'b10) event_str = "SEAT_CORRECTION";
            else if (heal_trigger && heal_mode == 2'b01) event_str = "COMPENSATION";

            $fwrite(log_file,
                "%0d,%b,%b,%b,%b,%b,%s,%0d,%0d,%s,%s,%0d,%0d,%0d\n",
                cycle_count,
                book_req, success,
                fault_flag, predict_flag, heal_trigger,
                (heal_mode == 2'b10) ? "SEAT" : (heal_mode == 2'b01) ? "COMP" : "NONE",
                booked_count, fare,
                event_str, test_case,
                fault_history[0], fault_history[1], fault_history[2]
            );

            if (close_log) begin
                $fclose(log_file);
            end
        end
    end
endmodule