-- Work carried out by Luis Fernández Jiménez

package body Hash_Maps_G is
        
    procedure Change_Pos (M    : in out Map;
						  E_Pos: in Hash_Range;
						  D_Pos: in Hash_Range) is
		Key_Aux   : Key_Type;
		Value_Aux : Value_Type;
		Status_Aux: Status_Cell;
	
	begin
		-- Almacenar en estas variables contenido del elemento
		Key_Aux := M.P_Array(E_Pos).Key;
		Value_Aux := M.P_Array(E_Pos).Value;
		Status_Aux := M.P_Array(E_Pos).Status;
		-- Colocar elemento donde estaba marcar de borrado
		M.P_Array(E_Pos).Key := M.P_Array(D_Pos).Key;
		M.P_Array(E_Pos).Value := M.P_Array(D_Pos).Value;
		M.P_Array(E_Pos).Status := M.P_Array(D_Pos).Status;
		-- Pasar marca de borrado a donde estaba elemento
		M.P_Array(D_Pos).Key := Key_Aux;
		M.P_Array(D_Pos).Value := Value_Aux;
		M.P_Array(D_Pos).Status := Status_Aux;
	
	end Change_Pos;
    
    procedure Get (M      : in out Map;
                   Key    : in Key_Type;
                   Value  : out Value_Type;
                   Success: out Boolean) is

        Pos   : Hash_Range := Hash(Key); --Necesito saber el indice del array
        D_Pos : Hash_Range; -- Almacenar posicion de marca delete
        D_Mark: Boolean    := False; -- Indica si ya tengo una posicion de borrado guardada
                   
    begin
        
        Success := False;

        while not Success and M.P_Array(Pos).Status /= Empty loop
            
            if M.P_Array(Pos).Status = Full and then M.P_Array(Pos).Key = Key then
            
            Value := M.P_Array(Pos).Value;
			Success := True;
        
            else
                
                if M.P_Array(Pos).Status = Deleted and not D_Mark then
                    
                    D_Pos  := Pos;
                    D_Mark := True;
                    
                end if;
                
                Pos := Pos + 1;
            
            end if;
        
        end loop;
        
        if Success and D_Mark then
		    -- Cambio la posicion de la marca por la posicion del elemento
			Change_Pos(M, Pos, D_Pos);
		
		end if;
        
    end Get;
    
    procedure Put (M    : in out Map;
                   Key  : in Key_Type;
                   Value: in Value_Type) is

	    Pos     : Hash_Range := Hash(Key);
	    D_Pos   : Hash_Range;
	    Found   : Boolean    := False;
	    D_Mark  : Boolean    := False;
	    
    begin
        
        while not Found loop
		    -- Actualizacion del Last_Connection del Cliente
		    if M.P_Array(Pos).Status = Full and then M.P_Array(Pos).Key = Key then
			
			    M.P_Array(Pos).Value := Value;
			    Found                := True;
		    
		    else
		            
	            if M.Length = Max then
			
                    raise Full_Map;
                    
	            end if;
	            
	            if M.P_Array(Pos).Status = Empty and not D_Mark then
                    -- Añadir Cliente a la lista
                    M.P_Array(Pos) := (Key, Value, Full);
                    M.Length := M.Length + 1;
                    Found    := True;
                
                else
	            
	                if M.P_Array(Pos).Status = Deleted and not D_Mark then
                        -- Guardamos posicion con marca de borrado
                        D_Pos  := Pos;
                        D_Mark := True;
                    
                    elsif M.P_Array(Pos).Status = Empty and D_Mark then
                        -- Añadir Cliente a la lista en la posicion de la marca de borrado
                        M.P_Array(D_Pos) := (Key, Value, Full);
                        M.Length := M.Length + 1;
                        Found    := True;
                    
                    end if;
                    
                    Pos := Pos + 1;
                    
                end if;

            end if;
	    
	    end loop;
        
    end Put;

    procedure Delete (M      : in out Map;
                      Key    : in Key_Type;
                      Success: out Boolean) is

        Pos: Hash_Range := Hash(Key);
                   
    begin
        
        Success := False;
        
        while not Success and M.P_Array(Pos).Status /= Empty loop
                
            if M.P_Array(Pos).Key = Key then
                
                Success               := True;
                M.Length              := M.Length - 1;
                M.P_Array(Pos).Status := Deleted;
         
            else
            
                Pos := Pos + 1;
            
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
            
        While M.P_Array(Pos).Status /= Full and not Final loop
            
            if Pos = Hash_Range'Last then

                Pos   := Hash_Range'First;
                Final := True;
            
            else 
    
                Pos := Pos + 1;
            
            end if;
                        
        end loop;

        return (M, Pos, Final);
    
    end First;
    
    procedure Next (C: in out Cursor) is
    
    begin
        
        C.Element_A := C.Element_A + 1;
           
        if C.Element_A = Hash_Range'First then
        -- Se ha recorrido toda la lista
            C.Final := True;
            
        end if;
        
        While not C.Final and C.M.P_Array(C.Element_A).Status /= Full loop
            
            C.Element_A := C.Element_A + 1;
            
            if C.Element_A = Hash_Range'First then
                -- Se ha recorrido toda la lista
                C.Final := True;
            
            end if;
            
        end loop;
        
    end Next;

    function Has_Element (C: in Cursor) return Boolean is
        
    begin
        
        return (not C.Final and C.M.P_Array(C.Element_A).Status = Full);
        
    end Has_Element;
    
    function Element (C: in Cursor) return Element_Type is
        
    begin
        
        if not Has_Element(C) then
            
            raise No_Element;
        
        end if;
        
        return (C.M.P_Array(C.Element_A).Key, C.M.P_Array(C.Element_A).Value);
    
    end Element;
    
end Hash_Maps_G;
