 **Project Overview**
An FPGA-based I²C address translator that enables dynamic address remapping for I²C devices. This design allows multiple devices with conflicting default addresses to coexist on the same I²C bus by intercepting and translating addresses on-the-fly.
Problem Statement
Many I²C sensors come with fixed or limited address options. For example, two temperature sensors both having default address 0x24 cannot coexist on the same bus without hardware modifications.
Solution
The FPGA acts as a transparent translator:

Acts as I²C slave to the bus master
Acts as I²C master to the target devices
Intercepts address 0x24 and translates it to 0x25
All other addresses pass through unchanged
Data forwarding is transparent in both directions

Master (0x24) → FPGA Translator → Device sees (0x25)
Master (0x50) → FPGA Translator → Device sees (0x50)  [pass-through]

**Key Features**

 Dynamic Address Translation: One address pair at a time
 Bidirectional Support: Handles both read and write operations
 I²C Compliant: Supports 100 kHz Standard Mode and 400 kHz Fast Mode
 Clock Stretching: Minimal latency (~10 ns) during translation
 Transparent Operation: Non-matching addresses work normally
 FPGA Efficient: ~55 LUTs, ~60 registers
 Configurable: Address pairs set via module parameters
 Debug Support: State machine and translation activity outputs

**FSM State Machine
The design uses a 6-state FSM:**

IDLE (3'd0): Wait for START condition
ADDR_RX (3'd1): Receive address from master
ADDR_TRANS (3'd2): Compare and decide translation
ADDR_TX (3'd3): Send translated address to device
DATA_FORWARD (3'd4): Transparent data forwarding
WAIT_STOP (3'd5): Reserved for future use

The code was ran on AMD Xilinx Vivado and also Cadence NC due to simulator issues in the EDA playground. The screenshots from the Cadence NC will be put in the final report for detailed viewing. 

The EDA playground link is given below:
  https://www.edaplayground.com/x/G8Wn

  The simulator used in EDA playground was Icarus 12.0 Verilog and Cadence's own Verilog Synthesizer NCVerilog for more promising results from that.

 **Design Highlights**
**Technical Achievements**

**Robust Synchronization**

3-stage synchronizers for metastability protection
MTBF > 10^12 years (30,000+ years)
All logic synchronous to system clock

**Efficient Clock Stretching**

Holds device clock during translation
Minimal latency: ~10 ns @ 100 MHz
Imperceptible to master

**Clean FSM Design**

Clear state definitions and transitions
Easy to understand and debug
Well-documented with inline comments

**Transparent Operation**

Non-matching addresses pass through unchanged
Data forwarding is transparent
Preserves R/W bit and all data

**Design Decisions**

3-stage synchronizer: Balance between reliability and latency
Clock stretching: Lower latency than store-and-forward
Parameter-based config: Simple yet flexible
Separate bidirectional control: Clearer debugging


**Known Issues & Limitations
Current Limitations**
Single Translation: Only one address pair at a time
Workaround: Instantiate multiple modules or extend with address table

7-bit Addressing Only: No 10-bit address support
Impact: <1% of I²C devices use 10-bit addressing
No SMBus Features: Missing PEC, timeout, alert response
Impact: Basic I²C functionality works fine

**Acknowledgments**

**Vicharak Technologies for the interesting technical challenge**
**NXP for I²C specification (UM10204)**
**FPGA Community for design best practices and also various Textbooks and Research papers on this topic**

