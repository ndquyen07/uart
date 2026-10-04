# UART

A UART transmitter and receiver, 8N1 frame (1 start bit, 8 data bits LSB first, 1 stop bit, no parity).

## Design

- Parameters: `CLK_FREQ` (default 50 MHz), `BAUD` (default 115200), `CLKS_PER_BIT = CLK_FREQ / BAUD`
- Active-low asynchronous reset `rst_n`
- The line idles high

`uart_tx`:
- Valid/ready handshake: a byte is accepted when `tx_valid = 1` and `tx_ready = 1`
- `tx_ready` is high only while idle. `tx_valid` is ignored while a frame is being sent

`uart_rx`:
- `rx` passes through a 2-flip-flop synchronizer
- Waits half a bit after the start edge, checks the start bit is still low, then samples each bit in its middle
- `rx_valid` pulses for one clock when a byte arrives with a valid stop bit; `rx_data` holds the byte
- `rx_frame_err` pulses for one clock if the stop bit is low; the receiver then waits for the line to go high before looking for the next start bit

## Run

```
mkdir -p sim
iverilog -P tb_uart_tx.CLK_FREQ=1600000 -P tb_uart_tx.BAUD=100000 -o sim/tb_uart_tx.vvp tb/tb_uart_tx.v rtl/uart_tx.v
vvp sim/tb_uart_tx.vvp

iverilog -o sim/tb_uart.vvp tb/tb_uart.v rtl/uart_tx.v rtl/uart_rx.v
vvp sim/tb_uart.vvp
```

`tb_uart_tx` checks one bit every 16 clocks, so it needs `CLKS_PER_BIT = 16`. The `-P` flags set that. With its default parameters (434 clocks per bit) it reports failures.

Waveforms are written to `uart_tx.vcd` and `uart.vcd` in the current directory: `gtkwave uart.vcd`.

## Tests

- `tb_uart_tx`: sends `0x43` and checks `tx` on every clock of the frame (start bit, 8 data bits, stop bit): 160 checks
- `tb_uart`: connects `uart_tx` to `uart_rx`, sends `0x41`, checks the received byte, and counts any `rx_frame_err` pulse as a failure

## Files

```
rtl/uart_tx.v      Transmitter
rtl/uart_rx.v      Receiver
tb/tb_uart_tx.v    Transmitter testbench
tb/tb_uart.v       TX to RX loopback testbench
```
