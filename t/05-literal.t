#!/usr/bin/env perl
use strict;
use warnings;
use 5.016;

use Test::More;
use FindBin;
require "$FindBin::Bin/test_setup.pl";

my $sluz = setup_sluz();

# -------------------------------------------------------------------
# Literal tests
# -------------------------------------------------------------------
sluz_test($sluz, '{literal}{{/literal}'                  , '{'                  , 'Literal #1 - {');
sluz_test($sluz, '{literal}}{/literal}'                  , '}'                  , 'Literal #2 - }');
sluz_test($sluz, '{literal}{}{/literal}'                 , '{}'                 , 'Literal #3 - Literal + {}');
sluz_test($sluz, '{literal}{foreach}{/literal}'          , '{foreach}'          , 'Literal #4 - {literal}');
sluz_test($sluz, '{literal}{literal}{/literal}{/literal}', '{literal}{/literal}', 'Literal #5 - Meta literal');
sluz_test($sluz, "{literal}\nfoo\n{/literal}"            , "foo"                , 'Literal #6 - lone-line strips newline');
sluz_test($sluz, "{literal}\nfoo\nbar\n{/literal}"       , "foo\nbar"           , 'Literal #7 - internal newline preserved');
sluz_test($sluz, "{literal}\nfoo{/literal}"              , "foo"                , 'Literal #8 - only open tag on its own line');
sluz_test($sluz, "{literal}foo\n{/literal}"              , "foo"                , 'Literal #9 - only close tag on its own line');
sluz_test($sluz, "x{literal}\nfoo\n{/literal}"           , "x\nfoo"             , 'Literal #10 - inline open keeps \n, close alone strips');
sluz_test($sluz, "{literal}\nfoo\n{/literal}y"           , "foo\ny"             , 'Literal #11 - open alone strips, inline close keeps \n');
sluz_test($sluz, ' { '                                   , ' { '                , 'Literal #12 - { with whitespace');
sluz_test($sluz, '{}'                                    , '{}'                 , 'Literal #13 - Raw {}');

done_testing();
