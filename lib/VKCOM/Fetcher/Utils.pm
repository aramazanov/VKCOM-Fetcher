package VKCOM::Fetcher::Utils;

use strict;
use warnings;

use Carp;
use JSON;
use Try::Tiny;
use List::Compare;
use HTML::Entities;
use Fcntl qw( :DEFAULT ); 

use base qw(Exporter);

our @EXPORT = qw(
    read_dir
    write_file
    json_decode
    compare_list
    html_decode
);

sub STORE_FLAGS { O_WRONLY | O_CREAT | O_BINARY }

sub read_dir {
    my ( $dir, $ext ) = @_;

    croak("directory $dir is not existed") 
        unless ( -d $dir );

    my $check_ext = $ext ? sub { 1 } : sub { 
        my $file = shift;
        $_ = $ext;
        return /\Q$file\E$/;
    };

    opendir(my $dh, $dir) || croak "can't opendir $dir: $!";
    my @files = ( 
        grep { !/^\./ && -f "$dir/$_" && &$check_ext($_) } 
        readdir($dh) 
    );

    return $dh, \@files;
}

sub write_file {
    my ( $file, $data, $file_create_mode ) = @_;
    $file_create_mode = oct(666) if !defined($file_create_mode);
    
    my $fh;
    unless ( sysopen( $fh, $file, STORE_FLAGS(), $file_create_mode ) )
    {
        croak "write_file '$file' - sysopen: $!";
    }
    my $size_left = length($data);
    my $offset    = 0;
    do {
        my $write_cnt = syswrite( $fh, $data, $size_left, $offset );
        unless ( defined $write_cnt ) {
            croak "write_file '$file' - syswrite: $!";
        }
        $size_left -= $write_cnt;
        $offset += $write_cnt;
    } while ( $size_left > 0 );

    return 1;
}

sub json_decode {
    my ( $json ) = @_;
    
    my $decoded_result;
    
    try   { $decoded_result = JSON::decode_json($json) }
    catch { croak "Couldn't decode '$json': $_" };
    
    return $decoded_result;
}

sub compare_list {
    my ( $how, $list_1, $list_2 ) = @_;

    defined $how or 
        croak 'compare method not specified';

    my $lc = List::Compare->new( $list_1, $list_2 );

    my @result = $lc->can($how) ? ( $lc->$how ) :
        croak "incorrect compare method: $how";
    
    return wantarray ? @result : [ @result ];
}

sub html_decode { 
    return HTML::Entities::decode_entities(shift); 
}

1;
