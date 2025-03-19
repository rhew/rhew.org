#!/usr/bin/perl

print "Content-type:text/html\n\n";

#
# Convert any form data into a usable format
#

read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
@pairs = split(/&/, $buffer);
foreach $pair (@pairs)
{
    ($name, $value) = split(/=/, $pair);
    $value =~ tr/+/ /;
    $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
    $value =~ s/~!/ ~!/g;
    $FORM{$name} = $value;
}

print "<html><head><title>Form Output</title></head><body>";
print "<h2>Results from FORM post</h2>\n";

# initialize the board (empty)
@board = ('-', '-', '-', '-', '-', '-', '-', '-', '-');

#
# Convert the key values into the board
#
# There are two types.  If the key name is a number, it represents a position 
# on the board.  It's value is either 'X' or 'O'.
#
# If the key name is "player", It's value is the symbol of the player who
# last played
#

$i=0;
foreach $key (keys(%FORM)) 
    {
    $i++;
    print "$key = $FORM{$key}<br>";

    if ($key eq "player")
        # who's turn was it last time?
        {
        if ($FORM{$key} eq 'X')
            {
            $player = 'O';
            }
        else
            {
            $player = 'X';
            }
        }
    else
        {
        $board[$key] = $FORM{$key};
        }
    }

$winner = "nobody";

if ($i == 0)
    {
    # If this game was just opened or was reset, initialize the player 
    # and board (X always goes first!)
    $player = 'X';
    @board = ('-', '-', '-', '-', '-', '-', '-', '-', '-');
    }
else
    # Did anyone win?
    {

    # horizontal
    if (($board[0] eq $board[1]) && ($board[1] eq $board[2]) && ($board[0] ne '-'))
        {
        $winner=$board[0];
        }
    elsif (($board[3] eq $board[4]) && ($board[4] eq $board[5]) && ($board[3] ne '-'))
        {
        $winner=$board[3];
        }
    elsif (($board[6] eq $board[7]) && ($board[7] eq $board[8]) && ($board[6] ne '-'))
        {
        $winner=$board[6];
        }

    # vertical
    elsif (($board[0] eq $board[3]) && ($board[3] eq $board[6]) && ($board[0] ne '-'))
        {
        $winner=$board[0];
        }
    elsif (($board[1] eq $board[4]) && ($board[4] eq $board[7]) && ($board[1] ne '-'))
        {
        $winner=$board[1];
        }
    elsif (($board[2] eq $board[5]) && ($board[5] eq $board[8]) && ($board[2] ne '-'))
        {
        $winner=$board[2];
        }

    # diag
    elsif (($board[0] eq $board[4]) && ($board[4] eq $board[8]) && ($board[0] ne '-'))
        {
        $winner=$board[0];
        }
    elsif (($board[2] eq $board[4]) && ($board[4] eq $board[6]) && ($board[2] ne '-'))
        {
        $winner=$board[2];
        }
    }

# Draw the board

print <<EndOfHTML;
<html><head><title>James Rhew: Tic Tac Toe</title></head>
<body>

<form action="tictactoe.cgi" method="POST">
EndOfHTML
;

print "winner:", $winner, "<BR>";

print "<input TYPE=\"hidden\" NAME=\"player\" SIZE=\"40\" MAXLENGTH=\"40\" VALUE=\"", $player, "\">";

$i=0;
foreach $row ('r1', 'r2', 'r3') 
    {
    foreach $col ('c1', 'c2', 'c3') 
        {
        if ($board[$i] eq '-')
            {
            print "<input type=\"radio\" name=\"", $i, "\" value=\"$player\">";
            }
        else
            {
            print "<input TYPE=\"hidden\" NAME=\"", $i, "\" VALUE=\"", $board[$i], "\">";
            print "$board[$i]"
            }
        $i++;
        }
    print "<BR>"
    }


print <<EndOfHTML;
<input type="submit" value="Go"><input type="reset" value="Bummer">
</form>

EndOfHTML
;

foreach $row ('r1', 'r2', 'r3') {
print "<input type=\"radio\" name=\"r1c1\" value=\"-\">"
}

# close up shop

print "</body></html>";
