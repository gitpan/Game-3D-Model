#!/usr/bin/perl -w

use Test::More tests => 4;
use strict;

BEGIN
  {
  $| = 1;
  unshift @INC, '../blib/lib';
  unshift @INC, '../blib/arch';
  unshift @INC, '.';
  chdir 't' if -d 't';
  use_ok ('Game::3D::Model');
  }

can_ok ('Game::3D::Model', qw/ 
  new render_frame frames _read_file
  /);

my $model = Game::3D::Model->new ( file => '');
is (ref($model), 'Game::3D::Model', 'new worked');

$model = Game::3D::Model->new ( file => '', type => 'MD2');
is (ref($model), 'Game::3D::Model::MD2', 'new w/ type worked');


