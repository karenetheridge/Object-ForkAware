use strict;
use warnings FATAL => 'all';

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Fatal;
use Object::ForkAware;

is(
    exception {
        ok(Object::ForkAware->isa('Object::ForkAware'), 'isa as a class method checks isa of class');

        ok(!Object::ForkAware->isa('Warble'), '..and correctly returns false');
    },
    undef,
    "isa as a class method doesn't crash",
);

is(
    exception {
        is(
            Object::ForkAware->can('can'),
            \&Object::ForkAware::can,
            'can as a class method returns correct sub',
        );

        ok(!Object::ForkAware->can('nomethod'), '..or undef');
    },
    undef,
    "can as a class method doesn't crash",
);

done_testing;
