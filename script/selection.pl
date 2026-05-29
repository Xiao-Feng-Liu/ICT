use strict;
use warnings;

my%hash;
open IN1,"$ARGV[0]";#mmseq
while(<IN1>){
	chomp;
	my($ID1,$ID2)=(split /\t/,$_)[0,1];
	push @{$hash{$ID1}},$ID2;
}

open OUT1,">$ARGV[2]";
open OUT2,">$ARGV[3]";
open IN2,"$ARGV[1]";#cluster:
my$cluster=0;
while(<IN2>){
	chomp;
	$cluster++;
	my@info;
	print OUT1 "$cluster\t";
	my$gene_num=0;
	my$gene_list="";
	my@array=(split /\t/,$_);
	foreach my$gene (@array){
		if( exists $hash{$gene} ){
			$gene_list=$gene_list." ".$gene;	
			$gene_num++;
			foreach my$short ( @{$hash{$gene}} ){
				$gene_list=$gene_list." ".$short;
				$gene_num++;
				push @info,$short;
			}
		}
		else{	
			$gene_list=$gene_list." ".$gene;
			$gene_num++;
			push @info,$gene;
		}
	}
	print OUT1 "$gene_num\t$gene_list\n";
	my @sorted = map { $_->[0] }
             sort {
                 ($b->[2] >= 40 <=> $a->[2] >= 40)
                 ||
                 ($b->[2] <=> $a->[2])
                 ||
                 ($b->[1] <=> $a->[1])
             }
             map {
                 my @parts = split('=', $_);
                 my $bb_len = length($parts[1]); 
                 my $ff_val = int($parts[5]);    
                 [ $_, $bb_len, $ff_val ]
             } @info;
	print OUT2 "$sorted[0]=cluster$cluster\n"
}

#open IN3,"$ARGV[2]";#single
#while(<IN3>){
#	chomp;
#	$cluster++;
#        print OUT1 "$cluster\t";
#	my$gene_num1=0;
#        my$gene_list1="";
#	if( exists $hash{$_} ){
#		$gene_list1=$gene_list1." ".$_;
#		$gene_num1++;
#		foreach my$short ( @{$hash{$_}} ){
#			$gene_list1=$gene_list1." ".$short;
#			$gene_num1++;
#		}
#	}
#	else{
#		$gene_list1=$gene_list1." ".$_;
#		$gene_num1++;
#	}
#       print OUT1 "$gene_num1\t$gene_list1\n";
#}
=cut
