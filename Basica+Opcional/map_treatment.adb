-- Work carried out by Luis Fernández Jiménez

package body Map_Treatment is
    
    function Compare (K1, K2: Identifier) return Boolean is

    begin

       	return (K1.EP_Source = K2.EP_Source and then
       	        K1.EP_Destination = K2.EP_Destination and then
   			    K1.Num_Seq = K2.Num_Seq);

    end Compare;
    
    procedure Retransmission is
    
        C          : RT.Cursor := RT.First(My_Retrans_Map);
		Found      : Boolean   := False;
		RT_Time    : ART.Time; 
		RT_Value   : RT.Identifier;
		Mess_ID    : Identifier;
		Mess_Value : Value;
		Actual_Time: ART.Time := ART.Clock;
		Buffer     : aliased LLU.Buffer_Type(1024);
		
	begin
		
	    while RT.Has_Element(C) and then RT.Element(C).Ret_Time <= Actual_Time loop
			
			RT_Time  := RT.Element(C).Ret_Time;
			RT_Value := RT.Element(C).Id_Msg;
			Mess_ID  := (RT_Value.EP_Source, RT_Value.EP_Destination, RT_Value.Num_Seq);
			Pending_Msgs.Get(My_Pending_Map, Mess_ID, Mess_Value, Found);
		
		    if Found and ART."<="(RT_Time, ART.Clock) and RT_Value.Num_Ret <= Max_Ret then
		        
		        LLU.Reset(Buffer);
		        
		        if Mess_Value.Mess = CM.Server then
		            
					CM.Message_Type'Output(Buffer'Access, CM.Server);
					LLU.End_Point_Type'Output(Buffer'Access, Mess_ID.EP_Source);
					Seq_T.Seq_N_T'Output(Buffer'Access, Mess_ID.Num_Seq);
					ASU.Unbounded_String'Output(Buffer'Access, Mess_Value.Nick);
					ASU.Unbounded_String'Output(Buffer'Access, Mess_Value.Text);
	            
	            end if;
	            
	            LLU.Send(Mess_ID.EP_Destination, Buffer'Access);
				RT_Value.Num_Ret := RT_Value.Num_Ret + 1;
				RT.Delete(My_Retrans_Map, RT.Element(C).Id_Msg, Found);
				RT_Time := ART."+"(ART.Clock, ART.To_Time_Span(Plazo_Retransmision));
				RT.Put(My_Retrans_Map, RT_Time, RT_Value);
				
            else
				
				RT.Delete(My_Retrans_Map, RT.Element(C).Id_Msg, Found);
			
			end if;
			
			RT.Next(C);
			Protected_Ops.Program_Timer_Procedure (Retransmission'Access,
		                            ART.Clock + ART.To_Time_Span(Plazo_Retransmision));
        end loop;
        
    end Retransmission;
    
    function String_Hash (S: ASU.Unbounded_String) return My_Hash_Range is
        
        R: My_Hash_Range := 0;	
        	 
	begin
	    
		for I in 1..ASU.Length(S) loop
		    
		    R := R + My_Hash_Range((Character'Pos(ASU.To_String(S)(I))*I) mod Max_Clients);
		
		end loop;

		return R;
	
	end String_Hash;
	
    function Check_Nick (Mess : in CM.Message_Type;
                         Nick : in ASU.Unbounded_String;
                         EP   : in LLU.End_Point_Type) return Boolean is
        
        Get_Value   : Values;
        Admit, Found: Boolean := False;
        C_Active    : Hash_Maps.Cursor := Hash_Maps.First(My_Active_Map);
    
    begin
        -- Compruebar si esta en la lista de Clientes Activos
        Hash_Maps.Get(My_Active_Map, Nick, Get_Value, Found);
        
        if (Nick /= "server") and then 
           ((Mess = CM.Init and then (not Found or else (Found and EP = Get_Value.EP))) 
           or else (Mess /= CM.Init and then Found)) then
            
            Admit := True;
        
        else
            
            Admit := False;
        
        end if;
        
        return Admit;

    end Check_Nick;
    
    procedure Inactive_Client (Nick_Del : out ASU.Unbounded_String;
                               Value_Del: out Values) is
        
        C_Active: Hash_Maps.Cursor := Hash_Maps.First(My_Active_Map);
        
    begin
        -- Value del primer elemento del Mapa
        Value_Del := Hash_Maps.Element(C_Active).Value;
            
        while Hash_Maps.Has_Element(C_Active) loop
		    -- Si la ultima conexion del cliente apuntado por el cursor 
		    -- es antes que la ultima conexion de mi cliente guardado
		    if (Hash_Maps.Element(C_Active).Value.Last_Connection <= Value_Del.Last_Connection) then
		
			    Value_Del := Hash_Maps.Element(C_Active).Value;
			    Nick_Del  := Hash_Maps.Element(C_Active).Key;
			
		    end if;

		    Hash_Maps.Next(C_Active);

	    end loop;

    end Inactive_Client;
    
    procedure Inactive_Old_Client (Nick_Del : out ASU.Unbounded_String;
                                   Value_Del: out Values) is
        
        C_Old: Ordered_Maps.Cursor := Ordered_Maps.First(My_Old_Map);
        
    begin
        -- Value del primer elemento del Mapa
        Value_Del := Ordered_Maps.Element(C_Old).Value;
            
        while Ordered_Maps.Has_Element(C_Old) loop
		    -- Si la ultima conexion del cliente apuntado por el cursor 
		    -- es antes que la ultima conexion de mi cliente guardado
		    if (Ordered_Maps.Element(C_Old).Value.Last_Connection <= Value_Del.Last_Connection) then
		
			    Value_Del := Ordered_Maps.Element(C_Old).Value;
			    Nick_Del  := Ordered_Maps.Element(C_Old).Key;
			
		    end if;

		    Ordered_Maps.Next(C_Old);

	    end loop;
    
    end Inactive_Old_Client;
  
    procedure Add_Active_Client (Nick             : in ASU.Unbounded_String;
                                 Client_EP_Handler: in LLU.End_Point_Type;
                                 Del_Active_Client: out Boolean;
                                 Nick_Del         : out ASU.Unbounded_String) is
                                     
        Client_Value: Values;
        Value_Del   : Values;
        
    begin
        -- Creo Value con Actualizacion del Last_Time
        Client_Value := (Client_EP_Handler, AC.CLock);
        -- necesito saber si se ha eliminado cliente de la lista de clientes activos y decirselo al server_handler
        Del_Active_Client := False;
        Nick_Del          := ASU.To_Unbounded_String("unknown");
        
        Hash_Maps.Put(My_Active_Map, Nick, Client_Value);
        
    exception
        -- Se ha alcanzado el maximo de Clientes Activos permitidos
        when Hash_Maps.Full_Map =>
            
            Del_Active_Client := True;
            
            -- Buscar Cliente inactivo durante más tiempo --> Cliente que se va a eliminar
            Inactive_Client(Nick_Del, Value_Del);
            
            -- Añadir Cliente eliminado al Mapa de Clientes Viejos
            Add_Old_Client(Nick_Del, Value_Del.EP);
    
    end Add_Active_Client;
    
    procedure Add_Old_Client (Nick: in ASU.Unbounded_String;
                              EP  : in LLU.End_Point_Type) is
    
        Nick_Del : ASU.Unbounded_String;
        Value_Del: Values;
        Value    : Values;
        Found    : Boolean := False;
        
    begin
        -- Actualizo su tiempo y lo guardo en clientes viejos
        Value := (EP, AC.Clock);
        Ordered_Maps.Put(My_Old_Map, Nick, Value);

	    exception
            -- Se ha alcanzado el maximo de Clientes Viejos permitidos
            when Ordered_Maps.Full_Map =>                
                -- Encontrar Cliente Viejo mas antiguo
                Inactive_Old_Client(Nick_Del, Value_Del);

                -- Eliminar Cliente Viejo mas antiguo
                Ordered_Maps.Delete(My_Old_Map, Nick_Del, Found);
                
                if Found then
                
                    Ada.Text_IO.Put_Line("Old Client has been removed"); -- opcional
                    -- Añadir cliente eliminado al Mapa de Clientes Viejos
                    Ordered_Maps.Put(My_Old_Map, Nick, Value);
                
                end if;
        
    end Add_Old_Client;
    
    procedure Delete_Active_Client (Nick : in ASU.Unbounded_String;
                                    Found: out Boolean) is
        
    begin
        
        Hash_Maps.Delete(My_Active_Map, Nick, Found);
        
        Ada.Text_IO.Put_Line("Active Client has been removed"); -- opcional
        
    end Delete_Active_Client;
    
    procedure Send_To_All (Nick     : in ASU.Unbounded_String;
                           S_Nick   : in ASU.Unbounded_String;
                           Send_All : in Boolean;
                           Server_EP: in LLU.End_Point_Type;
                           Text     : in ASU.Unbounded_String;
                           P_Buffer : access LLU.Buffer_Type) is
        
        C_Active  : Hash_Maps.Cursor := Hash_Maps.First(My_Active_Map);
        Mess_ID   : Identifier;
        Mess_Value: Value;
        Ret_Time  : ART.Time;
        Found     : Boolean;
    
    begin
        
        while Hash_Maps.Has_Element(C_Active) loop

	        if Send_All or else 
	           (not Send_All and Nick /= Hash_Maps.Element(C_Active).Key) then
                
                LLU.Send(Hash_Maps.Element(C_Active).Value.EP, P_Buffer);
                -- Guardar información del envío
                Seq_Maps.Get(My_Seq_Map, Hash_Maps.Element(C_Active).Value.EP, Last_Seq, Found);
                Mess_ID    := (Server_EP, Hash_Maps.Element(C_Active).Value.EP, Last_Seq.Server_Seq);
                Mess_Value := (CM.Server, S_Nick, Text);
                Pending_Msgs.Put(My_Pending_Map, Mess_ID, Mess_Value);
                -- Gestion de Retransmisiones
                Ret_Time := ART."+"(ART.Clock, ART.To_Time_Span(Plazo_Retransmision));
                RT.Put(My_Retrans_Map, Ret_Time, (Server_EP, Hash_Maps.Element(C_Active).Value.EP, Last_Seq.Server_Seq, 0));
                Last_Seq.Server_Seq := Last_Seq.Server_Seq + 1;
                Seq_Maps.Put(My_Seq_Map, Hash_Maps.Element(C_Active).Value.EP, Last_Seq);
                Protected_Ops.Program_Timer_Procedure (Retransmission'Access, Ret_Time);
	            
	        end if;

	        Hash_Maps.Next(C_Active);
            
        end loop;

    end Send_to_All;
    
    procedure Ack (Server_EP: in LLU.End_Point_Type;
                   P_Buffer : access LLU.Buffer_Type) is
        
        Client_EP_Handler: LLU.End_Point_Type;
        Num_Seq          : Seq_T.Seq_N_T;
        Mess_ID          : Identifier; 
        Mess_Value       : Value;       
        Found            : Boolean := False;
        
    begin
        
        Client_EP_Handler := LLU.End_Point_Type'Input(P_Buffer);
	    Num_Seq           := Seq_T.Seq_N_T'Input(P_Buffer);
	    Mess_ID           := (Server_EP, Client_EP_Handler, Num_Seq);
	    Pending_Msgs.Get(My_Pending_Map, Mess_ID, Mess_Value, Found);
		    
	    if Found then
		
		    Pending_Msgs.Delete(My_Pending_Map, Mess_ID, Found);
	    
	    end if;
        
    end Ack;
    
    function Time_Image (T: in AC.Time) return String is

    begin

        return Gnat.Calendar.Time_IO.Image(T, "%d-%b-%y %T.%i");

    end Time_Image;

    procedure Print_Active_Clients is
        
        C_Active: Hash_Maps.Cursor := Hash_Maps.First(My_Active_Map);
        List    : ASU.Unbounded_String := ASU.To_Unbounded_String("");
        Count   : Integer := 0;
        Full_Address, IP, Port: ASU.Unbounded_String;
        
    begin
        
        if not Hash_Maps.Has_Element(C_Active) then
            
            raise Hash_Maps.No_Element;
            
        end if; 
        
		while Hash_Maps.Has_Element(C_Active) loop
-- Full_Address := LOWER_LAYER.INET.UDP.UNI.ADDRESS IP: 193.147.49.72, Port: 1025		    
		    Full_Address := ASU.To_Unbounded_String(LLU.Image(Hash_Maps.Element(C_Active).Value.EP));
		    
		    while Count /= 1 loop
                    
                Count := ASU.Index(Full_Address, Ada.Strings.Maps.To_Set(" :,"));	            
                Full_Address := ASU.Tail(Full_Address, ASU.Length(Full_Address) - Count);
            
            end loop;
-- Full_Address := 193.147.49.72, Port: 1025                
            Count := ASU.Index(Full_Address, Ada.Strings.Maps.To_Set(" :,"));
            IP := ASU.Head(Full_Address, Count - 1);
-- Full_Address :=  Port: 1025             
            Full_Address := ASU.Tail(Full_Address, ASU.Length(Full_Address) - Count);

            while Count /= 0 loop
                
                Count := ASU.Index(Full_Address, Ada.Strings.Maps.To_Set(" :,"));	            
                Full_Address := ASU.Tail(Full_Address, ASU.Length(Full_Address) - Count);
                
            end loop;
-- Full_Address := 1025
            Port := ASU.Tail(Full_Address, ASU.Length(Full_Address) - Count);
		    
            List := List & Hash_Maps.Element(C_Active).Key &
                    " (" & IP & ":" & Port & "): " & 
                    Time_Image(Hash_Maps.Element(C_Active).Value.Last_Connection) & 
                    ASCII.LF;

            Hash_Maps.Next(C_Active);
        
        end loop;

        Ada.Text_IO.Put_Line(ASU.To_String(List));
        
    exception

        when Hash_Maps.No_Element =>
            
            Ada.Text_IO.Put_Line("The Map or the List of Active Clients is empty" & ASCII.LF);
    
    end Print_Active_Clients;
    
    procedure Print_Old_Clients is
        
        C_Old : Ordered_Maps.Cursor  := Ordered_Maps.First(My_Old_Map);
        List  : ASU.Unbounded_String := ASU.To_Unbounded_String("");
        
    begin

        if not Ordered_Maps.Has_Element(C_Old) then
            
            raise Ordered_Maps.No_Element;
            
        end if;
        
		while Ordered_Maps.Has_Element(C_Old) loop
		    
            List := Ordered_Maps.Element(C_Old).Key & ": " & 
                    Time_Image(Ordered_Maps.Element(C_Old).Value.Last_Connection) &
                    ASCII.LF & List;
            
            Ordered_Maps.Next(C_Old);
        
        end loop;

        Ada.Text_IO.Put_Line(ASU.To_String(List));
    
    exception

        when Ordered_Maps.No_Element =>
            
            Ada.Text_IO.Put_Line("The Map or the List of Old Clients is empty" & ASCII.LF);
    
    end Print_Old_Clients;
        
end Map_Treatment;
