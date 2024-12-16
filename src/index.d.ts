export interface ProfileRunData {
    Total: number;
    Sections: Map<string, number>;
}

export type ProfileData = {
    Runs: Array<ProfileRunData>,
    Iterations: number,
} & ProfileRunData

export interface ProfileBucketData {
    Start: number;
    Interval: number;
    Buckets: Array<Array<ProfileRunData>>,
}

export type ModuleProfileResults = Map<string,ProfileData>

export interface ProfileStatistics {
    Mean: number,
    Median: number,
    StandardDeviation: number,
}

export interface ProfileBoxPlot {
    LowerFence: number,
    Q0: number,
    Q1: number,
    Q2: number,
    Q3: number,
    Q4: number,
    UpperFence: number
}


export interface ProfileConfig {
    Sections?: Array<string>,
    Iterations?: number,
    Benchmarker?: boolean,
    ParameterGenerator?: () => LuaTuple<Array<unknown>>
}

export type Profiler = {
    Begin: (name: string) => void;
    End: () => void;
}

export type BenchyProfileFunction = (Profiler: Profiler, Begin: (name: string) => void, End: () => void) => void
export type BenchmarkerProfileFunction = (Profiler: Profiler, ...Data: unknown[]) => void
type ProfileFunction = BenchyProfileFunction | BenchmarkerProfileFunction

type Result<T> = [true, T] | [false, ErrorCode]

export enum ErrorCode {
    UNKNOWN_INTERNAL_ERROR = -1,

    FunctionYield = 1,
    InvalidSectionName = 2,

    InvalidModule = 3,
    InvalidModuleFormat = 4,
    InvalidModuleFunction = 5
}

export namespace Statistics {
    export function SplitIntoBuckets(Profile: ProfileData, Count: number, BucketInterval: number): ProfileBucketData;
    export function CalculateBoxPlot(Profile: ProfileData): ProfileBoxPlot;
    export function RemoveOutliers(Profile: ProfileData): ProfileData
}

export function ProfileFunction(Function: ProfileFunction, Config?: ProfileConfig): Result<ProfileData>
export function ProfileModule(Module: ModuleScript, Config?: ProfileConfig): Result<ModuleProfileResults>