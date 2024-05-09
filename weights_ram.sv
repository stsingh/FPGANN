`timescale 1ns / 1ps
`define LEARNING_RATE 8'h04
module weights_ram #(
    parameter integer IMG_SIZE = 256,
    parameter integer CLASSES = 10
) (
    input logic clk, 
    input logic en_update,
    input logic [7:0] bram_addr,
    input logic [CLASSES-1:0][7:0] weight_deltas,

    output logic [CLASSES-1:0][7:0] weights
);
    logic [79:0] new_weights;
    logic [CLASSES-1:0][7:0] parsed_weights;
    logic [79:0] curr_weights;

    weight_ram_1 wram ( // block mem instantiation
        .addra(bram_addr),
        .clka(clk),
        .dina(new_weights),
        .wea(en_update),

        .douta(curr_weights)
    );

    always_comb begin
        for(integer j = 0; j < CLASSES; j++) begin
            parsed_weights[j][7:0] = curr_weights[8*j+:8];
        end
        weights = parsed_weights;
        for(integer i = 0; i < CLASSES; i++) begin
            new_weights[8*i+:8] = curr_weights[8*i+:8] + ((`LEARNING_RATE * weight_deltas[i]) >> 5); 
        end
    end

endmodule