--!strict
if true then return end

local Benchy = require(script.Parent.Parent.Benchy)

local agg = 0

local Success, Data = Benchy.ProfileFunction(function(Profiler, beginSection, endSection)
    beginSection("Add")

    for i = 1,100000 do
        local a = 10 + 20

    end
    
    endSection()
end, {Iterations = 10000})
if not Success or not Data then return end