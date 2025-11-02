`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:    21:39:04 10/16/25
// Design Name:    
// Module Name:    rtv_multi_train
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
module rtv_multi_train #(parameter N = 10) (
    input clk,
    input rst,
    input book_req,
    input [0:0] train_id,
    input [2:0] src,
    input [2:0] dest,
    input [3:0] num_tickets,
    output reg success,
    output reg [3:0] booked_count,
    output reg [N*4-1:0] booked_seats,
    output reg [15:0] total_fare,
    output reg [9:0] fare,
    output reg [N-1:0] seat_status_train1,
    output reg [N-1:0] seat_status_train2
);

    // Internal Signals
    reg [2:0] seat_start [0:1][0:N-1];
    reg [2:0] seat_end   [0:1][0:N-1];
    reg       seat_used  [0:1][0:N-1];
    integer i;
    integer temp_count_int;
    reg [9:0] fare_reg;
    reg [3:0] booked_count_next;
    reg [15:0] total_fare_next;
    reg booking_done;
    integer seat_assign_count;
    integer j;

    // FARE MATRIX
    always @(*) begin
        fare_reg = 0;
        case (train_id)
            1'b0: begin
                case ({src, dest})
                    6'b000001: fare_reg = 150; // Chennai to Katpadi
                    6'b000010: fare_reg = 300; // Chennai to Jolarpettai
                    6'b000011: fare_reg = 400; // Chennai to KrishnarajaPuram
                    6'b000100: fare_reg = 500; // Chennai to Bangalore
                    6'b001010: fare_reg = 150; // Katpadi to Jolarpettai
                    6'b001011: fare_reg = 250; // Katpadi to Krishnarajapuram
                    6'b001100: fare_reg = 350; // Katpadi to Bangalore
                    6'b010011: fare_reg = 150; // Jolarpettai to Krishnarajapuram
                    6'b010100: fare_reg = 200; // Jolarpettai to Bangalore
                    default: fare_reg = 0;
                endcase
            end
            1'b1: begin
                case ({src, dest})
                    6'b000001: fare_reg = 200;
                    6'b000010: fare_reg = 350;
                    6'b000011: fare_reg = 500;
                    6'b001010: fare_reg = 200;
                    6'b001011: fare_reg = 350;
                    6'b010011: fare_reg = 200;
                    default: fare_reg = 0;
                endcase
            end
            default: fare_reg = 0;
        endcase
    end

    // BOOKING LOGIC (combinational)
    always @(*) begin
        booked_count_next = 0;
        total_fare_next = 0;
        temp_count_int = 0;

        if (book_req && (src != dest) && (fare_reg > 0)) begin
            for (i = 0; i < N && temp_count_int < num_tickets; i = i + 1) begin
                if (!seat_used[train_id][i] || (dest <= seat_start[train_id][i] || src >= seat_end[train_id][i])) begin
                    temp_count_int = temp_count_int + 1;
                end
            end
            booked_count_next = temp_count_int;
            total_fare_next = temp_count_int * fare_reg;
        end
    end

    // SEQUENTIAL LOGIC
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < N; i = i + 1) begin
                seat_start[0][i] <= 0;
                seat_end[0][i]   <= 0;
                seat_used[0][i]  <= 0;
                seat_start[1][i] <= 0;
                seat_end[1][i]   <= 0;
                seat_used[1][i]  <= 0;
                booked_seats[i*4 +: 4] <= 0;
                seat_status_train1[i] <= 0;
                seat_status_train2[i] <= 0;
            end
            success <= 0;
            booked_count <= 0;
            total_fare <= 0;
            fare <= 0;
            booking_done <= 0;
        end
        else begin
            if (book_req) begin
                if (src == dest || fare_reg == 0) begin
                    success <= 0;
                    booked_count <= 0;
                    total_fare <= 0;
                    fare <= 0;
                    booking_done <= 0;
                    for (i = 0; i < N; i = i + 1) begin
                        booked_seats[i*4 +: 4] <= 0;
                    end
                end
                else begin
                    fare <= fare_reg;
                    success <= (booked_count_next > 0);
                    booked_count <= booked_count_next;
                    total_fare <= total_fare_next;
                    // clear booked_seats output before filling
                    for (i = 0; i < N; i = i + 1) begin
                        booked_seats[i*4 +: 4] <= 0;
                    end

                    // Seat allocation loop (corrected, non-overlap enforcement)
                    seat_assign_count = 0;
                    for (i = 0; i < N && seat_assign_count < booked_count_next; i = i + 1) begin
                        // Check if seat is completely free
                        if (!seat_used[train_id][i]) begin
                            seat_used[train_id][i] <= 1;
                            seat_start[train_id][i] <= src;
                            seat_end[train_id][i]   <= dest;
                            booked_seats[seat_assign_count*4 +: 4] <= i[3:0];
                            seat_assign_count = seat_assign_count + 1;
                        end
                        else if ((dest <= seat_start[train_id][i]) || (src >= seat_end[train_id][i])) begin
                            // Non-overlapping reuse (only if truly disjoint)
                            // Update stored interval conservatively
                            if (src < seat_start[train_id][i])
                                seat_start[train_id][i] <= src;
                            if (dest > seat_end[train_id][i])
                                seat_end[train_id][i]   <= dest;
                            booked_seats[seat_assign_count*4 +: 4] <= i[3:0];
                            seat_assign_count = seat_assign_count + 1;
                        end
                        // else: overlapping — skip this seat
                    end

                    booking_done <= (seat_assign_count > 0);
                    // success stricter: only if full requested tickets allocated
                    success <= (seat_assign_count == num_tickets);
                    // If you prefer previous behavior (partial booking is success), comment previous line and
                    // restore success <= (booked_count_next > 0);
                end
            end
            else begin
                booking_done <= 0;
            end

            // Update seat status outputs
            for (i = 0; i < N; i = i + 1) begin
                seat_status_train1[i] <= seat_used[0][i];
                seat_status_train2[i] <= seat_used[1][i];
            end
        end
    end

endmodule
