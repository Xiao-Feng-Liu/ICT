use strict;
use warnings;

my%hash;
open IN1,"$ARGV[0]";#ID
while(<IN1>){
	chomp;
	my@info=(split /=/,$_);
	my$ID="$info[0]=$info[1]";
	my$cluster=$info[6];
	my$marker=$info[4];
	my$quality=$info[5];
	$hash{$ID}="$quality=$marker=$cluster";
}

open IN2,"$ARGV[1]";#full fasta
open OUT1,">$ARGV[2]";
$/=">";<IN2>;
while(<IN2>){
	chomp;
	my($ID,$seq)=(split /\n/,$_,2)[0,1];
	$ID=(split /\t/,$ID)[0];
	$ID=(split / /,$ID)[0];
	$seq=~s/>//g;
	$seq=~s/\n//g;
	my@info=split /=/,$ID;
	my$IDnew="$info[0]=$info[1]";
	
	if( exists $hash{$IDnew} ){
		print OUT1 ">$IDnew=$hash{$IDnew}\n$seq\n";
	}
}
