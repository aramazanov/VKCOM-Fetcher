#!/usr/bin/perl

use strict;
use warnings;

use VKCOM::Fetcher;

my $vkfetcher = VKCOM::Fetcher->new( 
    access_token => 'dbe2a38e94eb187edbe9ff6cbddb8e22ebddba4dba4cd34f07829e534c79991', 
    uid => 4615858 
);

$vkfetcher->fetchAudio(
    storage => '/Users/aramazanov/Music/vk'
);
