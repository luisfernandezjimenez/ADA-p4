-- Work carried out by Luis Fernández Jiménez

package body Client_Handler is
    
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
		        
		        if Mess_Value.Mess = CM.Writer then
		            
					CM.Message_Type'Output(Buffer'Access, CM.Writer);
					LLU.End_Point_Type'Output(Buffer'Access, Mess_ID.EP_Source);
					Seq_T.Seq_N_T'Output(Buffer'Access, Mess_ID.Num_Seq);
					ASU.Unbounded_String'Output(Buffer'Access, Mess_Value.Nick);
					ASU.Unbounded_String'Output(Buffer'Access, Mess_Value.Text);
		            
	            elsif Mess_Value.Mess = CM.Logout then
	                
	                CM.Message_Type'Output(Buffer'Access, CM.Logout);
	                LLU.End_Point_Type'Output(Buffer'Access, Mess_ID.EP_Source);
	                Seq_T.Seq_N_T'Output(Buffer'Access, Mess_ID.Num_Seq);
	                ASU.Unbounded_String'Output(Buffer'Access, Mess_Value.Nick);
	                
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

    procedure Client (From: in LLU.End_Point_Type;
                      To:   in LLU.End_Point_Type;
                      P_Buffer: access LLU.Buffer_Type) is

        Client_EP: LLU.End_Point_Type := To;
        Server_EP: LLU.End_Point_Type;
        
        Mess: CM.Message_Type := CM.Server;
        Nick: ASU.Unbounded_String;
        Text: ASU.Unbounded_String;
        
        Num_Seq: Seq_T.Seq_N_T := 0;
        
        Mess_ID   : Identifier;
        Mess_Value: Value;
        Found     : Boolean := False;
    
    begin
    
        Mess := CM.Message_Type'Input(P_Buffer);

        if Mess = CM.Server then
            
            Server_EP := LLU.End_Point_Type'Input(P_Buffer);
			Num_Seq   := Seq_T.Seq_N_T'Input(P_Buffer);
            Nick      := ASU.Unbounded_String'Input(P_Buffer);
            Text      := ASU.Unbounded_String'Input(P_Buffer);
        
            if Num_Seq = Last_Seq then
            
				LLU.Reset(P_Buffer.all);
				CM.Message_Type'Output(P_Buffer, CM.Ack);
				LLU.End_Point_Type'Output(P_Buffer, Client_EP);
				Seq_T.Seq_N_T'Output(P_Buffer, Num_Seq);
				LLU.Send(Server_EP, P_Buffer);
                
                Ada.Text_IO.Put(ASCII.LF & ASU.To_String(Nick) & ": " & 
			                ASU.To_String(Text) & ASCII.LF & ">> ");
			                
				Last_Seq := Last_Seq + 1;
				
			elsif Num_Seq < Last_Seq then
			
				LLU.Reset(P_Buffer.all);
				CM.Message_Type'Output(P_Buffer, CM.Ack);
				LLU.End_Point_Type'Output(P_Buffer, Client_EP);
				Seq_T.Seq_N_T'Output(P_Buffer, Num_Seq);
				LLU.Send(Server_EP, P_Buffer);
			
			end if;
			
		elsif Mess = CM.Ack then
			
			Server_EP := LLU.End_Point_Type'Input(P_Buffer);
			Num_Seq   := Seq_T.Seq_N_T'Input(P_Buffer);
			Mess_ID   := (Client_EP, Server_EP, Num_Seq);
			Pending_Msgs.Get(My_Pending_Map, Mess_ID, Mess_Value, Found);
			
			if Found then
				
				Pending_Msgs.Delete(My_Pending_Map, Mess_ID, Found);
			    
			    if Mess_Value.Mess = CM.Logout then

                    End_of_Program := True;
                    
                end if;
            
			end if;

        end if;
        
    end Client;
    
end Client_Handler;
