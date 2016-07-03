
-- Return the directional offset(comparable to Sin and Cos) for a given rotation
function dir_offset(rotation)
   if(rotation == 0) then
      return 1, 0;
   elseif(rotation == 1) then
      return 0, 1;
   elseif(rotation == 2) then
      return -1, 0;
   else
      return 0, -1;
   end
end

-- Copy a given object and return it, instead of the same table
function copy(self)
   local newtable = {}

   if(type(self) ~= "table") then
      return self;
   end

   for k, i in pairs(self) do
      newtable[k] = copy(i);
   end

   return newtable;
end
