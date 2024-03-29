
# Game-3D-Model-MD2 - load/render an .md2 3d model

package Game::3D::Model::MD2;

# (C) by Tels <http://bloodgate.com/>

use strict;

use Exporter;
use Game::3D::Model;
use SDL::OpenGL;
use vars qw/@ISA $VERSION/;
@ISA = qw/Exporter Game::3D::Model/;

$VERSION = '0.01';

##############################################################################
# struct used to load file

my $unpack_header = 
  'a4' .	# ident, equal to IDP2
  'V' .		# version (should be 8)	
  'V' .		# skin width
  'V' .		# skin height
  'V' .		# framesize
  'V' .		# num textures
  'V' .		# num points per frame
  'V' .		# num texture coordinates
  'V' .		# num triangles per frame
  'V' .		# num OpenGL command types
  'V' .		# num frames
  'V' .		# skins offset
  'V' .		# mesh st offset
  'V' .		# triangles offset
  'V' .		# frames offset
  'V' .		# OpenGL cmds offset
  'V' ;		# offset end

# For simplicity reasons, we use the following directly, e.g. no structs or
# objects. This makes conversion to XS code easier.

my $unpack_vector = 'fff'; 			# (x,y,z);
my $unpack_st_index = 'vv'; 			# (s,t);
my $unpack_frame_point = 'CCCC'; 		# (c1,c2,c3,normal);
my $unpack_frame = 'ffffffC16';	
						# (scale_x,scale_y,scale_z,
						#  trans_x, trans_y, trans_z,
						#  name, frame_point) 
my $unpack_mesh = 'vvvvvv';			# mesh_index_x,index_y,index_z,
						# st_index_x, st_index_y,
						# st_index_z

##############################################################################
# methods

sub _init
  {
  # create a new instance of a model
  my $self = shift;

  $self->SUPER::_init(@_);

  $self->{meshes} = [];			# triangles
  $self->{text_coords} = [];		# text coords
  $self->{vertices} = [];		# point list (for each frame the
					# offset into triangles and textures)
  $self->{triangles} = [];		# triangles (mesh and text coord)
					# only one big list
  $self->{textures} = [];		# text coord list (one big list)
  
  }

sub _read_file
  {
  my ($self,$filename) = @_;

  return if $filename eq '';		# for tests

  # read in entire model
  open my $FILE, $filename or die ("Cannot read file $filename: $!");
  binmode $FILE;
  my ($buffer, $file);
  while (sysread($FILE,$buffer,8192) != 0)
    {
    $file .= $buffer;
    }
  close $FILE;
  $self->_parse_data($file);
  }

sub _parse_data
  {
  my ($self,$file) = @_;

  # extract header info
  my ($ident,$version);
  ($ident,$version,
    $self->{skin_width},
    $self->{skin_height},
    $self->{frame_size}, 
    $self->{num_textures},
    $self->{num_points}, 
    $self->{num_text_coords},
    $self->{num_triangles}, 
    $self->{num_opengl_cmd_types},
    $self->{num_frames}, 
    $self->{offset_skins},
    $self->{offset_text_coords}, 
    $self->{offset_triangles}, 
    $self->{offset_frames}, 
    $self->{offset_opengl_cmds}, 
    $self->{offset_end})
  = unpack ($unpack_header,$file);

  die ("File $file seems not to be a .md2 file") if $ident ne 'IDP2';

  my $frame_ofs = $self->{offset_frames};
  for (my $i = 0; $i < $self->{num_frames}; $i++)
    {
    die ("frame_size $self->{frame_size} != ", 40 + 4 * $self->{num_points}) 
     if $self->{frame_size}  != 4 * $self->{num_points} + 40;

    my $pnt_ofs = $frame_ofs + 40;
    my ($sx, $sy, $sz, $tx, $ty, $tz, $name) =
       unpack ($unpack_frame, substr($file,$frame_ofs, 40));
    $self->{vertices}->[$i] = [];
    for (my $j = 0; $j < $self->{num_points}; $j++)
      {
      my ($cx, $cy, $cz, $normal) =
       unpack ($unpack_frame_point, substr($file,$pnt_ofs, 4));
      push @{$self->{vertices}->[$i]},
         [ $sx * $cx + $tx,
         $sy * $cy + $ty,
         $sz * $cz + $tz ];
      $pnt_ofs += 4;
      }
 
    $frame_ofs += $self->{frame_size};
    }

  # for each texture coord
  my $text_ofs = $self->{offset_text_coords};
  for (my $i = 0; $i < $self->{num_text_coords}; $i++)
    {
    my ($s,$t) = unpack($unpack_st_index, substr($file,$text_ofs,4));
    push @{$self->{text_coords}}, 
      ($s / $self->{skin_width}, $t / $self->{skin_height});
    $text_ofs += 4; 
    # print "$i ($s,$t)\n";
    }
  
  my $mesh_ofs = $self->{offset_triangles};
  # create a mesh (triangle list) for each frme
  for (my $j = 0; $j < $self->{num_triangles}; $j++)
    {
    push @{$self->{triangles}},
        [ unpack ( $unpack_mesh,substr($file,$mesh_ofs,12)) ];
    $mesh_ofs += 12;	 # 6 shorts
    }

  $self;
  }


sub render_frame
  {
  # render one frame from the model, without any interpolation
  my ($self,$frame) = @_;

  $frame = $self->{num_frames} - 1 if $frame >= $self->{num_frames};

  my $v = $self->{vertices}->[$frame];
  srand(3);
  glBegin(GL_TRIANGLES()); my $ofs;
  foreach my $t (@{$self->{triangles}})
    {
    glColor(rand(),rand(),rand(),1.0);	# random colorization

    $ofs = $t->[0]; glVertex($v->[$ofs]->[0],$v->[$ofs]->[1],$v->[$ofs]->[2]);
    $ofs = $t->[2]; glVertex($v->[$ofs]->[0],$v->[$ofs]->[1],$v->[$ofs]->[2]);
    $ofs = $t->[1]; glVertex($v->[$ofs]->[0],$v->[$ofs]->[1],$v->[$ofs]->[2]);
   
    }
  glEnd;
  }

1;

__END__

=pod

=head1 NAME

Game::3D::Model::MD2 - load/render 3D models based on the .md2 file format

=head1 SYNOPSIS

	use Game::3D::Model::MD2;

	my $model = Game::3D::Model::MD2->new( 'ogre.md2' );

	$model->render_frame(0);

=head1 EXPORTS

Exports nothing on default.

=head1 DESCRIPTION

This package let's you load and render (via OpenGL) models based on the popular
.md2 file format.

=head1 METHODS

=over 2

=item new()

	my $model = Game::3D::Model::MD2->new( $filename );

Load a model into memory and return an object reference.

=item render_frame()

	$model->render_frame($frame_num);

Render one frame from the model.

=item frames()

	$model->frames();

Return the number of frames in the model.

=back

=head1 AUTHORS

(c) 2003 Tels <http://bloodgate.com/>

=head1 SEE ALSO

L<Game::3D>, L<SDL:App::FPS>, and L<SDL::OpenGL>.

=cut

