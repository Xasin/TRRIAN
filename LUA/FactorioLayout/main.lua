print("\nLoading FactorioLayout planner v0.1 ...\n");

require "piece"

function gen_new_object(self)
  local newobject = copy(self);
  setmetatable(newobject, {__call = gen_new_object});
  return newobject;
end

function insert_piece(self, piece)
  local i = 1;
  while true do
    if(self[i] == nil) then
      self[i] = piece;
      break;
    end

    i = i+1;
  end
end

function remove_piece(piecelist, piece)
  for k,i in pairs(piecelist) do
    if(piecelist[k] == piece) then
      piecelist[k] = nil;
    end
  end
end

function list_length(piecelist)
  print("mop")

  local i = 0
  for k, d in pairs(piecelist) do
    i = i + 1
  end
  return i;
end

function init_map(self)
  for i = 1, self.size.X do
    self.map[i] = {}

    for j = 1, self.size.Y do
      self.map[i][j] = {type = "empty"}
    end
  end
end

-- // OBJECT TABLE DEFINITION //////////////////////////////////////////////////
sPiece = {size = {X = 0, Y = 0}, headpoints = {{X = 1, Y = 1, R = 0}}, endpoints = {{X = 15, Y = 15}}, length = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, map = {{}}}
setmetatable(sPiece, {__call = gen_new_object});

winnerpiece = {};

function known_length(self)
  local totallen = 0;
  for k, i in pairs(self.length) do
    totallen = totallen + i;
  end

  return totallen;
end

function expected_length(self)
  if((#self.endpoints == 0) or (#self.headpoints == 0)) then
    print("No start/endpoints defined in " .. tostring(self) .. "!");
    return 0;
  end

  local approxlengths = 0;
  for i = 1, #self.headpoints do
    approxlengths = approxlengths + math.abs(self.endpoints[i].X - self.headpoints[i].X) + math.abs(self.endpoints[i].Y - self.headpoints[i].Y);
  end

  return approxlengths;
end

function heuristic(self)
  local tHeur = known_length(self) + expected_length(self);
  return tHeur;
end

function get_best_piece(pList)
  if(#pList == 0) then
    print("Empty piece list!!");
    return;
  end

  local minheuristic = 1000000000;
  local bestkey = 0;
  for k,i in pairs(pList) do
    local heur = heuristic(i);
    if(heur < minheuristic) then
      bestkey = k;
      minheuristic = heur;
    end
  end

  return pList[bestkey];
end

function get_shortest_headpoint(self)
  local minlen = 10000000000;
  local bestheadpoint;

  for i = 1, #self.headpoints do
    if((self.length[i] < minlen) and not is_partially_at_goal(self, i)) then
      minlen = i;
      bestheadpoint = i;
    end

    return bestheadpoint;
  end
end


function is_empty(self, coorX, coorY)
  if(coorX < 1 or coorY < 1 or coorX > self.size.X or coorY > self.size.Y) then
    return false;
  end

  if(self.map[coorX] == nil) then
    self.map[coorX] = {}
    return true;
  end

  if(self.map[coorX][coorY] == nil) then
    return true;
  end

  if(self.map[coorX][coorY].type == "empty") then return true; end

  return false;
end

function is_partially_at_goal(piece, h)
  if((piece.headpoints[h].X ~= piece.endpoints[h].Y) or (piece.headpoints[h].Y ~= piece.endpoints[h].Y)) then
    return false;
  end

  return true;
end

function is_at_goal(piece)
  for k,i in pairs(piece.headpoints) do
    if((i.X ~= piece.endpoints[k].Y) or (i.Y ~= piece.endpoints[k].Y)) then
      return false;
    end
  end

  return true;
end

function belt_check(self, type, startX, startY, rotation, length)
  for i = 1, length - 1 do
    local thisX, thisY = startX + math.cos(math.pi/2 * rotation)*i, startY + math.sin(math.pi/2 * rotation)*i;

    if(not is_empty(self, thisX, thisY) and (self.map [thisX][thisY].type == type .. "_exit" or self.map[thisX][thisY].type == type)
      and self.map[thisX][thisY].rotation == rotation) then
      return false;
    end
  end

  return true;
end


function is_viable(self, objtype, coorX, coorY, coorR, coorL)
  if(not is_empty(self, coorX, coorY)) then
    return false
  end

  if(objtype == "belt" and is_empty(self, coorX + math.cos(math.pi/2 * coorR), coorY + math.sin(math.pi/2 * coorR))) then
    return true;
  end

  if(objtype == "underground_belt"
      and is_empty(self, coorX + math.cos(math.pi/2 * coorR)*coorL, coorY + math.sin(math.pi/2 * coorR)*coorL)
      and is_empty(self, coorX + math.cos(math.pi/2 * coorR)*(coorL + 1), coorY + math.sin(math.pi/2 * coorR)*(coorL + 1))
      and belt_check(self, "underground_belt", coorX, coorY, coorR, coorL)) then
        return true;
  end


  return false;
end

function set_piece(self, coorX, coorY, type_, rotation_)
  if(not is_empty(self, coorX, coorY)) then
    return false;
  end

  rotation_ = rotation_ % 4;
  self.map[coorX][coorY] = {type = type_, rotation = rotation_}

  return true;
end

function branch_if_viable(piecelist, self, headpoint, objtype, coorX, coorY, rotation, length)
  if(not is_viable(self, objtype, coorX, coorY, rotation, length)) then
    return;
  end

  local newobject = copy(self);

  if(objtype == "belt") then
    set_piece(newobject, coorX, coorY, "belt", rotation);

    newobject.headpoints[headpoint] = {X = coorX, Y = coorY, R = rotation}
    newobject.length[headpoint] = newobject.length[headpoint] + 0.99
  end

  if(objtype == "underground_belt") then
    exitX = coorX + math.cos(math.pi/2 * rotation)*length;
    exitY = coorY + math.sin(math.pi/2 * rotation)*length;

    set_piece(newobject, coorX, coorY, "underground_belt", rotation);
    set_piece(newobject, exitX, exitY, "underground_belt_exit", rotation);

    newobject.headpoints[headpoint] = {X = exitX, Y = exitY, R = rotation};
    newobject.length[headpoint] = newobject.length[headpoint] + 6;
  end

  if(is_at_goal(newobject)) then
    winnerpiece = newobject
  end

  display_piece(newobject);
  insert_piece(piecelist, newobject);
end

function expand_piece(piecelist, piece)
  print("Expanding " .. tostring(piece))

  local h = get_shortest_headpoint(piece);

  local rotation = math.pi/2 * piece.headpoints[h].R;
  local newX, newY = piece.headpoints[h].X + math.cos(rotation), piece.headpoints[h].Y + math.sin(rotation);

  for i = piece.headpoints[h].R -1, piece.headpoints[h].R + 1 do
    branch_if_viable(piecelist, piece, h, "belt", newX, newY, i % 4, 0);
  end

  --for i = 2, 7 do
  --  branch_if_viable(piecelist, piece, h, "underground_belt", newX, newY, piece.headpoints[h].R, i)
  --end

  remove_piece(piecelist, piece);
end

function iterate_solve(piecelist)
  winnerpiece = nil;
  while(not winnerpiece) do
    expand_piece(piecelist, get_best_piece(piecelist));
  end
end

function get_char_for(piece, X, Y)
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


function display_piece(piece)
  print("Displaying piece " .. tostring(piece))

  local output = "  "
  for x = 1, piece.size.X do
    output = output .. tostring(math.floor(x / 10))
  end
  print(output)
  output = "  "
  for x = 1, piece.size.X do
    output = output .. tostring(x % 10)
  end
  print(output)

  output = ""

  for y = 1, piece.size.Y do
    output = tostring(math.floor(y / 10)) .. tostring(y % 10);

    for x = 1, piece.size.X do
      output = output .. get_char_for(piece, x, y);
    end

    print(output);
  end
end

testpiece = sPiece();
testpiece.size.X = 15;
testpiece.size.Y = 15;
init_map(testpiece);

testpiece.headpoints[2] = {X = 1, Y = 15, R = 0}
testpiece.endpoints[2]  = {X = 15, Y = 1}

piecelist = {testpiece}
