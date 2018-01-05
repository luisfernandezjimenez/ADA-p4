-- Work carried out by Luis Fernández Jiménez

with Lower_Layer_UDP;
with Ada.Strings.Unbounded;
with Ada.Text_IO;
with Ada.Exceptions;
with Ada.Command_Line;
with Chat_Messages;
with Client_Handler;

procedure Chat_Client_3 is
    
    package LLU renames Lower_Layer_UDP;
    package ASU renames Ada.Strings.Unbounded;
    package ACL renames Ada.Command_Line;
    package CM  renames Chat_Messages;
    package CH  renames Client_Handler;
    
    use type CM.Message_Type;
   
    Server_EP, Client_EP_Receive, Client_EP_Handler: LLU.End_Point_Type;
    
    Buffer : aliased LLU.Buffer_Type(1024);
    Expired: Boolean := False;
    Admit  : Boolean := True;

    Server_name, IP_Server, Nick, Text: ASU.Unbounded_String;
    
    Mess: CM.Message_Type := CM.Init;
    
    Usage_Error, Expired_Error, Admit_Error: exception;
    
begin
    
    if ACL.Argument_Count /= 3 then
        
        raise Usage_Error;
    
    end if; 
-- Construye el End_Point en el que está atado el servidor
    Server_Name := ASU.To_Unbounded_String(ACL.Argument(1));
    IP_Server   := ASU.To_Unbounded_String(LLU.To_IP(ASU.To_String(Server_Name)));
    Server_EP   := LLU.Build(ASU.To_String(IP_Server), Integer'Value(ACL.Argument(2)));
    Nick        := ASU.To_Unbounded_String(ACL.Argument(3));
    
    LLU.Bind_Any(Client_EP_Receive);
    LLU.Bind_Any(Client_EP_Handler, CH.Client'Access);
-- Rellenar buffer con mensaje INIT y enviar al servidor
    CM.Message_Type'Output(Buffer'Access, CM.Init);
    LLU.End_Point_Type'Output(Buffer'Access, Client_EP_Receive);
    LLU.End_Point_Type'Output(Buffer'Access, Client_EP_Handler);
    ASU.Unbounded_String'Output(Buffer'Access, Nick);
    
    LLU.Send(Server_EP, Buffer'Access);

    LLU.Receive(Client_EP_Receive, Buffer'Access, 10.0, Expired);
    
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
-- Rellenar buffer con mensaje Writer y enviar al servidor
        if ASU.To_String(Text) /= ".quit" then
            
            CM.Message_Type'Output(Buffer'Access, CM.Writer);
            LLU.End_Point_Type'Output(Buffer'Access, Client_EP_Handler);
            ASU.Unbounded_String'Output(Buffer'Access, Nick);
            ASU.Unbounded_String'Output(Buffer'Access, Text);
            
            LLU.Send(Server_EP, Buffer'Access);
            
        end if;
    
    end loop;
-- Rellenar buffer con mensaje Logout y enviar al servidor    
    CM.Message_Type'Output(Buffer'Access, CM.Logout);
    LLU.End_Point_Type'Output(Buffer'Access, Client_EP_Handler);
    --Seq_T.Seq_N_T'Output(Buffer'Access, Num_Seq);
    ASU.Unbounded_String'Output(Buffer'Access, Nick);
    
    LLU.Send(Server_EP, Buffer'Access);
    
    LLU.Finalize;

exception
    
    when Usage_Error =>

        Ada.Text_IO.Put_Line(ASCII.LF & "Usage: " & ACL.Command_Name & 
                             " + <dir_ip> + <port> + <nick>");
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
            
    when Ex:others =>
    
        Ada.Text_IO.Put_Line(ASCII.LF & "Excepción imprevista: " &
                             Ada.Exceptions.Exception_Name(Ex) & " en: " &
                             Ada.Exceptions.Exception_Message(Ex));
        LLU.Finalize;

end Chat_Client_3;
