-- Work carried out by Luis Fernández Jiménez

package body Server_Handler is
	
    procedure Server (From: in LLU.End_Point_Type;
                      To:   in LLU.End_Point_Type;
                      P_Buffer: access LLU.Buffer_Type) is

        Mess: CM.Message_Type := CM.Init;
        
        Client_EP_Receive, Client_EP_Handler: LLU.End_Point_Type;
        
        Server_EP: LLU.End_Point_Type := To;
        
        Nick, Nick_Del, Text: ASU.Unbounded_String;
        
        Admit, Found, Del_Active_Client: Boolean := False;
        
        Num_Seq: Seq_T.Seq_N_T := 0;
        
        Get_Value: MT.Values;
        
        Nick_Error, Client_Error: exception;
    
    begin
        -- Simulacion de Pérdidas y Retardos	
	    LLU.Set_Faults_Percent (Fault_PCT);
	    LLU.Set_Random_Propagation_Delay (Min_Delay, Max_Delay);
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
		        
                MT.Hash_Maps.Get(MT.My_Active_Map, Nick, Get_Value, Found);
		        
		        if not Found then
                    -- Añadir cliente al Mapa de Clientes Activos
                    -- Si Del_Active_Client es True quiere decir que se ha eliminado un cliente activo (Nick_Del)
                    MT.Add_Active_Client(Nick, Client_EP_Handler, Del_Active_Client, Nick_Del);
                    MT.Last_Seq := (0, 0);
                    MT.Seq_Maps.Put(MT.My_Seq_Map, Client_EP_Handler, MT.Last_Seq);
                    if Del_Active_Client then
                    
                        LLU.Reset(P_Buffer.all);
                        -- Enviar mensaje Server a todos los clientes, incluido al cliente expulsado
                        CM.Message_Type'Output(P_Buffer, CM.Server);
                        LLU.End_Point_Type'Output(P_Buffer, Server_EP);
                        Seq_T.Seq_N_T'Output(P_Buffer, Num_Seq);
                        ASU.Unbounded_String'Output(P_Buffer, ASU.To_Unbounded_String("server")); -- nick del servidor
                        Text := Nick_Del & " banned for being idle too long"; -- nick del cliente expulado
                        ASU.Unbounded_String'Output(P_Buffer, Text);
                        -- Enviar a todos los Clientes incluido cliente eliminado --> True
                        MT.Send_To_All(Nick, ASU.To_Unbounded_String("server"), True, Server_EP, Text, P_Buffer);
                        
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
	                LLU.End_Point_Type'Output(P_Buffer, Server_EP);
                    Seq_T.Seq_N_T'Output(P_Buffer, Num_Seq);
	                ASU.Unbounded_String'Output(P_Buffer, ASU.To_Unbounded_String("server")); -- nick del servidor
	                ASU.Unbounded_String'Output(P_Buffer, Text);
			        -- Enviar a todos los clientes menos al que ha sido aceptado --> False (no envio a todos)
			        MT.Send_To_All(Nick, ASU.To_Unbounded_String("server"), False, Server_EP, Text, P_Buffer);
                
                end if;
                    
            when CM.Writer =>
            
                Client_EP_Handler := LLU.End_Point_Type'Input(P_Buffer);
                Num_Seq           := Seq_T.Seq_N_T'Input(P_Buffer);
		        Nick              := ASU.Unbounded_String'Input(P_Buffer);
		        Text              := ASU.Unbounded_String'Input(P_Buffer);
		        
		        Ada.Text_IO.Put("WRITER received from ");
		        -- Comprobar Nick
		        Found := MT.Check_Nick(Mess, Nick, Client_EP_Handler);
                
                if not Found then
                    
                    raise Client_Error;
                    
                end if;
                
                Ada.Text_IO.Put_Line(ASU.To_String(Nick) & ": " & ASU.To_String(Text));
                
                MT.Seq_Maps.Get(MT.My_Seq_Map, Client_EP_Handler, MT.Last_Seq, Found);
                
                if Num_Seq = MT.Last_Seq.Client_Seq then
                    
                    -- Actualizacion del Last_Connection
                    MT.Add_Active_Client(Nick, Client_EP_Handler, Del_Active_Client, Nick_Del);
                    MT.Last_Seq.Client_Seq := MT.Last_Seq.Client_Seq + 1;
                    MT.Seq_Maps.Put(MT.My_Seq_Map, Client_EP_Handler, MT.Last_Seq);
                    -- Enviar Ack al cliente
                    LLU.Reset(P_Buffer.all);
                    CM.Message_Type'Output(P_Buffer, CM.Ack);
                    LLU.End_Point_Type'Output(P_Buffer, Server_EP);
                    Seq_T.Seq_N_T'Output(P_Buffer, Num_Seq);
                    LLU.Send(Client_EP_Handler, P_Buffer);
                    -- Enviar al resto de clientes mensajer Server
                    LLU.Reset(P_Buffer.all);
                    CM.Message_Type'Output(P_Buffer, CM.Server);
                    LLU.End_Point_Type'Output(P_Buffer, Server_EP);
                    Seq_T.Seq_N_T'Output(P_Buffer, Num_Seq);
		            ASU.Unbounded_String'Output(P_Buffer, Nick); -- nick del cliente
		            ASU.Unbounded_String'Output(P_Buffer, Text);

				    MT.Send_To_All(Nick, Nick, False, Server_EP, Text, P_Buffer);

			    elsif Num_Seq < MT.Last_Seq.Client_Seq then
					
					LLU.Reset(P_Buffer.all);
                    CM.Message_Type'Output(P_Buffer, CM.Ack);
                    LLU.End_Point_Type'Output(P_Buffer, Server_EP);
                    Seq_T.Seq_N_T'Output(P_Buffer, Num_Seq);
					LLU.Send(Client_EP_Handler, P_Buffer);
				
				end if;
                
            when CM.Logout =>
                
                Client_EP_Handler := LLU.End_Point_Type'Input(P_Buffer);
                Num_Seq           := Seq_T.Seq_N_T'Input(P_Buffer);
		        Nick              := ASU.Unbounded_String'Input(P_Buffer);
		        
		        Ada.Text_IO.Put("LOGOUT received from ");
                
                MT.Seq_Maps.Get(MT.My_Seq_Map, Client_EP_Handler, MT.Last_Seq, Found);
                
                if Num_Seq = MT.Last_Seq.Client_Seq then
                    -- Enviar Ack al cliente
                    LLU.Reset(P_Buffer.all);
                    CM.Message_Type'Output(P_Buffer, CM.Ack);
                    LLU.End_Point_Type'Output(P_Buffer, Server_EP);
                    Seq_T.Seq_N_T'Output(P_Buffer, Num_Seq);
                    LLU.Send(Client_EP_Handler, P_Buffer);   
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
                    -- Enviar al resto de clientes mensajer Server
                    LLU.Reset(P_Buffer.all);
                    CM.Message_Type'Output(P_Buffer, CM.Server);
                    LLU.End_Point_Type'Output(P_Buffer, Server_EP);
                    Seq_T.Seq_N_T'Output(P_Buffer, Num_Seq);
		            ASU.Unbounded_String'Output(P_Buffer, ASU.To_Unbounded_String("server"));
		            Text := Nick & " leaves the chat";
		            ASU.Unbounded_String'Output(P_Buffer, Text);
		            
		            MT.Send_To_All(Nick, ASU.To_Unbounded_String("server"), True, Server_EP, Text, P_Buffer);
                    
                end if;
            
            when CM.Ack =>

			    MT.Ack(Server_EP, P_Buffer);
			
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
