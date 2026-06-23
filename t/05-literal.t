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
# Literal tests
# -------------------------------------------------------------------
sluz_test('{literal}{{/literal}'                  , '{'                  , 'Literal #1 - {');
sluz_test('{literal}}{/literal}'                  , '}'                  , 'Literal #2 - }');
sluz_test('{literal}{}{/literal}'                 , '{}'                 , 'Literal #3 - Literal + {}');
sluz_test('{literal}{foreach}{/literal}'          , '{foreach}'          , 'Literal #4 - {literal}');
sluz_test('{literal}{literal}{/literal}{/literal}', '{literal}{/literal}', 'Literal #5 - Meta literal');
sluz_test(' { '                                   , ' { '                , 'Literal #6 - { with whitespace');
sluz_test('{}'                                    , '{}'                 , 'Literal #7 - Raw {}');

done_testing();
