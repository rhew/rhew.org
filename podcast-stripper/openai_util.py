import datetime
import json


def srt_format(timestamp):
    return datetime.datetime.strftime(
        datetime.datetime.fromtimestamp(timestamp), "%H:%M:%S,%f")[:-3]


def get_transcript(client, filename):
    transcript = client.audio.transcriptions.create(
        model="whisper-1",
        prompt="",
        response_format="verbose_json",
        file=open(filename, "rb")
    )
    return transcript


def get_commercials(client, transcript):
    # TODO Bobby: use "structured outputs" Aug 6 model
    prompt = """Analyze the following SRT transcript of a podcast episode to
        identify commercial segments. Commercial segments are typically
        introduced by a break or change in topic, often followed by
        sponsorship mentions. For each commercial:

        - Identify the sponsor of the commercial (company name).
        - Determine which lines of the transcript the commercial spans.
        - Output the sponsor and the start and end line numbers of each
          commercial segment.

        Use JSON. Example format:

        [
            {"sponsor": "Some Company",
             "start_line": 77,
             "end_line": 80},
            {"sponsor": "Some Other Company",
             "start_line": 103,
             "end_line": 111}
        ]
        """

    messages = [
        {
            "role": "user",
            "content": (f"{line} {srt_format(segment.start)}"
                        + f"--> {srt_format(segment.end)} {segment.text}")
        } for line, segment in enumerate(transcript.segments)
    ]
    messages.insert(0, {"role": "system", "content": prompt})

    completion = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=messages
    )

    # trim non-json from the front
    json_string = completion.choices[0].message.content[
        completion.choices[0].message.content.index('['):]

    # handle non-json in the end
    try:
        return json.loads(json_string)
    except json.JSONDecodeError as e:
        return json.loads(json_string[:e.pos])


def write_sponsor(client, company, file):
    with client.audio.speech.with_streaming_response.create(
        model="tts-1",
        voice="onyx",
        input=f"This podcast is sponsored by, {company}.",
        response_format='wav'
    ) as response:
        response.stream_to_file(file)