use strict;
use warnings;

open my $in, '<', $ARGV[0];
open my $out, '>', $ARGV[1];
while (<$in>) {
    chomp;
    next unless /^>>/;

    my $next_line = <$in>;
    last unless defined $next_line;

    if ($next_line =~ /Evalue/) {
        my @fields = split ' ', $_;
        if (@fields >= 2) {
            #my$readsID=(split /=/,$fields[1])[0];
            print $out "$fields[1]\n";
        }
    }
}
close $in;
