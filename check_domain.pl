#!/usr/bin/perl

#add to cron
#/root/bin/checkdomain/checkdomain.pl < /root/bin/checkdomain/domains.txt 2>&1

# added cache whois 
use Net::Domain::ExpireDate;
use Time::Piece;
use Net::Whois::Raw qw( whois );

my $mailto = 'root@examle.com';
my $debug = 1;
my $now = localtime;
my $mail = 'mail -Es "Domain Expiration Status" '.$mailto;
#my $mail = 'cat';
my $warntime = 3*30*24*60*60; # 3 months
#my $warntime = 3*30*24*60;

$Net::Whois::Raw::CHECK_EXCEED = 0;
$Net::Whois::Raw::TIMEOUT = 60;
$Net::Whois::Raw::USE_CNAMES = 1;

while (<STDIN>) {
	chomp;

	if ( $_ !~ /^([-a-z0-9]+\.)+[a-z]{2,6}$/i ) { # domain name?
		print "$_: not a domain name\n" if $debug;
		next;
	}
	
	$domainname = $_;

	my $try = 1;
	while ( $try <= 3 ) { # try 3 times with sleeps
		eval {
 			$exp = expire_date( $_ );
		};
		last unless ( $@ or not defined ($exp));
		print "$_: try $try\n" if $debug;
		$try++;
		sleep 15;
	}

	if ( $@ ) {
                print("$domainname: whois error\n");
                push @unwhoised, $domainname;
		next;
	}

	sleep 1;

	if ( defined ($exp)) {
		printf("%s %d-%02d-%02d ",$domainname,$exp->year,$exp->mon,$exp->mday) if $debug;
		if ( $exp < $now ) {
			push @expired, $domainname;
			@expired{$domainname}=$exp;
			print "expired\n" if $debug;
			next;
		} 
                if ( $exp - $warntime < $now ) {
                        push @expiring, $domainname;
			@expiring{$domainname} = $exp;
                        print "expiring\n" if $debug;
			next;
                }
		
		($domaininfo = whois($domainname) ) =~ s/^Last\ updated.*$//m;
		open (F,"> "."cache/$domainname");
		print F $domaininfo;
		close (F);
		
		print "ok\n" if $debug;
	} else {
		print("$_: whois error\n");
		push @unwhoised, $domainname;
	}
}

open(MAIL, "| $mail");

if ( defined(@expiring) ){
	printf(MAIL "Expiring:\n");
	foreach $domain (sort { @expiring{$a} <=> @expiring{$b} } @expiring) {
		printf(MAIL "%s %d-%02d-%02d\n",$domain,@expiring{$domain}->year,
			@expiring{$domain}->mon,@expiring{$domain}->mday);
	}
	printf(MAIL "\n");
}

if ( defined(@expired) ){
	printf(MAIL "Expired:\n");
	foreach $domain (sort { @expired{$a} <=> @expired{$b} } @expired) {
		printf(MAIL "%s %d-%02d-%02d\n",$domain,@expired{$domain}->year,
                        @expired{$domain}->mon,@expired{$domain}->mday);
	}
	printf(MAIL "\n");
}

if ( defined(@unwhoised)) {
	printf(MAIL "Whois error:\n%s", join("\n",@unwhoised));
	print(MAIL "\n\n");
}

close (MAIL);

