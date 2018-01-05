-- Work carried out by Luis Fernández Jiménez

with Ada.Text_IO;
with Ada.Strings.Unbounded;
with Lower_Layer_UDP;
with Maps_G;
with Retransmission_Times;
with Ada.Real_Time;
with Chat_Messages;
with Ada.Command_Line;
with Seq_T;
with Protected_Ops;

package Client_Handler is
    
    package ASU renames Ada.Strings.Unbounded;
    package LLU renames Lower_Layer_UDP;
    package RT  renames Retransmission_Times;
    package ART renames Ada.Real_Time;
    package CM  renames Chat_Messages;
    package ACL renames Ada.Command_Line;
    
    use type LLU.End_Point_Type;
    use type ART.Time;
    use type CM.Message_Type;
    use type Seq_T.Seq_N_T;
       
    type Identifier is record
    
        EP_Source     : LLU.End_Point_Type;
        EP_Destination: LLU.End_Point_Type;
        Num_Seq       : Seq_T.Seq_N_T;
        
    end record;
    
    type Value is record
    
        Mess: CM.Message_Type;
        Nick: ASU.Unbounded_String;
        Text: ASU.Unbounded_String;
        
    end record;
    
    Plazo_Retransmision: Duration := 2 * Duration(Natural'Value(ACL.Argument(5))) / 1000;
	Max_Ret            : Integer  := 10 + ((Natural'Value(ACL.Argument(6)))/10)**2;
	
	Last_Seq: Seq_T.Seq_N_T := 0;
	End_of_Program: Boolean;
    
    function Compare (K1, K2: Identifier) return Boolean;
    
    procedure Retransmission;
    
    package Pending_Msgs is new Maps_G(Key_Type   => Identifier,
						               Value_Type => Value,
									   "="        => Compare);
	
	My_Pending_Map: Pending_Msgs.Map;
	My_Retrans_Map: RT.Map;	
    -- Handler para utilizar como parámetro en LLU.Bind en el cliente
    -- Muestra en pantalla la cadena de texto recibida
    -- Este procedimiento NO debe llamarse explícitamente                                
    procedure Client (From: in LLU.End_Point_Type;
                      To:   in LLU.End_Point_Type;
                      P_Buffer: access LLU.Buffer_Type);
                                    
end Client_Handler;
