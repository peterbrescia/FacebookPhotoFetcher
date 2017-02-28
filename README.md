# FacebookPhotoFetcher
Tool for downloading from Facebook all photos that user is tagged in (see Notes).

# Setup
- Install Julia (v0.5)
- Run the following into your `julia` prompt:
```jl
Pkg.clone("https://github.com/peterbrescia/FacebookPhotoFetcher.jl")
```

# Running
- Create a FB access token for the Graph API with `user_photos` permission.
- In a julia prompt, type the following:
```jl
using FacebookPhotoFetcher
fetch_photos(access_token, save_directory)
```
- Your photos will be saved to `save_directory`.

# Notes
- Facebook [permissions](https://developers.facebook.com/docs/graph-api/reference/photo) set by the owner of a photo can block the app from accessing certain photos.
