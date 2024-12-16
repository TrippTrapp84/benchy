--[=[
    @class Types
]=]
local Types = {}

export type ErrorCode = number
Types.ErrorCode = {
    UNKNOWN_INTERNAL_ERROR = -1,

    FunctionYield = 1,
    InvalidSectionName = 2,

    InvalidModule = 3,
    InvalidModuleFormat = 4,
    InvalidModuleFunction = 5
}

export type ProfileRunData = {
    Total: number,
    Sections: {
        [string]: number
    }
}

export type ProfileData = {
    Runs: {ProfileRunData},

    Iterations: number,
} & ProfileRunData

export type ModuleProfileResults = {
    [string]: ProfileData
}

export type ProfileStatistics = {
    Mean: number,
    Median: number,
    StandardDeviation: number,

}

export type ProfileBoxPlot = {
    LowerFence: number,
    Q0: number,
    Q1: number,
    Q2: number,
    Q3: number,
    Q4: number,
    UpperFence: number
}

export type ProfileBucketData = {
    Start: number,
    Interval: number,
    Buckets: {{ProfileRunData}}
}

--[=[
    @interface ProfileConfig
    @within Types
    .Sections {string}? -- Additional sections to construct data for in your `ProfileData`. Required if you conditionally begin sections in your profile function.
    .Iterations number -- How many runs of your profile function to perform. Benchy defaults to `10,000` iterations if unspecified
    .Benchmarker boolean -- Should Benchy execute your function with Benchmarker compatible arguments. Defaults to true. It is recommended to set this to false if not required, as Benchmarker's format has additional overhead
    .DataFunction 
]=]
export type ProfileConfig = {
    Sections: {string}?,
    Iterations: number?,
    Benchmarker: boolean?,
    ParameterGenerator: (() -> ...any)?
}

export type BenchyProfileFunction = (Profiler, (string) -> (), () -> ()) -> ()
export type BenchmarkerProfileFunction = (Profiler, ...any) -> ()
export type ProfileFunction = BenchyProfileFunction | BenchmarkerProfileFunction

export type Profiler = {
    Begin: (name: string) -> (),
    End: () -> (),
}

return Types