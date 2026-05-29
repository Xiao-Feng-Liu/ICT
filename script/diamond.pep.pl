use strict;
use warnings;

my %hash;

my $infile  = $ARGV[0] // die "Usage: perl script.pl input.txt output_dir\n";
my $outdir  = $ARGV[1] // die "Usage: perl script.pl input.txt output_dir\n";

die "Output directory does not exist: $outdir\n" unless -d $outdir;

open my $IN1, '<', $infile or die "Cannot open $infile: $!\n";

while (<$IN1>) {
    chomp;
    next if /^\s*$/;

    my @info = split /\t/, $_, -1;

    die "Bad line: $_\n" unless @info >= 5;

    push @{ $hash{$info[5]} }, ">$info[0]=$info[1]=$info[2]=$info[3]=$info[5]\n$info[4]";
}

close $IN1;

foreach my $gene (keys %hash) {
    my $safe_gene = $gene;
    $safe_gene =~ s/[\/\\:\*\?"<>\|]/_/g;

    my $outfile = "$outdir/$safe_gene.pep";

    open my $OUT, '>', $outfile or die "Cannot write $outfile: $!\n";

    foreach my $seq (@{ $hash{$gene} }) {
        print $OUT "$seq\n";
    }

    close $OUT;
}
