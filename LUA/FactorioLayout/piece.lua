function dir_offset(rotation)
   if(rotation == 0) then
      return 1, 0;
   elseif(rotation == 1) then
      return 0, -1;
   elseif(rotation == 2) then
      return -1, 0;
   else
      return 0, 1;
   end
end

-- Initialise the map to contain only types "E"
local function init_map(self)
   for X = 1, self.map.x do
      self.map[X] = {}
      for Y = 1, self.map.y do
         self.map[X][Y] = {type = "E"}
      end
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

-- Generate a new route and initialise all values
function new_route(self, StartX, StartY, EndX, EndY, rotation_)
   local i = 1;
   while(self[i]) do
      i = i + 1;
   end

   self[i] = {}

   self[i]["start"]   = {x = StartX, y = StartY, r = rotation_}
   self[i]["endp"]    = {x = EndX, y = EndY}
   self[i]["length"]  = 0;
   self[i]["cost"]    = 0;
end
-- Return the route r, or false if not present.
function get_route(self, r)
   if(self[r] == nil) then
      return false;
   else
      return self[r];
   end
end
function append_route(self, r, pX, pY, rot, length, cost)
   if(not self[r]) then
      return false;
   end

   route = self[r];

   route["start"]    = {x = pX, y = pY, r = rot};
   route["length"]   = route["length"] + length;
   route["cost"]     = route["cost"] + cost;
end

-- Return true if the given route is at its endpoint
function route_is_at_goal(self, r)
   return (self[r].start.x == self[r].endp.x and self[r].start.y == self[r].endp.x);
end

-- Return the total length of all routes
function get_total_length(self)
   local tLen = 0;

   for k, v in pairs(self.routes) do
      if(type(v) == "table") then
         tLen = tLen + v.length;
      end
   end

   return tLen;
end
-- Return the total cost of all routes
function get_total_cost(self)
   local tCost = 0;

   for k, v in pairs(self.routes) do
      if(type(v) == "table") then
         tCost = tCost + v.cost;
      end
   end

   return tCost;
end
-- Return the expected length of all routes
function get_total_estimate(self)
   local tExpect = 0;

   for k,v in pairs(self.routes) do
      if(type(v) == "table") then
         tExpect = tExpect + math.abs(v.start.x - v.endp.x) + math.abs(v.start.y - v.endp.y);
      end
   end

   return tExpect;
end
-- Return the total heuristic value
function get_heuristic(self, expect_fact, lenFact, costFact)
   lenFact = lenFact or 1;
   costFact = costFact or 2;
   expect_fact = expect_fact or 1.1;

   return get_total_cost(self) * costFact
            + get_total_length(self) * lenFact
            + get_total_estimate(self) * (lenFact + costFact) * expect_fact;
end

-- Return true if every route is at its endpoint
function piece_is_at_goal(self)
   for k,v in pairs(self.routes) do
      if(type(v) == "table" and not route_is_at_goal(self.routes, k)) then
         return false;
      end
   end

   return true;
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

-- Initialise a new object
function new_piece(sizeX, sizeY)
  local newobject = {}

  newobject["routes"] = {}
  newobject["map"] = {x = sizeX, y = sizeY}

  newobject["copy"] = copy;

  newobject["routes"]["get"]  =  get_route;
  newobject["routes"]["new"]  =  new_route;
  newobject["routes"]["append"]  =  append_route;
  newobject["routes"]["is_at_goal"] = route_is_at_goal;

  newobject["get_total_length"]   = get_total_length;
  newobject["get_total_cost"]     = get_total_cost;
  newobject["get_total_estimate"] = get_total_estimate;
  newobject["get_heuristic"]      = get_heuristic;

  newobject["is_at_goal"]        = piece_is_at_goal;

  newobject["map"]["in_bounds"]  = in_bounds;
  newobject["map"]["set_block"]  = set_block;
  newobject["map"]["get_block"]  = get_block;
  newobject["map"]["is_empty"]   = is_empty;
  newobject["map"]["generate"]   = generate_map;

  newobject["map"]["is_viable"]  = is_viable;
  newobject["map"]["place_if_viable"]  = place_if_viable;

  newobject["draw"]              = draw;

  init_map(newobject);

  return newobject;
end
