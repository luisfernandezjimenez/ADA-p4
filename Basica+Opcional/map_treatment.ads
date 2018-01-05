-- Work carried out by Luis Fernández Jiménez

with Ada.Text_IO;
with Ada.Strings.Unbounded;
with Ada.Strings.Maps;
with Ada.Exceptions;
with Hash_Maps_G;
with Ordered_Maps_G;
with Lower_Layer_UDP;
with Ada.Command_Line;
with Ada.Calendar;
with Gnat.Calendar.Time_IO;
with Ada.Real_Time;
with Seq_T;
with Protected_Ops;
with Retransmission_Times;
with Chat_Messages;
with Maps_G;

package Map_Treatment is
    
    package ASU renames Ada.Strings.Unbounded;
    package LLU renames Lower_Layer_UDP;
    package ACL renames Ada.Command_Line;
    package AC  renames Ada.Calendar;
    package ART renames Ada.Real_Time;
    package RT  renames Retransmission_Times;
    package CM  renames Chat_Messages;
    
    use type LLU.End_Point_Type;
    use type ASU.Unbounded_String;
    use type AC.Time;
    use type ART.Time;
    use type Seq_T.Seq_N_T;
    use type CM.Message_Type;
    
    type Values is record
        
        EP             : LLU.End_Point_Type;
        Last_Connection: AC.Time;
   
    end record;
    
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
    
    type Nums_Seq is record
		
		Client_Seq: Seq_T.Seq_N_T;
		Server_Seq: Seq_T.Seq_N_T;
	
	end record;
    -- Necesito definir el maximo de clientes activos permitidos en el server_handler
    Max_Clients: Natural := Natural'Value(ACL.Argument(2));
    
    Min_Delay: Natural := Natural'Value(ACL.Argument(3));
    Max_Delay: Natural := Natural'Value(ACL.Argument(4));
    Fault_PCT: Natural := Natural'Value(ACL.Argument(5));
    -- Establecer Maximo numero de Retransmisiones y Plazo de Espera para Retransmitir	    
    Plazo_Retransmision: Duration := 2 * Duration(Max_Delay) / 1000;
    Max_Ret            : Integer  := 10 + (Fault_PCT/10)**2;
    
    Last_Seq: Nums_Seq;
    
    type My_Hash_Range is mod 50; -- maximo de clientes posibles

    function String_Hash (S: ASU.Unbounded_String) return My_Hash_Range;
    
    function Compare (K1, K2: Identifier) return Boolean;
    
    -- Clientes Activos --> tabla Hash
    package Hash_Maps is new Hash_Maps_G(Key_Type   => ASU.Unbounded_String,
							             Value_Type => Values,
							             "="        => ASU."=",
							             Hash_Range => My_Hash_Range,
							             Hash       => String_Hash,
           						   	     Max        => Max_Clients);
   	-- Clientes Antiguos No Activos	--> array ordenado con búsqueda binaria							 
    package Ordered_Maps is new Ordered_Maps_G(Key_Type   => ASU.Unbounded_String,
               								   Value_Type => Values,
               								   "="        => ASU."=",
               								   "<"        => ASU."<",
               								   Max        => 150);

    package Pending_Msgs is new Maps_G(Key_Type   => Identifier,
						               Value_Type => Value,
									   "="        => Compare);
    
    package Seq_Maps is new Maps_G (Key_Type   => LLU.End_Point_Type,
						            Value_Type => Nums_Seq,
								    "="        => LLU."=");
									   
    My_Active_Map : Hash_Maps.Map;
    My_Old_Map    : Ordered_Maps.Map;
	My_Pending_Map: Pending_Msgs.Map;
	My_Retrans_Map: RT.Map;
	My_Seq_Map    : Seq_Maps.Map;
	
	procedure Retransmission;
    
    function Check_Nick (Mess : in CM.Message_Type;
                         Nick : in ASU.Unbounded_String;
                         EP   : in LLU.End_Point_Type) return Boolean;
    
    procedure Inactive_Client (Nick_Del : out ASU.Unbounded_String;
                               Value_Del: out Values);
                               
    procedure Inactive_Old_Client (Nick_Del : out ASU.Unbounded_String;
                                   Value_Del: out Values);
    
    procedure Add_Active_Client (Nick             : in ASU.Unbounded_String;
                                 Client_EP_Handler: in LLU.End_Point_Type;
                                 Del_Active_Client: out Boolean;
                                 Nick_Del         : out ASU.Unbounded_String);
                                
    procedure Add_Old_Client (Nick: in ASU.Unbounded_String;
                              EP  : in LLU.End_Point_Type);

    procedure Delete_Active_Client (Nick : in ASU.Unbounded_String;
                                    Found: out Boolean);

    procedure Send_To_All (Nick     : in ASU.Unbounded_String;
                           S_Nick   : in ASU.Unbounded_String;
                           Send_All : in Boolean;
                           Server_EP: in LLU.End_Point_Type;
                           Text     : in ASU.Unbounded_String;
                           P_Buffer : access LLU.Buffer_Type);

    procedure Ack (Server_EP: in LLU.End_Point_Type;
                   P_Buffer : access LLU.Buffer_Type);
                               
    function Time_Image (T: in AC.Time) return String;
    
    procedure Print_Active_Clients;
    
    procedure Print_Old_Clients;
    
end Map_Treatment;
