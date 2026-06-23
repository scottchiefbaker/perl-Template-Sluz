#!/usr/bin/env perl
use strict;
use warnings;
use 5.016;

use File::Basename qw(dirname);
use lib dirname(__FILE__) . '/../lib';
use Template::Sluz;

use Test::More;

# -------------------------------------------------------------------
# Setup
# -------------------------------------------------------------------
my $sluz = Template::Sluz->new();
$sluz->assign('array' => ['one', 'two', 'three']);

# -------------------------------------------------------------------
# Test helper
# -------------------------------------------------------------------
sub sluz_test {
    my ($input, $expected, $name) = @_;

    my $got = $sluz->parse_string($input);

    my $is_regex;
    if ($expected =~ m|^/(.+)/$|) {
        $is_regex = 1;
    } else {
        $is_regex = 0;
    }

    if ($is_regex) {
        my $pat = $1;
        if ($got =~ /$pat/) {
            pass($name);
        } else {
            fail("$name -- expected pattern $expected, got " . explain($got));
        }
    } else {
        is($got, $expected, $name);
    }
}

# -------------------------------------------------------------------
# Comment tests
# -------------------------------------------------------------------
sluz_test('{* Comment *}'                       , '', 'Comment #1 - With text');
sluz_test('{* ********* *}'                     , '', 'Comment #2 - ******');
sluz_test('{**}'                                , '', 'Comment #3 - No whitespace');
sluz_test('{*{$array|count}*}'                  , '', 'Comment #4 - Variable inside');
sluz_test('{* {* nested *} *}'                  , '', 'Comment #5 - Nested');
sluz_test('{* {* {* nested *} *} *}'            , '', 'Comment #6 - Triple Nested');
sluz_test('{* {* {* {* nested *} *} *} *}'      , '', 'Comment #7 - 4-level nested');
sluz_test('{* {* {* {* {* nested *} *} *} *} *}', '', 'Comment #8 - 5-level nested (max depth)');

done_testing();
