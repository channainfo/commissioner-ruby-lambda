module Service
  module Helper
    module MediaConvert
      module Config
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

        SUPPORTED_PROTOCOLS = %w[FILE HLS DASH].freeze
        SUPPORTED_QUALITIES = %i[low standard medium high].freeze

        def video_quality_configs
          @video_quality_configs ||= {
            high: { resolution: '1920x1080', bitrate: 4500..6000, framerate: [24, 30, 60], audio_rate: 128 },
            medium: { resolution: '1280x720', bitrate: 2500..3500, framerate: [24, 30, 60], audio_rate: 128 },
            standard: { resolution: '854x480', bitrate: 1000..1500, framerate: [24, 30], audio_rate: 128 },
            low: { resolution: '640x360', bitrate: 500..1000, framerate: [24, 30], audio_rate: 96 },
            bottom: { resolution: '426x240', bitrate: 300..700, framerate: [24, 30], audio_rate: 64 }
          }
        end

        # protocol either: 'HLS' or DASH
        def config_outputs(protocol)
          qualities = selected_qualities(context.quality)
          qualities.map { |quality| create_output(protocol, quality) }
        end

        def config_output_dashs
          config_outputs('DASH')
        end

        def config_output_hlses
          config_outputs('HLS')
        end

        def config_output_files
          config_outputs('FILE')
        end
      end
    end
  end
end
