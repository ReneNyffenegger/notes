# vim: ft=perl
package notes;

use warnings;
use strict;

use utf8;
use Encode;
use Storable;

our $non_file_chars ='\ ,.()?:;`*→\[\]«»%~{}<>☰'; 

our %index;
our $html_suffix;

my  $verbose;

sub init { # {{{

  my $web              = shift;
  my $test             = shift;
     $verbose          = shift;

  if ($web or $test) {
      $html_suffix = '';
  }
  else {
      $html_suffix = '.html';
  }

  print "notes.pm: html_suffix = $html_suffix\n" if $verbose;


} # }}}

sub replace_notes_link { # {{{

  my $line = shift;
  my $input_filename_os = shift;


  $line =~ s{
    →\ *                    # start with an arrow, followed by 0 or more blanks
    (                       # capture linked page.
       [^$non_file_chars]+  #   linked page must not have spaces nor opening bracket
    )
    (                       # 
        \[                  # followed by an (optional) square bracket
           (
             [^\]]+
           )
        \]
    )?                      # square bracked is optional
  
  }{

    my $page_linked_to = $1;
    my $optional_text  = $3;
    my $anchor_id = '';


    if ($page_linked_to =~ /([^#]*)#(.*)/) {

      $page_linked_to = $1;
      $anchor_id      = $2;

      $page_linked_to = umlaute(os_to_perl($input_filename_os)) unless $page_linked_to;

    }
#   ------------------------------------------------------------------------
#   2017-01-03 using the absolute path (with $ENV{'github_root'}) breaks the
#              test cases, so test directory according to target_env
    if              ( ($RN::target_env eq 'test' and  -d $ENV{'github_root'} . 'notes/test/notes/' . perl_to_os($page_linked_to)) or
                      (                               -d $ENV{'github_root'} . 'notes/notes/'      . perl_to_os($page_linked_to)) 
                    )
#   ------------------------------------------------------------------------
    {

      $page_linked_to =~ s,/$,,;
      $page_linked_to .= '/index';

    }

    $page_linked_to = umlaute($page_linked_to);


    my $anchor_txt = '';

    my $text ='';
    if ($anchor_id) {
      $anchor_txt = "#$anchor_id";

      if ($optional_text) {
        $text = $optional_text;
      }
      else {
        $text = $index{$page_linked_to}{anchors}{$anchor_id}{title};
      }

      if (! $text) {

         print "no text/title found in page_linked_to: $page_linked_to, anchor_id: $anchor_id\n";

         for my $a (keys %{$index{$page_linked_to}{anchors}}) {
          
            print "  #$a -> $index{$page_linked_to}{anchors}{$a}{title}\n";

         }

         die "No text found, page_linked_to: >$page_linked_to<, anchor_id: $anchor_id" unless $text;
      }
    }
    else {
       if (exists $index{$page_linked_to}{title_intern}) {
         $text = $index{$page_linked_to}{title_intern};
       }
       else {
         $text = $index{$page_linked_to}{title};
       }

        if (! $text) {
          print "\nDying introduction (No title for paged_linked_to)\n";
          print "\n-------------------------------------------------\n";
          print "  input_filename_os = $input_filename_os<\n";
          print "  page_linked_to    = $page_linked_to<\n\n";
          print "  index{page_linked_to} does not exist\n" unless $index{$page_linked_to};
          print "  index{page_linked_to}{title} = " . $index{$page_linked_to}{title} . "\n";
          die "page_linked_to >$page_linked_to#$anchor_id<" unless $text;
        }

    }


    unless (exists $index{$page_linked_to}{title}) {
       $index{$page_linked_to}{title} = $page_linked_to;
    }

    $text = $optional_text if defined $optional_text;

    "<a href='" . RN::url_path_abs_2_url_full('/notes/') . umlaute($page_linked_to) . "$html_suffix$anchor_txt'>$text</a>"; 
      
  }gex;


  return $line;

} # }}}

sub load_index { # {{{

  my $index_file = shift;


  if (-e $index_file) {
    print "notes.pm: loading index file $index_file\n" if $verbose >= 1;
    %index = %{ retrieve $index_file };
  }
  else {
    print "notes.pm: index file $index_file cannot be loaded because it does not exist\n" if $verbose >= 1;
  }

} # }}}

sub store_index { # {{{

  my $index_file = shift;

  print "notes.pm: storing index file $index_file\n" if $verbose >= 1;
  store \%index, $index_file;

} # }}}

sub set_title_of_file { # {{{

  my $input_filename_os = shift;
  my $title             = shift;
  my $title_intern      = shift;

  die unless defined $title_intern; # 2017-02-12 TODO: remove me if it proves to work

  my $entry = umlaute(os_to_perl($input_filename_os));

  print "notes.pm: setting title of $entry to $title\n" if $verbose >= 1;

  $index{$entry}{title} = $title;
  if ($title_intern) {
    $index{$entry}{title_intern} = $title_intern;
  }

} # }}}

sub set_title_of_anchor { # {{{
  my $input_filename_os = shift;
  my $anchor_id         = shift;
  my $title             = shift;

  $index{umlaute(os_to_perl($input_filename_os))}{anchors}{$anchor_id}{title}=$title;

} # }}}

sub perl_to_os { # {{{

  my $perl = shift;
  if ($^O eq 'MSWin32') {
    return encode('latin-1', $perl);
  }
  else {
    return encode('utf-8', $perl);
  }

} # }}}

sub os_to_perl { # {{{

  my $filename_os = shift;
  if ($^O eq 'MSWin32') {
    return decode('latin-1', $filename_os);
  }
  else {
    return decode('utf-8', $filename_os);
  }

} # }}}

sub umlaute { # {{{

  my $text = shift;

  $text =~ s/ä/ae/g;
  $text =~ s/ö/oe/g;
  $text =~ s/ü/ue/g;

  $text =~ s/Ä/Ae/g;
  $text =~ s/Ö/Oe/g;
  $text =~ s/Ü/Ue/g;

  $text =~ s/é/e/g;

  return $text;

} # }}}

sub os_path_to_perl_path { # {{{

  my $os_path = shift;
  return umlaute(os_to_perl($os_path));

} # }}}

sub url_root { # {{{
  die "deprecated";
} # }}}

sub path_in_rel_2_path_out_abs { # {{{
  die "deprecated";
} # }}}

sub input_filename_os_2_out_filename { # {{{
  die "deprecated";

} # }}}

1;
