#!/usr/bin/perl
use strict;
use DBI;
use MP3::Info;
use LiveIce;

my $NUM_SONGS_IN_BLOCK=4;

my @scheduleFormat=qw(
    STATION_ANNOUNCE
    MUSIC_BLOCK
    WEATHER
    MUSIC_BLOCK
    NEWS
    MUSIC_BLOCK);

my $gTextOnly=0;
my $gStream=0;

my $arg;
while ($arg=shift)
{
    if ($arg eq "-textonly")
    {
        $gTextOnly=1;
    }
    elsif ($arg eq "-stream")
    {
        $gStream=1;
    }
}

my $gVoiceDir='/tmp/haywood/voice';
`rm -rf $gVoiceDir`;
`mkdir -p $gVoiceDir`;

my $gVoiceIndex=0;
my $MAX_VOICES_TO_KEEP=10;

my %fileFormats=(
    THX              => "mp3",
    STATION_ANNOUNCE => "mp3",
    MUSIC_BLOCK      => "mp3",
    NEWS             => "mp3",
    WEATHER          => "mp3");

my @liveiceFormat=convertScheduleToFileFormats(
    \@scheduleFormat,
    \%fileFormats);

my $gLiveIce;
if ((!$gTextOnly) and ($gStream))
{
    $gLiveIce=new LiveIce(
        -maxQueue => 4,
        -format => \@liveiceFormat);

    $gLiveIce->init();
}

print "haywood> building station announcement...\n";
my $gAnnounceFile="$gVoiceDir/announce.mp3";
sayToMp3($gAnnounceFile,
    "This is Haywood and you are listening to rhew dot org. ".
    "The Rhew dot org radio station is privately owned and ".
    "operated by James Rhew. For more information, point your ".
    "web browser to WWW dot rhew dot org. Thank you for listening.") if ($gStream);
print "haywood> done.\n";

my @gMasterFileList=getMasterFileList();
print "haywood> there are " .  scalar(@gMasterFileList) . " songs to play!\n";

while (1)
{
    print "haywood> shuffling songs\n";
    my @fileList=@gMasterFileList;

    randomizeArray(\@fileList);
    print "haywood> after shuffling, there are " .  scalar(@fileList) . 
        " songs to play!\n";
    
    my @block;
    
    my $done=0;
    while (!$done)
    {
        foreach my $segment (@scheduleFormat)
        {
            if ($segment eq "STATION_ANNOUNCE")
            {
                $gLiveIce->submitFile($gAnnounceFile) if ((!$gTextOnly) and ($gStream));
            }
            elsif ($segment eq "THX")
            {
                $gLiveIce->submitFile("/common/mp3/THX2.mp3") if ((!$gTextOnly) and ($gStream));
            }
            elsif ($segment eq "MUSIC_BLOCK")
            {
                if (@block=getBlock(\@fileList))
                {
                    sayIntro(@block);
                    playSongs(@block) if !$gTextOnly;
                    sayExit(\@block);
                }
                else
                {
                    $done=1;
                }
            }
            elsif ($segment eq "NEWS")
            {
                say("Coming up next, national news from yahoo.");
            }
            elsif ($segment eq "WEATHER")
            {
                my $lines=`cd /home/httpd/html/radio/admin_area; perl ./getWeather.pl`;
                $lines = "Now for local weather from Yahoo.\n" . $lines;
                print haywood> $lines;
                say ($lines);
            }
        }
    }
}

sub getMasterFileList
{
    my $dbh;
    my @list;

    # get all the files from the masterlist
    $dbh=DBI->connect("DBI:CSV:f_dir=/home/httpd/html/radio/db")
        or die "Cannot connect: " . $DBI::errstr;
    my $sth=$dbh->prepare("SELECT * from masterlist")
        or die "Cannot prepare: " . $dbh->errstr();
    $sth->execute
        or die "Cannot execute: " . $sth->errstr();
    my @row;
    while (@row=$sth->fetchrow_array())
    {
        push @list, $row[0];
    }
    $sth->finish();
    $dbh->disconnect();

    return @list;
}

sub sayToMp3
{
    my $voiceFile=shift;
    my $text=shift;

    return if ($gTextOnly);

    my $tempAuFile="$gVoiceDir/$gVoiceIndex.tmp.au";
    my $tempWavFile="$gVoiceDir/$gVoiceIndex.tmp.wav";

    `rm -f $tempAuFile`;
    `rm -f $tempWavFile`;
    `rm -f $voiceFile`;

    print "haywood> say...\n";
    system ("nice", "say", "-f", $tempAuFile, $text);

    print "haywood> convert to wav...\n";
    `nice sox $tempAuFile -sw $tempWavFile`;

    print "haywood> convert to mp3...\n";
    `nice notlame $tempWavFile $voiceFile`;
}

sub say
{
    my $text=shift;
    print $text . "\n";
    $text=pronounce($text);
    if (!$gTextOnly)
    {
        if (!$gStream)
        {
            `say \"$text\"`;
        }
        else
        {
            # create an empty file and link to it
            my $voiceFile="$gVoiceDir/$gVoiceIndex.mp3";
            `rm -f $voiceFile`;
            `touch $voiceFile`;
            $gLiveIce->submitFile($voiceFile);

            # launch a child to populate the file
            my $pid=fork;
            if ($pid)
            {
                print "haywood> spawning child $pid\n";
                sayToMp3($voiceFile, $text);
                print "haywood> child $pid exiting\n";

                exit;
            }

            $gVoiceIndex++;
            if ($gVoiceIndex > $MAX_VOICES_TO_KEEP)
            {
                $gVoiceIndex=0;
            }

        }
    }
}

# returns the next four songs (or less if there aren't that many)
sub getBlock
{
    my $songListRef=shift;
    my @retVal;
    my $numSongs=0;
    my $song;
    while (($song=shift @$songListRef ) and ($numSongs < $NUM_SONGS_IN_BLOCK))
    {
        if ( -f $song)
        {
            push (@retVal, $song);
            $numSongs++;
        }
        else
        {
            print "dead link, remove it from the DB!: $song\n";
        }
    }
    @retVal;
}

sub randomizeArray
{
    my $array=shift;
    my $i;
    for ($i= @$array; --$i;)
    {
        my $j=int rand ($i+1);
        next if $i == $j;
        @$array[$i, $j]=@$array[$j, $i];
    }
}

# list the artist of the songs in this block
sub sayIntro
{
    my @textList=( "Coming up next we have ",
                    "Stay tuned for ");
    my $text= $textList[int rand scalar @textList ];

    my $numSongs=scalar(@_);

    my $song;
    while ($song=shift)
    {
        my $ref=MP3::Info::get_mp3tag($song);
        my $artist=$ref->{"ARTIST"};

        $artist=addThe($artist);

        if ( (scalar(@_)+1) eq $numSongs)  # first song
        {
            $text .= "$artist";
        }
        elsif ((! scalar(@_)) and ($numSongs > 1)) # last song
        {
            $text .= ", and $artist";
        }
        else # middle song
        {
            $text .= ", $artist";
        }
    }
    $text.=".";
    say($text);
}

sub addThe
{
    my $retVal=shift;
    if (
        ($retVal =~ /Beastie/) or
        ($retVal =~ /Allman/) or
        ($retVal =~ /Troggs/) or
        ($retVal =~ /Doors/) or
        ($retVal =~ /Rolling/)
       )
    {
        $retVal="the $retVal";
    }

    $retVal;
}

sub pronounce
{
my %pronunciations=(
    'aretha'     => 'areetha',
    'ole'        => 'ohl',
    'daria'      => 'dahria',
    'skynyrd'    => 'skinerd',
    'queensryche'=> 'queensright',
    'rundgren'   => 'rungren',
    'grapevi'    => 'grapevine');

    my $text=shift;
    foreach my $word (keys(%pronunciations))
    {
        my $correction=$pronunciations{$word};
        $text=~s/$word/$correction/gi;
    }
    return $text;
}

sub playSongs
{
    my $song;
    while ($song=shift)
    {
        print "playSongs: $song\n";
        if ($gStream)
        {
            $gLiveIce->submitFile($song);
        }
        else
        {
            `mpg123 \"$song\"`;
        }
    }
    # big kludge.  Seems to be a period of time after the last mp3 plays that
    # Haywood is speechless.  Just have him say "test" for that duration.
    say ("test test test test test test test test test test test test test test test test test test") unless $gStream;
}

# list the artist, album and title of the songs played in this block
sub sayExit
{
    my $songsRef=shift;

    my $count=0;
    my $text;
    foreach my $song (@{$songsRef})
    {
        my $position;
        if (1== @{$songsRef})
        {
            $position="ONLY";
        }
        elsif (0==$count)
        {
            $position="FIRST";
        }
        elsif ($count+1 == @{$songsRef})
        {
            $position="LAST";
        }
        else
        {
            $position="MIDDLE";
        }

        $text .= getInfoText($song, $position);
        $count++;
    }

    say($text);
}

sub getInfoText
{
    my $song=shift;
    my $songPosition=shift;
    my $retText;

    my $ref=MP3::Info::get_mp3tag($song);
    my $artist=$ref->{"ARTIST"};
    $artist=addThe($artist);
    my $album=$ref->{"ALBUM"};
    if (defined($album) and ($album ne ""))
    {
        $album = ", from the album, $album";
    }
    else
    {
        $album="";
    }
    my $title=$ref->{"TITLE"};
    if (!defined($title) or ($title eq ""))
    {
        $title="a track";
    }

    if ("ONLY" eq $songPosition)
    {
        my @textList=( "You just heard, ",
                        "That was, ");
        $retText= $textList[int rand scalar @textList];
        $album=$album.". " if ($album ne "");
        $retText .= " $artist singing $title$album. ";
    }
    elsif ("FIRST" eq $songPosition)
    {
        my @textList=(
            "Handy as a pocket on a shirt",
            "Like a duck out of water",
            "Makes your mouth water",
            "Naked as a jaybird",
            "Nutty as a fruitcake",
            "Stone cold sober",
            "Tastes like chicken",
            "Till the cows come home"
            );
        my $quip= $textList[int rand scalar @textList];

        $retText .= "This is rhew dot org. $quip. $artist started this set with, $title$album. ";
    }
    elsif ("LAST" eq $songPosition)
    {
        $retText .= "$artist wrapped up the set with, $title$album. ";
    }
    else # MIDDLE
    {
        $retText .= "next was $artist with, $title$album. ";
    }

    return($retText);
}

sub convertScheduleToFileFormats
{
    my $scheduleRef=shift;
    my $ffRef=shift;
    my @retVal;

    foreach my $segment (@{$scheduleRef})
    {
print "segment: \"" . $segment . "\"\n";
        my $repeat=1;
        $repeat=$NUM_SONGS_IN_BLOCK if ($segment eq "MUSIC_BLOCK");
        push @retVal, "mp3" if ($segment eq "MUSIC_BLOCK"); # teaser
        while ($repeat)
        {
            $repeat--;
            push @retVal, $ffRef->{$segment};
print "pushing \"" . $ffRef->{$segment} . "\"\n";
        }
        push @retVal, "mp3" if ($segment eq "MUSIC_BLOCK"); # track listing
    }

    return(@retVal);
}

