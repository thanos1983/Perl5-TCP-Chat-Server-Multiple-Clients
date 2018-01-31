#!/usr/bin/perl
use utf8;
use strict;
use warnings;
use IO::Socket::INET;
use constant ARGUMENTS => scalar 2;
use constant NICKNAME => scalar 12;
use constant MAXBYTES => scalar 255;

# flush memory after every initialization
$| = 1;

my $info = $ARGV[0]; # User message argv[0]
my $Nickname = $ARGV[1]; # User nickname argv[1]
my ( $kidpid, $line , $client_sock , $server_data , $send );
my $error = 'ERROR';
my $newline = "\n";

if (@ARGV > ARGUMENTS) {
    print "\nPlease no more than ".ARGUMENTS." arguments ('@ARGV')!\n";
    print "\nCorrect Syntax: perl $0 'IP:PORT  NICKNAME' (e.g. 127.0.0.1:5000 Thanos)\n\n";
    exit 0;
}
elsif (@ARGV < ARGUMENTS) {
    print "\nPlease no less than ".ARGUMENTS." arguments ('@ARGV')\n";
    print "\nCorrect Syntax: perl $0 'IP:PORT  NICKNAME' (e.g. 127.0.0.1:5000 Thanos)\n\n";
    exit 0;
}
else {

    my $string = index($info, ':');

    if ($string == '-1') {
	die "Please add ':' in your input - ".$info."\n";
    }

    my @input = split( ':' , $info );

    # create a tcp connection to the specified host and port
    $client_sock = IO::Socket::INET->new( Proto    => "tcp",
					  PeerAddr => $input[0],
					  PeerPort => $input[1]
	) or die "Can't connect to port ".$input[1]." at ".$input[0].": $!\n";

    $client_sock->autoflush(1);    # so output gets there right away
    print STDERR "[Connected to ".$input[0].":".$input[1]."]\n";

    $line = <$client_sock>;
    my $receive = &receive($line);
    #print "First receive: ".$receive."\n";
    if ($receive eq "Hello version") {
	$Nickname = "NICK ".$Nickname."";
	$send = &send($Nickname);
	#print "First send: ".$Nickname."\n";
	$line = <$client_sock>;
	$receive = &receive($line);
	#print "Second receive: ".$receive."\n";
	if ($receive eq "OK") {
	    # split the program into two processes, identical twins
	    print "Client '".$ARGV[1]."' enter your text here:\n";
	    die "can't fork: $!" unless defined( $kidpid = fork() );
	    # the if{} block runs only in the parent process
	    if ($kidpid) {
		# copy the socket to standard output
		while ( defined( $line = <$client_sock> ) ) {
		    $receive = &receive($line);
		    print "Third receive: ".$receive."\n";
		    print "Client '".$ARGV[1]."' enter your text here:\n";
		} # End of While reading (parent)
	    } # End of if (parent)
	    # the else{} block runs only in the child process
	    else {
		# copy standard input to the socket
		while ( defined( $line = <STDIN> ) ) {
		    chomp ($line);
		    my $line = "MSG ".$line."";
		    $send = &send($line);
		    if ($line =~ /quit|exit/i) {
			$line = "Client request ".$line."";
			my $send = &send($line);
			kill( "TERM", $kidpid ); # send SIGTERM to child
		    }
		} # End of read and send
	    } # End of else child
	} # End of if (OK)
	else {
	    print "Did not Receive OK!\n";
	    exit();
	}
    } # End of if (Hello version)
    else {
	print "Did not receive Hello version!\n";
	exit();
    }
} # End of else @ARGV

sub send {
    $_[0] = "".$_[0]."".$newline."";
    utf8::encode($_[0]);
    print $client_sock $_[0];
    chomp($_[0]);
    #print "The following data send to Server: (\ ".$_[0]." \)\n";
    #$client_sock->send($client_packet,MAXBYTES);
    return $_[0];
}

sub receive {
    # we can read from socket through recv()  in IO::Socket::INET
    #$client_sock->recv($server_data,MAXBYTES);
    utf8::decode($_[0]);
    chomp($_[0]);
    #print STDOUT "The following data received form Server: (\ ".$_[0]." \)\n";
    return $_[0];
}
