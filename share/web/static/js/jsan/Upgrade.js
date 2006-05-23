/*
Keep package scanners happy
Upgrade.VERSION = 0.04;
*/

/*

=head1 NAME

Upgrade - Upgrade older JavaScript implementations to support newer features

=head1 SYNOPSIS

  // Upgrade Array.push if the client does not have it
  JSAN.use("Upgrade.Array.push");

=head1 DESCRIPTION

Many many different JavaScript toolkits start with something like the following:

  // Provides Array.push for implementations that don't have it
  if ( ! Array.prototype.push ) {
      Array.prototype.push = function () {
          var l = this.length;
          for ( var i = 0; i < arguments.length; i++ ) {
              this[l+i] = arguments[i];
          }
          return this.length;
      }
  }

These provide implementations of expected or required functions/classes
for older JavaScript implementations that do not provide them natively,
in effect "upgrading" the client at run-time.

In fact, due to its flexibility JavaScript is a language ideally suited
to this sort of behaviour.

C<Upgrade> is a JSAN package that provides standard implementations for
many of these standard functions. If your code relies on a particular
function that you later find to be not as common as you might have
initially thought, you can simply add a dependency on that function within
the C<Upgrade> namespace, and if an implementation exists the standard code
to implement it will be added it the current environment (when it doesn't
already have it).

Rather than one huge file that provides a "compatibility layer" and upgrades
verything all at once, C<Upgrade> is broken down into a large number of
maller .js files, each implementing one function or class.

Generally these functions are ones defined in the ECMA standard, and those
that aren't, such as C<HTMLHttpRequest> are not provided by Upgrade (as much
as we would like to) :)

=head1 USING UPGRADE

The C<Upgrade> namespace acts as a parallel root to the global namespace.
For any function you want to upgrade, you can then simply prepend
C<"Upgrade"> to it.

For example, to do the very common upgrade for the C<Array.push> function,
you simply add C<JSAN.use("Upgrade.Array.push") to your module (or manually
load the C<Upgrade/Array/push.js> file).

One advantage of using these standard implementations rather than your own
is that when a number of modules with C<Upgrade> depedencies are merged
together by C<JSAN::Concat> or another package merger it results in only
a single copy of the upgrading code at the appropriate place in the code.

=head1 UPGRADABLE FUNCTIONS

While implementations are provided seperately, rather than document them
this way we will instead defined all functions available in the C<Upgrade>
package here.

=head2 Upgrade.Array.push

This provides the same standard implementation of the instance method
C<Array.push> (located at Array.prototype.push) as used by all of the
major frameworks.

=head2 Upgrade.Function.apply

This provides a version of the instance method C<Function.apply>
(located at C<Function.prototype.apply>) adapted from an implementation
found in the L<Prototype> framework, which was itself adapted from an
implementation found on L<http://www.youngpup.net/>.

=head1 METHODS

The C<Upgrade> module itself does not at this time provide any
functionality, and only acts as a source of documentation.

Likewise, nothing is ever actually created at or beneath the C<Upgrade>
namespace, but serves as an address mechanism for determining which
.js files to load. Each of these files only inserts functions into the
core tree and do not create any additional useless namespace variables.

=head1 SUPPORT

Until the JSAN RT gains package-specific queues, bugs or new functions
to add to Upgrade should be reported to the jsan-authors mailing list.

For B<non-support> issues or questions, contact the author.

=head1 AUTHOR

Adam Kennedy <jsan@ali.as>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright (c) 2005 Adam Kennedy. All rights reserved.
This program is free software; you can redistribute it and/or modify
it under the the terms of the Perl dual GPL/Artistic license.

The full text of the license can be found in the
LICENSE file included with this package

=cut

*/
