`timescale 1ns / 1ps
module forprop_neuron (
    input logic clk,
    input logic reset,
    input logic clear,
    input logic en,
    input logic signed [7:0] weight, // 8 bit fixedpoint (3,5)
    input logic signed [7:0] data,   // fixed point (3,5)
    output logic signed [7:0] accum  // fixed point 3,5
);

    // Perform multiplication when enabled
    always @(posedge clk) begin
        if (reset) begin
            accum <= 0;
        end
        else if (clear) begin
            accum <= 0;
        end
        else if (en) begin
            accum <= accum + ((weight * data) >> 5); // Accumulating the result
        end
    end

endmodule