`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   22:15:15 10/16/2025
// Design Name:   rtv_multi_train
// Module Name:   tb_rtv_multi.v
// Project Name:  rail
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: rtv_multi_train
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_rtv_multi_v;

	// Inputs
	reg clk;
	reg rst;
	reg book_req;
	reg train_id;
	reg [2:0] src;
	reg [2:0] dest;
	reg [3:0] num_tickets;

	// Outputs
	wire success;
	wire [3:0] booked_count;
	wire [39:0] booked_seats;
	wire [15:0] total_fare;
	wire [9:0] fare;
	wire [9:0] seat_status_train1;
	wire [9:0] seat_status_train2;


	// Instantiate the Unit Under Test (UUT)
	rtv_multi_train uut (
		.clk(clk), 
		.rst(rst), 
		.book_req(book_req), 
		.train_id(train_id), 
		.src(src), 
		.dest(dest), 
		.num_tickets(num_tickets), 
		.success(success), 
		.booked_count(booked_count), 
		.booked_seats(booked_seats), 
		.total_fare(total_fare), 
		.fare(fare),
		.seat_status_train1(seat_status_train1),
		 .seat_status_train2(seat_status_train2)
	);
	// ------------------------------------------------------------
    // Helper task: Display booked seat numbers for a given train
    // ------------------------------------------------------------
	 task display_booked_seats;
    input train_id;
    input [39:0] seats;
    integer i;
    reg [3:0] seat_num;
    begin
        if (train_id == 0) $write("Train 1 (Chennai–Bengaluru) ");
        else $write("Train 2 (New Delhi–Varanasi) ");
        $write("Booked seats: ");
        if (seats == 0) $write("None");
        else begin
            for (i = 0; i < booked_count; i = i + 1) begin
                seat_num = seats[i*4 +: 4];
                $write("%0d ", seat_num + 1);
            end
        end
        $display("");
    end
endtask
	 // ------------------------------------------------------------
// Helper task: Decode and display seat indices from booked_seats
// ------------------------------------------------------------
task decode_booked_seats;
    input [3:0] count;               // Number of seats booked
    input [39:0] seats;              // Packed seat indices (10 × 4 bits)
    integer i;
    reg [3:0] seat_num;
    begin
        $write("Decoded seat indices: ");
        for (i = 0; i < count; i = i + 1) begin
            seat_num = seats[i*4 +: 4];
            $write("%0d ", seat_num + 1); // 1-based seat number
        end
        $display("");
    end
endtask
    // ------------------------------------------------------------
    // Clock Generation (10 ns period -> 100 MHz)
    // ------------------------------------------------------------
    always #5 clk = ~clk;

    // ------------------------------------------------------------
    // Main Test Sequence
    // ------------------------------------------------------------
    initial begin
        $display("\n=============== MULTI-TRAIN RESERVATION TEST ===============\n");

        // Initialize
        clk = 0;
        rst = 1;
        book_req = 0;
        train_id = 0;
        src = 0;
        dest = 0;
        num_tickets = 0;
        #20;
        rst = 0;
        #10;

        // -------------------------------------------------------------
        // TRAIN 1 TESTS (Chennai -> Bengaluru)
        // -------------------------------------------------------------
        $display("------ TRAIN 1: Chennai to Bengaluru ------");

        // Test 1: Normal booking (Chennai to Katpadi)
        $display("[T1.1] Booking 2 seats (src=Chennai, dest=Katpadi)");
        train_id = 0; src = 3'b000; dest = 3'b001; num_tickets = 2;
        book_req = 1; #10; book_req = 0; #50;
        $display("Success=%b | Count=%d | Fare=%d | Total=%d",
                 success, booked_count, fare, total_fare);
        display_booked_seats(train_id, booked_seats);
		  decode_booked_seats(booked_count, booked_seats);
		  $display("Train1 Seat Status: %b", seat_status_train1);
		  $display("Train2 Seat Status: %b", seat_status_train2);



        // Test 2:Non Overlapping route (Chennai to Katpadi, more tickets)
        $display("[T1.2] Non-Overlapping Booking (src=Chennai, dest=Katpadi, tickets=4)");
        train_id = 0; src = 3'b000; dest = 3'b001; num_tickets = 4;
        book_req = 1; #10; book_req = 0; #50;
        $display("Success=%b | Count=%d | Fare=%d | Total=%d",
                 success, booked_count, fare, total_fare);
        display_booked_seats(train_id, booked_seats);
		  decode_booked_seats(booked_count, booked_seats);
		  $display("Train1 Seat Status: %b", seat_status_train1);
$display("Train2 Seat Status: %b", seat_status_train2);



        // Test 3: Non-overlapping route (Jolarpettai to Bengaluru)
        $display("[T1.3] Non-overlapping Booking (src=Jolarpettai, dest=Bengaluru, tickets=4)");
        train_id = 0; src = 3'b010; dest = 3'b100; num_tickets = 4;
        book_req = 1; #10; book_req = 0; #50;
        $display("Success=%b | Count=%d | Fare=%d | Total=%d",
                 success, booked_count, fare, total_fare);
        display_booked_seats(train_id, booked_seats);
		  decode_booked_seats(booked_count, booked_seats);
		  $display("Train1 Seat Status: %b", seat_status_train1);
$display("Train2 Seat Status: %b", seat_status_train2);



        // Test 4: Katpadi to Jolarpettai
        $display("[T1.4] Booking 2 seats (src=Katpadi, dest=Jolarpettai)");
        train_id = 0; src = 3'b001; dest = 3'b010; num_tickets = 2;
        book_req = 1; #10; book_req = 0; #50;
        $display("Success=%b | Count=%d | Fare=%d | Total=%d",
                 success, booked_count, fare, total_fare);
        display_booked_seats(train_id, booked_seats);
		  decode_booked_seats(booked_count, booked_seats);
		  $display("Train1 Seat Status: %b", seat_status_train1);
		  $display("Train2 Seat Status: %b", seat_status_train2);


        // Test 5: Katpadi to Krishnarajapuram
        $display("[T1.5] Booking 3 seats (src=Katpadi, dest=Krishnarajapuram)");
        train_id = 0; src = 3'b001; dest = 3'b011; num_tickets = 3;
        book_req = 1; #10; book_req = 0; #50;
        $display("Success=%b | Count=%d | Fare=%d | Total=%d",
                 success, booked_count, fare, total_fare);
        display_booked_seats(train_id, booked_seats);
		  decode_booked_seats(booked_count, booked_seats);
		  $display("Train1 Seat Status: %b", seat_status_train1);
$display("Train2 Seat Status: %b", seat_status_train2);


        // Test 6: Katpadi to Bengaluru
        $display("[T1.6] Booking 2 seats (src=Katpadi, dest=Bengaluru)");
        train_id = 0; src = 3'b001; dest = 3'b100; num_tickets = 2;
        book_req = 1; #10; book_req = 0; #50;
        $display("Success=%b | Count=%d | Fare=%d | Total=%d",
                 success, booked_count, fare, total_fare);
        display_booked_seats(train_id, booked_seats);
		  decode_booked_seats(booked_count, booked_seats);
		  $display("Train1 Seat Status: %b", seat_status_train1);
$display("Train2 Seat Status: %b", seat_status_train2);


        // Test 7: Jolarpettai to Krishnarajapuram
        $display("[T1.7] Booking 3 seats (src=Jolarpettai, dest=Krishnarajapuram)");
        train_id = 0; src = 3'b010; dest = 3'b011; num_tickets = 3;
        book_req = 1; #10; book_req = 0; #50;
        $display("Success=%b | Count=%d | Fare=%d | Total=%d",
                 success, booked_count, fare, total_fare);
        display_booked_seats(train_id, booked_seats);
		  decode_booked_seats(booked_count, booked_seats);
		  $display("Train1 Seat Status: %b", seat_status_train1);
$display("Train2 Seat Status: %b", seat_status_train2);



        // -------------------------------------------------------------
        // TRAIN 2 TESTS (New Delhi -> Varanasi)
        // -------------------------------------------------------------
        $display("\n------ TRAIN 2: New Delhi to Varanasi ------");

        // Test 8: Normal booking
        $display("[T2.1] Booking 2 seats (src=New Delhi, dest=Kanpur)");
        train_id = 1; src = 3'b000; dest = 3'b001; num_tickets = 2;
        book_req = 1; #10; book_req = 0; #50;
        $display("Success=%b | Count=%d | Fare=%d | Total=%d",
                 success, booked_count, fare, total_fare);
        display_booked_seats(train_id, booked_seats);
		  decode_booked_seats(booked_count, booked_seats);
		  $display("Train1 Seat Status: %b", seat_status_train1);
$display("Train2 Seat Status: %b", seat_status_train2);



        // Test 9: Longer journey
        $display("[T2.2] Booking 3 seats (src=New Delhi, dest=Varanasi)");
        train_id = 1; src = 3'b000; dest = 3'b011; num_tickets = 3;
        book_req = 1; #10; book_req = 0; #50;
        $display("Success=%b | Count=%d | Fare=%d | Total=%d",
                 success, booked_count, fare, total_fare);
        display_booked_seats(train_id, booked_seats);
		  decode_booked_seats(booked_count, booked_seats);
		  $display("Train1 Seat Status: %b", seat_status_train1);
$display("Train2 Seat Status: %b", seat_status_train2);



        // Test 10: Invalid booking (same src/dest)
        $display("[T2.3] Invalid booking (src=Prayagraj, dest=Prayagraj)");
        train_id = 1; src = 3'b010; dest = 3'b010; num_tickets = 2;
        book_req = 1; #10; book_req = 0; #50;
        $display("Success=%b | Count=%d | Fare=%d | Total=%d",
                 success, booked_count, fare, total_fare);
        display_booked_seats(train_id, booked_seats);
		  decode_booked_seats(booked_count, booked_seats);
		  $display("Train1 Seat Status: %b", seat_status_train1);
$display("Train2 Seat Status: %b", seat_status_train2);



        // Test 11: Full capacity request
        $display("[T2.4] Full capacity booking (src=Kanpur, dest=Varanasi, tickets=12)");
        train_id = 1; src = 3'b001; dest = 3'b011; num_tickets = 12;
        book_req = 1; #10; book_req = 0; #50;
        $display("Success=%b | Count=%d | Fare=%d | Total=%d",
                 success, booked_count, fare, total_fare);
        display_booked_seats(train_id, booked_seats);
		  decode_booked_seats(booked_count, booked_seats);
		  $display("Train1 Seat Status: %b", seat_status_train1);
$display("Train2 Seat Status: %b", seat_status_train2);



        // -------------------------------------------------------------
        // RESET TEST
        // -------------------------------------------------------------
        $display("\n[RESET TEST]");
        rst = 1; #10; rst = 0; #20;
        $display("After Reset -> Success=%b | Count=%d | Total Fare=%d",
                 success, booked_count, total_fare);
        display_booked_seats(train_id, booked_seats);
		  decode_booked_seats(booked_count, booked_seats);
		  $display("Train1 Seat Status: %b", seat_status_train1);
$display("Train2 Seat Status: %b", seat_status_train2);



        $display("\n=============== SIMULATION COMPLETE ===============\n");
        $stop;
	end
      
endmodule

