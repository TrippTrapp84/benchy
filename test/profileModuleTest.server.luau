if false then return end

local Benchy = require(script.Parent.Parent.Benchy)

local TestModule = script.Parent.testModule

local Success, Result = Benchy.ProfileModule(TestModule, {Iterations = 10})

print(Success, Result)