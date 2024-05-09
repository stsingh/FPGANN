`timescale 1ns / 1ps
module nn_top #(
    parameter integer IMG_SIZE = 256,
    parameter integer CLASSES = 10
) (
    input logic clk, 
    input logic rst,

    input logic train,
    input logic test,
    
    output logic [7:0] hex_seg,
    output logic [3:0] hex_grid
);

    // instantiate network
    logic start_forprop;
    logic start_backprop;
    logic train_buff;
    logic test_buff;
    logic display_onhex;
    logic [IMG_SIZE-1:0][7:0] img;
    logic [CLASSES-1:0][7:0] curr_weights;
    logic [7:0] label_val;
    logic backprop_done;
    logic forprop_done;
    logic get_weights;
    logic [CLASSES-1:0][7:0] result;
    logic [CLASSES-1:0][7:0] delta;
    logic save_weight;
    logic update;
    logic save_update;
    logic [2:0] curr_fp_state;
    logic [2:0] curr_bp_state;

    logic Reset_SH, Train_SH, Test_SH;
    logic rest_onetime, train_onetime, test_onetime;
    logic start; 
    logic [7:0] wram_addr;

    assign start = train_onetime || test_onetime;

    // control unit
    control nn_control (
        .clk(clk),
        .reset(rst_onetime), 
        .start(start),
        .train(train_onetime),
        .test(test_onetime),
        .backprop_done(backprop_done),
        .forprop_done(forprop_done),

        .train_buff(train_buff),
        .test_buff(test_buff),
        .start_backprop(start_backprop),
        .start_forprop(start_forprop),
        .display_val(display_onhex) 
    );

    // computation unit
    network neural_network (
        .clk(clk),
        .reset(rst_onetime),
        .start_backprop(start_backprop),
        .start_forprop(start_forprop),
        .train_buff(train_buff),
        .test_buff(test_buff),
        .img(img),
        .weights(curr_weights),
        .label_val(label_val),

        .forprop_done(forprop_done),
        .backprop_done(backprop_done),
        .get_weights(get_weights),
        .result(result),
        .delta(delta),
        .update(update),
        .weight_addr(wram_addr),
        .fp_state_reg(curr_fp_state),
        .bp_state_reg(curr_bp_state)
    );

    // instantiate image storage

    image_ram img_ram (
        .clk(clk), 
        .rst(rst_onetime), 
        .curr_state(curr_fp_state),

        .image(img)
    );

    // instantiate weights storage
    weights_ram w_ram (
        .clk(clk),
        .en_update(update),
        .bram_addr(wram_addr),
        .weight_deltas(delta),

        .weights(curr_weights)
    );

    // instantiate label storage
    logic [7:0] curr_label;
    labels_ram l_ram (
        .clk(clk), 
        .rst(rst_onetime), 
        .curr_state(curr_bp_state),

        .label(label_val)
    );

    // get pred
    logic[7:0] prediction;
    calculate_prediction pred (
        .result(result), 
        .prediction(prediction)
    );

    sync_debounce button_sync [2:0] (
        .Clk  (clk),

        .d    ({rst, train, test}),
        .q    ({Reset_SH, Train_SH, Test_SH})
    );

    negedge_detector rst_once ( 
		.clk	(clk), 
		.in	    (Reset_SH), 
		.out    (rst_onetime)
	);

    negedge_detector train_once ( 
		.clk	(clk), 
		.in	    (Train_SH), 
		.out    (train_onetime)
	);

    negedge_detector test_once ( 
		.clk	(clk), 
		.in	    (Test_SH), 
		.out    (test_onetime)
	);

    HexDriver HexA (
        .clk        (clk),
        .reset      (rst_onetime),

        .in         ({label_val[7:4], label_val[3:0], prediction[7:4], prediction[3:0]}),
        .hex_seg    (hex_seg),
        .hex_grid   (hex_grid)
    );



endmodule