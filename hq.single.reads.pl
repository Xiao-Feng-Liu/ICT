use strict;
use warnings;

my%hash;
open IN1,"$ARGV[0]";#mcl ID
while(<IN1>){
	chomp;
	$hash{$_}=$_;
}

open IN3,"$ARGV[1]";#rep
open OUT1,">$ARGV[2]";
while(<IN3>){
	chomp;
	my$quality=(split /=/,$_)[-1];
	next if( exists $hash{$_} );
	if( defined $quality && $quality >= 40){
		print OUT1 "$_\n";
	}
}
