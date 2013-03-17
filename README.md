# NAME

Object::ForkAware - make an object aware of process forks, recreating itself as needed

# VERSION

version 0.001

# SYNOPSIS

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

# DESCRIPTION

If you've ever had an object representing a network connection to some server,
or something else containing a socket, a filehandle, etc, and used it in a
program that forks, and then forgot to close and reopen your socket/handle
etc, you'll know what chaos can ensue. Depending on the type of connection,
you can have multiple processes trying to write to the same resource at once,
or simultaneous reads getting each other's data, etc etc. It's horrible, and
it's an easy problem to run into.

This module invisibly wraps your object and makes it fork-aware, automatically
checking `$$` on every access and recreating the object if the process id
changes.  (This object is also thread-aware; if the thread id changes, the
object is recreated in the same manner.)

The object can be safely used with type checks and various type constraint
mechanisms, as `isa` and `can` respond as if they were being called against
the contained object itself.

You can also ensure that a fork never happens, by making use of the optional
`on_fork` handler:

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

# METHODS

- `new(option => val, option => val...)`

    Provides an instance of this class.  Available options are:

    - `create` (mandatory) - a sub reference containing the code to be run
    when the object is initially created, as well as re-recreated, returning the
    object instance.
    - `on_fork` - a sub reference containing the code to be run when a fork
    is detected. It should either generate an exception or return the new object
    instance.
    - `lazy` - a boolean (defaults to false) - when true, the `create` sub
    is not called immediately, but instead deferred until the first time the
    object is used. This prevents useless object creation if it is not to be used
    until after the first fork.

There are no other public methods. All method calls on the object will be
passed through to the containing object, after checking `$$` and possibly
recreating the object via the provided `create` (or `on_fork`) sub.

# LIMITATIONS

Using the [Object::ForkAware](http://search.cpan.org/perldoc?Object::ForkAware) object with an operator that the containing
object has overloaded will not work; behaviour is as if there was no operator
overloading.  Partial support is possible, but is not yet implemented.

# SUPPORT

Bugs may be submitted through [https://rt.cpan.org/Public/Dist/Display.html?Name=Object-ForkAware](https://rt.cpan.org/Public/Dist/Display.html?Name=Object-ForkAware)
or [bug-Object-ForkAware@rt.cpan.org](http://search.cpan.org/perldoc?bug-Object-ForkAware@rt.cpan.org).
I am also usually active on irc, as 'ether' at `irc.perl.org`.

# ACKNOWLEDGEMENTS

The concept for this module came about through a conversation with Matt S.
Trout <mst@shadowcat.co.uk> after experiencing the issue described in the
synopsis on a prefork job-processing daemon.

# SEE ALSO

[Object::Wrapper](http://search.cpan.org/perldoc?Object::Wrapper), [Object::Wrapper::Fork](http://search.cpan.org/perldoc?Object::Wrapper::Fork)

# AUTHOR

Karen Etheridge <ether@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
