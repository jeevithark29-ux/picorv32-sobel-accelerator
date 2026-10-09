`timescale 1ns / 1ps

module gaussian_blur_3x3 (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       in_valid,
    input  wire [7:0] p00, input wire [7:0] p01, input wire [7:0] p02,
    input  wire [7:0] p10, input wire [7:0] p11, input wire [7:0] p12,
    input  wire [7:0] p20, input wire [7:0] p21, input wire [7:0] p22,

    output reg        out_valid,
    output reg  [7:0] out_pixel
);

    reg [11:0] sum;
    reg        val_pipe;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum       <= 0;
            out_pixel <= 0;
            val_pipe  <= 0;
            out_valid <= 0;
        end else begin
            val_pipe  <= in_valid;
            out_valid <= val_pipe;

            if (in_valid) begin
                // Kernel multiply by shifts: 1x, 2x (<<1), 4x (<<2)
                sum <= (p00 + p02 + p20 + p22) +
                       ((p01 + p10 + p12 + p21) << 1) +
                       (p11 << 2);
            end

            if (val_pipe) begin
                // Divide by 16: >> 4
                out_pixel <= sum[11:4];
            end
        end
    end
endmodule