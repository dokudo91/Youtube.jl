using PyCall
using GoogleAuth
using DataFrames, Dates

const SCOPES = ["https://www.googleapis.com/auth/youtube.force-ssl"]

"""
    build_youtube(secretpath, tokenpath)
    build_youtube(secretpath, ::Nothing)
    build_youtube(secretpath)

YouTube Data APIの初期化。`tokenpath`を指定しない場合、自動で作成する。

# Example
```
secretpath = "client_secret.json"
tokenpath = "token.json"
build_youtube(secretpath, nothing)
build_youtube(secretpath, tokenpath)
build_youtube(secretpath)
```
"""
function build_youtube(secretpath, tokenpath)
    build_service(secretpath, tokenpath, SCOPES, "youtube", "v3")
end
function build_youtube(secretpath, ::Nothing)
    build_service(secretpath, SCOPES, "youtube", "v3")
end
build_youtube(secretpath) = build_youtube(secretpath, nothing)
"""
    get_videodf(youtube, playlistId, nresults)
    get_videodf(youtube, playlistId)

# Example
```
secretpath = "client_secret.json"
youtube = build_youtube(secretpath)
playlistId = "UUBR8-60-B28hp2BmDPdntcQ"
nresults = 10
df = get_videodf(youtube, playlistId, nresults)
```
"""
function get_videodf(youtube, playlistId, nresults)
    items = get_items(youtube.playlistItems().list::PyObject, nresults; part="snippet", playlistId)
    df = DataFrame((id=String[], videoId=String[], publishedAt=DateTime[], title=String[]))
    for item in items
        snippet = item["snippet"]::Dict{Any,Any}
        datetime = DateTime(snippet["publishedAt"]::String, dateformat"yyyy-mm-ddTHH:MM:SSZ")
        push!(df,
            (item["id"]::String,
                snippet["resourceId"]["videoId"]::String,
                datetime,
                snippet["title"]::String))
    end
    df
end
get_videodf(youtube, playlistId) = get_videodf(youtube, playlistId, nothing)

"""
    get_uploadsid(youtube, channelid)

チャンネルのアップロードされた全ての動画を取得する。

# Example
```
secretpath = "client_secret.json"
youtube = build_youtube(secretpath)
channelid = "UCBR8-60-B28hp2BmDPdntcQ"
```
"""
function get_uploadsid(youtube, channelid)
    request = youtube.channels().list(;
        part="contentDetails",
        id=channelid
    )
    response = request.execute()
    response["items"][1]["contentDetails"]["relatedPlaylists"]["uploads"]::String
end

"""
    create_playlist(youtube, title)

# Example
```
secretpath = "client_secret.json"
youtube = build_youtube(secretpath)
title = "test"
create_playlist(youtube, title)
```
"""
function create_playlist(youtube, title)
    request = youtube.playlists().insert(;
        part="snippet",
        body=Dict(:snippet => Dict(:title => title))
    )::PyObject
    response = request.execute()::Dict{Any,Any}
    return response["id"]::String
end

function delete_playlist(youtube, playlistid)
    request = youtube.playlists().delete(; id=playlistid)
    request.execute()
end

"""
    get_items(requestfunction, nresults::Integer; kwargs...)
    get_items(requestfunction; kwargs...)
    get_items(requestfunction, ::Nothing; kwargs...)

# Example
```
secretpath = "client_secret.json"
youtube = build_youtube(secretpath)
requestfunction = youtube.playlists().list
nresults = 2
kwargs = (part="snippet", mine=true)
get_items(requestfunction; kwargs...)
```
"""
function get_items(requestfunction, nresults::Integer; kwargs...)
    request = requestfunction(; kwargs..., maxResults=clamp(nresults, 1, 50))::PyObject
    response = request.execute()::Dict{Any,Any}
    items = get(response, "items", [])
    if nresults > 50 && haskey(response, "nextPageToken")
        nextkwargs = merge(kwargs, Dict(:pageToken => response["nextPageToken"]::String))
        nextitems = get_items(requestfunction, nresults - 50; nextkwargs...)
        append!(items, nextitems)
    end
    return items
end
get_items(requestfunction; kwargs...) = get_items(requestfunction, typemax(Int); kwargs...)
get_items(requestfunction, ::Nothing; kwargs...) = get_items(requestfunction; kwargs...)

function get_playlistdf(youtube, nresults)
    items = get_items(youtube.playlists().list::PyObject, nresults; part="snippet", mine=true)
    get_playlistdf(items)
end
get_playlistdf(youtube) = get_playlistdf(youtube, nothing)

function get_playlistdf(youtube, channelId::AbstractString, nresults)
    items = get_items(youtube.playlists().list::PyObject, nresults; part="snippet", channelId)
    get_playlistdf(items)
end
get_playlistdf(youtube, channelId::AbstractString) = get_playlistdf(youtube, channelId, nothing)

function get_playlistdf(items::AbstractArray)
    df = DataFrame((id=String[], publishedAt=DateTime[], title=String[]))
    for item in items
        snippet = item["snippet"]::Dict{Any,Any}
        datetime = DateTime(snippet["publishedAt"]::String, dateformat"yyyy-mm-ddTHH:MM:SSZ")
        push!(df, (item["id"]::String, datetime, snippet["title"]::String))
    end
    df
end

"""
    add_video(youtube, playlistId, videoId)

# Example
```
secretpath = "client_secret.json"
youtube = build_youtube(secretpath)
playlistId = "UU5fwtXKwDpgboOud4DbjQTg"
videoId = "afdtN_qiBX4"
add_video(youtube, playlistId, videoId)
```
"""
function add_video(youtube, playlistId, videoId)
    request = youtube.playlistItems().insert(;
        part="snippet",
        body=Dict(:snippet => Dict(:playlistId => playlistId,
            :resourceId => Dict(:kind => "youtube#video", :videoId => videoId)))
    )::PyObject
    request.execute()::Dict{Any,Any}
end

"""
    search_channel(youtube, q, nresults)

# Example
```
secretpath = "client_secret.json"
youtube = build_youtube(secretpath)
q = "YouTube"
nresults = 10
search_channel(youtube, q, nresults)
```
"""
function search_channel(youtube, q, nresults)
    items = get_items(youtube.search().list, nresults; part="snippet", q, type="channel")
    df = DataFrame((channelId=String[], title=String[]))
    for item in items
        snippet = item["snippet"]::Dict{Any,Any}
        push!(df, (snippet["channelId"]::String, snippet["title"]::String))
    end
    df
end

function delete_video(youtube, itemid)
    try
        request = youtube.playlistItems().delete(; id=itemid)
        request.execute()
    catch e
        reasons = google_error_reasons(e)
        length(reasons) == 1 && reasons[1] == "playlistItemNotFound" && return :playlistItemNotFound
        rethrow()
    end
    return :success
end