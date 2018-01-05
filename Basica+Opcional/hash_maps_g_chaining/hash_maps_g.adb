-- Work carried out by Luis Fernández Jiménez

package body Hash_Maps_G is
    
    procedure Free is new Ada.Unchecked_Deallocation (Cell, Cell_A);
    
    procedure Get (M      : in out Map;
                   Key    : in Key_Type;
                   Value  : out Value_Type;
                   Success: out Boolean) is

        Pos  : Hash_Range := Hash(Key); --Necesito saber el indice del array
        P_Aux: Cell_A     := M.P_Array(Pos); --Apunto al primer elemento en dicho indice
                   
    begin
        
        Success := False;
        
        while not Success and P_Aux /= Null Loop
            
            if P_Aux.all.Key = Key then
                
                Value   := P_Aux.all.Value;
                Success := True;
            
            end if;
            
            P_Aux := P_Aux.all.Next;
        
        end loop;
        
    end Get;
    
    procedure Put (M    : in out Map;
                   Key  : in Key_Type;
                   Value: in Value_Type) is

	    Pos  : Hash_Range := Hash(Key);
	    P_Aux: Cell_A     := M.P_Array(Pos);
	    Found: Boolean    := False;
	    
    begin
        
        while not Found loop
		    -- Actualizacion del Last_Connection del Cliente
		    if P_Aux /= Null and then P_Aux.all.Key = Key then
			
			    P_Aux.all.Value := Value;
			    Found           := True;
		    
		    elsif P_Aux = Null or else P_Aux.all.Next = Null then
		        
		        if M.Length = Max then
			
			        raise Full_Map;
            
                end if;
                -- Añadir Cliente a la lista
                M.P_Array(Pos) := new Cell'(Key, Value, M.P_Array(Pos));
                M.Length       := M.Length + 1;
                Found          := True;

	        elsif P_Aux.all.Next /= Null then

	            P_Aux := P_Aux.all.Next;
	            
		    end if;
	    
	    end loop;

    end Put;

    procedure Delete (M      : in out Map;
                      Key    : in Key_Type;
                      Success: out Boolean) is

        Pos        : Hash_Range := Hash(Key);
        P_Current  : Cell_A;
        P_Previous : Cell_A;
                   
    begin
        
        Success    := False;
        P_Previous := Null;
        P_Current  := M.P_Array(Pos);

        while not Success and P_Current /= Null loop
                
            if P_Current.all.Key = Key then
                
                Success := True;
                M.Length := M.Length - 1;
                
                if P_Previous /= Null then
                
                    P_Previous.all.Next := P_Current.all.Next;
                
                end if;
            
                if M.P_Array(Pos) = P_Current then
                    
                    M.P_Array(Pos) := M.P_Array(Pos).all.Next;
                
                end if;
                
                Free (P_Current);
         
            else
            
                P_Previous := P_Current;
                P_Current := P_Current.all.Next;
            
            end if;
        
        end loop;
    
    end Delete;
    
    function Map_Length (M: in Map) return Natural is
	
	begin
	
    	return M.Length;	
	
	end Map_Length;
    
    function First (M: in Map) return Cursor is
        
        Pos  : Hash_Range := Hash_Range'First;
        Final: Boolean    := False;
    
    begin
        
        While M.P_Array(Pos) = Null and not Final loop
            
            if Pos = Hash_Range'Last then

                Pos   := Hash_Range'First;
                Final := True;
            
            end if;
            
            Pos := Pos + 1;
        
        end loop;

        return (M, Pos, Final);
    
    end First;
    
    procedure Next (C: in out Cursor) is
        
    begin
    
        if C.M.P_Array(C.Element_A).all.Next /= Null then
            -- Recorrer los elementos de un mismo Indice del array
            C.M.P_Array(C.Element_A) := C.M.P_Array(C.Element_A).all.Next;
            
        else
            -- Buscar siguiente indice del array distinto de null
            C.Element_A := C.Element_A + 1;
            -- Volver al primer elemento --> se ha recorrido toda la lista
            if C.Element_A = Hash_Range'First then
                -- Final de la lista
                C.Final := True;
            
            end if;
            
            while not C.Final and C.M.P_Array(C.Element_A) = Null loop
                
                C.Element_A := C.Element_A + 1;
                
                if C.Element_A = Hash_Range'First then
                    -- Final de la lista
                    C.Final := True;
                
                end if;                
            
            end loop;
            
        end if;
        
    end Next;

    function Has_Element (C: in Cursor) return Boolean is
        
    begin

        return (not C.Final and C.M.P_Array(C.Element_A) /= Null);
        
    end Has_Element;
    
    function Element (C: in Cursor) return Element_Type is
        
    begin
        
        if not Has_Element(C) then
            
            raise No_Element;
        
        end if;
        
        return (C.M.P_Array(C.Element_A).Key, C.M.P_Array(C.Element_A).Value);
    
    end Element;
    
end Hash_Maps_G;
