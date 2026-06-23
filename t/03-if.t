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
$sluz->assign('debug'   => 1);
$sluz->assign('first'   => 'Scott');
$sluz->assign('last'    => 'Baker');
$sluz->assign('x'       => '7');
$sluz->assign('y'       => [2, 4, 6]);
$sluz->assign('null'    => undef);
$sluz->assign('number'  => 15);
$sluz->assign('key'     => 'val');
$sluz->assign('zero'    => 0);
$sluz->assign('array'   => ['one', 'two', 'three']);
$sluz->assign('true'    => 1);
$sluz->assign('conf'    => {main => 1, debug => 0});
$sluz->assign('cust'    => {first => 'Scott', last => 'Baker'});

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
# If tests
# -------------------------------------------------------------------
sluz_test('{if $debug}DEBUG{/if}'                                                 , 'DEBUG'   , 'If #1 - Simple');
sluz_test('{if $bogus_var}DEBUG{/if}'                                             , ''        , 'If #2 - Missing var');
sluz_test('{if $debug}{$first}{/if}'                                              , 'Scott'   , 'If #3 - Variable as payload');
sluz_test('{if $debug}{if $debug}FOO{/if}{/if}'                                   , 'FOO'     , 'If #4 - Nested');
sluz_test('{if $x}{if $null}yes{else}no{/if}{/if}'                                , 'no'      , 'If #5 - Nested with else');
sluz_test('{if $one}{if $name}Yes{else}No{/if}{else}Unknown{/if}'                 , 'Unknown' , 'If #6 - Nested with two elses');
sluz_test('{if $bogus_var}YES{else}NO{/if}'                                       , 'NO'      , 'If #7 - Else');
sluz_test('{if $cust.first}{$cust.first}{/if}'                                    , 'Scott'   , 'If #8 - Hash lookup');
sluz_test('{if $number > 10}GREATER{/if}'                                         , 'GREATER' , 'If #9 - Comparison');
sluz_test('{if $bogus_var || $key}KEY{/if}'                                       , 'KEY'     , 'If #10 - ||');
sluz_test('{if $number == 15 && $debug}YES{/if}'                                  , 'YES'     , 'If #11 - Two comparisons');
sluz_test('{if !$verbose}QUIET{/if}'                                              , 'QUIET'   , 'If #12 - Negated comparison');
sluz_test('{if ($zero || $number > 10)}YES{/if}'                                  , 'YES'     , 'If #13 - Parens');
sluz_test('{if count($array) > 2}YES{/if}'                                        , 'YES'     , 'If #14 - PHP function conditional');
sluz_test('{if $debug}{$key}{$last}{/if}'                                         , 'valBaker', 'If #15 - Two block payload');
sluz_test('{if $debug}ONE{else}TWO{/if}'                                          , 'ONE'     , 'If #16 - Else not needed');
sluz_test('{if $zero}1{elseif $debug}2{else}3{/if}'                               , '2'       , 'If #17 - Elseif');
sluz_test('{if $key}{if $one}one{elseif $x}X{else}ELSE{/if}{/if}'                 , 'X'       , 'If #18 - Nested if with elseif');
sluz_test('{if $number}1{if $key}2{/if}3{/if}'                                    , '123'     , 'If #19 - Nested if leading/trailing chars');
sluz_test('{if $true}123{else}456{/if}'                                           , '123'     , 'If #20 - Boolean');
sluz_test('{if !$true}123{else}456{/if}'                                          , '456'     , 'If #21 - Boolean inverted');
sluz_test('{if $conf.main}123{else}456{/if}'                                      , '123'     , 'If #22 - Hash boolean');
sluz_test('{if !$conf.main}123{else}456{/if}'                                     , '456'     , 'If #23 - Hash boolean inverted');
sluz_test('{if $x}{if $y}yes{/if}{else}no{/if}'                                   , 'yes'     , 'If #24 - Nested if with an else');
sluz_test('{if true}a{else}b{if true}c{/if}{/if}'                                 , 'a'       , 'If #25 - Nested with true');
sluz_test('{if false}a{else}b{if true}c{/if}{/if}'                                , 'bc'      , 'If #26 - Nested with false');
sluz_test('{if true}{/if}'                                                        , ''        , 'If #27 - If with "" for payload');
sluz_test('{if $bogus_var}a{elseif $debug}b{elseif $true}c{else}d{/if}'           , 'b'       , 'If #28 - Multiple elseif (first match)');
sluz_test('{if $bogus_var}a{elseif $bogus_var2}b{elseif $true}c{else}d{/if}'      , 'c'       , 'If #29 - Multiple elseif (second match)');
sluz_test('{if $bogus_var}a{elseif $bogus_var2}b{elseif $bogus_var3}c{else}d{/if}', 'd'       , 'If #30 - Multiple elseif (all false, else)');

done_testing();
