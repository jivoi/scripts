#!bash

TMPDIR=$1

if [ -x /usr/bin/wget ]; then
	wget -q --timeout=30 --no-check-certificate -O users-whitelist.txt https://mnt.example.ru/pub/${TMPDIR}/users-whitelist.txt
else
	fetch -q -T 30 https://mnt.relax.ru/pub/${TMPDIR}/users-whitelist.txt
fi


RE_FILTER='^([-a-z0-9_\.]+:(\*:|\!:|\!\!:|\!\$1\$|\*LOCKED\*)|#)'

if [[ "`uname`" == 'Linux' ]]; then
	PASSWD=/etc/shadow
else
	PASSWD=/etc/master.passwd
fi

# Checking passwords
cat ./users-whitelist.txt | cut -d ':' -f 1 > ./users-whitelist-logins.txt
sudo cat ${PASSWD} | grep -v -f ./users-whitelist-logins.txt | egrep -i -v "${RE_FILTER}"
rm -f ./users-whitelist-logins.txt

# 1. More than one login.
# 2. GID of 0.
# 3. authorized_keys

# Checking other data
cat <<'EOP' | perl
	use strict;
	use Data::Dumper;

	my (%white, %passwd, %shadow);

	open(FH, '< users-whitelist.txt') or die('Cannot open ./users-whitelist.txt.');
	while (<FH>) { chomp(); @{$white{substr($_, 0, index($_, ':'))}} = split(':'); }
	close(FH);

	my $passwd_re = qr/^([-a-z0-9_\.]+:(\*:|\!:|x:|\!\!:|\!\$1\$|\*LOCKED\*)|#)/;

	# Reading passwords
	my ($pwfile);
	if (-r '/etc/master.passwd') { $pwfile = '/etc/master.passwd'; }
	elsif (-r '/etc/shadow') { $pwfile = '/etc/shadow'; }
	if (-r $pwfile) {
		open(FH, '<', $pwfile) or die('Cannot open ${pwfile}.');
		while (<FH>) {
			chomp();
			if ($_ =~ /^#/) { next(); }
			@{$shadow{substr($_, 0, index($_, ':'))}} = split(':');
		}
		close(FH);
	}

	open(FH, '< /etc/passwd') or die('Cannot open /etc/passwd.');
	while (<FH>) {
		chomp();
		my $line = $_;
		if ($line =~ /^#/) { next(); }
		my ($login, $passwd, $uid, $gid, $comment, $home, $shell) = split(':', $line);
		if ($shadow{$login} =~ $passwd_re && ! -f "~$login/.ssh/authorized_keys") {
			print "Shadow line:\n$shadow{$login}\n";
			# TODO: check if user home exists and have authorized_keys
			next();
		}

		# TODO: delete this
		if ($uid < 500) { next(); }

		$passwd{$login} = $line;

		if ($login eq 'nobody') { next(); }

		my $wgid = $white{$login}[1];
		my $wcomment = $white{$login}[2];

		if ($wcomment && $comment ne $wcomment) {
			print "Real name of ${login} is ${comment}; must be ${wcomment}:"
				. "\n" . $line . "\n";
		}
		if ($wgid != 0 && $home !~ m@^/home/@
			&& $login !~ /ftp/i && $comment !~ /ftp/i
		) {
			print "Home of user ${login} not in /home/:"
				. "\n" . $line . "\n";
		}
		if ($shell =~ /nologin/ && $login !~ /ftp$/i && $comment !~ /ftp/i
			&& $login != 'nfsnobody'
			&& $login != 'wwwpartner' # Must be converted to FTP login
		) {
			print "Shell of not blocked user ${login} is nologin:"
				. "\n" . $line . "\n";
		}

		if ($shell !~ /nologin/ && ($login =~ /ftp/i || $comment =~ /ftp/i)
			&& $login ne 'kards.ru' 
		) {
			print "Shell of FTP user ${login} is not nologin:"
				. "\n" . $line . "\n";
		}

		# nologin && auth
	}
	close(FH);

	foreach (keys %white) { delete($passwd{$_}); }
	foreach (keys %passwd) { print $passwd{$_}; }
EOP

rm -f users-whitelist.txt
