with Ada.Real_Time;

--
--  Calls to any Procedure_A, either through a timer handler programmed
--  through Program_Timer_Procedure or through calls to Protected_Call,
--  are executed in mutual exclusion.
--

package Protected_Ops is

   type Procedure_A is access procedure;

   procedure Program_Timer_Procedure (H: Procedure_A; T: Ada.Real_Time.Time);
   -- Programs H to be executed at time T. When H.all is called, it
   --  will be executed in mutual exclusion with calls executed
   --  through Protected_Call


   procedure Protected_Call (H: Procedure_A);
   -- Calls H.all in mutual exclusion with other calls made through
   --  Protected_Call and with calls to a handler programmed with
   --  Program_Timer_Procedure


end Protected_Ops;
