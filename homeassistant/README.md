# Home Assistant version

Replaces `epg.sh` / `programming.sh` / cron. Per channel you used to have an EPG script and a download-URL script; now:

| Old | New |
|---|---|
| `channelX_schedule.sh` + cron + `programming.sh` | an automation calling `script.sync_schedule` with the channel's URL and **rules**; results land in a **Local Calendar** (the schedule entity) |
| `channelX_download_url.sh` | `script.stream_url_<channel>`, returns `{url: ...}` |
| cron entry running `downloader.sh` | calendar **start** automation -> `script.record_start`; calendar **end** automation -> `script.record_stop` |

## Layout
- `packages/archiver_core.yaml` - shared: `sync_schedule`, `record_start`, `record_stop`, `rest_command.fetch_json`, `shell_command`s, `input_text.stream_url_override`.
- `packages/channel_<id>.yaml` - one per channel (copy `channel_tv8.yaml`): URL script, sync automation with rules, start/stop automations.
- `scripts/record_stream.sh` - ffmpeg start/stop (pid file per recording).

## Install
1. `configuration.yaml`: `homeassistant: {packages: !include_dir_named packages}`.
2. Copy `packages/*` to `/config/packages/`, `scripts/record_stream.sh` to `/config/scripts/` (`chmod +x`).
3. Add a **Local Calendar** per channel (e.g. "TV8 schedule" -> `calendar.tv8_schedule`).
4. In `channel_<id>.yaml` set the EPG URL (`{day}` becomes `YYYY-MM-DD`), the rules and your stream-URL logic. Restart HA.

## Rules (in the sync automation's `data`)
- `include_titles`: keep programs whose title contains any entry (case-insensitive).
- `genres`: keep programs whose genre or subgenre equals any entry (e.g. `Film`, `Documentario`).
- `exclude_titles`: drop programs matching any entry.
- Both include lists empty = keep everything. A program is kept if it matches title **or** genre, unless excluded.

## Recording
- Starts at event start minus the trigger offset (2 min), stops at event end plus offset (5 min); set both to `0:0:0` for exact times.
- Stopped with SIGINT so the last segment is finalised. `RECORD_MAX_SECS` (6 h) is a safety cap.
- Files go to `/media/recordings/<channel>_<title>_<timestamp>_<n>.mp4`, segmented every 30 min.
- Manual stream: set `input_text.stream_url_override` (the sample URL script honours it).

## Caveats
- Untested in a live HA; check `sync_schedule` output in Developer tools first. The rule/parsing template was tested locally against your JSON shape.
- Sync adds new programs only. Events already in the calendar are not removed when rules change; delete them in the calendar UI.
- A recording is lost if HA restarts mid-program (ffmpeg dies with its parent).
- Telegram messages are now `notify.notify`.
