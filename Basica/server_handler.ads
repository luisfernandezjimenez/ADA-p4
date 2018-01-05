-- Work carried out by Luis Fernández Jiménez

with Ada.Text_IO;
with Ada.Strings.Unbounded;
with Lower_Layer_UDP;
with Ada.Exceptions;
with Chat_Messages;
with Map_Treatment;

package Server_Handler is
    
    package ASU renames Ada.Strings.Unbounded;
    package LLU renames Lower_Layer_UDP;
    package CM  renames Chat_Messages;
    package MT  renames Map_Treatment;
    
    use type ASU.Unbounded_String;
    use type LLU.End_Point_Type;
    use type CM.Message_Type;
    -- Handler para utilizar como parámetro en LLU.Bind en el servidor
    -- Este procedimiento NO debe llamarse explícitamente
    procedure Server (From    : in LLU.End_Point_Type;
                      To      : in LLU.End_Point_Type;
                      P_Buffer: access LLU.Buffer_Type);
                                    
end Server_Handler;
