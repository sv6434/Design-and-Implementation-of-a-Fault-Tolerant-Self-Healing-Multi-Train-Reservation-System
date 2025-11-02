`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:    09:51:56 10/20/25
// Design Name:    
// Module Name:    rtv_multi_train_self_healing
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
module rtv_multi_train_self_healing(
    input clk,
    input rst,
    input book_req,
    input [0:0] train_id,
    input [2:0] src,
    input [2:0] dest,
    input [3:0] num_tickets,
    output reg success,
    output reg [3:0] booked_count,
    output reg [9:0] fare,
    output wire fault_flag,
    output wire predict_flag,
    output wire heal_trigger,
    output wire [1:0] heal_mode
);

    // Internal wires
    wire [3:0] core_booked_count;
    wire [9:0] core_fare;
    wire core_success;
    wire [39:0] booked_seats;
    wire [15:0] total_fare;
    wire [9:0] seat_status_train1;
    wire [9:0] seat_status_train2;

    // Booking Core
    rtv_multi_train core (
        .clk(clk),
        .rst(rst),
        .book_req(book_req),
        .train_id(train_id),
        .src(src),
        .dest(dest),
        .num_tickets(num_tickets),
        .success(core_success),
        .booked_count(core_booked_count),
        .fare(core_fare),
        .booked_seats(booked_seats),
        .total_fare(total_fare),
        .seat_status_train1(seat_status_train1),
        .seat_status_train2(seat_status_train2)
    );

    // Fault Detection
    fault_detection_unit fdu (
        .clk(clk),
        .rst(rst),
        .booked_count(core_booked_count),
        .fare(core_fare),
        .fault_flag(fault_flag)
    );

    // Predictive Monitor
    predictive_monitor pmu (
        .clk(clk),
        .rst(rst),
        .fault_flag(fault_flag),
        .predict_flag(predict_flag)
    );

    // Self-Healing Controller
    self_healing_controller shu (
        .clk(clk),
        .rst(rst),
        .fault_flag(fault_flag),
        .predict_flag(predict_flag),
        .heal_trigger(heal_trigger),
        .heal_mode(heal_mode)
    );

    // Healing Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            success <= 0;
            booked_count <= 0;
            fare <= 0;
        end else begin
            success <= core_success;
            booked_count <= core_booked_count;
            fare <= core_fare;

            if (heal_trigger && !predict_flag) begin

                case (heal_mode)
                    2'b01: fare <= core_fare + 10'd50; // Compensation
                    2'b10: booked_count <= booked_count - 1; // Seat correction
                    2'b11: begin // Full recovery
                        success <= 0;
                        booked_count <= 0;
                        fare <= 0;
                    end
                    default: ; // No healing
                endcase
            end
        end
    end
endmodule
