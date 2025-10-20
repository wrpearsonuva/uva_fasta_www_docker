#!/usr/bin/perl
use strict;
use warnings;
use CGI;

my $cgi = CGI->new;
print $cgi->header('text/html');
print "<html><head><title>FASTA36 Web Interface</title></head><body>";
print "<h2>FASTA36 Web Interface</h2>";

if (my $seq = $cgi->param('sequence')) {
    $seq =~ s/\r//g;         # Remove CR for Windows line endings
    $seq =~ s/^\s+|\s+$//g;  # Trim leading/trailing whitespace
    $seq =~ s/\n+/\n/g;      # Normalize multiple line breaks

    # Ensure FASTA format
    my $fasta = $seq;
    $fasta = ">query\n$seq" unless $seq =~ /^>/;

    open(my $fh, '>', '/tmp/query.fasta') or die "Cannot write temp file: $!";
    print $fh $fasta;
    close($fh);

    print "<h3>Input Sequence:</h3><pre>$fasta</pre>";
    print "<h3>Running FASTA36...</h3><pre>";

    # Run FASTA36 against itself
    my $output = `fasta36 /tmp/query.fasta /tmp/query.fasta 2>&1`;
    print $output;

    print "</pre>";
} else {
    print $cgi->start_form(-method=>'POST');
    print "<textarea name='sequence' rows='10' cols='70' placeholder='Paste sequence here'></textarea><br>";
    print "<input type='submit' value='Run FASTA36'>";
    print $cgi->end_form;
}

print "</body></html>";
