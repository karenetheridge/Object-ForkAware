use strict;
use warnings;
package Object::ForkAware;
# ABSTRACT: make an object aware of process forks, recreating itself as needed

sub new
{
    my ($class, %opts) = @_;

    my $self = {};
    $self->{_create} = $opts{create} || die 'missing required option: create';

    $self = bless($self, $class);

    # TODO: lazy option?
    $self->_create_obj;

    return $self;
}

sub _create_obj
{
    my $self = shift;

    my $obj = $self->{_create}->();
    $self->{_pid} = $$;
    $self->{_tid} = threads->tid if $INC{'threads.pm'};
    $self->{_obj} = $obj;
}

sub _get_obj
{
    my $self = shift;

    if ($$ != $self->{_pid}
        or defined $self->{_tid} and $self->{_tid} != threads->tid)
    {
        $self->_create_obj;
    }

    return $self->{_obj};
}

sub isa
{
    my ($self, $class) = @_;
    $self->SUPER::isa($class) || $self->_get_obj->isa($class);
}

sub can
{
    my ($self, $class) = @_;
    $self->SUPER::can($class) || $self->_get_obj->can($class);
}

our $AUTOLOAD;
sub AUTOLOAD
{
    my $self = shift;

    # Remove qualifier from original method name...
    (my $called = $AUTOLOAD) =~ s/.*:://;
    return $self->_get_obj->$called(@_);
}

sub DESTROY {}  # avoid calling AUTOLOAD at destruction time

1;
__END__

=pod

=head1 SYNOPSIS

    use Object::ForkAware;
    my $client = Object::ForkAware->new(
        create => sub { MyClient->new(server => 'foo.com', port => '1234') },
    );

    # do things with object as normal...
    $client->send(...);

    # later, we fork for some reason
    if (!fork) {
        # child process
        $client->send(...);
    }

    # no boom happens! fork is detected and client object is regenerated

=head1 DESCRIPTION

If you've ever had an object representing a network connection to some server,
or something else containing a socket, a filehandle, etc, and used it in a
program that forks, and then forgot to close and reopen your socket/handle
etc, you'll know what chaos can ensue. Depending on the type of connection,
you can have multiple processes trying to write to the same resource at once,
or simultaneous reads getting each other's data, etc etc. It's horrible, and
it's an easy problem to run into.

This module invisibly wraps your object and makes it fork-aware, automatically
checking C<$$> on every access and recreating the object if the process id
changes.  (This object is also thread-aware; if the thread id changes, the
object is recreated in the same manner.)

The object can be safely used with type checks and various type constraint
mechanisms, as C<isa> and C<can> respond as if they were being called against
the contained object itself.

=head1 METHODS

=over

=item * C<< new(option => val, option => val...) >>

Provides an instance of this class.  Available options are:

=over

=item * C<create> (mandatory) - a sub reference containing the code to be run
when the object is initially created, as well as re-recreated, returning the
object instance.

=back

=back

There are no other public methods. All method calls on the object will be
passed through to the containing object, after checking C<$$> and possibly
recreating the object via the provided C<create> sub.

=for Pod::Coverage::TrustPod isa can

=head1 LIMITATIONS

Using the L<Object::ForkAware> object with an operator that the containing
object has overloaded will not work; behaviour is as if there was no operator
overloading.  Partial support is possible, but is not yet implemented.

=head1 SUPPORT

Bugs may be submitted through L<https://rt.cpan.org/Public/Dist/Display.html?Name=Object-ForkAware>
or L<bug-Object-ForkAware@rt.cpan.org>.
I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 ACKNOWLEDGEMENTS

The concept for this module came about through a conversation with Matt S.
Trout <mst@shadowcat.co.uk> after experiencing the issue described in the
synopsis on a prefork job-processing daemon.

=head1 SEE ALSO

L<Object::Wrapper>, L<Object::Wrapper::Fork>

=cut
