my $DMESG_CMD  = 'dmesg | tail -50 | grep "I/O error"';

my @DMESG_OUT = qx($DMESG_CMD);
foreach (@DMESG_OUT) {
    if ((/I\/O error/)) {
    $errors{'DMESG'}++;
    $errors_text .= "Dmesg disk IO errors. ";
    last;
    }
}
my $text = join('', @GMIRROR_OUT, "\n\n\n",
                    @MD_OUT, "\n\n\n",
                    @MEGACLI_OUT, "\n\n\n",
                    @MEGARC_OUT);