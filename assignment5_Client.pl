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

    return;
}

checkArgumentInput( @ARGV );
exit 0;
