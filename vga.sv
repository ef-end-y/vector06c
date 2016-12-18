module vga(
    input       clk,
    input       reset_n,
    output reg  vga_hs,
    output reg  vga_vs,
    output wire [11:0] pixel_x,
    output wire [11:0] pixel_y,
    output wire [11:0] future_x,
    output wire [11:0] future_y,
    output reg  vga_de
);

parameter A_TIME_H = 16;
parameter B_TIME_H = 96;
parameter C_TIME_H = 48;
parameter D_TIME_H = 640;
parameter TOTAL_TIME_H = A_TIME_H + B_TIME_H + C_TIME_H + D_TIME_H;
parameter BLANK_H = A_TIME_H + B_TIME_H + C_TIME_H;

parameter A_TIME_V = 10;
parameter B_TIME_V = 2;
parameter C_TIME_V = 33;
parameter D_TIME_V = 480;
parameter TOTAL_TIME_V = A_TIME_V + B_TIME_V + C_TIME_V + D_TIME_V;
parameter BLANK_V = A_TIME_V + B_TIME_V + C_TIME_V;

reg [11:0] H_Counter;
reg [11:0] V_Counter;

assign  pixel_x     = (H_Counter >= BLANK_H)        ?   H_Counter-BLANK_H   :   12'hfff ;
assign  pixel_y     = (V_Counter >= BLANK_V)        ?   V_Counter-BLANK_V   :   12'hfff ;
assign  future_x    = (H_Counter >= (BLANK_H-6))    ?   H_Counter-BLANK_H+6 :   12'hfff ;
assign  future_y    = pixel_y;


always @(posedge(clk) or negedge(reset_n))
begin
    if( !reset_n )
    begin
        H_Counter   <= 1'b0;
        vga_hs      <= 1'b1;
        V_Counter   <= 1'b0;
        vga_vs      <= 1'b1;
    end
    else
    begin
        if( H_Counter < (TOTAL_TIME_H - 1) )
            H_Counter <= H_Counter + 1'b1;
        else
            begin
                H_Counter   <= 1'b0;
                vga_de      <= 1'b0;
            end 
        if(H_Counter == (A_TIME_H - 1) )
            vga_hs <= 1'b0;
        if( H_Counter == (A_TIME_H + B_TIME_H - 1) )
            begin
                vga_hs <= 1'b1;
                if( V_Counter < (TOTAL_TIME_V-1) )
                    V_Counter <= V_Counter + 1'b1;
                else
                    V_Counter <= 1'b0;
                if( V_Counter == (A_TIME_V - 1) )
                    vga_vs <= 1'b0;
                if( V_Counter == (A_TIME_V + B_TIME_V - 1) )
                    vga_vs <= 1'b1;
            end
        if( H_Counter == BLANK_H )
            vga_de <= 1'b1;
    end
end
endmodule
