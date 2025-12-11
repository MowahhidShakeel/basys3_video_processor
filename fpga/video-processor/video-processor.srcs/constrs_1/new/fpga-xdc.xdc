## Clock Signal
# NOTE: Ensure your top-level module input is named "clk" or "clk_100mhz". 
# If your Verilog says "input clk_100mhz", change [get_ports clk] below to [get_ports clk_100mhz]
set_property -dict { PACKAGE_PIN W5    IOSTANDARD LVCMOS33 } [get_ports clk_100mhz]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk_100mhz]

## UART RX (FPGA input from USB-UART bridge)
set_property -dict { PACKAGE_PIN B18   IOSTANDARD LVCMOS33 } [get_ports uart_rxd]

## Reset Button (BTNC - center button, active high)
set_property -dict { PACKAGE_PIN U18   IOSTANDARD LVCMOS33 } [get_ports btnC]

## LEDs (Display last received byte)
set_property -dict { PACKAGE_PIN U16   IOSTANDARD LVCMOS33 } [get_ports {led[0]}]
set_property -dict { PACKAGE_PIN E19   IOSTANDARD LVCMOS33 } [get_ports {led[1]}]
set_property -dict { PACKAGE_PIN U19   IOSTANDARD LVCMOS33 } [get_ports {led[2]}]
set_property -dict { PACKAGE_PIN V19   IOSTANDARD LVCMOS33 } [get_ports {led[3]}]
set_property -dict { PACKAGE_PIN W18   IOSTANDARD LVCMOS33 } [get_ports {led[4]}]
set_property -dict { PACKAGE_PIN U15   IOSTANDARD LVCMOS33 } [get_ports {led[5]}]
set_property -dict { PACKAGE_PIN U14   IOSTANDARD LVCMOS33 } [get_ports {led[6]}]
set_property -dict { PACKAGE_PIN V14   IOSTANDARD LVCMOS33 } [get_ports {led[7]}]

## VGA Connector (CORRECTED FOR BASYS 3)
set_property -dict { PACKAGE_PIN G19   IOSTANDARD LVCMOS33 } [get_ports {vga_red[0]}]
set_property -dict { PACKAGE_PIN H19   IOSTANDARD LVCMOS33 } [get_ports {vga_red[1]}]
set_property -dict { PACKAGE_PIN J19   IOSTANDARD LVCMOS33 } [get_ports {vga_red[2]}]
set_property -dict { PACKAGE_PIN N19   IOSTANDARD LVCMOS33 } [get_ports {vga_red[3]}]

set_property -dict { PACKAGE_PIN N18   IOSTANDARD LVCMOS33 } [get_ports {vga_blue[0]}]
set_property -dict { PACKAGE_PIN L18   IOSTANDARD LVCMOS33 } [get_ports {vga_blue[1]}]
set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS33 } [get_ports {vga_blue[2]}]
set_property -dict { PACKAGE_PIN J18   IOSTANDARD LVCMOS33 } [get_ports {vga_blue[3]}]

set_property -dict { PACKAGE_PIN J17   IOSTANDARD LVCMOS33 } [get_ports {vga_green[0]}]
set_property -dict { PACKAGE_PIN H17   IOSTANDARD LVCMOS33 } [get_ports {vga_green[1]}]
set_property -dict { PACKAGE_PIN G17   IOSTANDARD LVCMOS33 } [get_ports {vga_green[2]}]
set_property -dict { PACKAGE_PIN D17   IOSTANDARD LVCMOS33 } [get_ports {vga_green[3]}]

set_property -dict { PACKAGE_PIN P19   IOSTANDARD LVCMOS33 } [get_ports vga_hsync]
set_property -dict { PACKAGE_PIN R19   IOSTANDARD LVCMOS33 } [get_ports vga_vsync]

## Configuration options
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]