#!/usr/bin/perl

use strict;
use Data::Dumper;

my $tmp_file = '/tmp/diskload.txt';
my %dev;

if ($ARGV[0] eq 'snmp') {
    my @lines;
    if (time() - (stat($tmp_file))[9] < 300) {
        open(FH, "<$tmp_file") or die('Cannot open file');
        @lines = <FH>;
        close(FH);
    }
    my ($max_u_dev, $dev_max_u);
    foreach (@lines) {
        my ($d, $r, $w, $u) = split();
        $dev{$d}{'avg_r'} = $r;
        $dev{$d}{'avg_w'} = $w;
        $dev{$d}{'avg_u'} = $u;
        if ($u > $dev_max_u) {
            $dev_max_u = $u;
            $max_u_dev = $d;
        }
    }
    #print Dumper(\%dev);
    my $t = $ARGV[1];
    my $d = $ARGV[2] || $max_u_dev;
    if ($t eq 'read') { print $dev{$d}{'avg_r'}; }
    if ($t eq 'write') { print $dev{$d}{'avg_w'}; }
    if ($t eq 'util') { print $dev{$d}{'avg_u'}; }
} else {
    my $count = 0;

    open(IN, 'iostat -x 15 2 | grep -A 1000 "Device:" | grep -v "%" | grep -Ev "^ " | grep -v "^$" | awk \'{print $1, $4, $5, $12}\' |') or die('Cannot open pipe.');

    while (<IN>) {
        my @line = split();
        # This 'if' skippes first abnormal result.
        if (!defined($dev{$line[0]})) {
            $dev{$line[0]} = {};
            next();
        }
        $dev{$line[0]}{'avg_r'} += $line[1];
        $dev{$line[0]}{'avg_w'} += $line[2];
        $dev{$line[0]}{'avg_u'} += $line[3];
        $count++;
    }

    close(IN);

    #print Dumper(\%dev);

    open(FH, ">$tmp_file") or die('Cannot open file');
    foreach my $d (keys(%dev)) {
        $dev{$d}{'avg_r'} /= $count;
        $dev{$d}{'avg_w'} /= $count;
        $dev{$d}{'avg_u'} /= $count;
        print(FH $d." ".int($dev{$d}{'avg_r'})." ".int($dev{$d}{'avg_w'})." ".int($dev{$d}{'avg_u'})."\n");
    }
    close(FH);
}
