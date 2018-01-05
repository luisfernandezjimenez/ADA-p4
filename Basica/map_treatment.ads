-- Work carried out by Luis Fernández Jiménez

with Ada.Text_IO;
with Ada.Strings.Unbounded;
with Ada.Strings.Maps;
with Ada.Exceptions;
with Hash_Maps_G;
with Ordered_Maps_G;
with Lower_Layer_UDP;
with Ada.Command_Line;
with Chat_Messages;
with Ada.Calendar;
with Gnat.Calendar.Time_IO;

package Map_Treatment is
    
    package ASU renames Ada.Strings.Unbounded;
    package LLU renames Lower_Layer_UDP;
    package ACL renames Ada.Command_Line;
    package CM  renames Chat_Messages;
    package AC  renames Ada.Calendar;
    
    use type LLU.End_Point_Type;
    use type ASU.Unbounded_String;
    use type CM.Message_Type;
    use type AC.Time;
    
    type Values is record
        
        EP             : LLU.End_Point_Type;
        Last_Connection: AC.Time;
   
    end record;
    -- Necesito definir el maximo de clientes activos permitidos en el server_handler
    Max_Clients: Natural := Natural'Value(ACL.Argument(2));
    
    type My_Hash_Range is mod 50; -- maximo de clientes posibles

    function String_Hash (S: ASU.Unbounded_String) return My_Hash_Range;
    
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
    
    My_Active_Map: Hash_Maps.Map;
    My_Old_Map   : Ordered_Maps.Map;
    
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

    procedure Send_To_All (Nick:     in ASU.Unbounded_String;
                           Send_All: in Boolean; 
                           P_Buffer: access LLU.Buffer_Type);

    function Time_Image (T: in AC.Time) return String;
    
    procedure Print_Active_Clients;
    
    procedure Print_Old_Clients;
    
end Map_Treatment;
