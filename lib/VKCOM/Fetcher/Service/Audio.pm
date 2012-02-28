package VKCOM::Fetcher::Service::Audio;

use Any::Moose 'Role';
use VKCOM::Fetcher::Utils;

use Carp;

sub http_method_name { 'audio.get' }
sub file_extension   { 'mp3' }

sub fetchAudio {
    my $self = shift;
    my (%opts) = @_;
    my $storage = $opts{'storage'} or
        croak('storage not specified');

    my $method_name = http_method_name();
    my $ext    = file_extension();
    
    my ( $dh, $storage_songs ) = read_dir( $storage, $ext );

    my $struct = json_decode( 
        $self->fetch( 1, "method/$method_name" ) 
    );

    my $vk_songs = {}; 
    for my $song ( @{$struct->{response}} ) {
        my $song_name = sprintf(
                '%s - %s.%s', 
                html_decode( $song->{artist} ), 
                html_decode( $song->{title}  ), 
                $ext 
        );
        $vk_songs->{$song_name} = $song->{url};
    }

    if ( keys( %$vk_songs ) ) {
        my @new_songs = $opts{'rewrite'} ? ( keys( %$vk_songs ) ) : 
            ( compare_list( 'get_symdiff', [ keys %$vk_songs ], $storage_songs ) );
               
        for my $song_name ( @new_songs ) {
            my $url = $vk_songs->{$song_name};
            write_file(
                "$storage/$song_name", 
                $self->fetch( 0, $url )
            )
            or carp("can't write file: $storage/$song_name");
        }
    }
}

1;
