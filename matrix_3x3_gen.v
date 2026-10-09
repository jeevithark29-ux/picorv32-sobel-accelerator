`timescale 1ns / 1ps

module matrix_3x3_gen #(
    parameter IMG_WIDTH = 128  // Configurable: e.g. 128, 256
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       in_valid,
    input  wire [7:0] in_pixel,

    output reg        out_valid,
    // 3x3 Window: [Row][Col]
    output reg  [7:0] p00, output reg  [7:0] p01, output reg  [7:0] p02,
    output reg  [7:0] p10, output reg  [7:0] p11, output reg  [7:0] p12,
    output reg  [7:0] p20, output reg  [7:0] p21, output reg  [7:0] p22
);

    // Line buffers for previous 2 rows
    reg [7:0] line_buf0 [0:IMG_WIDTH-1];
    reg [7:0] line_buf1 [0:IMG_WIDTH-1];

    reg [$clog2(IMG_WIDTH)-1:0] col_ptr;
    reg [15:0] pixel_count;

    wire [7:0] lb0_out = line_buf0[col_ptr];
    wire [7:0] lb1_out = line_buf1[col_ptr];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            col_ptr     <= 0;
            pixel_count <= 0;
            out_valid   <= 0;
            p00 <= 0; p01 <= 0; p02 <= 0;
            p10 <= 0; p11 <= 0; p12 <= 0;
            p20 <= 0; p21 <= 0; p22 <= 0;
        end else if (in_valid) begin
            // Shift line buffers
            line_buf0[col_ptr] <= in_pixel;
            line_buf1[col_ptr] <= lb0_out;

            if (col_ptr == IMG_WIDTH - 1)
                col_ptr <= 0;
            else
                col_ptr <= col_ptr + 1;

            pixel_count <= pixel_count + 1;

            // Shift 3x3 window horizontally
            p00 <= p01;     p01 <= p02;     p02 <= lb1_out;
            p10 <= p11;     p11 <= p12;     p12 <= lb0_out;
            p20 <= p21;     p21 <= p22;     p22 <= in_pixel;

            // Valid once at least 2 full lines + 2 pixels are buffered
            if (pixel_count >= (IMG_WIDTH * 2 + 2))
                out_valid <= 1'b1;
            else
                out_valid <= 1'b0;
        end else begin
            out_valid <= 1'b0;
        end
    end
endmodule