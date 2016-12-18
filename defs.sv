`ifndef UT88_DEFS
`define UT88_DEFS

`define DEBUG
`define INDICATOR_ENABLED
//`define PC_TO_INDICATOR

// Уменьшим во столько раз скорость cpu
//`define CPU_CLK_DIV        200

// Параметры для VGA генератора 640x480@60
`define H_DISP                  640
`define H_FPORCH                24
`define H_SYNC                  40
`define H_BPORCH                128
`define V_DISP                  480
`define V_FPORCH                9
`define V_SYNC                  3
`define V_BPORCH                28



typedef bit     [255:0] kk;


`endif