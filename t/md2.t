#!/usr/bin/perl -w

use Test::More tests => 2;
use strict;

BEGIN
  {
  $| = 1;
  unshift @INC, '../blib/lib';
  unshift @INC, '../blib/arch';
  unshift @INC, '.';
  chdir 't' if -d 't';
  use_ok ('Game::3D::Model::MD2');
  }

can_ok ('Game::3D::Model::MD2', qw/ 
  new render_frame frames _read_file
  /);

#my $area = Game::3D::Area->new ( );
#
#is (ref($area), 'Game::3D::Area', 'new worked');


