-- Work carried out by Luis Fernández Jiménez

package body Client_Handler is

    procedure Client (From: in LLU.End_Point_Type;
                      To:   in LLU.End_Point_Type;
                      P_Buffer: access LLU.Buffer_Type) is

        Mess: CM.Message_Type := CM.Server;
        Nick: ASU.Unbounded_String;
        Text: ASU.Unbounded_String;
    
    begin
        -- Los mensajes que se reciben son tipo Server
        Mess := CM.Message_Type'Input(P_Buffer);
        Nick := ASU.Unbounded_String'Input(P_Buffer);
        Text := ASU.Unbounded_String'Input(P_Buffer);
        
        Ada.Text_IO.Put(ASCII.LF & ASU.To_String(Nick) & ": " & 
			            ASU.To_String(Text) & ASCII.LF & ">> ");
        
        LLU.Reset(P_Buffer.all);
        
    end Client;
    
end Client_Handler;
