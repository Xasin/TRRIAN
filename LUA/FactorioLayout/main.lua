
require "piece"
require "piecelist"

piecelist = {}

math.randomseed(os.time() + os.clock());

for i = 1, 200 do math.random(1, 1); end

function initialise_randomly(size, fill)
   tespiece = nil;
   piecelist = nil;

   testpiece = new_piece(size, size);
   testpiece.routes:new(1, 1, size, size, 0);

   for i = 1, fill * size^2 do
      testpiece.map:set_block(math.random(1, size), math.random(1, size), "X", 0);
   end

   testpiece.map:set_block(size, size, "E", 0);

   -- testpiece:draw();

   piecelist = new_piecelist();
   piecelist:insert(testpiece);
end

function run_verbose()
   local maxInitTime    = 60 * 3;
   local maxFinalTime   = 20;

   local oldWinner = nil;

   local oTime = os.time();
   local starttime = os.time();
   local startCPU    = os.clock();

   print("Beginning the pathfind!\nTrying to find some solution, this will take max. " .. maxInitTime .. " seconds.");

   while(not piecelist:get_winner()) do
      piecelist:expand_best();
      if(#piecelist == 0 or maxInitTime - (os.time() - winnerT) <= 0) then break; end

      if(oTime ~= os.time()) then
         oTime  = os.time();
         print("Remaining: " .. maxInitTime - (os.time() - winnerT)  .. " seconds, with " .. #piecelist .. " in buffer.");
      end
   end

   oldWinner = piecelist:get_winner();

   if(piecelist:get_winner()) then
      print("Found a first solution!");
      print("\nGoing into finalising phase.\nThis'll take max. " .. maxFinalTime .. " seconds.");

      while(os.time() - winnerT < maxFinalTime) do
         if(#piecelist == 0) then break; end
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
   end

   if(piecelist:get_winner()) then
      piecelist:get_winner():draw();
   else
      print("Absolutely nothing was found!");
   end

   local totaltime   = os.time() - starttime;
   local totalCPU    = os.clock() - startCPU;
   print("Took: " .. totaltime .. " seconds, with a CPU-Time of " .. totalCPU .. " seconds.");
end

function run_quiet()
   local maxInitTime    = 10;
   local maxFinalTime   = 1;

   local endTime = os.time() + maxInitTime;

   while((os.time() - endTime) < 0) do

      if(#piecelist == 0) then
         return piecelist:get_winner();
      end

      if(newWinner) then
         endTime = os.time() + maxFinalTime;
         newWinner = false;
      end

      piecelist:expand_best();
   end
end

function get_run_average(size, fill)
   local startTime, totalTime, sucesses = 0, 0, 0;

   while(sucesses ~= 1) do
      initialise_randomly(size, fill);

      startTime = os.clock();

      Wpiece = run_quiet();

      if(Wpiece) then
         totalTime = totalTime + os.clock() - startTime;
         sucesses = sucesses + 1;
      end
   end

   return totalTime, sucesses;
end

local xBegin, xStep, xEnd = 15, 0.1, 15;
local pBegin, pStep, pEnd = 0.01, 0.03, 0.9;


function begin_octave_header()
   io.write("x = ", xBegin, ":", xStep, ":", xEnd,";\n");
   io.write("y = ", pBegin, ":", pStep, ":", pEnd, ";\n");
   io.write([[
z = []]);
end

function end_octave_header()
   io.write([[];

x = x(1:rows(z));
y = y(1:columns(z));

[xx, yy] = meshgrid(y, x);

if rows(z) == 1
   plot(y, z);
else
   meshc(xx, yy, z);
endif

input("Press enter to close!");
]]);
end

function make_z_row(row)
   for perc= pBegin, pEnd , pStep do
      local tTime, sucesses = get_run_average(row, perc);
      local avgTime = tTime / sucesses;

      if(perc ~= pBegin) then
         io.write(",");
      end
      io.write(avgTime);
      io.flush();
   end
end

function make_z_table()
   for size = xBegin, xEnd, xStep do
      print("At row: " .. size);

      if(size ~= xBegin) then
         io.write(";");
      end

      make_z_row(size);
      io.write("\n");
   end
end

local filename = "FactorioLayout_AUTOGENERATE_" .. os.time() .. ".m";
io.output(filename);

begin_octave_header();

make_z_table();

end_octave_header();

io.output():close();

os.execute("octave " .. filename);
