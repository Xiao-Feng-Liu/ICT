#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;
use File::Basename;

my %opt = (
    min_identity => 98,
    min_block    => 500,
    output_class => 0,
    keep_best    => 1,
    skip_self    => 1,
    max_overhang => 30,
    ratio        => 0.9,
    input        => undef,
    output       => undef,
    help         => 0,
);

GetOptions(
    'min_identity=f' => \$opt{min_identity},
    'min_block=f'    => \$opt{min_block},
    'output_class!'  => \$opt{output_class},
    'keep_best!'     => \$opt{keep_best},
    'skip_self!'     => \$opt{skip_self},
    'max_overhang=i' => \$opt{max_overhang},
    'ratio=f'        => \$opt{ratio},
    'input|i=s'      => \$opt{input},
    'output|o=s'     => \$opt{output},
    'help|h'         => \$opt{help},
) or die "Error in command line arguments\n";

if ($opt{help}) {
    print <<"END_HELP";
Usage: paf2pair.pl [options] [-i input.paf] [-o output.pair]

Options:
  --min_block INT        Minimum alignment block (default: 500)
  --output_class         Output additional columns: class, strand, maplen, identity
  --keep_best            Keep only best alignment per read pair (default: enabled)
  --no-keep_best         Disable best-only filtering (output all passing alignments)
  --skip_self            Skip self matches (query == target) (default: enabled)
  --no-skip_self         Allow self matches
  --max_overhang INT     Maximum allowed overhang (default: 30)
  --ratio FLOAT          Overhang threshold as fraction of alignment length (default: 0.8)
  --input, -i FILE       Read PAF from FILE (default: STDIN)
  --output, -o FILE      Write output to FILE (default: STDOUT)
  --help, -h             Show this help

Input: PAF format (minimap2 output with -c --eqx, 12+ columns)
Output: 
  If --output_class is not used: two columns: qname<tab>tname
  If --output_class is used: six columns: qname<tab>tname<tab>class<tab>strand<tab>maplen<tab>identity(%)

Examples:
  paf2pair.pl -i alignments.paf -o pairs.txt
  paf2pair.pl --output_class --min_identity 95 < alignments.paf > pairs_with_class.txt
END_HELP
    exit(0);
}

my $in_fh;
if (defined $opt{input}) {
    open($in_fh, '<', $opt{input}) or die "Cannot open input file '$opt{input}': $!";
} else {
    $in_fh = \*STDIN;
}

my $out_fh;
if (defined $opt{output}) {
    open($out_fh, '>', $opt{output}) or die "Cannot open output file '$opt{output}': $!";
} else {
    $out_fh = \*STDOUT;
}

sub min2 { $_[0] < $_[1] ? $_[0] : $_[1] }
sub max2 { $_[0] > $_[1] ? $_[0] : $_[1] }

sub classify_mapping {
    my ($b1, $e1, $l1, $b2, $e2, $l2) = @_;
    my $left_overhang  = min2($b1, $b2);
    my $right_overhang = min2($l1 - $e1, $l2 - $e2);
    my $overhang       = $left_overhang + $right_overhang;
    my $maplen1 = $e1 - $b1;
    my $maplen2 = $e2 - $b2;
    my $maplen  = max2($maplen1, $maplen2);
    my $threshold = min2($opt{max_overhang}, $maplen * $opt{ratio});

    if ($overhang > $threshold) {
        return ("INTERNAL_MATCH", $maplen);
    } elsif ($b1 <= $b2 && ($l1 - $e1) <= ($l2 - $e2)) {
        return ("FIRST_CONTAINED", $maplen);
    } elsif ($b1 >= $b2 && ($l1 - $e1) >= ($l2 - $e2)) {
        return ("SECOND_CONTAINED", $maplen);
    } elsif ($b1 > $b2) {
        return ("FIRST_TO_SECOND_OVERLAP", $maplen);
    } else {
        return ("SECOND_TO_FIRST_OVERLAP", $maplen);
    }
}

my %best;
while (<$in_fh>) {
    chomp;
    next if /^\s*$/ || /^#/;
    my @f = split /\t/;
    next if @f < 12;

    my ($qname, $qlen, $qstart, $qend, $strand, $tname, $tlen, $tstart, $tend, $paf_match, $paf_block) = @f[0..10];

    next if ($opt{skip_self} && $qname eq $tname);
    #next if $paf_block <= $opt{min_block};

    my $identity = 100.0 * $paf_match / $paf_block;
    #next if $identity < $opt{min_identity};

    my ($b1, $e1) = ($qstart, $qend);
    my ($b2, $e2) = ($tstart, $tend);
    if ($strand eq '-') {
        ($b2, $e2) = ($tlen - $tend, $tlen - $tstart);
    }

    my ($class, $maplen) = classify_mapping($b1, $e1, $qlen, $b2, $e2, $tlen);
    next if $class eq "INTERNAL_MATCH";

    my $key = join("\t", $qname, $tname);
    if (!$opt{keep_best}) {
        if ($opt{output_class}) {
            print $out_fh join("\t", $qname, $tname, $class, $strand, $maplen, sprintf("%.2f", $identity)), "\n";
        } else {
            print $out_fh join("\t", $qname, $tname), "\n";
        }
    } else {
        if (!exists $best{$key} || $maplen > $best{$key}{maplen}) {
            $best{$key} = {
                qname    => $qname,
                tname    => $tname,
                class    => $class,
                strand   => $strand,
                maplen   => $maplen,
                identity => $identity,
            };
        }
    }
}

if ($opt{keep_best}) {
    foreach my $key (sort keys %best) {
        my $r = $best{$key};
        if ($opt{output_class}) {
            print $out_fh join("\t", $r->{qname}, $r->{tname}, $r->{class}, $r->{strand}, $r->{maplen}, sprintf("%.2f", $r->{identity})), "\n";
        } else {
            print $out_fh join("\t", $r->{qname}, $r->{tname}), "\n";
        }
    }
}

close $in_fh if defined $opt{input};
close $out_fh if defined $opt{output};
