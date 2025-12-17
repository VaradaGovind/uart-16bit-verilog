`timescale 1ns / 1ps

module tb;

    parameter CLK_FREQ = 50_000_000;
    parameter BAUD_RATE = 115200;

    reg clk;
    reg rst;
    reg tx_start;
    reg [15:0]tx_data;
    
    wire tx_line;
    wire tx_busy;
    wire [15:0]rx_data;
    wire rx_done;
    wire parity_error;

    always #10 clk = ~clk;

    uart_tx #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)) 
        u_tx (.clk(clk), .rst(rst), .tx_start(tx_start), .tx_data(tx_data), .tx(tx_line), .tx_busy(tx_busy));

    uart_rx #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)) 
        u_rx (.clk(clk), .rst(rst), .rx(tx_line), .rx_data(rx_data), .rx_done(rx_done), .parity_error(parity_error));

    task wait_for_rx;
        integer timeout;
        begin
            timeout = 0;
            while (rx_done == 0 && timeout < 20000) begin
                @(posedge clk);
                timeout = timeout + 1;
            end
            if (timeout >= 20000) 
                $display("ERROR: Receiver Timeout! rx_done never went high.");
        end
    endtask

    initial begin
        clk = 0; rst = 1; tx_start = 0; tx_data = 0;
        #100 rst = 0;
        #100;

        // --- Test 1 ---
        $display("--------------------------------");
        $display("Test 1: Sending 0xABCD...");
        tx_data = 16'hABCD;
        tx_start = 1;
        #20 tx_start = 0;
        
        wait_for_rx();
        #20;
        if (rx_data == 16'hABCD) $display("PASS: Received 0x%h", rx_data);
        else $display("FAIL: Received 0x%h", rx_data);


        $display("Waiting for TX to free up...");
        wait(tx_busy == 0); 
        #1000;


        // --- Test 2 ---
        $display("--------------------------------");
        $display("Test 2: Sending 0x1234...");
        tx_data = 16'h1234;
        tx_start = 1;
        #20 tx_start = 0;

        wait_for_rx();
        #20;
        if (rx_data == 16'h1234) $display("PASS: Received 0x%h", rx_data);
        else $display("FAIL: Received 0x%h", rx_data);
        $display("--------------------------------");

        $finish;
    end
endmodule