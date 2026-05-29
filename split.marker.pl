#!/usr/bin/perl
use strict;
use warnings;

my $input_file = $ARGV[0];
my $output_file_path = $ARGV[1];

die "Usage: perl split_fastq_to_fasta.pl input.fastq(.gz) output_dir\n"
    unless defined $input_file && defined $output_file_path;

my %file_handles;
my $record_count = 0;

my $fh;
if ($input_file =~ /\.gz$/) {
    open($fh, "-|", "gzip", "-dc", $input_file)
        or die "Cannot open gzipped file $input_file: $!";
} else {
    open($fh, "<", $input_file)
        or die "Cannot open $input_file: $!";
}

while (my $line1 = <$fh>) {
    my $line2 = <$fh>;
    my $line3 = <$fh>;
    my $line4 = <$fh>;

    last unless defined $line2 && defined $line3 && defined $line4;

    chomp($line1);
    chomp($line2);
    chomp($line3);
    chomp($line4);

    my $header_clean = $line1;
    $header_clean =~ s/^\@//;

    # count number of "=" in header
    my $equal_count = () = $header_clean =~ /=/g;

    my $output_name;

    if ($equal_count == 5) {
        my @fields = split /=/, $header_clean;
        my $target_id = $fields[-2];

        unless (defined $target_id && $target_id ne '') {
            warn "Empty target_id in header: $header_clean\n";
            next;
        }

        $output_name = "${target_id}.fasta";

    } elsif ($equal_count == 2) {
        $output_name = "full.fasta";

    } else {
        warn "Skip header with $equal_count '=' signs: $header_clean\n";
        next;
    }

    if (!exists $file_handles{$output_name}) {
        my $output_file = "$output_file_path/$output_name";
        open(my $out_fh, ">", $output_file)
            or die "Cannot open output file $output_file: $!";
        $file_handles{$output_name} = $out_fh;
    }

    my $out = $file_handles{$output_name};

    # FASTA output
    print $out ">$header_clean\n";
    print $out "$line2\n";

    $record_count++;
}

close($fh);

foreach my $name (keys %file_handles) {
    close($file_handles{$name});
}

print STDERR "Total records written: $record_count\n";
