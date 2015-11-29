#!/usr/bin/perl
use strict;
use warnings;

sub checkArgumentInput {
    die "\nUsage: $0 [filename.txt].\n\n"
	if @_ != 1;

    die "\nPlease use a source file with the '.txt' extension: "
	.$_[0]."\n\n" if (index($_[0], ".txt") == -1);
    return;
}

sub processInputAsciiFile {
    my ($non_blank_lines, $chars) = 0;
    open(my $fh, "<", $_[0] )
    	or die "Cannot open '$_[0]': $!";

    while(<$fh>){
	$non_blank_lines++;
	$chars += length($_);
	chomp $_;
	print $_ . "\n";
    }

    close($fh)
	or die "File '$_[0]' close failed: $!";

    print "The number of lines: '"
	.$non_blank_lines
	."' and number of characters: '"
	.$chars."'\n";

    return "\nCaution: the total number of characters includes the '\\n' new line character\n\n";
}

checkArgumentInput(@ARGV);
print(processInputAsciiFile($ARGV[0]));
exit 0;