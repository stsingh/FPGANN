`timescale 1ns / 1ps
module image_ram #(
    parameter integer IMG_SIZE = 256,
    parameter integer CLASSES = 10
) (
    input logic clk, 
    input logic rst, 
    input logic [2:0] curr_state,

    output logic [IMG_SIZE-1:0][7:0] image
);

    logic [8:0] img_addr;
    logic [2047:0] img_data;
    integer i;
    // parse data for image
    always_comb begin
        for(i = 0; i < IMG_SIZE; i++) begin
            image[i][7:0] = img_data[8*i+:8];
        end
    end

    image_ram_1 img_mem (
        .addra(img_addr),
        .clka(clk),
        .dina(2048'b0),
        .wea(1'b0),

        .douta(img_data)
    );

    // iterate img ptr if next image is being trained on or classified
    always_ff @(posedge clk) begin
        if(rst) begin
            img_addr <= 9'b111111111;
        end else begin
            if(curr_state == 3'b001) begin
                img_addr <= img_addr + 1;
            end else begin
                img_addr <= img_addr;
            end
        end
    end

endmodule