#!/usr/bin/perl
use strict;

package ObjectQueue;
use File::Basename;

sub new
{
    my $type=shift;
    my $self={};
    $self->{'depth'}=0;
    $self->{'totalQueued'}=0;

    # list of references
    # new ones go on the end (right)
    # old ones are removed from the beginning (left)
    $self->{'list'}=[];

    return bless $self, $type;
}

sub depth
{
    my $self=shift;
    return $self->{'depth'};
}

sub push
{
    # new ones go on the end (right)

    my $self=shift;
    my $newRef=shift;
    push @{$self->{'list'}}, $newRef;
    $self->{'depth'}++;
    $self->{'totalQueued'}++;
}

sub pop
{
    # old ones are removed from the beginning (left)

    my $self=shift;
    my $oldRef = shift @{$self->{'list'}};
    $self->{'depth'}--;
    return $oldRef;
}

sub dump
{
    my $self=shift;
    my $funcRef=shift;

    my $count=1;
    print "\n--- Song queue ----------------------------------------------------------------\n";
    foreach my $ref(@{$self->{'list'}})
    {
        my ($name, $path, $suffix)=fileparse($ref, '\..*');

        print "| $count ". &$funcRef($ref);
        print " (NOW PLAYING)" if (1 == $count);
        print "\n";
        $count++;
    }
    print "|\n";
    print "| A total of ".$self->{'totalQueued'}." songs have been queued!\n";
    print "-------------------------------------------------------------------------------\n\n";
}

package LISong;
use File::Basename;

sub new
{
    my $type=shift;
    my $self={};

    my $file=shift;
    my ($name, $path, $suffix)=fileparse($file, '\..*');
    $self->{'file'}=$name.$suffix;

    my $link=shift;
    ($name, $path, $suffix)=fileparse($link, '\..*');
    $self->{'link'}=$name.$suffix;

    return bless $self, $type;
}

sub print
{
    my $self=shift;
    return $self->{'file'} . " (link=" . $self->{'link'} . ")";
}


package LiveIce;
use File::Basename;
my $LIVEICE_DIR='/usr/local/liveice';
my $LINK_DIR='/tmp/LiveIce';

sub new
{
    my $type=shift;
    my $self={};

    # overridable parameters
    $self->{'-maxQueue'}=4;

    # user specified parameters
    my ($parm, $value);
    while ($parm=shift)
    {
        $self->{$parm}=shift;
    }

    # "private" parameters
    $self->{'firstSongQueued'}=0;
    $self->{'formatIndex'}=0;
    $self->{'fh'}=undef;
    $self->{'initted'}=0;
    $self->{'queue'}=new ObjectQueue();

    validateParms($self);

    return bless $self, $type;
}

sub validateParms
{
    my $self=shift;

    my $formatRef=$self->{'-format'};
    die "-format must be specified" if (!defined($formatRef));

    my $numFormats=@{$formatRef};
    die "at least 1 format must be specified" if (!$numFormats);

    print "LiveIce> $numFormats formats received:";
    foreach my $format (@{$formatRef})
    {
        print " $format";
    }
    print "\n";
}

sub init
{
    my $self=shift;

    $self->{'initted'}=1;

    # make a clean directory
    `rm -rf $LINK_DIR`;
    `mkdir $LINK_DIR`;

    # populate with template links
    `rm -f $LIVEICE_DIR/playlist`;

    my $index=0;
    foreach my $format (@{$self->{'-format'}})
    {
        my $link="$LINK_DIR/$index.$format";
        print "LiveIce> creating $link\n";
        `echo $link >> $LIVEICE_DIR/playlist`;
        $index++;
    }
}

sub submitFile
{
    my $self=shift;
    my $file=shift;
    my $retVal=0;

    die("init() must be called first") if (! ($self->{'initted'}));


    # validate the file type
    my $format=($self->{'-format'})->[ $self->{'formatIndex'} ];
    my ($name, $path, $suffix)=fileparse($file, '\..*');
    warn ("expected \"\.$format\", not \"$suffix\"") if ($suffix ne ".$format");
    
    # update the link
    my $link= $LINK_DIR. "/" . $self->{'formatIndex'} . "\." . $format;
    print "LiveIce> linking $link to $file\n";
    `rm -f $link`;
    `ln -s \"$file\" $link`;

    # start liveice if necessary
    if (!defined($self->{'fh'}))
    {
        print("LiveIce> starting liveice\n");
        $self->{'fh'}=IO::File->new("cd $LIVEICE_DIR; ./liveice -@ 1 2>&1 |");
    }

    # check the queue and optionally wait until the file is started 
    # before returning to the caller
    my $song=new LISong($file, $link);
    $self->{'queue'}->push($song);
    $self->{'queue'}->dump(\&LISong::print);

    if ($self->{'queue'}->depth() >= $self->{'-maxQueue'})
    {
        # wait for track to finish
        my $line=undef;
        print("LiveIce> waiting for track to finish...");
        while (defined($line=$self->{'fh'}->getline()))
        {
            #if ($line =~ /Using log track.log/)
            if ($line =~ /\001/)
            {
                if ($self->{'firstSongQueued'})
                {
                    print("done.\n");
                    last;
                }
                else
                {
                    $self->{'firstSongQueued'}=1;
                    print("first song queued...");
                }
            }
        }

        print "LiveIce> removed ".  $self->{'queue'}->pop()->print() ."\n";

    }


    $self->{'formatIndex'}++;
    if ($self->{'formatIndex'} >= @{$self->{'-format'}})
    {
        $self->{'formatIndex'}=0;
    }


    return($retVal);
}


1
