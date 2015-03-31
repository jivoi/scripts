#!/usr/local/bin/perl -w

use IO::Socket;
use Net::hostent;
use Sys::Syslog;
use File::Pid;

$pidFile  = "/tmp/block_daemon.pid";
$denyconf = "/usr/local/etc/nginx/blocked.conf";

$pid = fork();
if($pid) {
    exit(0);
}

$pidfile = File::Pid->new( { file => $pidFile, } );
$pidfile->write or die "Can't write PID file, /dev/null: $!";

$server = new IO::Socket::INET ( LocalPort => '7070', Proto => 'tcp', Listen => 1, Reuse => 1,  );
die "Could not create socket: $!\n" unless $server;
 while ($client = $server->accept()) {
   $client->autoflush(1);
   print $client "200 Welcome to $0\n";
   $hostinfo = gethostbyaddr($client->peeraddr);
   while ( <$client>) {
     next unless /\S/;       # blank line
     if    (/quit|exit/i)    { last;                                     }
     elsif (/date|time/i)    { printf $client "200 %s\n", scalar localtime;  }
     elsif (/commit MEDVED/i) {
    system("nginx -t -q && killall -1 nginx"); 
    syslog("security|notice", "COMMIT from %s\n", $hostinfo->name || $client->peerhost);
     }
     elsif (/commit/i){ printf $client "421 try again\n",  }
     elsif (/clear/i) {
        open FILE, ">", $denyconf or die $!;
        printf FILE "";
        close FILE;
    syslog("security|notice", "CLEAR from %s\n", $hostinfo->name || $client->peerhost);
     }
     elsif (m/^(?:(?:25[0-5]|2[0-4]\d|[01]?\d\d?)\.){3}(?:25[0-5]|2[0-4]\d|[01]?\d\d?) PREVED$/) {
    open FILE, ">>", $denyconf or die $!;
    chomp;
    s/PREVED//g;
    printf FILE "deny %s;\n", $_;
    close FILE;
    syslog("security|notice", "%s from %s\n", $_, $hostinfo->name || $client->peerhost);
     }
     else {
       print $client "301 Commands: {clear|commit|quit}\n";
     }
   } continue {
      print $client "220 Ready\n";
   }
   close $client;
 }  

