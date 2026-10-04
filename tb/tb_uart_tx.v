`timescale 1ns/1ps

module tb_uart_tx #(
    parameter CLK_FREQ = 50_000_000,
    parameter BAUD = 115_200
);

    reg clk;
    reg rst_n;
    reg [7:0] tx_data;
    reg tx_valid;
    wire tx_ready;
    wire tx;

    uart_tx #(.CLK_FREQ(CLK_FREQ), .BAUD(BAUD) ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .tx_data(tx_data),
        .tx_valid(tx_valid),
        .tx_ready(tx_ready),
        .tx(tx)
    );

    integer test_num = 0;
    integer pass_n = 0;
    integer fail_n = 0;


    task check(input got, input exp);
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

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("uart_tx.vcd");
        $dumpvars(0, tb_uart_tx);
    end

    integer t;
    integer i = 0;
    integer k;

    initial begin
        tx_valid = 0; 
        rst_n = 0;
        @(posedge clk);
        #1;
        rst_n = 1;

        @(posedge clk);
        #1;
        tx_data = 8'b01000011;
        tx_valid = 1;
        @(posedge clk);
        #1;
        tx_valid = 0;
        check(tx, 0);
        for (t = 1; t < 160; t = t + 1) begin
            @(posedge clk);
            #1;
            k = t/16;
            if (k === 0)
                check(tx, 0);
            else if (k === 9)
                check(tx, 1);
            else
                check(tx, tx_data[k-1]);
        end


        repeat (200) @(posedge clk);
        
        $display("%0d passed, %0d failed", pass_n, fail_n);
        $finish;

    end




endmodule