import os
import unittest

from ffmpeg_util import (
    seconds_to_ffmpeg_format, reduce_audio_file,
    write_audio_clip, join_segments, get_duration_s, get_size
)


FILE1 = os.path.join(os.path.dirname(__file__), 'pizza1.mp3')
FILE2 = os.path.join(os.path.dirname(__file__), 'pizza2.mp3')


class TestFFmpegUtil(unittest.TestCase):

    def test_timestamp_to_ffmpeg_format(self):
        self.assertEqual(seconds_to_ffmpeg_format(0), '00:00:00.000')
        self.assertEqual(seconds_to_ffmpeg_format(3603.5), '01:00:03.500')

    def test_reduce_audio_file(self):
        output_file = '/tmp/test-reduced.mp3'
        reduce_audio_file(FILE1, output_file)
        self.assertLessEqual(get_size(output_file), get_size(FILE1))

    def test_write_audio_clip(self):
        output_file = '/tmp/test-clip.mp3'
        write_audio_clip(FILE1, output_file, 3, 5)
        self.assertGreaterEqual(get_duration_s(output_file), 1)
        self.assertLessEqual(get_duration_s(output_file), 3)

    def test_write_audio_clip_no_end(self):
        output_file = '/tmp/test-clip-no-end.mp3'
        last_4_seconds_start_time = get_duration_s(FILE1) - 4
        write_audio_clip(FILE1, output_file, last_4_seconds_start_time)
        self.assertGreaterEqual(get_duration_s(output_file), 3)
        self.assertLessEqual(get_duration_s(output_file), 5)

    def test_join_segments(self):
        input_files = [FILE1, FILE2]
        output_file = '/tmp/test-join-segments.mp3'
        join_segments(input_files, output_file)
        expected_duration = (get_duration_s(FILE1) +
                             get_duration_s(FILE2))
        self.assertGreaterEqual(get_duration_s(output_file),
                                expected_duration - 1)
        self.assertLessEqual(get_duration_s(output_file), expected_duration + 1)
