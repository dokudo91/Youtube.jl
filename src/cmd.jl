using CSV, DataFrames
using JSON3
using GoogleAuth

include("args.jl")
include("google.jl")

function run_cmd()
    s = create_settings()
    args = parse_args(s; as_symbols=true)::Dict{Symbol, Any}
    command = args[:_COMMAND_]::Symbol
    cargs = args[command]::Dict{Symbol, Any}
    if command == :videos
        ret = run_videos(cargs)
    elseif command == :playlists
        ret = run_playlists(cargs)
    elseif command == :filter
        ret = run_filter(cargs)
    elseif command == :add
        ret = run_add(cargs)
    elseif command == :delete
        ret = run_delete(cargs)
    end
    @show ret
end
"""
```
s = create_settings()
args = parse_args(["videos", "-n", "2", "-c", "channels.txt", "-p", "playlists.txt"], s; as_symbols=true)
command = args[:_COMMAND_]
cargs = args[command]
run_videos(cargs)
```
"""
function run_videos(cargs)
    try
        secretpath = cargs[:secret]::String
        tokenpath = cargs[:token]::Union{Nothing,String}
        channelpath = cargs[:channels]::Union{Nothing,String}
        playlistpath = cargs[:playlists]::Union{Nothing,String}
        csvpath = cargs[:write]::String
        nresults = cargs[:nresults]::Union{Nothing,Int}
        youtube = build_youtube(secretpath, tokenpath)
        playlistids = String[]
        if !isnothing(channelpath)
            channelids = readlines(channelpath)
            append!(playlistids, get_uploadsid.(youtube, channelids))
        end
        if !isnothing(playlistpath)
            append!(playlistids, readlines(playlistpath))
        end
        isempty(playlistids) && return :empty
        dfs = get_videodf.(youtube, playlistids, nresults)
        df = reduce(vcat, dfs)
        CSV.write(csvpath, df)
    catch e
        reasons = google_error_reasons(e)
        reasons ∈ "quotaExceeded" && return :quotaExceeded
        rethrow()
    end
    return :success
end
"""
```
s = create_settings()
args = parse_args(["playlists"], s; as_symbols=true)
command = args[:_COMMAND_]
cargs = args[command]
run_playlists(cargs)
```
"""
function run_playlists(cargs)
    try
        secretpath = cargs[:secret]::String
        tokenpath = cargs[:token]::Union{Nothing,String}
        channelpath = cargs[:channels]::Union{Nothing,String}
        csvpath = cargs[:write]::String
        nresults = cargs[:nresults]::Union{Nothing,Int}
        youtube = build_youtube(secretpath, tokenpath)
        if isnothing(channelpath)
            df = get_playlistdf(youtube, nresults)
        else
            channelids = readlines(channelpath)
            dfs = get_playlistdf.(youtube, channelids, nresults)
            df = reduce(vcat, dfs)
        end
        CSV.write(csvpath, df)
    catch e
        reasons = google_error_reasons(e)
        reasons ∈ "quotaExceeded" && return :quotaExceeded
        rethrow()
    end
    return :success
end
"""
```
s = create_settings()
args = parse_args(["filter", "-e", "exclude.txt"], s; as_symbols=true)
command = args[:_COMMAND_]
cargs = args[command]
run_filter(cargs)
```
"""
function run_filter(cargs)
    inputcsvpath = cargs[:read]::String
    outputcsvpath = cargs[:write]::String
    includepath = cargs[:include]::Union{Nothing,String}
    excludepath = cargs[:exclude]::Union{Nothing,String}
    df = CSV.File(inputcsvpath) |> DataFrame
    if !isnothing(includepath)
        includes = readlines(includepath)
        subset!(df, :title => ByRow(x -> any(contains.(x, includes))))
    end
    if !isnothing(excludepath)
        excludes = readlines(excludepath)
        subset!(df, :title => ByRow(x -> !any(contains.(x, excludes))))
    end
    sort!(df, :publishedAt)
    CSV.write(outputcsvpath, df)
    return :success
end
"""
```
s = create_settings()
args = parse_args(["add", "--title", "test"], s; as_symbols=true)
command = args[:_COMMAND_]
cargs = args[command]
run_add(cargs)
```
"""
function run_add(cargs)
    try
        secretpath = cargs[:secret]::String
        tokenpath = cargs[:token]::Union{Nothing,String}
        videocsvpath = cargs[:read]::String
        title = cargs[:title]::String
        youtube = build_youtube(secretpath, tokenpath)
        playlistdf = get_playlistdf(youtube)
        subset!(playlistdf, :title => ByRow(==(title)))
        videodf = CSV.File(videocsvpath) |> DataFrame
        if isempty(playlistdf)
            playlistid = create_playlist(youtube, title)
        else
            playlistid = first(playlistdf).id::String
            palylistvideodf = get_videodf(youtube, playlistid)
            subset!(videodf, :videoId => ByRow(∉(palylistvideodf.videoId::Vector{String})))
        end
        for videoId in String.(videodf.videoId)::Vector{String}
            add_video(youtube, playlistid, videoId)
        end
    catch e
        reasons = google_error_reasons(e)
        "quotaExceeded" ∈ reasons && return :quotaExceeded
        rethrow()
    end
    return :success
end

"""
```
s = create_settings()
args = parse_args(["delete"], s; as_symbols=true)
command = args[:_COMMAND_]
cargs = args[command]
run_delete(cargs)
```
"""
function run_delete(cargs)
    try
        secretpath = cargs[:secret]::String
        tokenpath = cargs[:token]::Union{Nothing,String}
        deleteidspath = cargs[:read]::String
        youtube = build_youtube(secretpath, tokenpath)
        df = CSV.File(deleteidspath) |> DataFrame
        for id in String.(df.id)::Vector{String}
            delete_video(youtube, id)
        end
    catch e
        reasons = google_error_reasons(e)
        "quotaExceeded" ∈ reasons && return :quotaExceeded
        rethrow()
    end
    return :success
end
isinteractive() || run_cmd()
