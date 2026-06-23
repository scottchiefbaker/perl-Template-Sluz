#!/usr/bin/env perl
use strict;
use warnings;
use 5.016;

use File::Basename qw(dirname);
use lib dirname(__FILE__) . '/../lib';
use Template::Sluz;

use Test::More;

# -------------------------------------------------------------------
# Inject test helper functions into Template::Sluz namespace
# (so they're found by the modifier/expression eval machinery)
# -------------------------------------------------------------------
BEGIN {
    no strict 'refs';
    *{'main::truncate'}     = sub { substr($_[0], 0, $_[1]) };
    *{'main::join_comma'}   = sub { my $s = $_[1] // ', '; join $s, @{$_[0]} };
    *{'main::hello_world'}  = sub { "Hello world" };
    *{'main::return_false'} = sub { 0 };
    *{'main::return_null'}  = sub { undef };
}

# -------------------------------------------------------------------
# Setup
# -------------------------------------------------------------------
my $sluz = Template::Sluz->new();
$sluz->assign('x'            => '7');
$sluz->assign('y'            => [2, 4, 6]);
$sluz->assign('key'          => 'val');
$sluz->assign('first'        => 'Scott');
$sluz->assign('last'         => 'Baker');
$sluz->assign('animal'       => 'Kitten');
$sluz->assign('word'         => 'cRaZy');
$sluz->assign('debug'        => 1);
$sluz->assign('array'        => ['one', 'two', 'three']);
$sluz->assign('cust'         => {first => 'Scott', last => 'Baker'});
$sluz->assign('number'       => 15);
$sluz->assign('zero'         => 0);
$sluz->assign('members'      => [{first => 'Scott', last => 'Baker'}, {first => 'Jason', last => 'Doolis'}]);
$sluz->assign('subarr'       => {one => [2, 4, 6], two => [3, 6, 9]});
$sluz->assign('arrayd'       => [[1, 2], [3, 4], [5, 6]]);
$sluz->assign('empty'        => []);
$sluz->assign('empty_string' => '');
$sluz->assign('null'         => undef);
$sluz->assign('true'         => 1);
$sluz->assign('false'        => 0);
$sluz->assign('conf'         => {main => 1, debug => 0});
$sluz->assign('colors', {a => 'red', b => 'green', c => 'blue'});
$sluz->assign('scores', {math => 95, science => 88, art => 76});
$sluz->assign('inc_file', 'tpls/extra.stpl');
$sluz->assign({color => 'yellow', age => 43, book => 'Dark Tower'});

# Assign a raw hash where all the keys live in the root namespace
my %data = (
	car     => 'Honda',
	ltuae   => 42,
	console => 'Nintendo',
	milk    => ['goat', 'cow', 'soy'],
);
$sluz->assign(%data);

$sluz->{perl_file_dir} = dirname(__FILE__);

# -------------------------------------------------------------------
# Test helpers
# -------------------------------------------------------------------
sub sluz_test {
    my ($input, $expected, $name) = @_;

    my $got;
    if (ref $input eq 'ARRAY') {
        my @blocks = $sluz->_get_blocks($input->[0]);
        $got = scalar @blocks;
    } else {
        $got = $sluz->parse_string($input);
    }

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

sub sluz_fetch_test {
    my ($files, $pattern, $name) = @_;

    my $child  = $files->[0];
    my $parent = $files->[1];
    my $str = $sluz->fetch($child, $parent);

    if ($str =~ /$pattern/) {
        pass($name);
    } else {
        fail("$name -- expected $pattern, got " . explain($str));
    }
}

# -------------------------------------------------------------------
# Basic tests
# -------------------------------------------------------------------
sluz_test('Hello there',                             'Hello there',                 'Basic #1 - Static string');
sluz_test('{$first}',                                'Scott',                       'Basic #2 - Basic variable');
sluz_test('{$bogus_var}',                            '',                            'Basic #3 - Missing variable');
sluz_test('{$cust.first}',                           'Scott',                       'Basic #5 - Hash Lookup');
sluz_test('{$array.1}',                              'two',                         'Basic #6 - Array Lookup');
sluz_test('{$array|count}',                          '3',                           'Basic #7 - PHP Modifier array');
sluz_test('{$number + 3}',                           '18',                          'Basic #8 - Addition');
sluz_test('{$number * $debug}',                      '15',                          'Basic #9 - Multiplication of two vars');
sluz_test('{3}',                                     '3',                           'Basic #10 - Number literal');
sluz_test('{"Scott"}',                               'Scott',                       'Basic #11 - String literal');
sluz_test('{$x}',                                    '7',                           'Basic #12 - Single Character variable');
sluz_test('{$array[1]}',                             'two',                         'Basic #13 - Array Lookup - PHP Syntax');
sluz_test('{$cust["last"]}',                         'Baker',                       'Basic #14 - Hash Lookup - PHP Syntax');

# Default values
sluz_test('{$last|default:\'123\'}',                 'Baker',                       'Basic #15 - Default - Not Used');
sluz_test('{$zero|default:\'123\'}',                 '0',                           'Basic #16 - Default - Zero Not Used');
sluz_test('{$empty_string|default:\'123\'}',         '123',                         'Basic #17 - Default - Empty String');
sluz_test('{$null|default:\'123\'}',                 '123',                         'Basic #18 - Default - Null');
sluz_test('{$bogus_var|default:"?*%.|"}',            '?*%.|',                       'Basic #19 - Default - non word char');

# Undefined variables with modifiers
sluz_test('{$bogus_var|join}',                        '',                            'Basic #20 - Undefined var with array modifier');
sluz_test('{$bogus_var|uc}',                          '',                            'Basic #21 - Undefined var with string modifier');
sluz_test('{$bogus_var|count}',                       '',                            'Basic #22 - Undefined var with count modifier');
sluz_test('{$bogus_var|substr:0,2}',                  '',                            'Basic #23 - Undefined var with string modifier with params');

# Error tests (croak via eval)
eval { $sluz->parse_string('{foo') };
like($@, qr/45821/, 'Basic #24 - Unclosed block');

eval { $sluz->parse_string('{$first') };
like($@, qr/45821/, 'Basic #25 - Unclosed block variable');

# Hash with default
sluz_test('{$cust.first|default:\'Jason\'}',         'Scott',                       'Basic #26 - Hash with default value, not used');
sluz_test('{$cust.foo|default:\'Jason\'}',           'Jason',                       'Basic #27 - Hash with default value, used');
sluz_test('{$array}',                                'ARRAY',                       'Basic #28 - Array used as a scalar');
sluz_test('{$first|substr:2}',                       'ott',                         'Basic #29 - PHP function with one param');
sluz_test('{$first|substr:2,2}',                     'ot',                          'Basic #30 - PHP function with two params');

{
    local $TODO = "Negated hash lookup";
    sluz_test('{if !$cust.age}unknown{else}{$age}{/if}', 'unknown',                 'Basic #31 - Negated hash lookup');
}

sluz_test('{1.1234 + 2.3456}', '3.469'       , 'Basic #32 - Simple math that returns floating point');
sluz_test(''                 , ''            , 'Basic #33 - Empty template');
sluz_test(' '                , ' '           , 'Basic #34 - Whitespace only template');
sluz_test('{$bogus_var + 3}' , '3'           , 'Basic #35 - Undefined var in numeric expression');
sluz_test('{!$false}'        , '1'           , 'Basic #36 - Standalone negated expression (false to true)');
sluz_test('{!$true}'         , ''            , 'Basic #37 - Standalone negated expression (true to false)');
sluz_test('{$car}'           , 'Honda'       , 'Basic #38 - String variable set from hash');
sluz_test('{$ltuae}'         , '42'          , 'Basic #39 - Integer variable set from hash');
sluz_test('{$milk|join:":"}' , 'goat:cow:soy', 'Basic #40 - Array set from hash');

# -------------------------------------------------------------------
# Custom/User functions
# -------------------------------------------------------------------
sluz_test('{$word|truncate:3}',                      'cRa',                         'Custom function #1 - Modifier with param');
sluz_test('{$last|truncate:4|truncate:2}',           'Ba',                          'Custom function #2 - Two modifiers with params');
sluz_test('{$y|join_comma}',                         '2, 4, 6',                     'Custom function #3 - Function with default param');

{
    local $TODO = "join_comma with numeric param";
    sluz_test('{$y|join_comma:9}',                   '29496',                       'Custom function #4 - Function with integer param');
}

sluz_test('{$y|join_comma:"*"}',                     '2*4*6',                       'Custom function #5 - Function with string param');
sluz_test('{$y|join_comma:"|"}',                     '2|4|6',                       'Custom function #6 - Function with string param pipe');
sluz_test('{$y|join_comma:","}',                     '2,4,6',                       'Custom function #7 - Function with string param pipe comma');
sluz_test('{$y|join_comma:"\'"}',                    "2'4'6",                       'Custom function #8 - Function with string param pipe single quote');
sluz_test('{$y|join_comma:"; "}',                    "2; 4; 6",                     'Custom function #9 - Function with string param and space');
sluz_test("{\$y|join_comma:\"\t\"}",                 "2\t4\t6",                     'Custom function #10 - Function with string param and tab');

# Built-in join modifier
sluz_test('{$array|join}',                           'one, two, three',             'Built-in join #1 - default glue');
sluz_test('{$array|join:" - "}',                     'one - two - three',           'Built-in join #2 - custom glue');
sluz_test('{$array|join:","}',                       'one,two,three',               'Built-in join #3 - comma glue');

# -------------------------------------------------------------------
# Function blocks
# -------------------------------------------------------------------
sluz_test('{hello_world()}',                         'Hello world',                 'Function #1 - Hello world');

is($sluz->parse_string('{return_false()}'), '0', 'Function #2 - Return false');

eval { $sluz->parse_string('{return_null()}') };
like($@, qr/18933/, 'Function #3 - Return null');

# -------------------------------------------------------------------
# Error blocks
# -------------------------------------------------------------------
eval { $sluz->parse_string('{junk}') };
like($@, qr/73467/, 'Error #1 - bare string');

eval { $sluz->parse_string('{junk(') };
like($@, qr/45821/, "Error #2 - string with action char");

eval { $sluz->parse_string('{$number + array}') };
like($@, qr/18933/, 'Error #3 - syntax error');

eval { $sluz->parse_string('{if debug}') };
like($@, qr/73467/, 'Error #4 - syntax error');

# -------------------------------------------------------------------
# Plain text tests
# -------------------------------------------------------------------
sluz_test('Scott',              'Scott',              'Plain text #1 - Static text');
sluz_test('<div>Scott</div>',   '<div>Scott</div>',   'Plain text #2 - HTML');

# -------------------------------------------------------------------
# Bad block tests
# -------------------------------------------------------------------
sluz_test(' {$first} ',         ' Scott ',            'Bad block #1 - Padding with whitespace');

eval { $sluz->parse_string('{first}') };
like($@, qr/73467/, 'Bad block #2 - {word}');

# -------------------------------------------------------------------
# Whitespace input/output
# -------------------------------------------------------------------
sluz_test("{\$x}{\$x}"                                   , '77'                 , 'Whitespace input/output #1');
sluz_test("{\$x} {\$x}"                                  , '7 7'                , 'Whitespace input/output #2');
sluz_test("{\$x}\n{\$x}"                                 , "7\n7"               , 'Whitespace input/output #3');
sluz_test("{foreach \$y as \$x}{\$x}{/foreach}"          , '246'                , 'Whitespace input/output #4');
sluz_test("{foreach \$y as \$x}\n{\$x}\n{/foreach}"      , "2\n4\n6\n"          , 'Whitespace input/output #5');
sluz_test("{if \$x}{\$x}{/if}"                           , '7'                  , 'Whitespace input/output #6');
sluz_test("{if \$x}\n{\$x}\n{/if}"                       , "7\n"                , 'Whitespace input/output #7');
sluz_test("{foreach \$y as \$x}\n{\$x}\n{/foreach}\nlast", "2\n4\n6\nlast"      , 'Whitespace input/output #8');
sluz_test("{foreach \$array as \$x}{\$x} {/foreach}\nEND", "one two three \nEND", 'Whitespace input/output #9');

# -------------------------------------------------------------------
# Fetch tests
# -------------------------------------------------------------------
sluz_fetch_test(['tpls/extra.stpl'],                qr/extra\.stpl/,            'Fetch #1 - Simple fetch');

{
    my $result = $sluz->fetch('tpls/child.stpl', 'tpls/parent.stpl');
    like($result, qr/Child TPL.*21c1a4c5/s, 'Parent/Child #1 - Fetch with two params');
}

$sluz->parent_tpl('tpls/parent.stpl');
{
    my $result = $sluz->fetch('tpls/child.stpl');
    like($result, qr/Child TPL.*21c1a4c5/s, 'Parent/Child #2 - Fetch with preset parent');
}
$sluz->parent_tpl(undef);
$sluz->{parent_tpl} = undef;

# -------------------------------------------------------------------
# Assign edge cases
# -------------------------------------------------------------------
eval { $sluz->assign('odd_args_test'); };
like($@, qr/#18956/, 'Assign #1 - Odd number of args (no-op)');

eval { $sluz->assign({}); };
is($@, "", 'Assign #2 - Empty hashref (no-op)');

# -------------------------------------------------------------------
# Variable edge cases
# -------------------------------------------------------------------
$sluz->assign('hashref', {nested => {deep => 'found'}});
sluz_test('{$hashref.nested.deep}',               'found',                     'Deep dive #1 - Three-level dotted hash access');
sluz_test('{$bogus_var}',                         '',                          'Deep dive #2 - Undefined variable returns empty');
sluz_test('{$null}',                              '',                          'Deep dive #3 - null variable returns empty');
sluz_test('{$array}',                             'ARRAY',                     'Deep dive #4 - Array returned as scalar');

# -------------------------------------------------------------------
# Error edge cases
# -------------------------------------------------------------------
eval { $sluz->parse_string('{if}') };
like($@, qr/73467/, 'Error #5 - Bare {if} without condition');

done_testing();
