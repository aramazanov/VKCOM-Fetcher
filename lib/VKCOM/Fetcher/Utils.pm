package VKCOM::Fetcher::Utils;

use strict;
use warnings;

use Carp;
use JSON;
use Try::Tiny;
use List::Compare;
use HTML::Entities;

sub read_dir {
    my ( $dir, $ext ) = @_;

    croak "directory $dir is not existed" 
        unless ( -d $dir );

    my $check_ext = $ext ? sub { 1 } : sub { 
        my $file = shift;
        $_ = $ext;
        return /\Q$file\E$/;
    };

    opendir(my $dh, $dir) || croak "can't opendir $dir: $!";
    my @files = ( 
            #map  { $_ => 1 } 
            grep { !/^\./ && -f "$dir/$_" && &$check_ext($_) } 
            readdir($dh) 
    );

    return $dh, \@files;
}

sub save_file {
    my ( $file, $data, $file_create_mode ) = @_;
    $file_create_mode = oct(666) if !defined($file_create_mode);
 
    # Fast spew, adapted from File::Slurp::write, with unnecessary options removed
    #
    {
        my $write_fh;
        unless ( sysopen( $write_fh, $file, $Store_Flags, $file_create_mode ) )
        {
            croak "write_file '$file' - sysopen: $!";
        }
        my $size_left = length($data);
        my $offset    = 0;
        do {
            my $write_cnt = syswrite( $write_fh, $data, $size_left, $offset );
            unless ( defined $write_cnt ) {
                croak "write_file '$file' - syswrite: $!";
            }
            $size_left -= $write_cnt;
            $offset += $write_cnt;
        } while ( $size_left > 0 );
    }
}


sub decode_json {
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

    my @result = ();
    my $lc = List::Compare->new( $list_1, $list_2 );
    if ( $how eq 'symdiff' )
    {
        @result = $lc->get_symdiff();
    }
    else
    {
        croak "incorrect compare method: $how";
    }
    
    return \@result;
}

1;
