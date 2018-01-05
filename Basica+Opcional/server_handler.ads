-- Work carried out by Luis Fernández Jiménez

with Ada.Text_IO;
with Ada.Strings.Unbounded;
with Lower_Layer_UDP;
with Ada.Exceptions;
with Ada.Command_Line;
with Chat_Messages;
with Seq_T;
with Map_Treatment;

package Server_Handler is
    
    package ASU renames Ada.Strings.Unbounded;
    package LLU renames Lower_Layer_UDP;
    package ACL renames Ada.Command_Line;
    package CM  renames Chat_Messages;
    package MT  renames Map_Treatment;
    
    use type ASU.Unbounded_String;
    use type LLU.End_Point_Type;
    use type CM.Message_Type;
    use type Seq_T.Seq_N_T;
	
    Min_Delay: Natural := Natural'Value(ACL.Argument(3));
    Max_Delay: Natural := Natural'Value(ACL.Argument(4));
    Fault_PCT: Natural := Natural'Value(ACL.Argument(5));
    -- Establecer Maximo numero de Retransmisiones y Plazo de Espera para Retransmitir	    
    Plazo_Retransmision: Duration := 2 * Duration(Max_Delay) / 1000;
    Max_Ret            : Integer  := 10 + (Fault_PCT/10)**2;
    Num_Ret            : Integer  := 0;
    -- Handler para utilizar como parámetro en LLU.Bind en el servidor
    -- Este procedimiento NO debe llamarse explícitamente
    procedure Server (From    : in LLU.End_Point_Type;
                      To      : in LLU.End_Point_Type;
                      P_Buffer: access LLU.Buffer_Type);
                                    
end Server_Handler;
