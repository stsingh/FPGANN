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
        temp = result[0];
        for(int i = 1; i < CLASSES; i++) begin
            if (result[i] > temp) begin
                temp = result[i];
                j = i[7:0];
            end else begin
                temp = temp;
                j = j;
            end
        end
    end

    assign prediction = j;

endmodule