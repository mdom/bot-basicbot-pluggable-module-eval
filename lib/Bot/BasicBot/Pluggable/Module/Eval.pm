package Bot::BasicBot::Pluggable::Module::Eval;

use warnings;
use strict;
use Safe;
use parent 'Bot::BasicBot::Pluggable::Module';

our $VERSION = '0.04';

sub init {
    my $self = shift;
    $self->config( { permit => [':default'], persistent => 1 } );
    $self->{compartments} = {};
}

sub told {
    my ( $self, $message ) = @_;
    my $body    = $message->{body};
    my $channel = $message->{channel};

    if ( $channel eq 'msg' ) {
        $channel = $message->{who};
    }

    my ( $command, $rest ) = split( ' ', $body, 2 );

    if ( $command eq 'perl' ) {
        my ( $subcommand, $args ) = split( ' ', $rest, 2 );
        if ( $subcommand eq 'eval' ) {
            $self->new_compartment($channel);

            $self->bot->forkit(
                run       => \&evaluate,
                arguments => [ $self->{compartments}->{$channel}, $args ],
                channel   => $message->{channel},
                who       => $message->{who},
                address   => $message->{address},
            );
            return 1;

        }
        elsif ( $subcommand eq 'clear' ) {
	    ## Only clear the compartment if we have to
            $self->new_compartment($channel) if $self->get('persistent');
        }
    }
    return;
}

sub new_compartment {
    my ( $self, $channel ) = @_;
    if ( !$self->{compartments}->{$channel} or !$self->get('persistent') ) {
        my $cpt = Safe->new();
        $cpt->permit( $self->get('permit') );
        $self->{compartments}->{$channel} = $cpt;
        return $cpt;
    }
    return;
}

sub evaluate {
    my ( $body, $cpt, $code ) = @_;
    $cpt->reval($code) or print "$@";
    print "\n";
}

sub help {
    return "Evaluate perl code. Usage: perl eval <code>.";
}

1;
__END__

=head1 NAME

Bot::BasicBot::Pluggable::Module::Eval - Evaluate perl code in your channel

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

This module evaluate any perl code and returns the output to the
questioner. The code is run in a forked process, so the bot is still
active while running the code. This module uses Safe to sandbox the
running code, so please refer to its documentation for any security
implications.

This module does not print the return code of the executed code back to
the channel, so you have to handle this yourself.

    !load Eval
    perl eval print "foo"
    perl eval foreach (qw(foo bar)) { print }

=head1 VARIABLES

=over 4

=item permit => [ $op ]

Permit the listed operators to be used when compiling code in the
compartment. You can list opcodes by names, or use a tag name; see
L<Opcode/"Predefined Opcode Tags">. This variable is not accessable as
user variabe due security concerns. This defaults to ':default' (sic!).

=item persistent => 0|1

If this variable is true (default), the compartments are not generated
for every request, but are safed on a per channel basis. Please call
I<perl clear> to restart the compartment.

=back

=head1 AUTHOR

Mario Domgoergen, C<< <dom at math.uni-bonn.de> >>

=head1 BUGS

Please report any bugs or feature requests
to C<bug-bot-basicbot-pluggable-module-eval
at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bot-BasicBot-Pluggable-Module-Eval>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 TODO

=over 4

=item

Long running compartments

=item

More tests, but i need to patch Test::Bot::BasicBot::Pluggable
fist as it is not able to emulate forkit in the moment.

=back


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Bot::BasicBot::Pluggable::Module::Eval


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Bot-BasicBot-Pluggable-Module-Eval>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Bot-BasicBot-Pluggable-Module-Eval>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Bot-BasicBot-Pluggable-Module-Eval>

=item * Search CPAN

L<http://search.cpan.org/dist/Bot-BasicBot-Pluggable-Module-Eval>

=back


=head1 SEE ALSO

L<Bot::BasicBot::Pluggable>, L<Safe>


=head1 COPYRIGHT & LICENSE

Copyright 2009 Mario Domgoergen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Bot::BasicBot::Pluggable::Module::Eval
