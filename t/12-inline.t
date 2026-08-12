use strict;
use warnings;
use Test::More;
use FindBin;
require "$FindBin::Bin/test_setup.pl";

use File::Temp qw(tempfile);

# Build the marker dynamically so the source above the real data section
# contains no literal marker string (index() finds the FIRST occurrence).
my $MARKER = '__DA' . 'TA__';

my $sluz = setup_sluz();

# -------------------------------------------------------------------
# Inline data-section content via fetch()
# -------------------------------------------------------------------
my $out = $sluz->fetch();
like($out, qr/Hello inline Scott Baker!/, 'Inline #1 - fetch() renders its own data section');

my $f = $sluz->{perl_file};
ok($f, 'Inline #2 - perl_file resolved');

my $line_no = 1;
{
    open my $fh2, '<', $f or die "Cannot open $f: $!";
    while (<$fh2>) {
        last if /^\Q$MARKER\E\s*$/;
        $line_no++;
    }
    close $fh2;
}
is($sluz->{tpl_line_offset}, $line_no, 'Inline #3 - line offset matches marker line number');

# -------------------------------------------------------------------
# Direct _get_inline_content unit tests
# -------------------------------------------------------------------
my ($fh, $path);

# LF file
($fh, $path) = tempfile();
print $fh "#!/usr/bin/perl\nmy \@x = 1;\n$MARKER\nline one\nline two\n";
close $fh;
my ($content, $line_offset) = $sluz->_get_inline_content($path);
is($content, "line one\nline two\n", 'LF #1 - content extracted');
is($line_offset, 3, 'LF #2 - line offset counts marker line');

# CRLF file
($fh, $path) = tempfile();
print $fh "#!/usr/bin/perl\nmy \@x = 1;\n$MARKER\r\nline one\r\nline two\r\n";
close $fh;
($content, $line_offset) = $sluz->_get_inline_content($path);
is($content, "line one\r\nline two\r\n", 'CRLF #1 - content starts clean (no stray newline)');
is($line_offset, 3, 'CRLF #2 - line offset counts marker line');

# Marker at EOF with no trailing newline
($fh, $path) = tempfile();
print $fh "a\n${MARKER}tail only";
close $fh;
($content, $line_offset) = $sluz->_get_inline_content($path);
is($content, '', 'EOF #1 - no newline after marker, empty content');
is($line_offset, 1, 'EOF #2 - offset counts newlines before data (none after marker)');

# No marker section
($fh, $path) = tempfile();
print $fh "no data section here\n";
close $fh;
is($sluz->_get_inline_content($path), undef, 'NoData #1 - no marker returns undef');
ok(!exists $sluz->{_inline_cache}{$path}, 'NoData #2 - undef not cached');

# -------------------------------------------------------------------
# Cache behavior
# -------------------------------------------------------------------
ok(exists $sluz->{_inline_cache}{$f}, 'Cache #1 - inline content cached by file');

my ($c1, $o1) = $sluz->_get_inline_content($f);
my ($c2, $o2) = $sluz->_get_inline_content($f);
is($c1, $c2, 'Cache #2 - repeated calls return same content');
is($o1, $o2, 'Cache #3 - repeated calls return same offset');
is($sluz->fetch(), $out, 'Cache #4 - repeated fetch() renders identical output');

done_testing();

__DATA__
Hello inline {$first} {$last}!
