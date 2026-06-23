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
$sluz->assign('x'       => '7');
$sluz->assign('y'       => [2, 4, 6]);
$sluz->assign('first'   => 'Scott');
$sluz->assign('array'   => ['one', 'two', 'three']);
$sluz->assign('members' => [{first => 'Scott', last => 'Baker'}, {first => 'Jason', last => 'Doolis'}]);
$sluz->assign('arrayd'  => [[1, 2], [3, 4], [5, 6]]);
$sluz->assign('subarr'  => {one => [2, 4, 6], two => [3, 6, 9]});
$sluz->assign('empty'   => []);
$sluz->assign('null'    => undef);
$sluz->assign('colors'  => {a => 'red', b => 'green', c => 'blue'});
$sluz->assign('scores'  => {math => 95, science => 88, art => 76});

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
# Foreach tests
# -------------------------------------------------------------------
sluz_test('{foreach $array as $num}{$num}{/foreach}'                         , 'onetwothree'      , 'Foreach #1 - Simple');
sluz_test("{foreach \$array as \$num}\n{\$num}\n{/foreach}"                  , "one\ntwo\nthree\n", 'Foreach #2 - Simple with whitespace');
sluz_test('{foreach $members as $x}{$x.first}{/foreach}'                     , 'ScottJason'       , 'Foreach #3 - Hash');
sluz_test('{foreach $arrayd as $x}{$x.1}{/foreach}'                          , '246'              , 'Foreach #4 - Array');
sluz_test('{foreach $arrayd as $key => $val}{$key}:{$val.0}{/foreach}'       , '0:11:32:5'        , 'Foreach #6 - Key/val array');
sluz_test('{foreach $members as $id => $x}{$id}{$x.first}{/foreach}'         , '0Scott1Jason'     , 'Foreach #7 - Key/val hash');
sluz_test('{foreach $subarr.one as $id}{$id}{/foreach}'                      , '246'              , 'Foreach #8 - Hash key');
sluz_test('{foreach $bogus_var as $x}one{/foreach}'                          , ''                 , 'Foreach #9 - Missing var');
sluz_test('{foreach $empty as $x}one{/foreach}'                              , ''                 , 'Foreach #10 - Empty array');
sluz_test('{foreach $array as $i => $x}{$i}{$x}{/foreach}'                   , '0one1two2three'   , 'Foreach #11 - One char variables');
sluz_test('{foreach $array as $i => $x}{if $x}{$x}{/if}{/foreach}'           , 'onetwothree'      , 'Foreach #12 - Foreach with nested if');
sluz_test('{foreach $arrayd as $i => $x}{if $x.1}{$x.1}{/if}{/foreach}'      , '246'              , 'Foreach #13 - Foreach with nested if (array)');
sluz_test('{foreach $null as $x}one{/foreach}'                               , ''                 , 'Foreach #14 - Null');
sluz_test('{foreach $first as $x}{$first}{/foreach}'                         , 'Scott'            , 'Foreach #15 - Scalar');
sluz_test('{foreach $array as $i}{foreach $array as $i}x{/foreach}{/foreach}', 'xxxxxxxxx'        , 'Foreach #16 - Nested');

# Foreach variable persistence tests
sluz_test('{$x}', '7', 'Foreach #17 - NOT overwrite variable - previously set');
sluz_test('{$i}', '' , 'Foreach #18 - NOT overwrite variable - no initial value');

sluz_test('{foreach $y as $z}{$z}{/foreach}'                                   , '246'                  , 'Foreach #19 - Foreach one char key');
sluz_test('{foreach $array as $x}{if $__FOREACH_FIRST}FIRST{/if}{$x}{/foreach}', 'FIRSTonetwothree'     , 'Foreach #20 - Foreach FIRST item');
sluz_test('{foreach $array as $x}{$x}{if $__FOREACH_LAST}LAST{/if}{/foreach}'  , 'onetwothreeLAST'      , 'Foreach #21 - Foreach LAST item');
sluz_test('{foreach $array as $x}{$x}{$__FOREACH_INDEX}{/foreach}'             , 'one0two1three2'       , 'Foreach #22 - Foreach index');
sluz_test('{foreach $colors as $k => $v}{$k}:{$v} {/foreach}'                  , 'a:red b:green c:blue ', 'Foreach #23 - Hashref iteration with key/val (sorted)');
sluz_test('{foreach $scores as $val}{$val} {/foreach}'                         , '76 95 88 '            , 'Foreach #24 - Hashref iteration value only (sorted)');
sluz_test('{foreach $empty as $k => $v}val{/foreach}'                          , ''                     , 'Foreach #25 - Empty array with key/val');
sluz_test('{foreach $members as $i => $m}{$i}:{$m.first} {/foreach}'           , '0:Scott 1:Jason '     , 'Foreach #26 - Array of hashes with key/val');

done_testing();
