---
name: spotify
description: "Use Hermes Spotify tools for playback, library and playlist requests, including device and authentication failures."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
prerequisites:
  tools: [spotify_playback, spotify_devices, spotify_queue, spotify_search, spotify_playlists, spotify_albums, spotify_library]
metadata:
  hermes:
    tags: [spotify, music, playback, playlists, media]
    related_skills: [gif-search]
---

# Spotify

Hermes Spotify tools control playback and manage the user's library and playlists. Playback needs a suitable active device and playback-changing actions require Premium.

- Match search results to the request rather than assuming the first result is correct. Use artist, album or playlist context URIs for context playback and track URIs for individual tracks.
- Find a user's playlist through `spotify_playlists` list rather than public catalog search. Match the library `kind` to the entity type.
- If playback reports no active device, ask the user to open Spotify on a device and start playback; a Premium-required response likewise needs user action rather than blind retries.
- An empty currently-playing response means nothing is playing. For authorization failure after refresh, reauthenticate; for rate limiting, respect the server's retry guidance.

Setup: https://hermes-agent.nousresearch.com/docs/user-guide/features/spotify

The tools are `spotify_playback` (including `play`, `pause`, `next`, `set_volume`, `get_currently_playing`, `recently_played`), `spotify_devices` (`list`, `transfer`), `spotify_queue` (`get`, `add`), `spotify_search`, `spotify_playlists` (`list`, `get`, `create`, `add_items`, `remove_items`, `update_details`), `spotify_albums` (`get`, `tracks`) and `spotify_library` (`list`, `save`, `remove`).

```text
spotify_search({"query": "artist album", "types": ["album"], "limit": 5})
spotify_playback({"action": "play", "context_uri": "spotify:album:<id>"})
spotify_playback({"action": "play", "uris": ["spotify:track:<id>"]})
spotify_playback({"action": "get_currently_playing"})
spotify_playlists({"action": "list"})
spotify_playlists({"action": "add_items", "playlist_id": "<id>", "uris": ["spotify:track:<id>"]})
spotify_library({"kind": "tracks", "action": "save", "uris": ["spotify:track:<id>"]})
spotify_devices({"action": "transfer", "device_id": "<id>", "play": true})
```

Search returns `uri`; use it directly. For a named user playlist, list playlists to get its ID, then obtain the track URI from search or currently playing. To create a playlist of recent tracks, call `recently_played`, `spotify_playlists` with `create` and `name`, then `add_items` with the returned ID and track URIs. Device transfer first requires `spotify_devices` with `list`.

Do not preflight every playback action with `get_state`. If authorization still fails after refresh, ask the user to run `hermes auth spotify`. A 204 currently-playing response is not an error; the tool returns `is_playing: false`.
