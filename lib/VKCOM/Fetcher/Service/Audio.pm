package VKCOM::Fetcher::Service::Audio;

use Any::Moose 'Role';
use VKCOM::Fetcher::Utils;

use Carp;

sub http_method    { 'audio.get' }
sub file_extension { 'mp3' }

sub audio {
    my $self = shift;
    my ($storage, %opts) = @_;

    my $method = http_method();
    my $ext = file_extension();
    
    defined $storage or croak 'dir not specified';
    my ($dh, $local_songs) = read_dir($storage, $ext);

    my $struct = decode_json( $self->fetch(1, "method/$method") );

    my @vk_songs = {}; 
    for my $song ( @{$struct->{response}} )
    {
        my $artist = decode_entities($song->{artist});
        my $title = decode_entities($song->{title});

        my $song_name = sprintf('%s - %s.%s', $artist, $title, $ext);
        $vk_songs->{$song_name} = $song->{url};
    }

    my @new_songs = compare_list('symdiff', [ keys %$vk_songs ], $local_songs);
   
    for my $song_name ( @new_songs )
    {
        save_file($storage, $song_name, $self->fetch(0, $vk->{$song_name}));
    }
}

1;
