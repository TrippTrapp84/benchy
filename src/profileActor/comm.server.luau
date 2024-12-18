local Benchy = require(script.Parent.Parent)
local Types = require(script.Parent.Parent.types)

type ProfileConfig = Types.ProfileConfig
type ProfileData = Types.ProfileData
type ModuleProfileResults = Types.ModuleProfileResults

local Actor = script.Parent

local CommEvent = Instance.new("BindableEvent")
CommEvent.Name = "CommEvent"
CommEvent.Parent = Actor

local function ProcessIncoming()
    local Instruction, Module, Config: ProfileConfig? = CommEvent.Event:Wait()

    if typeof(Module) ~= "Instance" then
        warn(`BENCHY: Module is not an instance, Error code: {Benchy.ErrorCode.InvalidModule}`)
        CommEvent:Fire("Error", Benchy.ErrorCode.InvalidModule)
        return
    end
    
    if not Module:IsA("ModuleScript") then
        warn(`BENCHY: {Module:GetFullName()} is not a ModuleScript`)
        CommEvent:Fire("Error", Benchy.ErrorCode.InvalidModule)
        return
    end
    
    if Instruction ~= "ProfileModule" then
        warn(`BENCHY: INTERNAL ERROR: Invalid instruction to profile actor, {Instruction}. Error code: {Benchy.ErrorCode.UNKNOWN_INTERNAL_ERROR}`)
        CommEvent:Fire("Error", Benchy.ErrorCode.UNKNOWN_INTERNAL_ERROR)
        return
    end
    
    CommEvent:Fire("Received")
    
    local RequireSuccess, ModuleTable = pcall(require, Module)
    if not RequireSuccess then
        warn(`BENCHY: Error while requiring {Module:GetFullName()}: ({ModuleTable}). Error code {Benchy.ErrorCode.InvalidModule}`)
        CommEvent:Fire("Error", Benchy.ErrorCode.InvalidModule)
        return
    end
    
    if typeof(ModuleTable) ~= "table" then
        warn(`BENCHY: {Module:GetFullName()} does not return a table. Error code: {Benchy.ErrorCode.InvalidModuleFormat}`)
        CommEvent:Fire("Error", Benchy.ErrorCode.InvalidModuleFormat)
        return
    end
    
    if not ModuleTable.Functions then
        warn(`BENCHY: Return table of {Module:GetFullName()} does not contain an entry named "Functions". Error code: {Benchy.ErrorCode.InvalidModuleFormat}`)
        CommEvent:Fire("Error", Benchy.ErrorCode.InvalidModuleFormat)
        return
    end
    
    local DataFunction = ModuleTable.ParameterGenerator
    local ProfileConfig: ProfileConfig = Config or {
        ParameterGenerator = DataFunction
    }
    
    if not Config and DataFunction then
        ProfileConfig.ParameterGenerator = DataFunction
    end
    
    local ProfileResults: ModuleProfileResults = {}
    
    for i,v in pairs(ModuleTable.Functions) do
        if typeof(v) ~= "function" then
            warn(`BENCHY: Entry {i} in {Module:GetFullName()}.Functions is not a function. Error code: {Benchy.ErrorCode.InvalidModuleFunction}`)
            CommEvent:Fire("Error", Benchy.ErrorCode.InvalidModuleFunction)
            return
        end
    
        local ProfileSuccess, ProfileData = Benchy.ProfileFunction(v, ProfileConfig)
        if not ProfileSuccess then
            warn(`BENCHY: Entry {i} in {Module:GetFullName()}.Functions failed to profile. Error code: {ProfileData}`)
            CommEvent:Fire("Error", ProfileData)
            return
        end
    
        ProfileResults[i] = ProfileData :: ProfileData
    end
    
    CommEvent:Fire("Complete", ProfileResults)
end

while true do
    ProcessIncoming()
end
