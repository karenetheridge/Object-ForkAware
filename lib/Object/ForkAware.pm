use strict;
use warnings;
package Object::ForkAware;
# ABSTRACT: Make an object aware of process forks and threads, recreating itself as needed
# KEYWORDS: process thread fork multiprocessing multithreading clone
# vim: set ts=8 sw=4 tw=78 et :

use Scalar::Util 'blessed';
use namespace::clean;

sub new
{
    my ($class, %opts) = @_;

    my $self = {};
    $self->{_create} = $opts{create} or die 'missing required option: create';
    $self->{_on_fork} = $opts{on_fork} if exists $opts{on_fork};

    $self = bless($self, $class);

    $self->_create_obj($self->{_create}) if not $opts{lazy};

    return $self;
}

sub _create_obj
{
    my ($self, $sub) = @_;

    my $obj = $sub->( defined $self->{_obj} ? $self->{_obj} : () );
    $self->{_pid} = $$;
    $self->{_tid} = threads->tid if $INC{'threads.pm'};
    $self->{_obj} = $obj;
}

sub _get_obj
{
    my $self = shift;

    return if not blessed $self;
    if (not defined $self->{_pid}
        or $$ != $self->{_pid}
        or defined $self->{_tid} and $self->{_tid} != threads->tid)
    {
        $self->_create_obj($self->{_on_fork} || $self->{_create});
    }

    return $self->{_obj};
}

sub isa
{
    my ($self, $class) = @_;
    $self->SUPER::isa($class) || blessed($self) && $self->_get_obj->isa($class);
}

sub can
{
    my ($self, $method) = @_;
    $self->SUPER::can($method) || blessed($self) && $self->_get_obj->can($method);
}

sub VERSION
{
    my ($self, @args) = @_;

    my $obj = $self->_get_obj;
    return $obj
        ? $obj->VERSION(@args)
        : $self->SUPER::VERSION(@args);
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

=for stopwords other's prefork

=head1 SYNOPSIS

    use Object::ForkAware;
    my $client = Object::ForkAware->new(
        create => sub { MyClient->new(server => 'foo.com', port => '1234') },
    );

    # do things with object as normal...
    $client->send(...);

    # later, we fork for some reason
    if (fork == 0) {
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
changes.  (The object is also thread-aware; if the thread id changes, the
object is recreated in the same manner.)

The object can be safely used with type checks and various type constraint
mechanisms, as C<isa> and C<can> respond as if they were being called against
the contained object itself.

You can also ensure that a fork never happens, by making use of the optional
C<on_fork> handler:

    my $client = Object::ForkAware->new(
        create => sub { MyClient->new(server => 'foo.com', port => '1234') },
        on_fork => sub { die 'fork detected!' },
    );

Or, if regenerating the object needs to be done differently than the initial
creation:

    my $client = Object::ForkAware->new(
        create => sub { MyClient->new(server => 'foo.com', port => '1234') },
        on_fork => sub { MyClient->new(server => 'other.foo.com' },
    );

=head1 METHODS

=head2 C<< new(option => val, option => val...) >>

Provides an instance of this class.  Available options are:

=over 4

=item * C<create> (mandatory) - a sub reference containing the code to be run
when the object is initially created (as well as recreated, if there is no
C<on_fork> sub provided), returning the
object instance.
If the object previously existed, it is passed as an argument to this method,
allowing you to copy any state from the old object to the new one.

=item * C<on_fork> - a sub reference containing the code to be run when a fork
is detected. It should either generate an exception or return the new object
instance.

=item * C<lazy> - a boolean (defaults to false) - when true, the C<create> sub
is not called immediately, but instead deferred until the first time the
object is used. This prevents useless object creation if it is not to be used
until after the first fork.
If the object previously existed, it is passed as an argument to this method,
allowing you to copy any state from the old object to the new one.

=back

There are no other public methods. All method calls on the object will be
passed through to the containing object, after checking C<$$> and possibly
recreating the object via the provided C<create> (or C<on_fork>) sub.

=for Pod::Coverage::TrustPod isa can VERSION

=head1 LIMITATIONS

Using the L<Object::ForkAware> object with an operator that the containing
object has overloaded will not work; behaviour is as if there was no operator
overloading.  Partial support is possible, but is not yet implemented.

=head1 SUPPORT

=for stopwords irc

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Object-ForkAware>
(or L<mailto:bug-Object-ForkAware@rt.cpan.org>).
I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 ACKNOWLEDGEMENTS

The concept for this module came about through a conversation with Matt S.
Trout <mst@shadowcat.co.uk> after experiencing the issue described in the
synopsis on a prefork job-processing daemon.

Some of the pid detection logic was inspired by the wonderful L<DBIx::Connector>.

=head1 SEE ALSO

=begin :list

* L<Object::Wrapper>
* L<Object::Wrapper::Fork>
* L<POSIX::AtFork>

=end :list

=cut
