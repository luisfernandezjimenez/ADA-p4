-- Work carried out by Luis Fernández Jiménez

with Ada.Text_IO;
with Ada.Strings.Unbounded;
with Lower_Layer_UDP;
with Chat_Messages;

package Client_Handler is
    
    package ASU renames Ada.Strings.Unbounded;
    package LLU renames Lower_Layer_UDP;
    package CM  renames Chat_Messages;
    
    use type LLU.End_Point_Type;
    use type CM.Message_Type;
    -- Handler para utilizar como parámetro en LLU.Bind en el cliente
    -- Muestra en pantalla la cadena de texto recibida
    -- Este procedimiento NO debe llamarse explícitamente                                
    procedure Client (From: in LLU.End_Point_Type;
                      To:   in LLU.End_Point_Type;
                      P_Buffer: access LLU.Buffer_Type);
                                    
end Client_Handler;
