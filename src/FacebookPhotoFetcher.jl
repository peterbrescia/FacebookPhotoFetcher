"""
Module for downloading a user's photos from Facebook.

Copyright Peter Brescia 2016.
"""
module FacebookPhotoFetcher

export fetch_photos

using Requests
using SQLite
using JSON

"""
Entry point for this tool.

function fetch_photos(access_token::String, save_directory::String)
"""
function fetch_photos(access_token::String, save_directory::String)
    output = set_up_output(save_directory)
    url = "https://graph.facebook.com/v2.5/me/photos?access_token=$access_token&limit=50"

    while true
        url = fetch_photos_in_batches(url, access_token, output)
        if url === false
            break
        end
    end
    println("Photo fetching complete")
end

function fetch_photos_in_batches(
    url::String,
    access_token::String,
    output::Dict,
)
    res = Requests.get(url)
    parsed_response = Requests.json(res)

    data = get(parsed_response, "data", false)
    if data === false
        println(parsed_response)
    end

    for photo in parsed_response["data"]
        fetch_image(photo["id"], access_token, output)
    end
    return get(parsed_response["paging"], "next", false) === false ? false : parsed_response["paging"]["next"]
end

function fetch_image(
    photo_id::String,
    access_token::String,
    output::Dict,
)
    url = "https://graph.facebook.com/v2.8/$photo_id?access_token=$access_token&fields=backdated_time_granularity,album,images,name,created_time,picture,link,event,from,name_tags,place,updated_time,width,page_story_id,can_delete,backdated_time,can_tag,height,icon,id,comments,likes,tags"

    res = Requests.get(url)
    parsed_response = Requests.json(res)

    SQLite.query(
        output["db"],
        "INSERT INTO images (facebook_id, metadata) VALUES (?, ?)";
        values=[
            photo_id,
            JSON.json(parsed_response),
        ]
    )

    img_source = parsed_response["images"][1]["source"]
    img = Requests.get(img_source)
    filename_fragments = split(img_source, "/")
    filename_last_fragment = filename_fragments[length(filename_fragments)]
    filename_subfragments = split(filename_last_fragment, "?")
    filename = filename_subfragments[1]

    Requests.save(img, output["output_directory"]*"/$filename")
end

function set_up_output(save_directory)
    if !isdir(save_directory)
        mkdir(save_directory)
    end
    timestamp = Dates.now()
    output_directory = "$save_directory/$timestamp"
    mkdir(output_directory)

    db = SQLite.DB("$output_directory/output.sqlite")
    SQLite.query(
        db,
        "CREATE TABLE images (
            id INTEGER not null PRIMARY KEY autoincrement,
            facebook_id INTEGER not null,
            metadata TEXT not null
        )",
    )
    SQLite.query(
        db,
        "CREATE INDEX images_fid_idx ON images (facebook_id)",
    )
    Dict(
        "db"                => db,
        "output_directory"  => output_directory,
    )
end

end
