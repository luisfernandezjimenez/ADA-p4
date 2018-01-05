-- Work carried out by Luis Fernández Jiménez

package body Retransmission_Times is

    procedure Free is new Ada.Unchecked_Deallocation(Cell, Cell_A);
    
    procedure Get_First (M       : in Map;
					  	 Ret_time: out ART.Time;
						 Id_Msg  : out Identifier;
						 Found   : out Boolean) is
						    
    begin
   	    
   	    Found := False;
   	    
   	    if M.P_First /= Null then
			 
            Ret_Time := M.P_First.Ret_Time;
		    Id_Msg   := M.P_First.Id_Msg;
		    Found    := True;
		    
		end if;

    end Get_First;
	               
    procedure Put (M       : in out Map;
				   Ret_Time: in ART.Time;
                   Id_Msg  : in Identifier) is
	
	    P_Aux     : Cell_A  := M.P_First;
	    P_Prev_Aux: Cell_A;
	    Included  : Boolean := False;

    begin
    
        -- Si la Colleccion esta vacia
		if M.P_First = Null then
			
			M.P_First := new Cell' (Ret_Time, Id_Msg, Null);
			M.Total   := M.Total + 1;
        
		else
			-- Buscamos Posicion del Mensaje
			while not Included loop
			
				if ART."<="(P_Aux.Ret_Time, Ret_Time) and P_Aux.Next = Null then
					
					P_Aux.Next := new Cell' (Ret_Time, Id_Msg, Null);
					Included   := True;
					M.Total    := M.Total + 1;
				
				elsif ART."<="(P_Aux.Ret_Time, Ret_Time) then 
				
					P_Prev_Aux := P_Aux;
					P_Aux      := P_Aux.Next;
				
				else

					P_Prev_Aux.Next := new Cell'(Ret_Time, Id_Msg, P_Aux);
					Included        := True;
					M.Total         := M.Total + 1;
				
				end if;
			
			end loop;
			
		end if;  
      
    end Put;

    procedure Delete (M     : in out Map;
     			      Id_Msg: in Identifier;
                      Found : out Boolean) is
		
		P_Current : Cell_A := M.P_First;
        P_Previous: Cell_A := Null;
   
    begin
   
        Found := False;
   
        while not Found and P_Current /= Null  loop
   
            if P_Current.Id_Msg = Id_Msg then
   
                Found   := True;
                M.Total := M.Total - 1;
   
                if P_Previous /= Null then
       
                   P_Previous.Next := P_Current.Next;
       
                end if;
   
                if M.P_First = P_Current then
       
                   M.P_First := M.P_First.Next;
       
                end if;
       
                Free (P_Current);
       
            else

                P_Previous := P_Current;
                P_Current  := P_Current.Next;

            end if;
   
        end loop;

    end Delete;

    function Map_Length (M : Map) return Natural is
	
	begin
	
		return M.Total;	
	
	end Map_Length;
	
	function First (M: Map) return Cursor is
   
   begin
   
      return (M => M, Element_A => M.P_First);
   
   end First;

   procedure Next (C: in out Cursor) is
   
   begin
   
      if C.Element_A /= null Then
   
         C.Element_A := C.Element_A.Next;
   
      end if;
   
   end Next;

   function Element (C: Cursor) return Element_Type is
   
   begin
   
      if C.Element_A /= null then
   
         return (Ret_Time => C.Element_A.Ret_Time,
                 Id_Msg   => C.Element_A.Id_Msg);
   
      else
   
         raise No_Element;
   
      end if;
   
   end Element;

   function Has_Element (C: Cursor) return Boolean is
   
   begin
   
      if C.Element_A /= null then
   
         return True;
   
      else
   
         return False;
   
      end if;
   
   end Has_Element;
   
end Retransmission_Times;
