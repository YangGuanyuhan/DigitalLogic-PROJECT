
module T_Flip_Flop(
input Clk,T,Reset,
output reg Q,
output nQ

    );
    assign nQ=~Q;

  
    always @(posedge Clk)
    begin
     if(Reset)
       begin
       Q=0;
       end
       else 
       begin
    case(T)
    1'b1:Q<=~Q;
    1'b0:Q<=Q;
    endcase
    end
    end
    
endmodule
