--!strict
local Types = require(script.Parent.types)
local TableUtil = require(script.Parent.util.table)

type ProfileData = Types.ProfileData
type ProfileRunData = Types.ProfileRunData
type ProfileBoxPlot = Types.ProfileBoxPlot
type ProfileBucketData = Types.ProfileBucketData

local function approximateIndex(index: number, tab: {number}): number
    local indexLow = math.floor(index)
    local indexHigh = math.ceil(index)

    if indexLow == indexHigh then
        return tab[index]
    end

    if indexHigh > #tab then
        return tab[indexLow]
    end

    if indexLow < 1 then
        return tab[indexHigh]
    end

    return (tab[indexLow] + tab[indexHigh]) / 2
end

local Util = {}

function Util.SplitIntoBuckets(Profile: ProfileData, Count: number, BucketInterval: number): ProfileBucketData
    local Min = math.huge
    local Max = -math.huge

    for i,v in pairs(Profile.Runs) do
        Min = math.min(Min, v.Total)
        Max = math.max(Max, v.Total)
    end

    local Range = Max - Min
    local Interval = if BucketInterval then BucketInterval else Range / Count

    local Buckets: {{ProfileRunData}} = table.create(Count)
    for i = 1,Count do
        Buckets[i] = {}
    end

    for i,v in pairs(Profile.Runs) do
        local Bucket = math.ceil((v.Total - Min) / Interval)
        table.insert(Buckets, Bucket, v)
    end
    
    local Data: ProfileBucketData = {
        Start = Min,
        Interval = Interval,
        Buckets = Buckets
    }

    return Data
end

function Util.CalculateBoxPlot(Profile: ProfileData): ProfileBoxPlot
    local Count = #Profile.Runs
    local SortedData: {number} = table.create(Count)

    for i,v in pairs(Profile.Runs) do
        table.insert(SortedData, v.Total)
    end

    table.sort(SortedData)

    local Q1Index = (Count + 1) / 4
    local Q2Index = (Count + 1) / 2
    local Q3Index = Q1Index * 3
    local Q1 = approximateIndex(Q1Index, SortedData)
    local Q2 = approximateIndex(Q2Index, SortedData)
    local Q3 = approximateIndex(Q3Index, SortedData)

    local Q0 = SortedData[1]
    local Q4 = SortedData[Count]

    local IQR = Q3 - Q1
    local FenceOffset = IQR * 1.5

    local LowerFence = Q1-FenceOffset
    local UpperFence = Q3+FenceOffset

    return {
        Q0 = Q0,
        Q1 = Q1,
        Q2 = Q2,
        Q3 = Q3,
        Q4 = Q4,
        LowerFence = LowerFence,
        UpperFence = UpperFence,
    }
end

function Util.RemoveOutliers(Profile: ProfileData): ProfileData
    local Data = TableUtil.DeepCopy(Profile)

    local BoxPlot = Util.CalculateBoxPlot(Profile)

    for i = #Data.Runs,1,-1 do
        local Run = Data.Runs[i]
        if not Run then continue end

        if Run.Total < BoxPlot.LowerFence then
            TableUtil.UnorderedRemove(Data.Runs, i)
        end
    end

    return Data
end

return Util