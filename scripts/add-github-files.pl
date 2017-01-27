#!/usr/bin/perl
# vim: ft=perl
use warnings;
use strict;

use File::Find;
use File::Basename;
use File::Spec;

my $github_repo = 'about-awk';

my $dest_top_dir;
my $src_top_dir;
my $title_prefix;

my $dir_depth_level = -1;

#  Variables that might be used in the hook functions.
#  The value of these variables is set in wanted
#
#  The (absolute) dest_path pointing into the notes directory:
my $dest_path;
#
#  The relative path within the notes directory structure
my $notes_path;
#
#  The path pointing to a real existing file on the HD of a
#  checked out github repository:
my $src_path;
#
#  Just(!) the filename, without paths and anyting:
my $filename;
#
#  The (almost absoloute) path in the github repository:
my $github_path;

#  Variables called from wanted
my $hook_init      = sub {print "init: $dest_path\n"};
my $hook_dir       = sub {print "dir  $src_path -> $dest_path\n"};
my $hook_file      = sub {print "file $src_path -> $dest_path\n"};
my $hook_dir_leave = sub {print "leave dir $src_path -> $dest_path\n"};


determine_variables();

find({ # {
       wanted => \&wanted,  
       preprocess => sub {
         $dir_depth_level ++;
         return grep { substr($_, 0, 1) ne '.' and substr($_, -4) ne '.swp' and $_ ne 'README.md' } @_ 
       },
       postprocess => sub {
         $dir_depth_level --;
         &$hook_dir_leave;
       }
    }, $src_top_dir);

sub wanted { # {
#
# The main purpose of wanted is to
# assign values to
#   $dest_path,
#   $src_path   and
#   $filename  (name of the file without path information)
# and then to call exactly one of the three hook functions
# $hook_init, $hook_dir or $hook_file.
#

  $filename  = $_;

  # Checking assumptions {
  if ($dir_depth_level == -1) {
     die unless $filename eq '.';
  }
  else {
     die if $filename eq '.';
  }
  # }

  my $full_path = $File::Find::name;

  my $rel_path;
  if ($filename eq '.') {
    $rel_path = '';
  }
  else {
    $rel_path = File::Spec->abs2rel($full_path, $src_top_dir);
  }

  $dest_path   = "$dest_top_dir$rel_path";
  $src_path    = "$src_top_dir$rel_path";

  $github_path = "/$rel_path";

  $notes_path  = File::Spec->abs2rel($dest_path, "$ENV{github_root}notes/notes/");

  if ($filename eq '.') {
    #
    # Check assumptions
    die "$dest_path does not end in /" unless substr($dest_path, -1) eq '/';
    die "$src_path does not end in /"  unless substr($src_path , -1) eq '/';

    &$hook_init;
  }
  else {
    #
    # Check assumptions
    die "$dest_path ends in /" if substr($dest_path, -1) eq '/';
    die "$src_path ends in /"  if substr($src_path , -1) eq '/';
    
    if (-d $src_path) {

    # Make sure that $src_path representing directories ends
    # in a slash
    #
    # Path does not end in slash (see check assumption above)
      $src_path    .= '/';
      $github_path .= '/';
      $notes_path  .= '/';

    # for github repo »awk«, directories are »flattened« into a single file
    # therefore, it doesn't make sense to append the trailing '/'
    # $dest_path .= '/';

      &$hook_dir;
    }
    elsif (-f $src_path) {
      &$hook_file;
    }
    else {
      die "$src_path";
    }
  }

} # }

sub determine_variables { # {

# my $dest_dir_root = $ENV{github_root}  . "notes/notes/";

  my ($dest_dir_rel, $src_dir_rel);

  if ($github_repo   eq 'about-awk') { # {

    $dest_dir_rel     = 'development/languages/awk/examples/';
    $src_dir_rel      = 'about/awk/';

    my @awk_examples = ();

    $hook_init = sub {
      make_sure_dest_path_is_dir_and_exists();
    };
    $hook_dir = sub {
      die "$dir_depth_level - $src_path" unless $dir_depth_level == 0;

    # $src_path is a directory, but we »flatten« it into a single file with the name of the
    # directory
    # make_sure_dest_path_is_dir_and_exists();


      my $title;
      if ($filename =~ /^([A-Z]+)[_ ]*(.*)/) {

         my $var = "\$$1";
        (my $explanation = $2) =~ s/_/ /g;
         
         $title = "$explanation ($var)";

      }
      else {
       ($title = $filename) =~ s/_/ /g;
      }
      open (my $f, '>', $dest_path) or die "could not open $dest_path";
      print "Notes path $notes_path\n";

    # We have to remove the trailing slash from $notes_path since
    # it's not a directory, but a file
      push @awk_examples, [substr($notes_path, 0, length($notes_path)-1), $title];

      $title = "\$ awk example: $title\n";
      print    $title;
      print $f $title;

    # Each example contains a »go.sh« script«
      print $f "\ngh|$github_repo|${github_path}go.sh||\n\n";
    
    # and one or more data files
  
      chdir($filename);
      for my $data_file (glob('data*')) {

        print "$data_file\n";
        print $f "gh|$github_repo|${github_path}$data_file||\n\n";

      }
      chdir('..');

      print $f "\nsa:\n\n  → development/languages/awk/examples\n";
    
      close $f;

    # Only index file created, for the moment, no need to descend into the directory
      $File::Find::prune = 1;
    };
    $hook_file = sub {
      die unless $dir_depth_level == 0;
    };
    $hook_dir_leave = sub {
       open (my $f, '>', "$ENV{github_root}notes/notes/${dest_dir_rel}index") or die "could not open $ENV{github_root}notes/notes/awk/examples/index";

       print $f "\$ awk examples\n\n";

       for my $e (@awk_examples) {
         printf $f ("\n → %s[%s]\n", $e->[0], $e->[1]);
       }
    };

  } # }
  else { # {
    die "unknown github_repo $github_repo";
  } # }


  die 'dest_dir_rel does not end on /' unless substr ($dest_dir_rel, -1) eq '/';
  die 'src_dir_rel does not end on /'  unless substr ($src_dir_rel , -1) eq '/';

  $dest_top_dir = "$ENV{github_root}notes/notes/$dest_dir_rel";
  $src_top_dir  = "$ENV{github_top_root}$src_dir_rel";

  die "$src_top_dir is not a directory" unless -d $src_top_dir;


} #  }

sub make_sure_dest_path_is_dir_and_exists { # {

  die "$dest_path should not be a file"  if -f $dest_path;
  return if -d $dest_path;

  print "creating dir $dest_path\n";
  mkdir $dest_path or die "Could not create $dest_path [$!]"

} # }

