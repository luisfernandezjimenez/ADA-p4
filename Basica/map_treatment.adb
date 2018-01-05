-- Work carried out by Luis Fernández Jiménez

package body Map_Treatment is
    
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
    
    procedure Send_To_All (Nick:     in ASU.Unbounded_String;
                           Send_All: in Boolean; 
                           P_Buffer: access LLU.Buffer_Type) is
        
        C_Active: Hash_Maps.Cursor := Hash_Maps.First(My_Active_Map);
    
    begin
        
        while Hash_Maps.Has_Element(C_Active) loop

	        if Send_All or else 
	           (not Send_All and Nick /= Hash_Maps.Element(C_Active).Key) then

                LLU.Send(Hash_Maps.Element(C_Active).Value.EP, P_Buffer);
	            
	        end if;

	        Hash_Maps.Next(C_Active);

        end loop;
        
    end Send_to_All;
    
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
