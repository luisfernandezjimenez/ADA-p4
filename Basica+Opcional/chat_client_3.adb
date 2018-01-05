-- Work carried out by Luis Fernández Jiménez

with Lower_Layer_UDP;
with Ada.Strings.Unbounded;
with Ada.Text_IO;
with Ada.Exceptions;
with Ada.Command_Line;
with Chat_Messages;
with Seq_T;
with Ada.Real_Time;
with Protected_Ops;
with Client_Handler;

procedure Chat_Client_3 is
    
    package LLU renames Lower_Layer_UDP;
    package ASU renames Ada.Strings.Unbounded;
    package ACL renames Ada.Command_Line;
    package CM  renames Chat_Messages;
    package ART renames Ada.Real_Time;
    package CH  renames Client_Handler;
    
    use type CM.Message_Type;
    use type Seq_T.Seq_N_T;
    use type ART.Time;
   
    Server_EP, Client_EP_Receive, Client_EP_Handler: LLU.End_Point_Type;
    
    Buffer : aliased LLU.Buffer_Type(1024);
    Expired     : Boolean := False;
    Admit, Found: Boolean := True;

    Server_name, IP_Server, Nick, Text: ASU.Unbounded_String;
    
    Min_Delay, Max_Delay, Fault_PCT: Natural;
    
    Plazo_Retransmision: Duration;
    
    Max_Ret: Integer;
	Num_Ret: Integer := 0;
	
	Num_Seq: Seq_T.Seq_N_T := 0;
    
    Mess: CM.Message_Type := CM.Init;
    
    Mess_ID   : CH.Identifier;
    Mess_Value: CH.Value;
    
    Ret_Time: ART.Time;
    
    Usage_Error, Expired_Error, Porcent_Error, Delay_Error, Admit_Error: exception;
    
begin
    
    if ACL.Argument_Count /= 6 then
        
        raise Usage_Error;
    
    elsif Natural'Value(ACL.Argument(ACL.Argument_Count)) < 0 or else 
          Natural'Value(ACL.Argument(ACL.Argument_Count)) > 100 then
        
        raise Porcent_Error;
    
    elsif Natural'Value(ACL.Argument(5)) < Natural'Value(ACL.Argument(4)) then
        
        raise Delay_Error;
        
    end if;    
    -- Construir el End_Point en el que está atado el servidor
    Server_Name := ASU.To_Unbounded_String(ACL.Argument(1));
    IP_Server   := ASU.To_Unbounded_String(LLU.To_IP(ASU.To_String(Server_Name)));
    Server_EP   := LLU.Build(ASU.To_String(IP_Server), Integer'Value(ACL.Argument(2)));
    Nick        := ASU.To_Unbounded_String(ACL.Argument(3));
    
    Min_Delay           := Natural'Value(ACL.Argument(4));
	Max_Delay           := Natural'Value(ACL.Argument(5));
	Fault_PCT           := Natural'Value(ACL.Argument(6));
    -- Maximo numero de Retransmisiones y Plazo de Espera para Retransmitir
	Max_Ret             := 10 + (Fault_PCT/10)**2;
	Plazo_Retransmision := 2 * Duration(Max_Delay) / 1000;
    -- Simulacion de Pérdidas y Retardos	
	LLU.Set_Faults_Percent (Fault_PCT);
	LLU.Set_Random_Propagation_Delay (Min_Delay, Max_Delay);
    
    LLU.Bind_Any(Client_EP_Receive);
    LLU.Bind_Any(Client_EP_Handler, CH.Client'Access);
    -- INIT
    CM.Message_Type'Output(Buffer'Access, CM.Init);
    LLU.End_Point_Type'Output(Buffer'Access, Client_EP_Receive);
    LLU.End_Point_Type'Output(Buffer'Access, Client_EP_Handler);
    ASU.Unbounded_String'Output(Buffer'Access, Nick);
    
    LLU.Send(Server_EP, Buffer'Access);
    -- Si antes del Plazo de Retransmision no se recibe Welcome --> Retransmitir        
    LLU.Receive(Client_EP_Receive, Buffer'Access, Plazo_Retransmision, Expired);
        
    if Expired then
    
        while Expired and then Num_Ret < Max_Ret loop
            -- Retransmision Init
            Expired := False;
            Num_Ret := Num_Ret + 1;
            LLU.Send(Server_EP, Buffer'Access);
	        LLU.Receive(Client_EP_Receive, Buffer'Access, Plazo_Retransmision, Expired);
            
        end loop;
    
    end if;
    
    if Expired then
    
        raise Expired_Error;
        
    end if;
    
    Mess  := CM.Message_Type'Input(Buffer'Access);
    Admit := Boolean'Input(Buffer'Access);

    if not Admit then
        
        raise Admit_Error;
    
    end if;
    
    Ada.Text_IO.Put_Line(ASCII.LF & "Mini-Chat v3.0: Welcome " & ASU.To_String(Nick));
    
    while ASU.To_String(Text) /= ".quit" loop
            
        LLU.Reset(Buffer);
        
        Ada.Text_IO.Put(">> ");
        Text := ASU.To_Unbounded_String(Ada.Text_IO.Get_Line);
        -- Writer
        if ASU.To_String(Text) /= ".quit" then
            
            CM.Message_Type'Output(Buffer'Access, CM.Writer);
            LLU.End_Point_Type'Output(Buffer'Access, Client_EP_Handler);
            Seq_T.Seq_N_T'Output(Buffer'Access, Num_Seq);
            ASU.Unbounded_String'Output(Buffer'Access, Nick);
            ASU.Unbounded_String'Output(Buffer'Access, Text);
            
            LLU.Send(Server_EP, Buffer'Access);
            -- Guardar información del envío del mensaje Writer
            Mess_ID    := (Client_EP_Handler, Server_EP, Num_Seq);
            Mess_Value := (CM.Writer, Nick, Text);
            CH.Pending_Msgs.Put(CH.My_Pending_Map, Mess_ID, Mess_Value);
            -- Gestion de Retransmisiones
            Ret_Time := ART."+"(ART.Clock, ART.To_Time_Span(Plazo_Retransmision));	
            CH.RT.Put(CH.My_Retrans_Map, Ret_Time, (Client_EP_Handler, Server_EP, Num_Seq, 0));
            Protected_Ops.Program_Timer_Procedure (CH.Retransmission'Access, Ret_Time);
			Num_Seq := Num_Seq + 1;
            
        end if;
    
    end loop;
    -- Logout    
    CM.Message_Type'Output(Buffer'Access, CM.Logout);
    LLU.End_Point_Type'Output(Buffer'Access, Client_EP_Handler);
    Seq_T.Seq_N_T'Output(Buffer'Access, Num_Seq);
    ASU.Unbounded_String'Output(Buffer'Access, Nick);
    
    LLU.Send(Server_EP, Buffer'Access); 
    -- Guardar información del envío del mensaje Logout
    Mess_ID    := (Client_EP_Handler, Server_EP, Num_Seq);
    Mess_Value := (CM.Logout, Nick, Text);
    CH.Pending_Msgs.Put(CH.My_Pending_Map, Mess_ID, Mess_Value);
    -- Gestion de Retransmisiones
    Ret_Time := ART."+"(ART.Clock, ART.To_Time_Span(Plazo_Retransmision));	
    CH.RT.Put(CH.My_Retrans_Map, Ret_Time, (Client_EP_Handler, Server_EP, Num_Seq, 0));
    Protected_Ops.Program_Timer_Procedure (CH.Retransmission'Access, Ret_Time);
    
    while not CH.End_of_Program loop
        -- Esperar hasta recibir ack
        delay 0.5;
        
    end loop;
    
    LLU.Finalize;
    
exception
    
    when Usage_Error =>

        Ada.Text_IO.Put_Line(ASCII.LF & "Usage: " & ACL.Command_Name & 
        " + <dir_ip> + <port> + <nick> + <min_delay> + <max_delay> + <fault_pct>");
        LLU.Finalize;
    
    when Expired_Error =>

        Ada.Text_IO.Put_Line(ASCII.LF & "Server unreachable");
        LLU.Finalize;
    
    when Admit_Error =>

        Ada.Text_IO.Put_Line(ASCII.LF & "Mini-Chat v3.0: IGNORED new user " &
                             ASU.To_String(Nick) & ", nick already used");
        LLU.Finalize;
    
    when Constraint_Error =>

        Ada.Text_IO.Put_Line(ASCII.LF & "The port must be an integer");
        LLU.Finalize;
        
    when Porcent_Error =>

        Ada.Text_IO.Put_Line(ASCII.LF & "The percentage must be a number " &
                             "between 0 and 100");
        LLU.Finalize;
        
    when Delay_Error =>
        
        Ada.Text_IO.Put_Line(ASCII.LF & "The maximum delay must be greater " & 
                             "or equal than the minimum delay");
        LLU.Finalize;
            
    when Ex:others =>
    
        Ada.Text_IO.Put_Line(ASCII.LF & "Excepción imprevista: " &
                             Ada.Exceptions.Exception_Name(Ex) & " en: " &
                             Ada.Exceptions.Exception_Message(Ex));
        LLU.Finalize;

end Chat_Client_3;
