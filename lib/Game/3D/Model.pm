
# Game-3D-Model - load/render 3d models

package Game::3D::Model;

# (C) by Tels <http://bloodgate.com/>

use strict;

use Exporter;
use SDL::OpenGL;
use vars qw/@ISA $VERSION/;
@ISA = qw/Exporter/;

$VERSION = '0.01';

# private vars

my $vertices = pack "d24",
        -0.5,-0.5,-0.5, 0.5,-0.5,-0.5, 0.5,0.5,-0.5, -0.5,0.5,-0.5, # back
        -0.5,-0.5,0.5,  0.5,-0.5,0.5,  0.5,0.5,0.5,  -0.5,0.5,0.5 ; # front

my $indicies = pack "C24",
	4,5,6,7,	# front
	1,2,6,5,	# right
	0,1,5,4,	# bottom
	0,3,2,1,	# back
	0,4,7,3,	# left
	2,3,7,6;	# top

##############################################################################
# methods


sub new
  {
  # create a new instance of a model
  my $class = shift;

  my $self = { };
  bless $self, $class;
  
  my $args = $_[0];
  $args = { @_ } unless ref $args eq 'HASH';
  $self->{type} = $args->{type} || '';

  if ($self->{type} ne '')
    {
    $class = 'Game::3D::Model::' . $self->{type};
    my $pm = $class; $pm =~ s/::/\//g; $pm .= '.pm';
    require $pm;
    bless $self, $class;				# rebless
    }
  $self->_init($args);
  $self->_read_file($self->{file});
  $self;
  }

sub _read_file
  {
  my $self = shift;

  $self;
  }

sub _init
  {
  my ($self,$args) = @_;

  $self->{file} = $args->{file} || '';
  $self->{type} = $args->{type} || '';
  $self->{name} = $args->{name} || '';
  $self->{model} = undef;

  $self->{cur_frame} = 0;
  $self->{next_frame} = 0;
  $self->{num_frames} = 1;

  $self;
  }

sub render_frame
  {
  # render one frame from the model, without any interpolation
  # should be overwritten. This method only renders a white cube
  my ($self,$frame) = @_;

  glPushMatrix();
    glColor(1,1,1,1);
    glScale(120,120,120);
    glTranslate(0,0,-40);
    glDisableClientState(GL_COLOR_ARRAY);
    glEnableClientState(GL_VERTEX_ARRAY());
    glVertexPointer(3,GL_DOUBLE(),0,$vertices);
    glDrawElements(GL_QUADS(), 24, GL_UNSIGNED_BYTE(), $indicies);
  glPopMatrix();

  }

sub frames
  {
  # return number of frames in model
  my $self = shift;

  $self->{num_frames};
  }

1;

__END__

=pod

=head1 NAME

Game::3D::Model - load/render 3D models

=head1 SYNOPSIS

	use Game::3D::Model;

	my $model = Game::3D::Model->new( 
          file => 'ogre.md2', type => 'MD2' );

	$model->render_frame(0);

=head1 EXPORTS

Exports nothing on default.

=head1 DESCRIPTION

This package let's you load and render (via OpenGL) 3D models based on 
various file formats (these are realized as subclasses).

=head1 METHODS

=over 2

=item new()

	my $model = Game::3D::Model->new( $args );

Load a model into memory and return an object reference. C<$args> is a hash
ref containing the following keys:

	file		filename of model
	type		'MD2' etc

=item render_frame()

	$model->render_frame($frame_num);

Render one frame from the model.

=item frames()

	$model->frames();

Return the number of frames in the model.

=back

=head1 KNOWN BUGS

=over 2

=item *

Currently the model is loaded as soon as the object is constructed. In some
cases however it might be better to do a delayed loading of models, like
when the player never sees a certain model because it is in a far-away spot of
the level for a long time.

=back

=head1 AUTHORS

(c) 2003 Tels <http://bloodgate.com/>

=head1 SEE ALSO

L<Game::3D>, L<SDL:App::FPS>, and L<SDL::OpenGL>.

=cut

