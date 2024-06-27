require_relative 'config'
module Service
  module Helper
    module MediaConvert
      module Output
        include Helper::MediaConvert::Config

        def output_groups
          protocols = selected_protocols(context.protocol)

          protocols.map do |protocol|
            case protocol
            when 'FILE'
              output_group_file
            when 'DASH'
              output_group_dash
            when 'HLS'
              output_group_hls
            end
          end
        end

        def output_group_file
          {
            name: 'FILEGroup',
            output_group_settings: {
              type: 'FILE_GROUP_SETTINGS',
              file_group_settings: {
                destination: "#{output_s3_uri_path}/file/#{output_sub_dir_name}/"
              }
            },
            outputs: config_output_files
          }
        end

        def output_group_dash
          # dash config
          min_buffer_time = SEGMENT_LENGTH * SEGMENT_BUFFER_COUNT * 1000
          {
            name: 'DASHGroup',
            output_group_settings: {
              type: 'DASH_ISO_GROUP_SETTINGS',
              dash_iso_group_settings: {
                destination: "#{output_s3_uri_path}/dash/#{output_sub_dir_name}/",
                segment_length_control: SEGMENT_LENGTH_CONTROL,
                segment_length: SEGMENT_LENGTH,
                segment_control: 'SEGMENTED_FILES',
                min_buffer_time: min_buffer_time,
                fragment_length: FRAGMENT_LENGTH
              }
            },
            outputs: config_output_dashs
          }
        end

        def output_group_hls
          # hls config
          {
            name: 'HLSGroup',
            output_group_settings: {
              type: 'HLS_GROUP_SETTINGS',
              hls_group_settings: {
                destination: "#{output_s3_uri_path}/hls/#{output_sub_dir_name}/",
                segment_length_control: SEGMENT_LENGTH_CONTROL,
                segment_control: 'SEGMENTED_FILES',
                segment_length: SEGMENT_LENGTH,
                # in HLS, the buffering behavior is managed by the player
                # min_buffer_time: SEGMENT_LENGTH * SEGMENT_BUFFER_COUNT
                min_segment_length: MIN_SEGMENT_LENGTH
              }
            },
            outputs: config_output_hlses
          }
        end

        def create_output(group_type, video_quality_type)
          video_quality = video_quality_configs[video_quality_type]
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

                framerate_numerator: context.framerate,
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

          protocol_to_container_mapping = {
            FILE: 'MP4',
            HLS: 'M3U8',
            DASH: 'MPD'
          }

          container_settings = {
            container: protocol_to_container_mapping[group_type.to_sym]
          }

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
end
