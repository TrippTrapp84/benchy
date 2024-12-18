--!strict
local RunService = game:GetService("RunService")

local Types = require(script.types)
local Statistics = require(script.statistics)

type ProfileData = Types.ProfileData
type ModuleProfileResults = Types.ModuleProfileResults
type ProfileConfig = Types.ProfileConfig
type Profiler = Types.Profiler
type ErrorCode = Types.ErrorCode

local Defaults = {
    Iterations = 100000
}

local ProfileActor = script.profileActor
if not RunService:IsEdit() then
    ProfileActor.comm.RunContext = Enum.RunContext.Server
end

local Benchy = {}
Benchy.Statistics = Statistics
Benchy.ErrorCode = Types.ErrorCode

function Benchy.ProfileFunction(Function: Types.ProfileFunction, Config: ProfileConfig?): (boolean, ProfileData | ErrorCode)
    local Function = Function :: (Profiler,(string) -> (), () -> ()) -> ()
    local TestProfileData = {
        Sections = {},
    }
    local InvalidData = false
    local TestProfiler: Profiler = {
        Begin = function(name: unknown)
            if typeof(name) ~= "string" then
                InvalidData = true
                return
            end
            TestProfileData.Sections[name] = true
        end,
        End = function()
            
        end
    }

    local TestProfileThread = task.spawn(function()
        if if Config then Config.Benchmarker ~= nil else true then
            local Data = if Config and Config.ParameterGenerator then {Config.ParameterGenerator()} else {}
            Function(TestProfiler, unpack(Data) :: never)
        else
            Function(TestProfiler, TestProfiler.Begin, TestProfiler.End)
        end
    end)
    if coroutine.status(TestProfileThread) ~= "dead" then return false, Benchy.ErrorCode.FunctionYield end
    if InvalidData then return false, Benchy.ErrorCode.InvalidSectionName end

    local Iterations = Defaults.Iterations
    if Config and Config.Iterations then Iterations = Config.Iterations end

    local ProfileData: ProfileData = {
        Sections = {},
        Runs = table.create(Iterations),
        Iterations = Iterations,
        Total = 0,
    }

    for i = 1, Iterations do
        table.insert(ProfileData.Runs, {Sections = {}, Total = 0})
    end

    for i,v in pairs(TestProfileData.Sections) do
        ProfileData.Sections[i] = 0

        for c = 1, Iterations do
            ProfileData.Runs[c].Sections[i] = 0
        end
    end

    if Config and Config.Sections then
        for i,v in pairs(Config.Sections) do
            ProfileData.Sections[v] = 0
    
            for c = 1, Iterations do
                ProfileData.Runs[c].Sections[v] = 0
            end
        end
    end

    local numSections = 0
    for i,v in pairs(ProfileData.Sections) do numSections += 1 end

    local ActiveSections = table.create(numSections)
    local ActiveTimes = table.create(numSections)
    local CurrentRun = 1

    local ProfilerTime = 0

    local Profiler: Profiler = {
        Begin = function(name)
            local ProfilerStart = os.clock()

            table.insert(ActiveSections, name)
            table.insert(ActiveTimes, os.clock())

            ProfilerTime += os.clock() - ProfilerStart
        end,
        End = function()
            local ProfilerStart = os.clock()

            local elapsed = ProfilerStart - table.remove(ActiveTimes) :: number
            ProfileData.Runs[CurrentRun].Sections[table.remove(ActiveSections) :: string] += elapsed

            ProfilerTime += os.clock() - ProfilerStart
        end
    }

    local beginSection = Profiler.Begin
    local endSection = Profiler.End

    if if Config then Config.Benchmarker ~= false else true then
        local DataFunction = Config and Config.ParameterGenerator
        if not DataFunction then
            for i = 1,Iterations do
                CurrentRun = i
                ProfilerTime = 0
                table.clear(ActiveSections)
                table.clear(ActiveTimes)
        
                local startTime = os.clock()
                ;(Function :: never)(Profiler)
                local endTime = os.clock()
        
                ProfileData.Runs[i].Total = endTime - startTime - ProfilerTime
            end
        else
            for i = 1,Iterations do
                CurrentRun = i
                ProfilerTime = 0
                table.clear(ActiveSections)
                table.clear(ActiveTimes)
        
                local startTime = os.clock()
                Function(Profiler, DataFunction())
                local endTime = os.clock()
        
                ProfileData.Runs[i].Total = endTime - startTime - ProfilerTime
            end
        end
    else
        for i = 1,Iterations do
            CurrentRun = i
            ProfilerTime = 0
            table.clear(ActiveSections)
            table.clear(ActiveTimes)
    
            local startTime = os.clock()
            Function(Profiler, beginSection, endSection)
            local endTime = os.clock()
    
            ProfileData.Runs[i].Total = endTime - startTime - ProfilerTime
        end
    end

    for i = 1, Iterations do
        local Run = ProfileData.Runs[i]
        
        for i,v in pairs(Run.Sections) do
            ProfileData.Sections[i] += v
        end

        ProfileData.Total += Run.Total
    end

    return true, ProfileData
end

function Benchy.ProfileModule(module: ModuleScript, config: ProfileConfig?): (boolean, ModuleProfileResults | ErrorCode)
    local CommEvent = ProfileActor:FindFirstChild("CommEvent")
    if not CommEvent:IsA("BindableEvent") then
        return false, Benchy.ErrorCode.UNKNOWN_INTERNAL_ERROR
    end

    local thread = coroutine.running()
    local Activated = false

    local function resume(...: any)
        local Args = {...}
        pcall(function()
            coroutine.resume(thread, unpack(Args))
        end)
    end

    CommEvent.Event:Connect(function(Event: string, ...: any)
        if Event == "Error" then
            local ErrorCode: ErrorCode? = ...
            if not Activated then
                Activated = true

                resume(false, ErrorCode or Benchy.ErrorCode.UNKNOWN_INTERNAL_ERROR)
            end
        elseif Event == "Complete" then
            local ProfileData: ModuleProfileResults? = ...
            if not Activated then
                Activated = true

                if not ProfileData then
                    resume(false)
                else
                    resume(true, ProfileData)
                end
            end
        end
    end)

    CommEvent:Fire("ProfileModule", module, config)

    local Success, ProfileData = coroutine.yield()

    return Success, ProfileData
end

return Benchy