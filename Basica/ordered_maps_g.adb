-- Work carried out by Luis Fernández Jiménez

package body Ordered_Maps_G is
    
    procedure Change_Pos (M    : in out Map;
						  Count: in Natural) is
	    
	    Pos_Empty  : Natural := Count + 1;
	    Pos_Element: Natural := Count;
	    
	begin
		
	    while Pos_Element <= Max+1 and M.P_Array(Count).Full loop

            if not M.P_Array(Pos_Empty).Full then
                
                M.P_Array(Pos_Empty)        := M.P_Array(Pos_Element);
                M.P_Array(Pos_Element).Full := False;
                Pos_Empty                   := Pos_Element;
                Pos_Element                 := Pos_Element -1;
            
            else
                
                Pos_Empty   := Pos_Empty + 1;
                Pos_Element := Pos_Empty;
            
            end if;
                   
        end loop;

	end Change_Pos;
	
	procedure Change_Pos_Del (M    : in out Map;
						      Count: in Natural) is
	    
	    Pos_Empty  : Natural := Count;
	    Pos_Element: Natural := Count + 1;
	    
	begin
		    
	    while Pos_Element <= Max+1 and M.P_Array(Pos_Element).Full loop
            
            if not M.P_Array(Pos_Empty).Full then
                
                M.P_Array(Pos_Empty)        := M.P_Array(Pos_Element);
                M.P_Array(Pos_Element).Full := False;
                
                if Pos_Element < Max then 
            
                    Pos_Empty   := Pos_Element;
                    Pos_Element := Pos_Element + 1;
            
                end if;
            
            end if;
                   
        end loop;
        
	end Change_Pos_Del;
    
    procedure Get (M      : in out Map;
                   Key    : in Key_Type;
                   Value  : out Value_Type;
                   Success: out Boolean) is

        Count : Natural := Max/2;
    
    begin
        
        Success := False;
        
        while not Success loop

		    if M.P_Array(Count).Full and then M.P_Array(Count).Key = Key then

			    Value   := M.P_Array(Count).Value;
			    Success := True;
                
            elsif M.P_Array(Count).Key < Key then

                Count := Count/2;
            
            else

                Count := Count + ((Max+1 - Count)/2);
                
            end if;
	    
	    end loop;
        
    end Get;

    procedure Put (M    : in out Map;
                   Key  : in Key_Type;
                   Value: in Value_Type) is

	    Count        : Natural := Max/2;
	    Found, Finish: Boolean := False;	    
	    
    begin

        while not Found and not Finish loop
		    -- Actualizacion del Last_Connection del Cliente
		    if M.P_Array(Count).Full and then M.P_Array(Count).Key = Key then
			
			    M.P_Array(Count).Value := Value;
			    Found                  := True;
            -- Buscar posición del nuevo elemento sin llegar a los extremos
            elsif Count > 1 and Count < Max then
            
                if (M.P_Array(Count).Key < Key and not (M.P_Array(Count-1).Key < Key)) or else
                   (not (M.P_Array(Count).Key < Key) and M.P_Array(Count+1).Key < Key) then

                    if (not (M.P_Array(Count).Key < Key) and 
                    M.P_Array(Count+1).Key < Key and not M.P_Array(Count+1).Full) then
                    -- si la posicion es el siguiente al utlimo elemento de la lista y es un hueco vacio
                        Count := Count + 1;
                    
                    end if;
                 
                    Finish := True;

                elsif M.P_Array(Count).Key < Key then

                    Count := Count/2;
                
                else

                    Count := Count + ((Max+1 - Count)/2);
                    
                end if;
            -- Buscar posición del nuevo elemento en los extremos
            elsif Count = 1 then
                
                if Key < M.P_Array(Count).Key then
    
                    Count := Count + 1;
                    
                    if Key < M.P_Array(Count).Key then
                        
                        Count := Count + 1;
                        
                    end if;
                    
                end if;
                
                Finish := True;
                
            end if;
	    
	    end loop;
	    
	    if M.Length = Max then
			
	        raise Full_Map;
    
        end if;
        
        if M.P_Array(Count).Full and Count <= Max+1 then
        -- Mover sucesores para crear hueco
            Change_Pos(M, Count);
        
        end if;
        
        -- Añadir nuevo elemento
        M.P_Array(Count) := (Key, Value, True);
        M.Length         := M.Length + 1;
        Found            := True;
        
    end Put;

    procedure Delete (M      : in out Map;
                      Key    : in Key_Type;
                      Success: out Boolean) is

    Count: Natural := Max/2;
                   
    begin
        
        Success := False;

        while not Success loop

		    if M.P_Array(Count).Full and then M.P_Array(Count).Key = Key then
			    -- Eliminar elemento
			    M.P_Array(Count).Full := False;
			    M.Length              := M.Length - 1;
			    Success               := True;

			    if Count < Max and then M.P_Array(Count+1).Full then
			        -- Mantener elementos contiguos
			        Change_Pos_Del (M, Count);
                
                end if;
                
            elsif M.P_Array(Count).Key < Key then

                Count := Count/2;
            
            else

                Count := Count + ((Max+1 - Count)/2);
                
            end if;
	    
	    end loop;
    
    end Delete;
    
    function Map_Length (M: in Map) return Natural is
	
	begin
	
    	return M.Length;	
	
	end Map_Length;
    
    function First (M: in Map) return Cursor is
    
    begin
    
        return (M, 1, False);
    
    end First;
    
    procedure Next (C: in out Cursor) is
    
    begin

        if C.Element_A < Max then

            C.Element_A := C.Element_A + 1;
        
        else
        
            C.Final := True;
        
        end if;
                
    end Next;

    function Has_Element (C: in Cursor) return Boolean is
    
    begin
    
   	    return (not C.Final and C.M.P_Array(C.Element_A).Full);
        
    end Has_Element;
    
    function Element (C: in Cursor) return Element_Type is
        
    begin
        
        if not Has_Element(C) then
            
            raise No_Element;
        
        end if;
        
        return (C.M.P_Array(C.Element_A).Key, C.M.P_Array(C.Element_A).Value);
    
    end Element;
    
end Ordered_Maps_G;
