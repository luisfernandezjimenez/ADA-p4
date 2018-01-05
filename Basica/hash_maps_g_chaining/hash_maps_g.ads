-- Work carried out by Luis Fernández Jiménez

--
--  TAD genérico de una tabla de símbolos (map) implementada como una
--  tabla hash con resolución de colisiones mediante encadenamiento.
--

with Ada.Unchecked_Deallocation;

generic
    
    type Key_Type   is private;
    type Value_Type is private;
    with function "=" (K1, K2: Key_Type) return Boolean;
    type Hash_Range is mod <>;
    with function Hash (K: Key_Type) return Hash_Range;
    Max: in Natural;

package Hash_Maps_G is

    type Map is limited private;
    
    Full_Map: exception;

    procedure Get (M      : in out Map;
                   Key    : in Key_Type;
                   Value  : out Value_Type;
                   Success: out Boolean);

    procedure Put (M    : in out Map;
                   Key  : in Key_Type;
                   Value: in Value_Type);

    procedure Delete (M      : in out Map;
                      Key    : in Key_Type;
                      Success: out Boolean);
                      
    function Map_Length (M: in Map) return Natural;
    --
    -- Cursor Interface for iterating over Map elements
    --
    type Cursor is limited private;

    function First (M: in Map) return Cursor;

    procedure Next (C: in out Cursor);

    function Has_Element (C: in Cursor) return Boolean;

    type Element_Type is record
        Key   : Key_Type;
        Value : Value_Type;
    end record;
    
    No_Element: exception;
    -- Raises No_Element if Has_Element(C) = False;

    function Element (C: in Cursor) return Element_Type;

private
    type Cell;
    type Cell_A is access Cell;
    type Cell is record
        Key  : Key_Type;
        Value: Value_Type;
        Next : Cell_A  := Null;
    end record;
    
    type Cell_Array is array (Hash_Range) of Cell_A;

    type Map is record
        P_Array: Cell_Array;
        Length : Natural := 0;
    end record;

    type Cursor is record
        M         : Map;
        Element_A : Hash_Range := 0;
        Final     : Boolean    := False;
    end record;

    
end Hash_Maps_G;
