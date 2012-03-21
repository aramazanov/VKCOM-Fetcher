package VKCOM::Fetcher;

use 5.012003;

our $VERSION = '0.01';

use Any::Moose;
use HTTP::Tiny;
use Data::Dumper;
use Carp;

with 'VKCOM::Fetcher::Service::Audio';

has 'access_token' => ( 
    is       => 'rw', 
    isa      => 'Str', 
    required => 1
);

has 'uid' => ( 
    is        => 'rw', 
    isa       => 'Int', 
    predicate => 'has_uid',
    required  => 0,
);

has 'gid' => ( 
    is        => 'rw', 
    isa       => 'Int',
    predicate => 'has_gid',
    required  => 0
);

has 'base_url' => ( 
    is      => 'ro', 
    isa     => 'Str', 
    default => 'https://api.vk.com/'
);

has ua => (
    is         => 'ro',
    isa        => 'HTTP::Tiny',
    lazy_build => 1,
);

has ua_args => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub {
        my $version = $VKCOM::Fetcher::VERSION || 'xx';
        return [ agent => "VKCOM::Fetcher/$version" ];
    },
);

sub BUILD 
{ 
    my $self = shift;

    croak('uid or gid must be specified')
        unless ($self->has_uid or $self->has_gid);        
}
 
sub _build_ua {
    my $self = shift;
 
    return HTTP::Tiny->new( @{ $self->ua_args } );
}

sub fetch {
    my $self = shift;
    my $auth = shift;
    my $url = shift;

    ( defined $auth and ( 1 == $auth or 0 == $auth ) ) 
        or croak('first argument auth must be 1 or 0');
    
    defined $url 
        or croak('url not specified');

    my $req_url = $auth ? 
        sprintf( "%s%s?%s", $self->base_url, $url, $self->get_auth_params() ) :
            $url;

    my $result = $self->ua->get($req_url);

    if ( defined ( my $success = $result->{'success'} ) ) {
        my $reason = $result->{'reason'} || '';
        $success or croak("Failed to fetch '$url': $reason");
    } else {
        croak('missing success in return value');
    }

    defined ( my $content = $result->{'content'} )
        or croak('missing content in return value');

    return $content;
}

sub get_auth_params {
    my $self = shift;

    my @attrs = ( 'access_token', ( $self->has_gid ? 'gid' : 'uid' ) );
    my @params = map { sprintf( '%s=%s', $_, $self->$_ ) } @attrs;
    return join('&', @params);
}

sub check_vk_api_response {
    my $self = shift;
    my $struct = shift;

    ref $struct eq 'HASH' or 
        croak('struct must be hash ref');

    if ( exists($struct->{error}) ) {
        croak("found error in request:\n". Data::Dumper::Dumper($struct));
    }
}

1;
__END__

=head1 NAME

VKCOM::Fetcher - Perl extension for fetching content from vk.com

=head1 SYNOPSIS

use VKCOM::Fetcher;

my $vkfetcher = VKCOM::Fetcher->new( 
    access_token => 'myAccessTokenString', 
    uid => 1234567
);

$vkfetcher->fetchAudio(
    storage => '/home/user/music'
);

=head1 DESCRIPTION

This module for only personal usage! 

You can fetch only the audio but in future we plan to add another services.
First you need register Standalone/Mobile application. Authorization works based on this article http://vk.com/developers.php?oid=-1&p=%D0%90%D0%B2%D1%82%D0%BE%D1%80%D0%B8%D0%B7%D0%B0%D1%86%D0%B8%D1%8F_%D0%BA%D0%BB%D0%B8%D0%B5%D0%BD%D1%82%D1%81%D0%BA%D0%B8%D1%85_%D0%BF%D1%80%D0%B8%D0%BB%D0%BE%D0%B6%D0%B5%D0%BD%D0%B8%D0%B9

For getting the access token you need do a request for example:
http://oauth.vkontakte.ru/authorize?client_id=1111111&scope=audio&redirect_uri=http://oauth.vkontakte.ru/blank.html&display=page&response_type=token
where client_id = application id

=head2 EXPORT

None. 

=head1 SEE ALSO

http://vk.com/developers.php

=head1 AUTHOR

Ali Ramazanov, E<lt>netspamer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Ali Ramazanov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
