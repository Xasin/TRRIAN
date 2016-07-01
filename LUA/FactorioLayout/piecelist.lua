require "piece"

deltaplus 	= 0;
deltaminus 	= 0;

local cWinner 	= nil;
local cHeur		= 1000000000000;
winnerT 	= os.time();
newWinner = false;

-- Search through a piece-list and get the best piece-list
function get_best_piece(self)
	local bestHeu 	= 10000000000000;
	local bestV 	= nil;

	for k,v in pairs(self) do
		if(type(v) == "table" and (v:get_heuristic() <= bestHeu)) then
			bestHeu 	= v:get_heuristic();
			bestV 	= v;
		end
	end

	return bestV;
end
-- Search through the piece-list and try to find a winner
function get_winner_piece(self)
	return cWinner or false;
end

-- Insert a new part into the list
function insert(self, piece)
	if(piece:is_at_goal() and piece:get_heuristic() < cHeur) then
		cWinner = piece;
		cHeur = piece:get_heuristic();
		winnerT = os.time();
		newWinner = true;
	-- Only insert piece if it is actually worth it
	elseif(self:get_winner() and self:get_winner():get_heuristic(1) <= piece:get_heuristic(1)) then
		return;
	end

	deltaplus = deltaplus + 1;

	local i = 1;
	while true do
		if(self[i] == nil) then
			self[i] = piece;
			break;
		end

		i = i+1;
	end
end
-- Remove a part from the list
function remove(self, piece)
	deltaminus = deltaminus + 1;

	for k,i in pairs(self) do
		if(i == piece) then
			self[k] = nil;
		end
	end
end

-- Return the length of this list
function list_length(piecelist)
	local i = 0
	for k, d in pairs(piecelist) do
		if(type(d) == "table") then
			i = i + 1
		end
	end

	return i;
end

-- Expand a route to contain all combinations of conveyor belts
function expand_route_belts(self, piece, r)
	local route = piece.routes:get(r);

	local dX, dY = dir_offset(route.start.r);
	local pX, pY = route.start.x + dX, route.start.y + dY;

	for i = 0, 3 do
		newobject = piece:copy();
		if(newobject.map:place_if_viable(pX, pY, "belt", i)) then
			newobject.routes:append(r, pX, pY, i, 1, 1)
			insert(self, newobject);
		end
	end
end
-- Expand a route to contain all combinations of underground belts
function expand_route_ubelts(self, piece, r)
	local route = piece.routes:get(r);

	local dX, dY = dir_offset(route.start.r);
	local pX, pY = route.start.x + dX, route.start.y + dY;

 	for i = 2, 6 do
		newobject = piece:copy();
		if(newobject.map:place_if_viable(pX, pY, "underground_belt", route.start.r, i)) then

			newobject.routes:append(r, pX + dX * i, pY + dY * i, route.start.r, i, 8);

			insert(self, newobject);
		end
	end
end
-- Expand a specific piece route!
function expand_piece_route(self, piece, r)
	expand_route_belts(self, piece, r);
	expand_route_ubelts(self, piece, r);
end
-- Expand a piece!
function expand_piece(self, piece)
	remove(self, piece)

	if(self:get_winner() and piece:get_heuristic(1) > self:get_winner():get_heuristic(1)) then
		return;
	end

	for k,v in pairs(piece.routes) do
		if(type(v) == "table" and (not piece.routes:is_at_goal(k))) then
			expand_piece_route(self, piece, k);
		end
	end
end
-- Just expand the best piece
function expand_best_piece(self)
	expand_piece(self, get_best_piece(self));
end

-- Iterate through a set until you get a winner!
function iterate_until_winner(self, timeout)
	timeout = timeout or 30;

	local maxTime = os.time() + timeout;

	while(os.time() < maxTime and not self:get_winner() and #self ~= 0) do
		self:expand_best();
	end

	return self:get_winner();
end
-- Iterate through a set until you are either empty or reach the timeout. Used for post-processing of a path.
function iterate_until_timeout(self, timeout)
	timeout = timeout or 10;

	local maxTime = os.time() + timeout;

	while(os.time() < maxTime and not self:get_winner() and #self ~= 0) do
		self:expand_best();
	end

	return self:get_winner();
end

-- Generate a new piecelist
function new_piecelist()
	local newobject = {}

	newobject["insert"] 	= insert;
	newobject["remove"]	= remove;
	newobject["get_best"]	= get_best_piece;
	newobject["get_winner"]	= get_winner_piece;

	newobject["expand"]	= expand_piece;
	newobject["expand_best"] = expand_best_piece;

	newobject["iterate_until_timeout"] 	= iterate_until_timeout;
	newobject["iterate_until_winner"]	= iterate_until_winner;

	setmetatable(newobject, {_len = list_length});

	return newobject;
end
