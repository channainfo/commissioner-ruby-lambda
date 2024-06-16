module Service
  module JobCreatorHelper
    def create_output(group_type, video_quality_type)
      video_quality = video_qualities[video_quality_type]
      resolution = video_quality[:resolution]
      bitrate = video_quality[:bitrate].first * 1_000

      # max_bitrate = video_quality[:bitrate].last * 1_000
      audio_bitrate = video_quality[:audio_rate] * 1_000
      name_modifier = "-#{resolution.tr('x', '_')}"

      (width, height) = resolution.split('x').map(&:to_i)

      video_description = {
        width: width,
        height: height,
        codec_settings: {
          codec: 'H_264',
          h264_settings: {
            # Use constant bit rate(CBR) for smooth playback and player compatibility.
            rate_control_mode: 'CBR',
            bitrate: bitrate,
            # Use QVBR (Quality-Defined Variable Bitrate) to maintain consistent quality.
            # rate_control_mode: 'QVBR',
            # max_bitrate: bitrate,
            scene_change_detect: 'ENABLED',
            quality_tuning_level: 'SINGLE_PASS',

            framerate_numerator: framerate,
            framerate_denominator: 1
          }
        }
      }

      audio_description = {
        audio_type_control: 'FOLLOW_INPUT',
        codec_settings: {
          codec: 'AAC',
          aac_settings: {
            bitrate: audio_bitrate,
            coding_mode: 'CODING_MODE_2_0',
            sample_rate: 48_000
          }
        }
      }

      # DEFAULT TO Dash
      container_settings = {
        container: 'MPD',
        mpd_settings: {}
      }

      if group_type == 'HLS'
        container_settings = {
          container: 'M3U8',
          m3u_8_settings: {}
        }
      end

      {
        name_modifier: name_modifier,
        container_settings: container_settings,
        video_description: video_description,
        audio_descriptions: [audio_description]
      }
    end
  end
end
