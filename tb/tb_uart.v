`timescale 1ns/1ps

module tb_uart #(
    parameter CLK_FREQ = 1_600_000,
    parameter BAUD = 100_000
);

    localparam CLKS_PER_BIT = CLK_FREQ / BAUD;


    reg tx_clk;
    reg tx_rst_n;
    reg [7:0] tx_data;
    reg tx_valid;
    wire tx_ready;
    wire tx;

    reg rx_clk;
    reg rx_rst_n;
    wire [7:0] rx_data;
    wire rx_valid;
    wire rx_frame_err;

    uart_tx #(.CLK_FREQ(CLK_FREQ), .BAUD(BAUD) ) dut_tx (
        .clk(tx_clk),
        .rst_n(tx_rst_n),
        .tx_data(tx_data),
        .tx_valid(tx_valid),
        .tx_ready(tx_ready),
        .tx(tx)
    );

    uart_rx #(.CLK_FREQ(CLK_FREQ), .BAUD(BAUD) ) dut (
        .clk(rx_clk),
        .rst_n(rx_rst_n),
        .rx(tx),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .rx_frame_err(rx_frame_err)
    );



    integer test_num = 0;
    integer pass_n = 0;
    integer fail_n = 0;

    task check(input [7:0] got, input [7:0] exp);
        begin
            test_num = test_num + 1;
            if (got === exp) begin
                $display("PASS %0d got=%h", test_num, got);
                pass_n = pass_n + 1;
            end
            else begin
                $display("FAIL %0d got=%h exp=%h", test_num, got, exp);
                fail_n = fail_n + 1;
            end
        end
    endtask


    initial begin
        $dumpfile("uart.vcd");
        $dumpvars(0, tb_uart);
    end

    initial begin
        tx_clk = 0;
        rx_clk = 0;
    end

    always #5 tx_clk = ~tx_clk;
    always #5 rx_clk = ~rx_clk;

    always @(posedge rx_clk)
        if (rx_frame_err) fail_n = fail_n + 1;

    initial begin
        tx_valid = 0; 
        tx_rst_n = 0;
        rx_rst_n = 0;
        @(posedge tx_clk);
        #1;
        tx_rst_n = 1;
        @(posedge rx_clk);
        #1;
        rx_rst_n = 1;

        @(posedge tx_clk);
        #1;
        tx_data = 8'h41;
        tx_valid = 1;
        @(posedge tx_clk);
        #1;
        tx_valid = 0;

        wait (rx_valid == 1);
        check(rx_data, tx_data);


        repeat (200) @(posedge rx_clk);
        $display("%0d passed, %0d failed", pass_n, fail_n);
        $finish;

    end


endmodule