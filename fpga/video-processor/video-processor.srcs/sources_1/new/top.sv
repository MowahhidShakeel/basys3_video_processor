module top (
    input  wire       clk_100mhz,     
    input  wire       btnC,           // Reset
    input  wire       uart_rxd,

    // VGA output
    output wire [3:0] vga_red,
    output wire [3:0] vga_green,
    output wire [3:0] vga_blue,
    output wire       vga_hsync,
    output wire       vga_vsync,

    output wire [7:0] led
);

    wire rst = btnC;

// ===================================================================
    // Clock Generation
    // ===================================================================
    wire clk_pixel;   // 25.175 MHz for VGA
    wire clk_system;  // 100 MHz for UART/Logic (Buffered)
    wire locked;

    clk_wiz_0 clk_gen (
        // ERROR WAS HERE: You must connect the physical pin 'clk_100mhz'
        .clk_in1(clk_100mhz),  
        
        .reset(rst),
        
        // OUTPUTS
        .clk_out1(clk_pixel),  // 25 MHz
        .clk_out2(clk_system), // 100 MHz (Make sure you enabled this in the Wizard!)
        
        .locked(locked)
    );
    // 2. UART Receiver
    wire [7:0] uart_data;
    wire       uart_valid;
    
    uart_rx #(868) u_uart_rx (
        .clk(clk_system), 
        .rst(rst), 
        .rx(uart_rxd), 
        .dout(uart_data), 
        .valid(uart_valid)
    );

    // 3. Frame Sync Logic
    wire [7:0]  pixel_data;
    wire        pixel_valid;
    wire        frame_start_pulse;
    wire        frame_done_pulse;

    frame_sync u_frame_sync (
        .clk(clk_system), 
        .rst(rst),
        .uart_data(uart_data),
        .uart_valid(uart_valid),
        .pixel_data(pixel_data),
        .pixel_valid(pixel_valid),
        .frame_start_pulse(frame_start_pulse),
        .frame_done_pulse(frame_done_pulse),
        .pixel_x(), // disconnected if unused
        .pixel_y()  // disconnected if unused
    );

    // 4. Ping-Pong RAM (The Bridge)
    wire [16:0] vga_rd_addr;
    wire [7:0]  vga_pixel_data;

    ping_pong_ram u_ping_pong (
        .rst(rst),
        
        // Write Side (100 MHz)
        .clk_wr(clk_system),
        .frame_start_pulse(frame_start_pulse),
        .wr_pixel_valid(pixel_valid),
        .wr_pixel_data(pixel_data),
        .frame_done_pulse(frame_done_pulse),
        
        // Read Side (25 MHz)
        .clk_rd(clk_pixel),
        .rd_addr(vga_rd_addr),
        .rd_pixel(vga_pixel_data)
    );

    // 5. VGA Controller
    vga_controller_640x480 u_vga (
        .clk_pixel(clk_pixel),
        .rst(rst | ~locked), // Reset if PLL unlocks
        .hsync(vga_hsync),
        .vsync(vga_vsync),
        .red(vga_red),
        .green(vga_green),
        .blue(vga_blue),
        .frame_rd_addr(vga_rd_addr),
        .frame_rd_data(vga_pixel_data),
        // .px_x(), .px_y() // unused
        .video_active()
    );

    // Debug LEDs
    assign led[7]   = frame_start_pulse; // Flash on new frame
    assign led[6]   = frame_done_pulse;  // Flash on frame end
    assign led[5:0] = vga_pixel_data[7:2]; // Show pixel activity

endmodule