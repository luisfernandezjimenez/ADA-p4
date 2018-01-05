-- Work carried out by Luis Fernández Jiménez

package body Server_Handler is
    
    procedure Server (From: in LLU.End_Point_Type;
                      To:   in LLU.End_Point_Type;
                      P_Buffer: access LLU.Buffer_Type) is

        Mess: CM.Message_Type := CM.Init;
        
        Client_EP_Receive, Client_EP_Handler: LLU.End_Point_Type;
        
        Nick, Nick_Del, Text: ASU.Unbounded_String;
        
        Admit, Found, Del_Active_Client: Boolean := False;
        
        Nick_Error, Client_Error: exception;
    
    begin       
        -- Ver tipo de mensaje que se recibe
        Mess := CM.Message_Type'Input(P_Buffer);
        
        case Mess is
        
            when CM.Init =>
                -- Extraer lo que tiene el buffer
		        Client_EP_Receive := LLU.End_Point_Type'Input(P_Buffer);
		        Client_EP_Handler := LLU.End_Point_Type'Input(P_Buffer);
		        Nick := ASU.Unbounded_String'Input(P_Buffer);

		        Ada.Text_IO.Put("INIT received from " & ASU.To_String(Nick));
		        -- Comprobar Nick y EP
		        Admit := MT.Check_Nick(Mess, Nick, Client_EP_Handler);
		        
		        LLU.Reset(P_Buffer.all);             

                if not Admit then
                    -- Cliente Rechazado
                    raise Nick_Error;
                
                end if;  
                -- Cliente Aceptado --> Envio mensaje Welcome al cliente
		        CM.Message_Type'Output(P_Buffer, CM.Welcome);
		        Boolean'Output(P_Buffer, Admit);
		        LLU.Send(Client_EP_Receive, P_Buffer);

		        Ada.Text_IO.Put_Line(": ACCEPTED");
		        
                -- Añadir cliente al Mapa de Clientes Activos
                -- Si Del_Active_Client es True quiere decir que se ha eliminado un cliente activo (Nick_Del)
                MT.Add_Active_Client(Nick, Client_EP_Handler, Del_Active_Client, Nick_Del);
                
                if Del_Active_Client then
                
                    LLU.Reset(P_Buffer.all);
                    -- Enviar mensaje Server a todos los clientes, incluido al cliente expulsado
                    CM.Message_Type'Output(P_Buffer, CM.Server);
                    ASU.Unbounded_String'Output(P_Buffer, ASU.To_Unbounded_String("server")); -- nick del servidor
                    Text := Nick_Del & " banned for being idle too long"; -- nick del cliente expulado
                    ASU.Unbounded_String'Output(P_Buffer, Text);
                    -- Enviar a todos los Clientes incluido cliente eliminado --> True
                    MT.Send_To_All(Nick, True, P_Buffer);
                    
                    -- Borrar cliente del Mapa de Clientes Activos para crear hueco
                    MT.Delete_Active_Client(NicK_Del, Found);
                    
                    if Found then
                        -- Añadir Cliente Nuevo al Mapa de Clientes Activos
                        MT.Add_Active_Client(Nick, Client_EP_Handler, Del_Active_Client, Nick_Del);
                    
                    end if;

                end if;
                				    
			    LLU.Reset(P_Buffer.all);
	            Text := Nick & " joins the chat";
	            CM.Message_Type'Output(P_Buffer, CM.Server);
	            ASU.Unbounded_String'Output(P_Buffer, ASU.To_Unbounded_String("server")); -- nick del servidor
	            ASU.Unbounded_String'Output(P_Buffer, Text);
			    -- Enviar a todos los clientes menos al que ha sido aceptado --> False (no envio a todos)
			    MT.Send_To_All(Nick, False, P_Buffer);
                    
            when CM.Writer =>
            
                Client_EP_Handler := LLU.End_Point_Type'Input(P_Buffer);
		        Nick              := ASU.Unbounded_String'Input(P_Buffer);
		        Text              := ASU.Unbounded_String'Input(P_Buffer);
		        
		        Ada.Text_IO.Put("WRITER received from ");
		        -- Comprobar Nick
		        Found := MT.Check_Nick(Mess, Nick, Client_EP_Handler);
                
                if not Found then
                    
                    raise Client_Error;
                    
                end if;
                
                Ada.Text_IO.Put_Line(ASU.To_String(Nick) & ": " & ASU.To_String(Text));
                -- Actualizacion del Last_Connection
                MT.Add_Active_Client(Nick, Client_EP_Handler, Del_Active_Client, Nick_Del);
                
                LLU.Reset(P_Buffer.all);
                CM.Message_Type'Output(P_Buffer, CM.Server);
		        ASU.Unbounded_String'Output(P_Buffer, Nick); -- nick del cliente
		        ASU.Unbounded_String'Output(P_Buffer, Text);
		        -- Enviar a todos los clientes menos al que lo ha enviado --> False (no envío a todos)
				MT.Send_To_All(Nick, False, P_Buffer);
                
            when CM.Logout =>
                
                Client_EP_Handler := LLU.End_Point_Type'Input(P_Buffer);
		        Nick              := ASU.Unbounded_String'Input(P_Buffer);
		        
		        Ada.Text_IO.Put("LOGOUT received from ");
		        -- Comprobar Nick
		        Found := MT.Check_Nick(Mess, Nick, Client_EP_Handler);
                
                if not Found then
                    
                    raise Client_Error;
                    
                end if;
                
                Ada.Text_IO.Put_Line(ASU.To_String(Nick));
                -- Añadir cliente del Mapa de Clientes Viejos
                MT.Add_Old_Client(Nick, Client_EP_Handler);
                -- Borrar cliente del Mapa de Clientes Activos
                MT.Delete_Active_Client(NicK, Found);
                
                if Found then
                
                    Text := Nick & " leaves the chat";
                    LLU.Reset(P_Buffer.all);
                    CM.Message_Type'Output(P_Buffer, CM.Server);
		            ASU.Unbounded_String'Output(P_Buffer, ASU.To_Unbounded_String("server")); -- nick del servidor
		            ASU.Unbounded_String'Output(P_Buffer, Text);
		            
		            MT.Send_To_All(Nick, True, P_Buffer);
                    
                end if;
            
            when CM.Welcome | CM.Server =>
                -- Estos mensajes los manda el servidor nunca los recibe
                null; 

        end case;
    
    exception
   
        when Nick_Error =>
            --Envio mensaje Welcome al cliente
		    CM.Message_Type'Output(P_Buffer, CM.Welcome);
		    Boolean'Output(P_Buffer, Admit); -- Admit ya esta a False
		    LLU.Send(Client_EP_Receive, P_Buffer);
            Ada.Text_IO.Put_Line(": IGNORED, nick already used");
            
        when Client_Error =>
            
            Ada.Text_IO.Put_Line("unknown client. IGNORED");
             
    end Server;
    
end Server_Handler;
