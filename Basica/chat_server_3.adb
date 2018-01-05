-- Work carried out by Luis Fernández Jiménez

with Lower_Layer_UDP;
with Ada.Strings.Unbounded;
with Ada.Text_IO;
with Ada.Exceptions;
with Ada.Command_Line;
with Server_Handler;
with Map_Treatment;

procedure Chat_Server_3 is

    package LLU renames Lower_Layer_UDP;
    package ASU renames Ada.Strings.Unbounded;
    package ACL renames Ada.Command_Line;
    package SH  renames Server_Handler;
    package MT  renames Map_Treatment;
   
    Server_EP: LLU.End_Point_Type;

    Option: Character := 'a';

    Server_name, IP_Server: ASU.Unbounded_String;

    Usage_Error, Number_Clients_Error: exception;
    
begin
    
    if ACL.Argument_Count /= 2 then
        
        raise Usage_Error;
    
    elsif Natural'Value(ACL.Argument(2)) < 2 or else 
          Natural'Value(ACL.Argument(2)) > 50 then
    
        raise Number_Clients_Error;
        
    end if;
    
    Server_name := ASU.To_Unbounded_String(LLU.Get_Host_Name);
    IP_Server   := ASU.To_Unbounded_String(LLU.To_IP(ASU.To_String(Server_Name)));
    Server_EP   := LLU.Build(ASU.To_String(IP_Server), Integer'Value(ACL.Argument(1)));
   
	LLU.Bind(Server_EP, SH.Server'Access);
	
	Ada.Text_IO.Put_Line(ASCII.LF & "INTERACTIVE MENU");
    Ada.Text_IO.Put_Line("================");
	Ada.Text_IO.Put_Line("Press E or e to exit");
	Ada.Text_IO.Put_Line("Press O or o to see the list of old clients");
	Ada.Text_IO.Put_Line("Press L or l to see the list of active clients" & ASCII.LF);
    
    while Option /= 'E' and Option /= 'e' loop
		
		Ada.Text_IO.Get_Immediate(Option);
		Ada.Text_IO.Put_Line(ASCII.LF & "Your Option is: " & Option);
		
		case Option is
		    
		    when 'O' | 'o' =>
		
			    Ada.Text_IO.Put_Line("OLD CLIENTS");
			    Ada.Text_IO.Put_Line("===========");
			    MT.Print_Old_Clients;
		
		    when 'L' | 'l' =>
			
			    Ada.Text_IO.Put_Line("ACTIVE CLIENTS");
			    Ada.Text_IO.Put_Line("==============");
			    MT.Print_Active_Clients;
		
		    when 'E' | 'e' =>
			
                LLU.Finalize;
		    
		    when others =>
		        
		        Ada.Text_IO.Put_Line("Incorrect Option");
		        Ada.Text_IO.Put_Line(ASCII.LF & "INTERACTIVE MENU");
                Ada.Text_IO.Put_Line("================");
	            Ada.Text_IO.Put_Line("Press E or e to exit");
	            Ada.Text_IO.Put_Line("Press O or o to see the list of old clients");
	            Ada.Text_IO.Put_Line("Press L or l to see the list of active clients" & ASCII.LF);
		
		end case;
	
	end loop;
    
exception
   
   when Usage_Error =>

        Ada.Text_IO.Put_Line(ASCII.LF & "Usage: " & ACL.Command_Name & 
        " + <port> + <max_clients> + <min_delay> + <max_delay> + <fault_pct>");
        LLU.Finalize;
    
    when Number_Clients_Error =>
        
        Ada.Text_IO.Put_Line(ASCII.LF & "The maximum number of allowed " &
                             "clients must be understood between 2 and 50");
        LLU.Finalize;
        
    when Constraint_Error =>

        Ada.Text_IO.Put_Line(ASCII.LF & "The port must be an integer");
        LLU.Finalize;
        
    when Ex:others =>
      
        Ada.Text_IO.Put_Line(ASCII.LF & "Excepción imprevista: " &
                             Ada.Exceptions.Exception_Name(Ex) & " en: " &
                             Ada.Exceptions.Exception_Message(Ex));
        LLU.Finalize;
        
end Chat_Server_3;
