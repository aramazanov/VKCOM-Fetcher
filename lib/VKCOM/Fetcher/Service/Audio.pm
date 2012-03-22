package VKCOM::Fetcher::Service::Audio;

use Any::Moose 'Role';
use VKCOM::Fetcher::Utils;

use Readonly;
use Carp;

Readonly our $HTTP_METHOD_NAME => 'audio.get';
Readonly our $FILE_EXTENSION   => 'mp3';

sub fetchAudio {
    my $self = shift;
    my (%opts) = @_;
    my $storage = $opts{'storage'} or
        croak('storage not specified');
    my $debug = $opts{'debug'} ? 1 : 0;
    my $rewrite = $opts{'rewrite'} ? 1 : 0;

    $storage = do_canonpath($storage);

    my $struct = json_decode( 
        $self->fetch( 1, "method/$HTTP_METHOD_NAME" ) 
    );

    $self->check_vk_api_response( $struct );

    my $vk_audio = {}; 
    for my $audio ( @{$struct->{'response'}} ) {
        my $audio_name = sprintf(
                '%s - %s.%s', 
                $audio->{'artist'}, 
                $audio->{'title'}, 
                $FILE_EXTENSION 
        );
        $audio_name = html_decode( transform_string( $audio_name ) ); 
        $vk_audio->{$audio_name} = $audio->{'url'};
    }

    if ( keys( %$vk_audio ) ) {
        my @new_audio = $rewrite ?
            ( keys( %$vk_audio ) ) : 
            ( compare_list( 'get_symdiff', [ keys %$vk_audio ], read_dir( $storage, $FILE_EXTENSION ) ) );

        # files was removed from your playlist in vk.com
        my @audio_removed_from_vk;
        for (0 .. $#new_audio) 
        {
            my $audio_name = $new_audio[$_];
            push @audio_removed_from_vk, delete $new_audio[$_] if !exists($vk_audio->{$audio_name});
        }

        @new_audio = grep { defined $_ } @new_audio;
        my $count_new_audio = scalar(@new_audio);
        print $count_new_audio . " audio found" .
            ( $rewrite ? " with flag 'rewrite'" : " without flag 'rewrite'" ) . 
                ( $count_new_audio ? ", trying to write:\n" : "\n" ) if $debug;

        for my $audio_name ( @new_audio ) {
            my $url = $vk_audio->{$audio_name};
            my $binary_data = $self->fetch( 0, $url );

            write_file(
                $storage,
                $audio_name, 
                $binary_data,
                $debug
            );
        }
    } elsif ( $debug ) {
        print "no audio in your playlist\n";
    }
}

1;
