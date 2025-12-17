module uart_rx (
    input clk,
    input rst,
    input rx,
    output reg [15:0]rx_data,
    output reg rx_done,
    output reg parity_error
);

    parameter CLK_FREQ = 50_000_000;
    parameter BAUD_RATE = 115200;

    localparam BAUD_DIV = CLK_FREQ / BAUD_RATE;
    localparam HALF_BAUD = BAUD_DIV / 2;

    integer baud_cnt;
    integer bit_cnt;

    reg rx_busy;
    reg rx_parity;
    reg [15:0]scratch_reg;

    reg rx_sync, rx_safe;
    
    always @(posedge clk) begin
        rx_sync <= rx;
        rx_safe <= rx_sync;
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rx_busy <= 0;
            rx_done <= 0;
            parity_error <= 0;
            baud_cnt <= 0;
            bit_cnt <= 0;
            rx_data <= 0;
            scratch_reg <= 0;
        end 
        else begin
            rx_done <= 0;

            if (!rx_busy && rx_safe == 0) begin
                rx_busy <= 1;
                baud_cnt <= HALF_BAUD;
                bit_cnt <= 0;
                $display("TIME %t: RX Start Bit Detected", $time);
            end
            
            else if (rx_busy) begin
                if (baud_cnt == BAUD_DIV - 1) begin
                    baud_cnt <= 0;

                    if (bit_cnt >= 1 && bit_cnt <= 16) begin
                        scratch_reg[bit_cnt - 1] <= rx_safe;
                    end
                    
                    else if (bit_cnt == 17) begin
                        rx_parity <= rx_safe;
                    end

                    else if (bit_cnt == 18) begin
                        rx_busy <= 0;
                        
                        $display("TIME %t: RX Stop Bit Check. Level=%b", $time, rx_safe);

                        if (rx_safe == 1) begin
                            rx_done <= 1;
                            rx_data <= scratch_reg;

                            if ((^scratch_reg) != rx_parity) begin
                                parity_error <= 1;
                                $display("TIME %t: RX Parity Error!", $time);
                            end 
                            else begin
                                parity_error <= 0;
                            end
                            $display("TIME %t: RX Success! Data=%h", $time, scratch_reg);
                        end 
                        else begin
                            $display("TIME %t: RX Framing Error! Stop bit was 0.", $time);
                        end
                    end
                    bit_cnt <= bit_cnt + 1;
                end 
                else begin
                    baud_cnt <= baud_cnt + 1;
                end
            end
        end
    end
endmodule