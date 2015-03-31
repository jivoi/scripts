#!/usr/bin/env perl
#/usr/local/etc/snmpd/snmpd.conf 
#exec raidmon /root/bin/check_disks.pl

#nagios config
#define service {
#        use                     hdd-service
#        host_name               youserver.example.com
#        service_description     raid
#        check_command           check_log_snmp!raidmon
#}



# TODO: add inode checks

use strict;
use POSIX qw(uname);
use Sys::Hostname;
use File::Glob ':glob';

my $mailto = 'root@example.com';
my $hostname = hostname();
my $now = time();
my $cache_file = '/tmp/check_disks_cache';
my $flag_file = '/tmp/check_disks_flag';

my (%errors, %warnings);
my ($nagios_crit_msg, $nagios_warn_msg);

my (%states, $current_dev, $errors_text, $warnings_text);

my $uname = (POSIX::uname())[0];

# Commands of checkers.
my $GMIRROR_CMD = '/sbin/gmirror list';
my $MD_CMD = "/sbin/mdadm -D `/bin/cat /proc/mdstat | /bin/awk '/^md/ {print \"/dev/\" \$1}'`";
my $MEGACLI_CMD = '/root/bin/MegaCli -CfgDsply -a0';
my $MEGARC_CMD  = '/root/bin/megarc  -dispCfg  -a0';

# Trying to read results from cache.
if ($ARGV[0] ne '-f') { 
    if ($now - (stat($cache_file))[9] < 300) {
        open(FH, "< $cache_file")
             or die "Can't open cache file $cache_file: $!";
        while (<FH>) { print $_; }
        close(FH);
        exit;
    }
}

# Analizing states.
my (@GMIRROR_OUT, @MD_OUT);

if ($uname eq 'FreeBSD' && -d '/dev/mirror') {
    @GMIRROR_OUT = qx($GMIRROR_CMD);
    foreach (@GMIRROR_OUT) {
        if (/State:\s+(\S+)/ and $1 ne 'ACTIVE' and $1 ne 'COMPLETE' || /^Components: 1/) {
            $errors{'GMIRROR'}++; last;
            $errors_text .= "One or more gmirrors were degraded or have only one component. ";
        }
    }
} elsif ($uname eq 'Linux' && `cat /proc/mdstat | /bin/egrep '^md.* : '`) {
    @MD_OUT = qx($MD_CMD);
    foreach (@MD_OUT) {
        if (/UUID :/) {
            if ($states{'State'} =~ /clean, degraded$/) {
                $errors{'MD'}++;
                $errors_text .= "$current_dev $states{'Raid Level'} degraded. ";
            } elsif ($states{'State'} =~ /clean, degraded, recovering/
                  || $states{'State'} =~ /clean, resyncing/) {
                $warnings{'MD'}++;
                $warnings_text .= "Rbld: $current_dev $states{'Raid Level'} $states{'Rebuild Status'}. ";
            } elsif ($states{'State'} ne 'clean' && $states{'State'} ne 'active') {
                $warnings{'MD'}++;
                $warnings_text .= "Unknown error state: $current_dev $states{'Raid Level'} $states{'State'}. ";
            }
        }
        if (/(.*) : (.*)$/) {
            my ($state, $value) = ($1, $2);
            $state =~ s/^\s*(.*)\s*$/$1/;
            $states{$state} = $value;
        }
        if (/^\/dev\/(.*):$/) {
            $current_dev = $1;
            %states = undef;
        }
    }
}

my @MEGACLI_OUT = qx($MEGACLI_CMD);
foreach (@MEGACLI_OUT) {
    if ((/^State:\s?(\w+)\s*$/ and $1 ne 'Optimal')) {
        $errors{'MEGACLI'}++; last;
    }
}

my @MEGARC_OUT = qx($MEGARC_CMD);
foreach (@MEGARC_OUT) {
    if (/^\s+\d+\s+\d+\s+0x\S+\s+0x\S+\s+(\w+)\s*$/ and $1 ne 'ONLINE') {
        $errors{'MEGARC'}++; last;
    }
}

my $text = join('', @GMIRROR_OUT, "\n\n\n",
                    @MD_OUT, "\n\n\n",
                    @MEGACLI_OUT, "\n\n\n",
                    @MEGARC_OUT);
my $warnings_list = join(', ', keys(%warnings));
my $errors_list = join(', ', keys(%errors));

if ($ARGV[0] eq '-v') { print $text; }

if ($warnings_list) {
    $nagios_warn_msg .= "There are warnings shown by $warnings_list. $warnings_text";
}

if ($errors_list) {
    $nagios_crit_msg .= "There are errors shown by $errors_list. $errors_text";
    if ($ARGV[0] eq '-c') {
        open(FH, "| mail -s '${hostname} RAID ${errors_list} alert' $mailto")
             or die "Can't open pipe to mail: $!";
        print(FH $text);
        close(FH);
    }
    open(FH, '>', $flag_file) or die "Can't create flag file: $!";
    close(FH);
} elsif (-f $flag_file) {
    open(FH, "| mail -s '${hostname} RAID recovery' $mailto")
         or die "Can't open pipe to mail: $!";
    print(FH $text);
    close(FH);
    unlink($flag_file);
}

# Nagios handler and cron mini patch
my @DF_OUT = qx'df | egrep \'^/dev/\' | awk \'{print $6 " " $5 " " $4}\' | tr -d "%" | egrep -v "(Mounted|/proc|/dev|/sys|/ports)"';
foreach (@DF_OUT) {
    my ($part, $percent, $free) = split(/\s/);
    my ($part_ext, $add_warn_msg, $add_crit_msg);
    my $free_text = sprintf('%.2f GB', $free / 1024 / 1024);

    if ($percent > 90 && $percent < 96) { $add_warn_msg++; }
    elsif ($percent >= 96) { $add_crit_msg++; }

    if ($part =~ m{^/www} && $percent > 85
            && (glob("$part/ff*.example1.ru") || glob("$part/file*.example2.ru"))) {
        ($add_warn_msg, $add_crit_msg) = undef;
        if (glob("$part/ff*.example1.ru")) {
            $part_ext = '/{ff*.example1.ru}';
            if ($free < 20 * 1024 * 1024) {
                $add_crit_msg++;
            } elsif ($free < 40 * 1024 * 1024) {
                $add_warn_msg++;
            }
        } elsif (glob("$part/file*.example2.ru")) {
            $part_ext = '/{file*.example2.ru}';
            if ($free < 1 * 1024 * 1024) {
                $add_crit_msg++;
            } elsif ($free < 8 * 1024 * 1024) {
                $add_warn_msg++;
            }
        }
    }

    if ($add_warn_msg) {
        $nagios_warn_msg .= "[${part}${part_ext}, used: ${percent}%, free: ${free_text}] ";
    }
    if ($add_crit_msg) {
        $nagios_crit_msg .= "[${part}${part_ext}, used: ${percent}%, free: ${free_text}] ";
    }
}

my $msg;
if ($nagios_crit_msg) {
    $msg = "CRITICAL: ${nagios_crit_msg}";
}
if ($nagios_warn_msg) {
    $msg .= "WARNING: ${nagios_warn_msg}";
}
if (!$msg && $ARGV[0] ne '-c') { # Suppress output of normal result for run from cron.
    $msg = 'OK';
}

print $msg;

open(FH, "> $cache_file")
     or die "Can't open cache file $cache_file: $!";
print(FH $msg);
close(FH);
