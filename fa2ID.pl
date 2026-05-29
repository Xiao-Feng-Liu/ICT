use strict;
use warnings;

open IN1,"$ARGV[0]";
open OUT1,">$ARGV[1]";
while(<IN1>){
	chomp;
	if(/>/){
		my$ID=(split /\t/,$_)[0];
		$ID=(split / /,$ID)[0];
		$ID=~s/>//;
		print OUT1 "$ID\n";
	}
}
