`timescale 1ns/ 1ps

module tb_soc_top;

    reg clk;
    reg resetn;
    reg uart_rx;
    wire uart_tx;

    // Image memories
    reg [7:0] input_img  [0:4095];
    integer out_file;
    integer pixel_idx;
    integer captured_pixels;

    // Instantiate your SoC
    soc_top uut (
        .clk    (clk),
        .resetn (resetn),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx)
    );

    // 100MHz clock (10ns period)
    always #5 clk = ~clk;

    // -------------------------------------------------------------
    // AUTOMATIC COLLECTOR: Catches every edge pixel and saves to file
    // -------------------------------------------------------------
    always @(posedge clk) begin
        if (resetn && uut.my_accel.sobel_valid) begin
            $fdisplay(out_file, "%02x", uut.my_accel.sobel_pixel);
            captured_pixels = captured_pixels + 1;

            if (captured_pixels % 500 == 0 || captured_pixels == 4096) begin
                $display("[VIVADO] Processed: %0d / 4096 pixels", captured_pixels);
            end
        end
    end

    // -------------------------------------------------------------
    // DRIVER: Feeds the 64x64 image into the Accelerator
    // -------------------------------------------------------------
    initial begin
        clk             = 0;
        resetn          = 0;
        uart_rx         = 1;
        captured_pixels = 0;

        // 1. Read input image hex
        $readmemh("input_image.hex", input_img);
        out_file = $fopen("output_image.hex", "w");

        $display("======================================================");
        $display("   HOSTEL SIMULATION: 64x64 IMAGE PROCESSING         ");
        $display("======================================================");

        // 2. Release Reset
        #100;
        @(posedge clk);
        resetn = 1;
        #50;

        // 3. Set Accelerator Threshold (0 = raw edge grayscale, 50 = binary)
        @(posedge clk);
        uut.my_accel.reg_threshold = 8'd0; // Clear visible edges!
        uut.my_accel.reg_ctrl      = 8'h01; // Enable

        $display("[VIVADO] Streaming all 4096 pixels from input_image.hex...");

        // 4. Stream 4096 pixels into the accelerator
        for (pixel_idx = 0; pixel_idx < 4096; pixel_idx = pixel_idx + 1) begin
            @(posedge clk);
            uut.my_accel.reg_pixel_in   = input_img[pixel_idx];
            uut.my_accel.in_valid_pulse = 1'b1;
            @(posedge clk);
            uut.my_accel.in_valid_pulse = 1'b0;
        end

        // 5. Flush the 3x3 line buffers
        for (pixel_idx = 0; pixel_idx < (64 * 3); pixel_idx = pixel_idx + 1) begin
            @(posedge clk);
            uut.my_accel.reg_pixel_in   = 8'd0;
            uut.my_accel.in_valid_pulse = 1'b1;
            @(posedge clk);
            uut.my_accel.in_valid_pulse = 1'b0;
        end

        #500;
        $fclose(out_file);
        $display("======================================================");
        $display("[SUCCESS] All 4096 edge pixels saved to output_image.hex!");
        $display("======================================================");
        $finish;
    end

endmodule