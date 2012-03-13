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

    $storage = do_canonpath($storage);

    my $method_name = http_method_name();
    my $ext = file_extension();

    my $struct = json_decode( 
        $self->fetch( 1, "method/$method_name" ) 
    );

    my $vk_songs = {}; 
    for my $song ( @{$struct->{response}} ) {
        my $song_name = sprintf(
                '%s - %s.%s', 
                $song->{artist}, 
                $song->{title}, 
                $ext 
        );
        $song_name = html_decode( transform_string( $song_name ) ); 
        $vk_songs->{$song_name} = $song->{url};
    }

    if ( keys( %$vk_songs ) ) {
        my @new_songs = $opts{'rewrite'} ?
            ( keys( %$vk_songs ) ) : 
            ( compare_list( 'get_symdiff', [ keys %$vk_songs ], read_dir( $storage, $ext ) ) );

        for my $song_name ( @new_songs ) {
            my $url = $vk_songs->{$song_name};
            my $binary_data = $self->fetch( 0, $url );

            write_file(
                $storage,
                $song_name, 
                $binary_data
            )
            or carp("can't write file: $storage/$song_name");
        }
    }
}

1;
