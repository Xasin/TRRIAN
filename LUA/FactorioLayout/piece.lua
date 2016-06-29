
-- Initialise the map to contain only types "E"
local function init_map(self)
   for X = 1, sizeX do
      newobject.map[X] = {}
      for Y = 1, sizeY do
         newobject.map[X][Y] = {type = "E"}
      end
   end
end

-- Copy a given object and return it, instead of the same table
function copy(self)
   local newtable = {}

   if(type(self) ~= "table") then
      return self;
   end

   for k,i in pairs(self) do
      newtable[k] = copy(i);
   end

   return newtable;
end

-- Generate a new route and initialise all values
function new_route(self, StartX, StartY, EndX, EndY)
   local i = 1;
   while(self.routes[i]) do
      i = i + 1;
   end

   self.routes[i]["start"]   = {x = StartX, y = StartY}
   self.routes[i]["endp"]     = {x = EndX, y = EndY}
   self.routes[i]["length"]  = 0;
   self.routes[i]["cost"]    = 0;
end
-- Return the route r, or false if not present.
function get_route(self, r)
   if(self.routes[r] == nil) then
      return false;
   else
      return self.routes[r];
   end
end
-- Return true if the given route is at its endpoint
function route_is_at_goal(self)
   return (route.start.x == route.endp.x and route.start.y == route.endp.x);
end

-- Return the total length of all routes
function get_total_length(self)
   local tLen = 0;

   for k, v in pairs(self.routes) do
      tLen = tLen + v.length;
   end

   return tLen;
end
-- Return the total cost of all routes
function get_total_cost(self)
   local tCost = 0;

   for k,v in pairs(self.routes) do
      tCost = tCost + v.cost;
   end

   return tCost;
end
-- Return the expected length of all routes
function get_total_estimate(self)
   local tExpect = 0;

   for k,v in pairs(self.routes) do
      tExpect = tExpect + math.abs(v.start.x - v.endp.x) + math.abs(v.start.y - v.endp.y);
   end

   return tExpect;
end
-- Return the total heuristic value
function get_heuristic(self, lenFact, costFact)
   lenFact = lenFact or 1;
   costFact = costFact or 1;

   return get_total_cost * costFact + (get_total_length + get_total_estimate) * lenFact;
end

-- Return true if every route is at its endpoint
function piece_is_at_goal(self)
   for k,v in pairs(self.routes) do
      if(not v.is_at_goal()) then
         return false;
      end
   end
end

-- Check if a given dot is still within the bounds of the map
local function in_bounds(self, pX, pY)
   return not (pX < 1 or pX > self.x or pY < 1 or pY > self.y)
end
-- Set a block in the map to a type.
function set_block(self, pX, pY, type_, rotation_)
   if(not in_bounds(self, pX, pY)) then return false; end

   self.map[pX][pY] = {type = type_, rotation = rotation_}
end
-- Return the block at given position, or, if OOB, a "blockade" block "X"
function get_block(self, pX, pY)
   if(not in_bounds(self, pX, pY)) then
      return {type = "X"}
   else
      return self[pX][pY];
   end
end
-- Check if a given map field is empty
function is_empty(self, pX, pY)
   local map = self;

   if(self.map ~= nil) then map = self.map end

   return get_block(self, pX, pY).type == "E"
end
-- Return true if it makes sense to place a block at that location, false if not
function is_viable(self, pX, pY, type_, rotation_, length_)
   -- Calculate the sin and cos for the according rotatation (easier code reading)
   dX = math.cos(rotation_ * math.pi/2);
   dY = math.sin(rotation_ * math.pi/2);

   -- Basic checks that kinda have to be true for every block
   if(type_ == "E") then return true;
   elseif(not is_empty(self, pX, pY)) then return false;

   elseif(type_ == "belt"
      and is_empty(self, pX + dX, pY + dY)) then return true;

   elseif(type == "underground_belt"
      and is_empty(self, pX + dX * length_, pY + dY * length_)
      and is_empty(self, pX + dX * (length_ +1), pY + dY * (length_ +1))) then

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

   elseif(type == "underground_belt") then
      local piRot = math.pi/2 * rotation_;

      set_block(self, pX, pY, "underground_belt", rotation_);
      set_block(self, pX + math.cos(piRot) * length_, pY + math.sin(piRot) * length_, "underground_belt", rotation_);
   else
      return false;
   end

   return true;
end

-- Initialise a new object
function new_piece(sizeX, sizeY)
  newobject = {}

  newobject["routes"] = {}
  newobject["map"] = {x = sizeX, y = sizeY}

  newobject["copy"] = copy;

  newobject["get_route"]  = get_route;
  newobject["new_route"]  = new_route;
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

  newobject["map"]["is_viable"]  = is_viable;
  newobject["map"]["place_if_viable"]  = place_if_viable;

  init_map(newobject);
end
