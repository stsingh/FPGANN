# FPGA Neural Network with Online Training
This project is a two-layer neural network with no hidden layers implemented on an FPGA. The operation of this design is as follows: 
1. Press a button assigned to either train or test.
2. If training is pressed and released, a full forward and backward propagation occurs on the image currently in memory (input by a .coe file to the BRAM or through other means).
3. If testing is pressed and released, only forward propagation occurs.
4. In both cases, a number representing the label of the image currently in memory is output, and the neural network's prediction for that image is output to the hex driver next to it.