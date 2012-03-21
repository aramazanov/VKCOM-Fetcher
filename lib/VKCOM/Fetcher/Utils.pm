package VKCOM::Fetcher::Utils;

use strict;
use warnings;

use Carp;
use JSON;
use File::Spec;
use Try::Tiny;
use List::Compare;
use HTML::Entities;
use Fcntl qw( :DEFAULT ); 
use Encode;
use Unicode::Normalize; 

use base qw(Exporter);

our @EXPORT = qw(
    do_canonpath
    read_dir
    write_file
    json_decode
    compare_list
    html_decode
    transform_string
);

### < FILESYSTEM FUNCTIONS > ###
#################################

sub STORE_FLAGS { O_WRONLY | O_CREAT | O_BINARY }

sub do_canonpath {
    my $path = shift;

    defined $path or
        croak('path not specified');
    
    return File::Spec->canonpath( $path ) ;
}

sub read_dir {
    my ( $dir, $ext ) = @_;

    croak("directory $dir is not existed") 
        unless ( -d $dir );

    my $check_ext = $ext ? 
    sub { 
        my $file = shift;
        $_ = $file;
        return /\Q$ext\E$/;
    } : 
    sub { 1 };

    opendir(my $dh, $dir) || croak("can't opendir $dir: $!");
    my @files = (
        grep { !/^\./ && -f "$dir/$_" && &$check_ext($_) } 
        readdir($dh) 
    );

    return \@files;
}

sub write_file {
    my ( $storage, $file, $data, $debug, $file_create_mode ) = @_;
    $file_create_mode = oct(666) if !defined($file_create_mode);

    my ( $volume, $path ) = File::Spec->splitpath( $storage, 1 );
    my $full_path = File::Spec->catpath( $volume, $path, $file );

    print "$full_path ... " if $debug;
    
    my $fh;
    unless ( sysopen( $fh, $full_path, STORE_FLAGS(), $file_create_mode ) )
    {
        croak("write_file '$full_path' - sysopen: $!");
    }

    my $size_left = length($data);
    my $offset    = 0;
    
    do {
        my $write_cnt = syswrite( $fh, $data, $size_left, $offset );
        unless ( defined $write_cnt ) {
            croak("write_file '$full_path' - syswrite: $!");
        }
        $size_left -= $write_cnt;
        $offset += $write_cnt;
    } while ( $size_left > 0 );

    print "OK\n" if $debug;

    return 1;
}

#################################
#################################

sub json_decode {
    my ( $json ) = @_;
    
    my $decoded_result;
    
    try   { $decoded_result = JSON::decode_json($json) }
    catch { croak("Couldn't decode '$json': $_") };
    
    return $decoded_result;
}

sub compare_list {
    my ( $how, $list_1, $list_2 ) = @_;

    defined $how or 
        croak 'compare method not specified';

    my $lc = List::Compare->new( $list_1, $list_2 );
    my @result = $lc->can($how) ? ( $lc->$how ) :
        croak("incorrect compare method: $how");
    
    return wantarray ? @result : [ @result ];
}

sub html_decode { 
    return HTML::Entities::decode_entities(shift); 
}

sub transform_string {
    my $string = shift;
 
    if ( Encode::is_utf8($string) && $string =~ /[^\x00-\xFF]/ ) {
        $string = Encode::encode( 'utf8', normalize_string( $string )  );
    }
 
    return $string;
}

sub normalize_string {
    my $string = shift;
    
    if ($string) {
        $string = Unicode::Normalize::NFD($string);
    }

    return $string;
}

1;
