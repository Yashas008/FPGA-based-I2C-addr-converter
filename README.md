# FPGA-based-I2C-address-translator-to-allow-a-single-device-s-I-C-address-to-be-dynamically-remapped
A fully custom I2C address translator which allows a single device, a master to communicate via a FPGA board which acts as a slave for the I2C device but as a master for the other 2 I2C devices on the same physical address.

The code is of DEBUG version and not the clean version. This means that all of the DEBUG prints used for reference such as $display are still in the code and not removed so that it will be easier to view internal behavior in waveform and console and it is mostly helpful in development.

I will also push a clean version where all the DEBUG lines are removed and can be used for final report.
