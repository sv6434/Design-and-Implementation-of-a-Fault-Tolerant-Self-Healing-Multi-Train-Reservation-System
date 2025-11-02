`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   00:37:31 10/24/2025
// Design Name:   rtv_multi_train_self_healing
// Module Name:   rtv_self_healing_ttb.v
// Project Name:  rail
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: rtv_multi_train_self_healing
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module rtv_self_healing_ttb_v;

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
	wire [9:0] fare;
	wire fault_flag;
	wire predict_flag;
	wire heal_trigger;
	wire [1:0] heal_mode;
	//Logging
	reg [63:0]current_case;
	reg close_log_trigger;

	// Instantiate the Unit Under Test (UUT)
	rtv_multi_train_self_healing uut (
		.clk(clk), 
		.rst(rst), 
		.book_req(book_req), 
		.train_id(train_id), 
		.src(src), 
		.dest(dest), 
		.num_tickets(num_tickets), 
		.success(success), 
		.booked_count(booked_count), 
		.fare(fare), 
		.fault_flag(fault_flag), 
		.predict_flag(predict_flag), 
		.heal_trigger(heal_trigger), 
		.heal_mode(heal_mode)
	);
	// LOGGER
    healer_log u_log (
        .clk(clk), .rst(rst), .book_req(book_req), .success(success),
        .fault_flag(fault_flag), .predict_flag(predict_flag),
        .heal_trigger(heal_trigger), .heal_mode(heal_mode),
        .booked_count({6'b0, booked_count}), .fare(fare),
        .test_case(current_case), .close_log(close_log_trigger)
    );
	// Clock generation
    always #5 clk = ~clk;

    // Fault Injection Task
	 task inject_fault;
begin
    @(negedge clk);
    force uut.fdu.fault_flag = 1'b1;   // Inject fault
    #7;                                // Hold high for >½ clock to ensure capture
    release uut.fdu.fault_flag;        // Release
    #8;                                // Allow one full cycle for recovery
end
endtask

//Health Monitor
reg prev_heal_trigger = 0;
always @(posedge clk) begin
    if (heal_trigger && !prev_heal_trigger) begin
        case (heal_mode)
            2'b01: $display("[HEAL] Compensation mode activated: Fare increased by 50.");
            2'b10: $display("[HEAL] Seat correction mode: One seat released.");
            2'b11: $display("[HEAL] Full system recovery: Booking and fare reset.");
            default: $display("[HEAL] Unknown healing mode!");
        endcase
    end
    prev_heal_trigger <= heal_trigger;
end

    // Simulation Process
    initial begin
        $display("\n================= SELF-HEALING TRAIN BOOKING SYSTEM TEST =================");

        // Initialize
        clk = 0;
        rst = 1;
        book_req = 0;
        train_id = 0;
        src = 0;
        dest = 0;
        num_tickets = 0;
		  current_case="INIT";
		  close_log_trigger=0;
        #20;
        rst = 0;
        $display("[INIT] System Reset Done");

        // CASE 1: Normal Booking
		  current_case="C1";
		  close_log_trigger=0;
        $display("\n[CASE 1] Normal booking operation");
        book_req = 1;
        train_id = 0;
        src = 3'b000;
        dest = 3'b010;
        num_tickets = 3;
        #10; book_req = 0; #30;
        $display("[INFO] Booking complete. Success=%b, Fare=%d, Count=%d", success, fare, booked_count);

        // CASE 2: Inject Single Fault
		  current_case="C2";
		  close_log_trigger=0;
        $display("\n[CASE 2] Injecting single fault");
        inject_fault();
        #40;
 // CASE 3: Repeated Faults
 current_case="C3";
 close_log_trigger=0;
 $display("\n[CASE 3] Triggering predictive healing by repeated faults");
repeat (3) begin
    inject_fault();
    #30;  // separation to allow proper edge capture and internal update
end
#50;  // wait for predictive compensation
        // CASE 4: Booking After Healing
		  current_case="C4";
		  close_log_trigger=0;
        $display("\n[CASE 4] Booking after healing");
        book_req = 1;
        train_id = 1;
        src = 3'b001;
        dest = 3'b011;
        num_tickets = 2;
        #10; book_req = 0; #40;
        $display("[INFO] Post-healing booking. Success=%b, Fare=%d, Count=%d", success, fare, booked_count);

        // RESET TEST
		  current_case="RST";
		  close_log_trigger=0;
        $display("\n[RESET TEST]");
        rst = 1; #10; rst = 0;
        #20;
		  $display("[RESET] System reset completed. State cleared.");
// END
        #100;
        close_log_trigger = 1;
        #10;
        $display("\n[LOG] healer_log.csv saved.");
        $display("=== SIMULATION DONE ===");
        $finish;
    end
endmodule