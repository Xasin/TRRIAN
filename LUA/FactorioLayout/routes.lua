require "utilities"

-- Generate a new route and initialise all values
local function new_route(self, StartX, StartY, EndX, EndY, rotation_)
	local i = 1;
   while(self[i]) do
      i = i + 1;
   end

   self.data[i] = {}

   self.data[i]["head"]   	= {x = StartX, y = StartY, r = rotation_}
   self.data[i]["endp"]    = {x = EndX, y = EndY}

   self.data[i]["length"]  = 0;
   self.data[i]["cost"]    = 0;
end
-- Return the route r, or false if not present.
local function get_route(self, r)
   if(self.data[r] == nil) then
      return false;
   else
      return self.data[r];
   end
end
-- "Continue" a route, meaning: set the new home coordinates and edit length and cost values
local function continue_route(self, r, pX, pY, rot, length, cost)
   if(not self[r]) then
      return false;
   end

   route = self[r];

   route["head"]    = {x = pX, y = pY, r = rot};
   route["length"]   = route["length"] + length;
   route["cost"]     = route["cost"] + cost;
end

-- Return true if the given route is at its endpoint
local function route_is_at_goal(self, r)
   return (self.data[r].head.x == self.data[r].endp.x) and (self.data[r].head.y == self[r].endp.x);
end
-- Return true if all routes are at their goals.
local function	all_routes_at_goal(self)
	for k,i in pairs(self.data) do
		if(not route_is_at_goal(self, k)) then return false; end
	end

	return true;
end

-- Return the total length of all routes
local function get_known_length(self, r)
	if(r ~= nil) then								-- If you only want to scan one route.
		return get_route(self, r).length;
	end

	local tLength = 0;
	for k, v in pairs(self.data) do
		tLength = tLength + v.length;
	end

	return tLength;
end
-- Return the total known cost of the
local function get_known_cost(self, r)
	if(r ~= nil) then								-- If you only want to scan one route.
		return get_route(self, r).cost;
	end

	local tCost = 0;
	for k, v in pairs(self.data) do
		tCost = tCost + v.cost;
	end

	return tCost;
end
-- Return the expected length of all, or one, route
local function get_predicted_length(self, r)
	if(r ~= nil) then
		local rData = get_route(self, r);
		return math.abs(rData.endp.x - rData.head.x) + math.abs(rData.endp.y - rData.head.y);
	end

	local eLength = 0;
	for k, v in pairs(self.data) do
		eLength = eLength + get_predicted_length(self, k);
	end

	return eLength;
end
-- Return the expected cost of all, or one, route
local function get_predicted_cost(self, r)
	return get_predicted_length(self, r) * self.heuristic.costPerLen;
end

-- Return the total length that this route will /have/ to have.
local function get_total_length(self, r, assmFactor)
	assmFactor = assmFactor or self.heuristic.assumptionFactor;
	return get_known_length(self, r) + get_predicted_length(self, r) * assmFactor;
end
-- Return the total cost that this route will /have/ to have.
local function get_total_cost(self, r, assmFactor)
	assmFactor = assmFactor or self.heuristic.assumptionFactor;
	return get_known_cost(self, r) + get_predicted_cost(self, r)	* assmFactor;
end

-- Return the heuristic value for one, or all, routes. Smaller means better!
local function get_heuristic(self, r, assmFactor)
	assmFactor = assmFactor or self.heuristic.assumptionFactor;

	return get_total_length(self, r, assmFactor) * self.heuristic.lengthFactor
				+ get_total_cost(self, r, assmFactor) * self.heuristic.costFactor;
end
-- Return the absolute and known minimal heuristic value
local function get_absolute_heuristic(self, r)
	return get_heuristic(self, r, 1);
end

-- Return the number of the routes saved.
local function get_number_routes(self)
	local num = 0;
	for k,v in pairs(self.data) do
		num = num + 1;
	end
	return num;
end

function new_route_table()
	local newobject = {};

	newobject["data"] 	= {};
	newobject["heuristic"]	= {lengthFactor = 1, costFactor = 1, costPerLen = 1, assumptionFactor = 1.01};

	newobject["new"]			= new_route;
	newobject["get"]			= get_route;
	newobject["continue"]	= continue_route;

	newobject["route_at_goal"]	= route_is_at_goal;
	newobject["all_at_goal"]	= all_routes_at_goal;

	newobject["get_known_cost"]	= get_known_cost;
	newobject["get_known_length"]	= get_known_length;

	newobject["get_predicted_length"]	= get_predicted_length;
	newobject["get_predicted_cost"]		= get_predicted_cost;

	newobject["get_total_length"]			= get_total_length;
	newobject["get_total_cost"]			= get_total_cost;

	newobject["get_heuristic"]				= get_heuristic;
	newobject["get_absolute_heuristic"]	= get_absolute_heuristic;

	setmetatable(newobject, {__len = get_number_routes});

	return newobject;
end
