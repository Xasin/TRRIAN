require "routes"
require "utilities"

-- Initialise the map to contain only types "E"
local function init_map(self)
   for X = 1, self.map.x do
      self.map[X] = {}
      for Y = 1, self.map.y do
         self.map[X][Y] = {type = "E"}
      end
   end
end

-- Check if a given dot is still within the bounds of the map
local function in_bounds(self, pX, pY)
   return not ((pX < 1) or (pX > self.x) or (pY < 1) or (pY > self.y))
end
-- Ensure that a block is present and can be accessed
local function ensure_block(self, pX, pY)
   if(self[pX] == nil) then
      self[pX] = {};
   end

   if(self[pX][pY] == nil) then
      self[pX][pY] = {type = "E"};
   end
end
-- Set a block in the map to a type.
function set_block(self, pX, pY, type_, rotation_)
   if(not in_bounds(self, pX, pY)) then return false; end

   ensure_block(self, pX, pY);

   local newblock = {type = type_, rotation = rotation_}
   self[pX][pY] = newblock;

   return true;
end
-- Return the block at given position, or, if OOB, a "blockade" block "X"
function get_block(self, pX, pY)
   if(not in_bounds(self, pX, pY)) then
      return {type = "X"}
   end

   ensure_block(self, pX, pY)

   return self[pX][pY];
end
-- Check if a given map field is empty
function is_empty(self, pX, pY)
   return get_block(self, pX, pY).type == "E"
end
-- Return true if it makes sense to place a block at that location, false if not
function is_viable(self, pX, pY, type_, rotation_, length_)
   -- Calculate the sin and cos for the according rotatation (easier code reading)
   local dX, dY = dir_offset(rotation_);

   -- Basic checks that kinda have to be true for every block
   if(type_ == "E") then return true;
   elseif(not is_empty(self, pX, pY)) then return false;

   elseif(type_ == "belt"
      -- and is_empty(self, pX + dX, pY + dY)
      ) then return true;

   elseif(type_ == "underground_belt"
      and is_empty(self, pX + dX * length_, pY + dY * length_)
      -- and is_empty(self, pX + dX * (length_ +1), pY + dY * (length_ +1))
      ) then


      for i = 1, length_ - 1 do
         if(not is_empty(self, pX + dX * i, pY + dY * i)
            and get_block(self, pX + dX * i, pY + dY * i).type == "underground_belt"
            and get_block(self, pX + dX * i, pY + dY * i).rotation % 2 == rotation_ % 2) then

            return false;
         end
      end

      return true;
   end

   return false;
end
-- Check if a block placement is viable, and if this is the case, place the block and return true
function place_if_viable(self, pX, pY, type_, rotation_, length_)
   if(not is_viable(self, pX, pY, type_, rotation_, length_)) then
      return false;
   end

   if(type_ == "belt") then
      set_block(self, pX, pY, "belt", rotation_);

   elseif(type_ == "underground_belt") then
      local dX, dY = dir_offset(rotation_);

      set_block(self, (pX + dX * length_), (pY + dY * length_), "underground_belt", rotation_);
      set_block(self, pX, pY, "underground_belt", rotation_);
   else
      return false;
   end

   return true;
end

local function get_char_for(piece, X, Y)
  if(piece.map[X] == nil) then return " " end

  if(piece.map[X][Y] == nil) then return " " end

  mappiece = piece.map[X][Y];

  if(mappiece.type == "belt") then
    if(mappiece.rotation == 0 or mappiece.rotation == 2) then
      return "–"
    else
      return "|"
    end

  elseif(mappiece.type == "underground_belt" or mappiece.type == "underground_belt_exit") then
    if(mappiece.rotation == 0) then return ">"
    elseif(mappiece.rotation == 1) then return "\\"
    elseif(mappiece.rotation == 2) then return "<"
    else return "^" end

  elseif(mappiece.type == "X") then return "X"
  end


  return " "

end


function draw(piece)
  print("Displaying piece " .. tostring(piece))

  local output = "  "
  for x = 1, piece.map.x do
    output = output .. tostring(math.floor(x / 10))
  end
  print(output)
  output = "  "
  for x = 1, piece.map.x do
    output = output .. tostring(x % 10)
  end
  print(output)

  output = ""

  for y = 1, piece.map.y do
    output = tostring(math.floor(y / 10)) .. tostring(y % 10);

    for x = 1, piece.map.x do
      output = output .. get_char_for(piece, x, y);
    end

    print(output);
  end
end

function generate_map(self, mArray)
   for y, arX in pairs(mArray) do
      for x, mP in pairs(arX) do
         if(in_bounds(self, x, y) and type(mP) == "table") then
            self[x][y] = mP;
         elseif(in_bounds(self, x, y) and mP == "X") then
            self[x][y] = {type = "X"};
         end
      end
   end
end

local function get_heuristic(self, assmFactor)
   return self.routes:get_heuristic(assmFactor);
end

-- Initialise a new object
function new_piece(sizeX, sizeY)
  local newobject = {}

  newobject["routes"] = new_route_table();
  newobject["map"] = {x = sizeX, y = sizeY}

  newobject["copy"] = copy;

  newobject["map"]["in_bounds"]  = in_bounds;
  newobject["map"]["set_block"]  = set_block;
  newobject["map"]["get_block"]  = get_block;
  newobject["map"]["is_empty"]   = is_empty;
  newobject["map"]["generate"]   = generate_map;

  newobject["map"]["is_viable"]  = is_viable;
  newobject["map"]["place_if_viable"]  = place_if_viable;

  newobject["draw"]              = draw;

  newobject["get_heuristic"]     = get_heuristic;

  init_map(newobject);

  return newobject;
end
