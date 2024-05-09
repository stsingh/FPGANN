// wip
module calculate_prediction #(
    parameter integer IMG_SIZE = 256,
    parameter integer CLASSES = 10
) (
    input logic[CLASSES-1:0][7:0] result,
    output logic [7:0] prediction
);
    logic [7:0] j;
    logic [7:0] temp;
    always_comb begin
        temp = 8'b0;
        for (j = 8'b0; j < CLASSES; j = j + 8'b00000001) begin
            if (result[j] > result[temp]) begin
                temp = j;
            end
        end
        prediction = temp;
    end

endmodule