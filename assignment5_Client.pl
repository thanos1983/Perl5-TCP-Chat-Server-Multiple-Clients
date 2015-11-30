#!/usr/bin/perl
use strict;
use warnings;

sub checkArgumentInput {
    if (@_ != 2) {
	die "\nUsage: $0 [IP:PORT] [NickName]\n\n"
    }
    elsif ($_[0] !~ /:/) {
	die "\nUsage: [IP:PORT] [NickName]\n\n";
    }

    my $column = ':';
    my @numberOfOccurences = $_[0] =~ /$column/g;

    if (@numberOfOccurences > 1) {
	die "\nUsage: [IP:PORT] please do not use more than one column\n\n";
    }

    # we use 2 as a number in split, into two fields
    my ($ip, $port) = split(/:/, $_[0], 2);

    print "IP: $ip\n";
    print "Port: $port\n";

    return;
}

checkArgumentInput( @ARGV );
exit 0;
