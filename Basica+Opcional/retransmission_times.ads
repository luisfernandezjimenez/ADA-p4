-- Work carried out by Luis Fernández Jiménez

--
--  TAD  implementada como una lista enlazada ordenada.
--

with Lower_Layer_UDP;
with Ada.Real_Time;
with Seq_T;
with Ada.Unchecked_Deallocation;

package Retransmission_Times is
	
	package LLU renames Lower_Layer_UDP;
	package ART renames Ada.Real_Time;
	package ST  renames Seq_T;
	
	use type ART.Time;
	use type Seq_T.Seq_N_T;
	
	type Map is limited private;
	
	type Identifier is record
	
		EP_Source     : LLU.End_Point_Type;
		EP_Destination: LLU.End_Point_Type;
		Num_Seq       : ST.Seq_N_T;
		Num_Ret       : Integer := 0;
	
	end record;
	
    procedure Get_First (M       : in Map;
					  	 Ret_time: out ART.Time;
						 Id_Msg  : out Identifier;
						 Found   : out Boolean);

    procedure Put (M       : in out Map;
     			   Ret_Time: in ART.Time;
                   Id_Msg  : in Identifier);
                  
    procedure Delete (M     : in out Map;
     			      Id_Msg: in Identifier;
                      Found : out Boolean);
                      
    function Map_Length (M : Map) return Natural;
   --
   -- Cursor Interface for iterating over Map elements
   --
   type Cursor is private;
   function First (M: Map) return Cursor;
   procedure Next (C: in out Cursor);
   function Has_Element (C: Cursor) return Boolean;
   type Element_Type is record
     Ret_Time: ART.Time;
     Id_Msg  : Identifier;
   end record;
   No_Element: exception;
   -- Raises No_Element if Has_Element(C) = False;
   function Element (C: Cursor) return Element_Type;
   
private
	type Cell;
	type Cell_A is access Cell;
	type Cell is record
		Ret_Time : ART.Time;
		Id_Msg   : Identifier;
		Next     : Cell_A;
	end record;
	
	type Map is record
		P_First	: Cell_A;
		Total	: Natural := 0;
	end record;
	
	type Cursor is record
		M         : Map;
		Element_A : Cell_A;
	end record;
	
end Retransmission_Times;
