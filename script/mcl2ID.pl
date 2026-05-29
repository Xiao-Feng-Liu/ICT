use strict;
use warnings;

open IN1,"$ARGV[0]" or die "Cannot open $ARGV[0]\n";
open OUT1,">$ARGV[1]";
while(<IN1>){
	chomp;
	my@array=split /\t/,$_;
	foreach my$ID (@array){
		print OUT1 "$ID\n";
	}
}
