use 5.00800;
use ExtUtils::MakeMaker;

WriteMakefile(
    ABSTRACT_FROM     => 'lib/VKCOM/Fetcher.pm',
    AUTHOR            => 'Ali Ramazanov <netspamer@gmail.com>',
    NAME              => 'VKCOM::Fetcher',
    DISTNAME          => 'VKCOM-Fetcher',
    VERSION_FROM      => 'lib/VKCOM/Fetcher.pm',
    EXE_FILES         => [],
    LICENSE           => 'perl',
    PREREQ_PM         => {
        'Any::Moose'         => 0,
        'Carp'               => 0,
        'HTTP::Tiny'         => 0,
        'Try::Tiny'          => 0,
        'JSON'               => 0,
        'File::Spec'         => 0,
        'List::Compare'      => 0,
        'HTML::Entities'     => 0,
        'Fcntl'              => 0,
        'Encode'             => 0,
        'Unicode::Normalize' => 0,
        'Readonly'           => 0,
        'Data::Dumper'       => 0, 
        'strict'             => 0,
        'warnings'           => 0
    },
);
