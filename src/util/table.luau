--!strict
local Util = {}

function Util.DeepCopy<T>(tab: T): T
    if typeof(tab) ~= "table" then return tab end

    local copy = {}
    for i,v in pairs(tab) do
        copy[i] = Util.DeepCopy(v)
    end

    return (copy :: never) :: T
end

function Util.UnorderedRemove<T>(tab: {T}, index: number)
    tab[index] = tab[#tab]
    table.remove(tab)
end

return Util