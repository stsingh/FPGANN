`timescale 1ns / 1ps
module labels_ram #(
    parameter integer IMG_SIZE = 256,
    parameter integer CLASSES = 10
) (
    input logic clk, 
    input logic rst, 
    input logic [2:0] curr_state,

    output logic [7:0] label
);

    logic [8:0] label_addr;

    labels_ram_1 lram (
        .addra(label_addr),
        .clka(clk),
        .dina(8'b0),
        .wea(1'b0),

        .douta(label)
    );

    always_ff @(posedge clk) begin
        if(rst) begin
            label_addr <= 9'b111111111;
        end else begin
            if(curr_state == 3'b010) begin
                label_addr <= label_addr + 1;
            end else begin
                label_addr <= label_addr;
            end
        end
    end

    
endmodule