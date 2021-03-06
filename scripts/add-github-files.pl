#!/usr/bin/perl
# vim: ft=perl
use warnings;
use strict;

use File::Find;
use File::Path qw(make_path);
use File::Basename;
use File::Spec;
use Cwd;
use Getopt::Long;

GetOptions(
  'force-overwrite' => \my $force_overwrite,
) or die;

my $github_repo = 
  # 'about-awk'
  # 'about-svg'
  # 'about-Document-Object-Model'
  # 'about-perl'
    'oracle-patterns'
  # 'scripts-and-utilities'
;
my $github_path_rel_under_repo = 
# '/'                                     # default
# 'functions/'                            # about-perl
# 'operators/'                            #    "   "
# 'regular-expressions/'                  #    "   "
# 'variables/'                            #    "   "
  'Installed/dynamic-performance-views/'  # oracle-patterns
# ''
;

my $dest_top_dir;
my $src_top_dir;
my $title_prefix;

my $remove_suffix_from_dest_path = 1;  # target scripts-and-utilities sets 0 to because of gitp and gitp.pl

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

my $rel_path;
#
#  Just(!) the filename, without paths and anyting:
my $filename;
#
#  The (almost absoloute) path in the github repository:
my $github_path;

#  Variables called from wanted
my $hook_init                 = sub {print "init: $dest_path\n"};
my $hook_dir                  = sub {print "dir  $src_path -> $dest_path\n"};
my $hook_file                 = sub {print "file $src_path -> $dest_path\n"};
my $hook_dir_leave            = sub {print "leave dir $src_path -> $dest_path\n"};
my $hook_exit                 = sub {print "exit\n"};
my $hook_transform_dest_path  = sub {}; # Needed because of directory 'require' in about/perl/functions


determine_variables();

find({ # {
       wanted => \&wanted,  
       preprocess => sub {
         $dir_depth_level ++;
         return sort grep { substr($_, 0, 1) ne '.' and substr($_, -4) ne '.swp' and $_ ne 'README.md' } @_ 
       },
       postprocess => sub {
         $dir_depth_level --;
         &$hook_dir_leave;
       }
    }, $src_top_dir);

&$hook_exit();

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

  return if $filename eq 'proxy.bat.old'; # scripts-and-utilities;

  # Checking assumptions {
  if ($dir_depth_level == -1) {
     die unless $filename eq '.';
  }
  else {
     die if $filename eq '.';
  }
  # }

  my $full_path = $File::Find::name;

# $rel_path;
  if ($filename eq '.') {
    $rel_path = '';
  }
  else {
    $rel_path = File::Spec->abs2rel($full_path, $src_top_dir);
  }

  $dest_path   = "$dest_top_dir$rel_path";

  &$hook_transform_dest_path();

  if ($remove_suffix_from_dest_path) {
    $dest_path =~ s/\.([^.]+)$//;            # foo/bar.bat -> foo/bar
  }
  else {
    $dest_path =~ s/\.([^.]+)$/_$1/;         # foo/bar.bat -> foo/bar_bat
  }
  $dest_path =~ s/\+/plus/g;
  $dest_path =~ s/\^/caret/g;
  $dest_path =~ s/#/hash/g;
  $dest_path =~ s/[()]/_/g;
  $dest_path =~ s/\@/at/g;


  $src_path    = "$src_top_dir$rel_path";

  $github_path = "/$github_path_rel_under_repo$rel_path";

  $notes_path = File::Spec->abs2rel($dest_path, "$ENV{github_root}notes/notes/");

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

    # Just to be sure there is no dot in $notes_path
      die "notes_path = $notes_path" if $notes_path =~ /\./;

      &$hook_dir;
    }
    elsif (-f $src_path) {

    # Just to be sure there is no dot in $notes_path
      die "notes_path = $notes_path" if $notes_path =~ /\./;

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

  if    ($github_repo eq 'about-awk') { # {

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
  elsif ($github_repo eq 'about-Document-Object-Model' ) { # {


    $dest_dir_rel  = 'development/web/DOM/examples/';
    $src_dir_rel   = 'about/Document-Object-Model/';

    one_to_one(
       dest_dir_rel => $dest_dir_rel ,
       title_prefix =>'DOM example:' ,
       index_title  =>'DOM examples' ,
    );


  } # }
  elsif ($github_repo eq 'about-perl' ) { # {

    if    ($github_path_rel_under_repo eq 'functions/') { #  {

       $dest_dir_rel  = 'development/languages/Perl/functions/';
       $src_dir_rel   = 'about/perl/functions/';

       $hook_transform_dest_path = sub {
         print "transform_dest_path: $dest_path\n";

         if ($dest_path =~ m!(.*)/require(/?)([^/]*)$!) {
           print "Changing $dest_path to $1$2$3\n";
           $dest_path = "$1$2";
         }

       };

       one_to_one(
          dest_dir_rel => $dest_dir_rel ,
          title_prefix =>'Perl function:' ,
          index_title  =>'Perl functions' ,
       );

    } #  }
    elsif ($github_path_rel_under_repo eq 'operators/') { #  {

       $dest_dir_rel  = 'development/languages/Perl/operators/';
       $src_dir_rel   = 'about/perl/operators/';


       one_to_one(
          dest_dir_rel => $dest_dir_rel ,
          title_prefix =>'Perl operator' ,
          index_title  =>'Perl operators' ,
       );

    } #  }
    elsif ($github_path_rel_under_repo eq 'regular-expressions/') { #  {

       $dest_dir_rel  = 'development/languages/Perl/regular-expressions/';
       $src_dir_rel   = 'about/perl/regular-expressions/';


       one_to_one(
          dest_dir_rel => $dest_dir_rel ,
          title_prefix =>'Perl regular expressions:',
          index_title  =>'Perl regular expressions' ,
       );

    } #  }
    elsif ($github_path_rel_under_repo eq 'variables/') { #  {

       $dest_dir_rel  = 'development/languages/Perl/variables/';
       $src_dir_rel   = 'about/perl/variables/';


       one_to_one(
          dest_dir_rel => $dest_dir_rel ,
          title_prefix =>'Perl variables:',
          index_title  =>'Perl variables' ,
       );

    } #  }
    else {
      die "Wrong sub topic $github_path_rel_under_repo for $github_repo";
    }


  } # }
  elsif ($github_repo eq 'about-svg' ) { # {

    $dest_dir_rel = 'design/graphic/svg/examples/';
    $src_dir_rel  = 'about/svg/';

    one_to_one(
       dest_dir_rel => $dest_dir_rel ,
       title_prefix =>'SVG example:' ,
       index_title  =>'SVG examples' ,
    );

  } # }
  elsif ($github_repo eq 'scripts-and-utilities' ) { # {

    $dest_dir_rel = 'development/tools/scripts/personal/';
    $src_dir_rel  = 'lib/scripts/';

    $remove_suffix_from_dest_path = 0;

    one_to_one(
       dest_dir_rel        => $dest_dir_rel ,
       title_prefix        =>'Script:' ,
       index_title         =>'Scripts' ,
       no_title_whitespace => 1        ,
       no_descend_dir      => 1        ,
    );

  } # }
  elsif ($github_repo eq 'oracle-patterns' ) { # {

    if    ($github_path_rel_under_repo eq 'Installed/dynamic-performance-views/') { #  {

       $dest_dir_rel  = 'development/databases/Oracle/installed/dynamic-performance-views/';
       $src_dir_rel   = 'github/oracle-patterns/Installed/dynamic-performance-views/';

       my @examples = ();
    
       $hook_init = sub {
         make_sure_dest_path_is_dir_and_exists();
       };
       $hook_dir = sub {
         make_sure_dest_path_is_dir_and_exists();
    
         print $File::Find::name, "\n";

         if (my @files = grep {-f} glob ("$src_path*.sql")) { # Does the directory contain files:

           my $v_view_name = $rel_path;
           $v_view_name =~  s!/!_!g;
           $v_view_name = 'v$' . $v_view_name;


           print "opening index in $dest_path\n";
           open(my $index, '>', "${dest_path}/index") or die;
           print $index '$ ' . $v_view_name . "\n";
           push @examples, [$notes_path, $v_view_name];

           foreach my $file (@files) {

             my $file_rel = File::Spec->abs2rel($file, $src_top_dir);

             print $index "\ngh|$github_repo|/$github_path_rel_under_repo$file_rel||\n"; 
           }

           print $index "\nsa:\n  → $dest_dir_rel\[Oracle Dynamic Performance Views]\n";

           close $index;

        }
        else {
        }
        

#     $File::Find::prune = 1;
    };
    $hook_file = sub {

#     do nothing

    };
    $hook_dir_leave = sub {
       open (my $f, '>', "$ENV{github_root}notes/notes/${dest_dir_rel}index") or die;

       print $f "\$ Oracle dynamic performance views\n\n";

       for my $e (@examples) {
         printf $f ("\n → %s[%s]\n", $e->[0], $e->[1]);
       }
    };


    } #  }
    else {
      die "Wrong sub topic $github_path_rel_under_repo for $github_repo";
    }


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

# print "creating dir $dest_path\n";
  make_path $dest_path or die "Could not create $dest_path [$!]"

} # }

sub open_dest_path { # {

# Just to be sure
  die "$dest_path contains a dot" if $dest_path =~ /\./;

  if (-e $dest_path) {
    if ($force_overwrite) {
      print "$dest_path already exists\n";

      open (my $f, '>', $dest_path) or die;
      return $f;

    }
    else {
      print "$dest_path already exists, I won't overrite\n";
      return undef;
    }
  }
  else {

      open (my $f, '>', $dest_path) or die;
      return $f;
  }

} # }

sub one_to_one { # Used for svg, document object model {

  print join "\n", @_;

  my %opts = @_;

  my $dest_dir_rel     = $opts{dest_dir_rel} or die; # 'development/web/DOM'
  my $title_prefix     = $opts{title_prefix} or die; # 'SVG example: '
  my $index_title      = $opts{index_title } or die; # 'SVG examples'

  my @all_examples = ();

  $hook_init = sub {
    make_sure_dest_path_is_dir_and_exists();
  };

  $hook_dir = sub {
    if ($opts{no_descend_dir}) {
      $File::Find::prune = 1;
      return;
    }
    make_sure_dest_path_is_dir_and_exists();
  };

  $hook_file = sub {

    die if $filename =~ /^\./;
    return if $filename eq 'README.md';

    my $title = $filename;

    unless ($opts{no_title_whitespace}) {
      $title =~ s/\..*//;
      $title =~ y/-_/  /;
    }


    my $f = open_dest_path();

    if ($f) {
  
      print $f "\$ $title_prefix $title\n\n";
      print $f "gh|$github_repo|$github_path||\n";
  
      print $f "\nsa:\n  → $dest_dir_rel\[$index_title]\n";

      close $f;
    }
    else {
      print "!\$f !!!!\n";
    }

    push @all_examples, [$notes_path, $title];  

  };
  $hook_exit = sub {

    my $example_path = "$ENV{github_root}notes/notes/$dest_dir_rel/index";

    if (-e $example_path) {
      if ($force_overwrite) {
        print "$example_path alraedy exists\n";
      }
      else {
        die "$example_path already exists\n";
      }
    }
    open (my $f, '>', $example_path) or die "could not open $example_path";

    print $f "\$ $index_title\n\n";

    for my $e (@all_examples) {
      printf $f ("→ %s[%s]\n\n", $e->[0], $e->[1]);
  }

    }
} # }
