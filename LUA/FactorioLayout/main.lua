
print("\nLoading FactorioLayout planner v0.2 ...\n");

require "piece"
require "piecelist"

testpiece = new_piece(10, 10);
testpiece.routes:new(1, 1, 10, 10, 0);
-- testpiece.routes:new(1, 10, 10, 1, 3);

piecelist = new_piecelist();
piecelist:insert(testpiece);

testpiece.map:generate({
   [1]   = {[3] = "X", [9] = "X"},
   -- [2]   = {[2] = "X"},
   [9]   = {[5] = "X", [10] = "X"},
   [10]  = {"X", "", "", "", "X", [9] = "X"}});

local maxInitTime    = 120;
local maxFinalTime   = 20;

local starttime   = os.time();
local startCPU    = os.clock();

local oldWinner = nil;

local oTime = os.time();

print("Beginning the pathfind!\nTrying to find some solution, this will take max. " .. maxInitTime .. " seconds.");

while(not piecelist:get_winner()) do
   piecelist:expand_best();
   if(#piecelist == 0) then break; end

   if(oTime ~= os.time()) then
      oTime  = os.time();
      print("Remaining: " .. maxInitTime - (os.time() - winnerT)  .. " seconds, with " .. #piecelist .. " in buffer.");
   end
end
oldWinner = piecelist:get_winner();

print("Found a first solution!");
print("\nGoing into finalising phase.\nThis'll take max. " .. maxFinalTime .. " seconds.");

while(os.time() - winnerT <= maxFinalTime) do
   piecelist:expand_best();
   if(#piecelist == 0) then break; end

   if(newWinner) then
      newWinner = false;
      print("Better solution: " .. piecelist:get_winner():get_heuristic(1) .. " vs. " .. oldWinner:get_heuristic());
      oldWinner = piecelist:get_winner();
   end
   if(oTime ~= os.time()) then
      oTime  = os.time();
      print("Remaining: " .. maxFinalTime - (os.time() - winnerT) .. " seconds, with " .. #piecelist .. " in buffer.");
   end
end

if(piecelist:get_winner()) then
   piecelist:get_winner():draw();
else
   print("Absolutely nothing was found!");
end

local totaltime   = os.time() - starttime;
local totalCPU    = os.clock() - startCPU;
print("Took: " .. totaltime .. " seconds, with a CPU-Time of " .. totalCPU .. " seconds.");
