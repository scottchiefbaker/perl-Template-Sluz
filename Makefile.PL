use 5.016;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Template::Sluz',
    VERSION_FROM => 'lib/Template/Sluz.pm',
    AUTHOR       => 'Scott Baker <scott@perturb.org>',
    LICENSE      => 'gpl_3',
    PREREQ_PM    => {},
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    MIN_PERL_VERSION => '5.016',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/scottchiefbaker/perl-sluz.git',
                web  => 'https://github.com/scottchiefbaker/perl-sluz',
            },
            bugtracker => {
                web => 'https://github.com/scottchiefbaker/perl-sluz/issues',
            },
        },
    },
);

