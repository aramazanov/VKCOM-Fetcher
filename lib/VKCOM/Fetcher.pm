package VKCOM::Fetcher;

use 5.012003;

our $VERSION = '0.01';

use Any::Moose;
use HTTP::Tiny;

with 'VKCOM::Fetcher::Service::Audio' => {
    -excludes => ['http_method_name', 'file_extension'] 
    };

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

    return $self->ua->get( $req_url );
}

sub get_auth_params {
    my $self = shift;

    my @attrs = ( 'access_token', ( $self->gid ? 'gid' : 'uid' ) );
    my @params = map { sprintf( '%s=%s', $_, $self->$_ ) } @attrs;
    return join('&', @params);
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

VKCOM::Fetcher - Perl extension for blah blah blah

=head1 SYNOPSIS

  use VKCOM::Fetcher;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for VKCOM::Fetcher, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Али Рамазанов, E<lt>aramazanov@apple.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Али Рамазанов

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
