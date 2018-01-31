#!/usr/bin/perl
use utf8;
use strict;
use warnings;
use IO::Select;
use Data::Dumper;
use IO::Socket::INET; # Non-blocking I/O concept.
use constant ARGUMENTS => scalar 1;
use constant NICKNAME  => scalar 12;
use constant MAXBYTES  => scalar 255;

# flush memory after every initialization
$| = 1;

my $info = $ARGV[0]; # User message IP:PORT;
my $error = "ERROR";
my $newline = "\n";
my %hash = (); # global variable
my %children = ();
my %a_hash = ();
my @clients = ();
my ( $client_data , $server_sock , $buf , $sock , $msg , $new_sock , $trans , $readable_handles , $port , $kidpid , $s_hash , $client );

if (@ARGV > ARGUMENTS) {
    print "\nPlease no more than ".ARGUMENTS." input!\n";
    print "\nCorrect Syntax: perl $0 IP:PORT (e.g. 127.0.0.1:5000)\n";
    exit 0;
}
elsif (@ARGV < ARGUMENTS) {
    print "\nPlease no less than ".ARGUMENTS." input!\n";
    print "\nCorrect Syntax: perl $0 IP:PORT (e.g. 127.0.0.1:5000)\n";
    exit 0;
}
else {
    my $string = index($info, ':');

    if ($string == '-1') {
	die "Please include ':' in your input - ".$info."\n";
    }

    my @input = split( ':' , $info );

    $server_sock = new IO::Socket::INET( LocalAddr => $input[0],
					 LocalPort => $input[1],
					 Proto     => 'tcp',
					 Listen    => SOMAXCONN,
					 Reuse     => 1 ) or die "Could not connect: $!";

    print "\n[Server $0 accepting clients at PORT: ".$input[1]." and IP: ".$input[0]."]\n";

    $readable_handles = new IO::Select();
    $readable_handles->add($server_sock);

    while (1) {
	(my $new_readable) = IO::Select->select($readable_handles, undef, undef, 0);
	# conver string to array @$new_readable
	foreach $sock (@$new_readable) {
	    # Check if sock is the same with server (e.g. 5000)
	    # if same (new client) accept client socket
	    # else read from socket input
	    if ($sock == $server_sock) {
		$new_sock = $sock->accept()
		    or die sprintf "ERROR (%d)(%s)(%d)(%s)", $!,$!,$^E,$^E;
		$readable_handles->add($new_sock);
		$trans = "Hello version";
		$client_data = &send($trans);
		print "First send: ".$client_data."\n";
	    }
	    else {
		$buf = <$sock>;
		$port = $sock->peerport();
		print "This is \$sock: ".$sock."\n";
		print "This is \$port: ".$port."\n";
		($msg) = receive($buf);
		print "First receive: ".$msg."\n";
		my @text = split(/ / , $msg , 2); # LIMIT = 2 Only the first two gaps split
		if ($text[0] eq "NICK") {
		    if (length($text[1]) > NICKNAME) {
			$trans = "".$error." Please no more than ".NICKNAME." characters as nickname!";
			$client_data = &send($trans);
			$readable_handles->remove($sock);
			close($sock);
		    }
		    elsif ($text[1] =~ s/\W//g) {
			$trans = "".$error." Special characters detected in the nickname, please remove them!";
			$client_data = &send($trans);
			$readable_handles->remove($sock);
			close($sock);
		    }
		    else {
			$hash{$port}=$text[1];
			#push( @clients , $text[1] );
			#print Dumper(\@clients);
			$trans = "OK";
			$client_data = &send($trans);
			print "Second send: ".$client_data."\n";
		    }
		} # End of if ($text[0] eq "NICK")
		elsif ($text[0] eq "MSG") {
		    if (length($text[1]) > MAXBYTES) {
			$trans = "".$error." Please remember that message limit is ".MAXBYTES."";
			$client_data = &send($trans);
			print "In case of message over ".MAXBYTES." send: ".$client_data."\n";
		    }
		    else {
			# Get all client(s) socket(s)
			my @sockets = $readable_handles->can_write();
			# Send the same message to client(s)
			print Dumper(\%hash);
			foreach my $sck (@sockets) {
                            my $final = "".$text[0]." ".$hash{$port}." ".$text[1]."";
			    utf8::encode($final);
			    print $sck "".$final."".$newline."";
			    print "Third send: ".$final."\n";
			    #print STDOUT "The following data send to Client(s): (\ ".$buf." \)\n";
			} # End of foreach
		    }
		} # End of elsif ($text[0] eq "MSG")
		else {
		    print "Closing client!\n";
		    # when the client disconnects
		    delete $hash{$port};
		    $readable_handles->remove($sock);
		    close($sock);
		} # End of else condition
	    } # End of else condition ($sock == $server_sock)
	} # End of foreach new sock
    } # End of While (1)

    print "Terminating Server\n";
    close $server_sock;
    getc();
} # End of else @ARGV

sub send {
    $_[0] = "".$_[0]."".$newline."";
    utf8::encode($_[0]);
    print $new_sock $_[0];
    chomp ($_[0]);
    #print "The following data send to Cliets: (\ ".$_[0]." \)\n";
    #$client_sock->send($client_packet,MAXBYTES);
    return $_[0];
}

sub receive {
    #$new_sock->recv($client_data,MAXBYTES);
    utf8::decode($_[0]);
    chomp ($_[0]);
    if($_[0] =~ /^$/) {
	print "Data packet received empty!\n";
	print "From host: ".$sock->peerhost()." and port: ".$sock->peerport()."\n";
	return $_[0];
    }
    elsif ($_[0] !~ /^$/) {
	#print STDOUT "The following data received from Client: (\ ".$buf." \)\n";
	#print "From host: ".$sock->peerhost()." and port: ".$sock->peerport()."\n";
	#return $_[0];
	return ($_[0]);
    }
    else {
	$error = "".$error."".$newline."";
	utf8::encode ($error);
	$server_sock->send($error);
	print "Invalid client: ".$new_sock->peerhost()." terminating!\n";
	$readable_handles->remove($sock);
	close($sock);
    }
}
