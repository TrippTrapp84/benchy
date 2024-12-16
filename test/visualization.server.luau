--!strict
if true then return end

local Benchy = require(script.Parent.Parent.Benchy)

task.wait(5)

local Success, Data = Benchy.ProfileFunction(function()
    for i = 1,10000 do
        local a = 10
        a += 20
    end
end, {Iterations = 1000})
if not Success or not Data then return end

local Min = Data.Runs[1].Total
local Max = Data.Runs[1].Total

for i,v in pairs(Data.Runs) do
    Min = math.min(Min, v.Total)
    Max = math.max(Max, v.Total)
end

local Range = Max - Min

local BucketNum = 100
local BucketSize = Range / BucketNum

local Buckets = table.create(BucketNum)

for i = 1,BucketNum do
    local Bucket = {}

    for RunNum,Run in pairs(Data.Runs) do
        if math.ceil((Run.Total - Min) / BucketSize) == i then
            table.insert(Bucket, Run)
        end
    end

    Buckets[i] = Bucket
end

local tempPart = Instance.new("Part")
tempPart.Anchored = true
tempPart.CanCollide = false
tempPart.CanQuery = false
tempPart.CanTouch = false

for i,Bucket in pairs(Buckets) do
    local BarSize = #Bucket

    local barPart = tempPart:Clone()
    barPart.Position = Vector3.new(i,10 + BarSize/2,0)
    barPart.Size = Vector3.new(1,BarSize,1)
    barPart.Color = Color3.fromHSV(BarSize / Data.Iterations, 1, 1)
    barPart.Parent = workspace
end
