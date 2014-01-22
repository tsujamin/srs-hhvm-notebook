-- Jan Zimmer, January 2014 --

with Ada.Command_Line;
with Ada.Text_IO;
with Ada.Integer_Text_IO;
with Ada.Containers.Vectors;
with Ada.Containers;
with Ada.Numerics.Elementary_Functions;
with Ada.Exceptions;

procedure lackey_parser is
   Custom_Constraint_Error : exception;

   File : Ada.Text_IO.File_Type; -- The input log file
   Out_File : Ada.Text_IO.File_Type;

   package Naturals_Vector is new Ada.Containers.Vectors (Index_Type   => Positive,
                                                          Element_Type => Natural);

   type Alloc_Info is record -- All the information we need about a memory block to monitor
         Active  : Boolean;
         Address : Long_Integer;
         Size    : Long_integer;
         Reads   : Naturals_Vector.Vector := Naturals_Vector.Empty_Vector;
         Writes  : Naturals_Vector.Vector := Naturals_Vector.Empty_Vector;
   end record;

   function Alloc_Info_Equal (L, R : Alloc_Info) return Boolean is begin return L.Address = R.Address; end Alloc_Info_Equal;

   package Alloc_Info_Vector is new Ada.Containers.Vectors (Index_Type   => Positive,
                                                            Element_Type => Alloc_Info,
                                                            "="          => Alloc_Info_Equal);
   Allocs : Alloc_Info_Vector.Vector := Alloc_Info_Vector.Empty_Vector;
   Alloc_Swap : Alloc_Info;
   Record_Allocs : Boolean := False; -- whether we are active or not

   function KeyWord (S : String) return String is begin -- The word before the colon, if there is a colon
      for i in S'Range loop
         if S(i) = ':' then return S(S'First .. i - 1); end if;
      end loop;
      return "";
   end KeyWord;

   function Strip_String (S : String) return String is
      Begining_Index : Positive := 1;
   begin
      for i in S'Range loop
         if S(i) /= ' ' then Begining_Index := i; exit; end if;
      end loop;
      for i in reverse Begining_Index .. S'Last loop
         if S(i) /= ' ' then return S (Begining_Index .. i); end if;
      end loop;
      return "";
   end Strip_String;

   function Strip_String_PID (S : String) return String is -- Get rid of the ==xxxxx== valgrind PID header in lines
      Equal_Sign_Count : Natural := 0;
   begin
      for i in S'Range loop
         if S(i) = '=' then
            Equal_Sign_Count := Natural'Succ (Equal_Sign_Count);
         end if;
         if Equal_Sign_Count = 4 then return S (i + 2 .. S'Last); end if;
      end loop;
      return S;
   end Strip_String_PID;

   function Get_Address (S : String) return Long_Integer is -- Get Address from HHVM lines
      Begining_Index : Positive := S'Last + 1;
   begin
      for i in S'Range loop
         if S(i) = ':' then Begining_Index := i + 1; end if;
      end loop;
      for i in Begining_Index .. S'Last loop
         if S(i) = ',' then return Long_Integer'Value (S (Begining_Index .. i - 1)); end if;
      end loop;
      case S'Last - Begining_Index < 0 is
         when False => return Long_Integer'Value (S(Begining_Index .. S'Last));
         when True => raise Program_Error with "Failed to convert in Get_Address: #" & S & '#';
      end case;
   exception
      when Constraint_Error => Ada.Text_IO.Put_Line ("Failed to parse: " & S); raise Custom_Constraint_Error;
   end Get_Address;

   function Get_Size (S : String) return Long_Integer is begin -- Get Size from HHVM lines
      for i in S'Range loop
         if S(i) = ',' then return Long_Integer'Value (S(i + 1 .. S'last)); end if;
      end loop;
      raise Program_Error with "Failed to Get_Size in: #" & S & '#';
   exception
      when Constraint_Error => Ada.Text_IO.Put_Line ("Failed to parse: " & S); raise Custom_Constraint_Error;
   end Get_Size;

   function Get_Address2 (S : String) return Long_Integer is begin -- Get Address from Valgrind lines
      for i in S'Range loop
         if S(i) = ',' then
            return Long_Integer'Value (S(S'First + 3 .. i - 1));
         end if;
      end loop;
         raise Program_Error with "Couldn't find the comma in Get_Address2: #" & S & '#';
   exception
      when Constraint_Error => Ada.Text_IO.Put_Line ("Failed to parse: " & S); raise Custom_Constraint_Error;
   end Get_Address2;

   function Get_Size2 (S : String) return Long_Integer is begin -- Get Size from Valgrind lines
      for i in S'Range loop
         if S(i) = ',' then return Long_Integer'Value (S (i + 1 .. S'Last)); end if;
      end loop;
      raise Program_Error with "Couldn't find comma in Get_Size2: #" & S & '#';
   exception
      when Constraint_Error => Ada.Text_IO.Put_Line ("Failed to parse: " & S); raise Custom_Constraint_Error;
   end Get_Size2;

   procedure Output_Alloc_Thing (C : Alloc_Info_Vector.Cursor) is -- Memory block has been freed, we can output it's information
      Not_Empty : Boolean := False;
      procedure Verify_that_not_empty (C : Naturals_Vector.Cursor) is begin
         if Naturals_Vector.Element(C) /= 0 then Not_Empty := True; end if;
      end Verify_that_not_empty;
      procedure Output_Alloc_Thing_Iterator (C : Naturals_Vector.Cursor) is begin
         Ada.Text_IO.Put(Out_File, Natural'Image(Naturals_Vector.Element(C))); Ada.Text_IO.Put (Out_File, ',');
      end Output_Alloc_Thing_Iterator;
   begin
      -- Check that the statistics have recorded at least one store or load operation.
      Naturals_Vector.Iterate (Container => Alloc_Info_Vector.Element(C).Reads,
                               Process   => Verify_that_not_empty'Access);
      Naturals_Vector.Iterate (Container => Alloc_Info_Vector.Element(C).Writes,
                               Process   => Verify_that_not_empty'Access);
      if Not_Empty then -- If they have ...
         Naturals_Vector.Iterate (Container => Alloc_Info_Vector.Element(C).Reads,
                                  Process   => Output_Alloc_Thing_Iterator'Access);
         Ada.Text_IO.New_Line (Out_File);
         Naturals_Vector.Iterate (Container => Alloc_Info_Vector.Element(C).Writes,
                                  Process   => Output_Alloc_Thing_Iterator'Access);
         Ada.Text_IO.New_Line (Out_File); Ada.Text_IO.New_Line (Out_File);
      end if;
   end Output_Alloc_Thing;

   procedure Increase_Counts (Address : Long_Integer; Size : Long_Integer; i : Integer; Writing : Boolean) is
      procedure Increase_Counts_Allocs_Editor (Element : in out Alloc_Info) is
         procedure Increase_Counts_Natural_Editor (Natural_Element : in out Natural) is begin
            Natural_Element := Natural'Succ (Natural_Element);
         end Increase_Counts_Natural_Editor;
      begin
         for i in Address - Element.Address + 1 .. Address - Element.Address + Size loop
            case Writing is
               when True  => Naturals_Vector.Update_Element (Element.Writes, Integer (i), Increase_Counts_Natural_Editor'Access);
               when False => Naturals_Vector.Update_Element (Element.Reads,  Integer (i), Increase_Counts_Natural_Editor'Access);
            end case;
         end loop;
      exception when Constraint_Error => raise Constraint_Error with "stupid bloody error" & Long_Integer'Image(Address) & Long_Integer'Image(Element.Address) &
            Long_Integer'Image(Size) & Ada.Containers.Count_Type'Image(Naturals_Vector.Length(Element.Writes));
      end Increase_Counts_Allocs_Editor;
   begin
      Alloc_Info_Vector.Update_Element (Allocs, i, Increase_Counts_Allocs_Editor'Access);
   end Increase_Counts;
begin
   case Ada.Command_Line.Argument_Count is
      when 1 => -- Make sure we get an input argument for the file we should parse
         Ada.Text_IO.Open (File => File,
                           Mode => Ada.Text_IO.In_File,
                           Name => Ada.Command_Line.Argument(1));
         Ada.Text_IO.Create (File => Out_File,
                             Mode => Ada.Text_IO.Out_File,
                             Name => (Ada.Command_Line.Argument(1) & ".proccessedcsv"));

         while not Ada.Text_IO.End_Of_File (File) loop -- start iterating through log document
            declare
               Input_Line : constant String := Strip_String_PID (Ada.Text_IO.Get_Line (File));
               Line_Key   : constant String := Strip_String (KeyWord (Input_Line));
            begin
               -- Start and stop actual recording of events
               if Input_Line    = "Start Lackey" then Record_Allocs := True; Ada.Text_IO.Put_Line("Start Lackey");
               elsif Input_Line = "Stop Lackey" then Record_Allocs := False; Ada.Text_IO.Put_Line("Stop Lackey");

               -- Listen for new things to record, or output finished recordings
               elsif Line_Key   = "Malloc" or else Line_Key = "Calloc" or else Line_Key = "Realloc" then
                  Ada.Text_IO.Put(".");
                  if Record_Allocs and then Get_Size (Input_Line) > 16 then
                     Naturals_Vector.Clear (Alloc_Swap.Reads); Naturals_Vector.Clear (Alloc_Swap.Writes);
                     Alloc_Swap := (Active  => True,
                                    Address => Get_Address (Input_line),
                                    Size    => Get_Size (Input_Line),
                                    Reads   => Naturals_Vector.Empty_Vector,
                                    Writes  => Naturals_Vector.Empty_Vector);
                     Naturals_Vector.Append (Container => Alloc_Swap.Reads,
                                             New_Item  => 0,
                                             Count     => Ada.Containers.Count_Type (Alloc_Swap.Size));
                     Naturals_Vector.Append (Container => Alloc_Swap.Writes,
                                             New_Item  => 0,
                                             Count     => Ada.Containers.Count_Type (Alloc_Swap.Size));
                     Alloc_Info_Vector.Append (Allocs, Alloc_Swap);
                  end if;
               elsif Line_Key   = "Free" then
                  Ada.Text_IO.Put (";");
                  for i in 1 .. Alloc_Info_Vector.Length (Allocs) loop
                     if Alloc_Info_Vector.Element(Container => Allocs,
                                                  Index     => Integer(i)).Address = Get_Address (Input_Line) then
                        Output_Alloc_Thing (Alloc_Info_Vector.To_Cursor(Allocs, Integer(i)));
                        Alloc_Info_Vector.Delete (Container => Allocs,
                                                  Index     => Integer(i));
                        exit;
                     end if;
                  end loop;

                  -- Write Sequence
               elsif Input_Line'Length > 2 and then Input_Line (Input_Line'First .. Input_Line'First + 1) = " S" then
                  --Ada.Text_IO.Put("+");
                  for i in 1 .. Alloc_Info_Vector.Length (Allocs) loop
                     declare
                        New_Address : Long_Integer := Get_Address2 (Input_Line);
                        Old_Address : Long_Integer := Alloc_Info_Vector.Element (Allocs, Integer (i)).Address;
                        The_Size    : Long_Integer := Alloc_Info_Vector.Element (Allocs, Integer (i)).Size;
                     begin
                        if New_Address - Old_Address < The_Size and then New_Address >= Old_Address then
                           Increase_Counts (Address => Get_Address2 (Input_Line),
                                            Size    => Get_Size2 (Input_Line),
                                            i       => Integer (i),
                                            Writing => True);
                           exit;
                        end if;
                     end;
                  end loop;

                  -- Load Sequence
               elsif Input_Line'Length > 2 and then Input_Line (Input_Line'First .. Input_Line'First + 1) = " L" then
                  --Ada.Text_IO.Put("-");
                  for i in 1 .. Alloc_Info_Vector.Length (Allocs) loop
                     declare
                        New_Address : Long_Integer := Get_Address2 (Input_Line);
                        Old_Address : Long_Integer := Alloc_Info_Vector.Element (Allocs, Integer (i)).Address;
                        The_Size    : Long_Integer := Alloc_Info_Vector.Element (Allocs, Integer (i)).Size;
                     begin
                        if The_Size < 1 then raise Program_Error with "But the size should be at least 1"; end if;
                        if New_Address - Old_Address < The_Size and then New_Address >= Old_Address then
                           Increase_Counts (Address => Get_Address2 (Input_Line),
                                            Size    => Get_Size2 (Input_Line),
                                            i       => Integer (i),
                                            Writing => False);
                           exit;
                        end if;
                     end;
                  end loop;

                  -- Modify Sequence (read and write together)
               elsif Input_Line'Length > 2 and then Input_Line (Input_Line'First .. Input_Line'First + 1) = " M" then
                  for i in 1 .. Alloc_Info_Vector.Length (Allocs) loop
                     declare
                        New_Address : Long_Integer := Get_Address2 (Input_Line);
                        Old_Address : Long_Integer := Alloc_Info_Vector.Element (Allocs, Integer (i)).Address;
                        The_Size    : Long_Integer := Alloc_Info_Vector.Element (Allocs, Integer (i)).Size;
                     begin
                        if The_Size < 1 then raise Program_Error with "But the size should be at least 1"; end if;
                        if New_Address - Old_Address < The_Size and then New_Address >= Old_Address then
                           Increase_Counts (Address => Get_Address2 (Input_Line),
                                            Size    => Get_Size2 (Input_Line),
                                            i       => Integer (i),
                                            Writing => False);
                           Increase_Counts (Address => Get_Address2 (Input_Line),
                                            Size    => Get_Size2 (Input_Line),
                                            i       => Integer (i),
                                            Writing => True);
                           exit;
                        end if;
                     end;
                  end loop;
               elsif Input_Line = "" then null;
               else Ada.Text_IO.Put_Line ("Unmatched Line: #" & Input_Line & '#');
               end if;
               exception when Custom_Constraint_Error => null;
            end;
         end loop;

         for i in 1 .. Alloc_Info_Vector.Length (Allocs) loop -- Output remaining non-freed statistics
            Output_Alloc_Thing (Alloc_Info_Vector.To_Cursor(Allocs, Integer(i)));
         end loop;
         Ada.Text_IO.Close (File);
         Ada.Text_IO.Close (Out_File);

      when others => Ada.Text_IO.Put_Line ("Needs an input file"); -- Didn't get an argument, display simple help
   end case;
end lackey_parser;
