# Home Assistant version

Replaces `epg.sh` / `programming.sh` / cron with HA automations. `downloader.sh`'s ffmpeg call lives on in `scripts/record_stream.sh`.

## Install
1. Enable packages in `configuration.yaml`:
   ```yaml
   homeassistant:
     packages: !include_dir_named packages
   ```
2. Copy `packages/streaming_archiver.yaml` to `/config/packages/`, `scripts/record_stream.sh` to `/config/scripts/` (`chmod +x`).
3. Copy your `channelX_download_url.sh` scripts to `/config/downloader/` (only needed when no manual URL is set).
4. Add the **Local Calendar** integration named "Stream recordings" (`calendar.stream_recordings`).
5. Edit `rest_command.fetch_epg.url` to your real EPG endpoint, then restart HA.
6. ffmpeg must exist where HA runs (HA OS/Container ship it). Recordings go to `/media/recordings`.

## Use
- `script.epg_refresh` runs at 03:00 and on start. It fetches today and tomorrow and fills `input_select.epg_program`.
- Pick a program, then run `script.schedule_selected_program`. It adds a calendar event.
- 10 minutes before the event, ffmpeg starts. The length is `(duration + 10 min) * 1.5`, rounded up to 30 minutes (the old `-d 10 -D 150`).
- Manual stream: put the URL in `input_text.stream_url_override`. Leave it empty to use the channel script.

Dashboard card:
```yaml
type: entities
entities:
  - input_select.epg_program
  - input_text.stream_url_override
  - type: button
    name: Schedule recording
    tap_action: {action: perform-action, perform_action: script.schedule_selected_program}
  - type: button
    name: Refresh EPG
    tap_action: {action: perform-action, perform_action: script.epg_refresh}
```

## Notes
- Untested against a live HA instance. Check template output in Developer tools > Template first.
- Only one channel is fetched (the `channel` field of `script.epg_refresh`).
- The Telegram messages become `notify.notify`. Change it to your notifier.
- `shell_command.stop_recordings` kills running ffmpeg recordings.
