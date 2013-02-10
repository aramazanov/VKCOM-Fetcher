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
        $audio_name =~ s/(\/|\\)/ /g; # temp simple solution for cross-platform
        $vk_audio->{$audio_name} = $audio->{'url'};
    }

    if ( keys( %$vk_audio ) ) {

        my (@new_audio, @audio_removed_from_vk);
        my $storage_audio = { map { $_ => 1 } @{read_dir( $storage, $FILE_EXTENSION )} };
        
        for my $vk_audio_name ( keys %$vk_audio )
        {
            push @new_audio, $vk_audio_name
                if ( ! exists($storage_audio->{$vk_audio_name}) );
        }

        my $count_new_audio = scalar(@new_audio);
        print $count_new_audio . " audio found" .
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
