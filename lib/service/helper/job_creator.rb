module Service
  module Helper
    module JobCreator
      # framerate
      FR_CINEMATIC = 24
      FR_TVSHOW = 30
      FR_ONLINE_VDO = 30
      FR_SPORT = 60
      FR_GAMING = 60

      # 'GOP_MULTIPLE' or 'EXACT'
      # GOP: This setting aligns segment boundaries with GOP boundaries. This can result in segments that are slightly longer
      # or shorter than the specified segment_length. Better Compression and Quality:
      # EXACT: this setting ensures that segments are exactly the length specified in the segment_length parameter. This may
      # result in a less efficient use of the GOP (Group of Pictures). EXACT for Strict Compliance
      SEGMENT_LENGTH_CONTROL = 'GOP_MULTIPLE'.freeze

      # HLS and DASH: in complex scenes or rapid changes, some segments might end up being much shorter than SEGMENT_LENGTH seconds
      # but can not be less than MIN_SEGMENT_LENGTH
      SEGMENT_LENGTH = 6

      # DASH: This allows for further subdivision of segments into smaller pieces, called fragments, which can be useful
      # for finer control over playback and buffering. There will be two fragments SEGMENT_LENGTH/FRAGMENT_LENGTH
      # HLS: Segment is the smallest and self-contained media in MPEG-2 Transport Stream (TS)
      FRAGMENT_LENGTH = 3

      # HLS: to prevent the actual segment_length to be less than this value
      # which can help avoid very short segments that might be inefficient for streaming.
      MIN_SEGMENT_LENGTH = 3

      # DASH:The player will buffer more content before starting playback, leading to more stable playback with fewer
      # interruptions, but at the cost of longer startup times
      # HLS: Auto control by player and MIN_SEGMENT_LENGTH is needed instead.
      SEGMENT_BUFFER_COUNT = 2

      # input_s3_uri_file: s3://production-cm/media-convert/startwar.mp4
      # output_s3_uri_path: s3://production-cm/media-convert-output
      # allow_hd: false
      # framerate: FR_CINEMATIC

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
end
