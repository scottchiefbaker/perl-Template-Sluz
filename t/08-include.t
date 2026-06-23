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
$sluz->assign('inc_file' => 'tpls/extra.stpl');
$sluz->assign('number'   => 15);
$sluz->{perl_file_dir} = dirname(__FILE__);

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
# Include tests
# -------------------------------------------------------------------
sluz_test("{include file='tpls/extra.stpl'}", '/e1ab49cf/', 'Include #1 - file=extra.stpl');
sluz_test("{include 'tpls/extra.stpl'}"     , '/e1ab49cf/', "Include #2 - 'extra.stpl'");

eval { $sluz->parse_string('{include}') };
like($@, qr/73467/, 'Include #3 - No payload');

sluz_test("{include file='tpls/extra.stpl' secret='eca4906'}", '/eca4906/' , 'Include #4 - With variable');
sluz_test("{include file=\"\$inc_file\"}"                    , '/e1ab49cf/', 'Include #5 - With variable file path');
sluz_test("{include file='tpls/nested_inc.stpl'}"            , '/e1ab49cf/', 'Include #6 - Nested include');
sluz_test("{include file='tpls/var_scope.stpl'}"             , '/SCOPE:15/', 'Include #7 - Variable scope (parent vars visible)');

done_testing();
