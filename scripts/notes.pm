package notes;

use utf8;
use Encode;
use Storable;

our $non_file_chars ='\ ,.()?:;`*→\[\]«»%~{}<>'; 

our %index;

our $notes_root;

our $html_suffix;

our $file_out_dir;

sub init { # {{{

  my $web              = shift;
  my $test             = shift;
  my $notes_input_root = shift; # For example /foo/bar/notes  (NOT /foo/bar/notes/notes)


  if ($web or $test) {
      $html_suffix = '';
      $file_out_dir = "$notes_input_root/out/";
      $notes_root = "/notes/";
  }
  else {
#     $notes_root =~ s|\\|/|g;
      $html_suffix = '.html';
      $file_out_dir = "$notes_input_root/out.html/";
      $notes_root = "file://${notes_input_root}/out.html/";
  }


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
    if (-d perl_to_os($page_linked_to)) {

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
       $text = $index{$page_linked_to}{title};

        if (! $text) {
          print "\nDying introduction\n";
          print "\n------------------\n";
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

    "<a href='$notes_root$page_linked_to$html_suffix$anchor_txt'>$text</a>"; 
      
  }gex;


  return $line;

} # }}}

sub load_index { # {{{

  my $index_file = shift;


  %index = %{ retrieve $index_file } if -e $index_file;

} # }}}

sub store_index { # {{{

  my $index_file = shift;
  store \%index, '.index';

} # }}}

sub set_title_of_file { # {{{

  my $input_filename_os = shift;
  my $title             = shift;

  $index{umlaute(os_to_perl($input_filename_os))}{title} = $title;

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

  $text =~ s/ä/ae/;
  $text =~ s/ö/oe/;
  $text =~ s/ü/ue/;

  $text =~ s/Ä/Ae/;
  $text =~ s/Ö/Oe/;
  $text =~ s/Ü/Ue/;

  $text =~ s/é/e/;

  return $text;

} # }}}

sub url_root { # {{{

  return $notes_root;

} # }}}

sub path_in_rel_2_path_out_abs { # {{{

  my $file_in_rel = shift;

  return "$file_out_dir$file_in_rel";

} # }}}

sub input_filename_os_2_out_filename { # {{{

  my $input_filename_os = shift;

  return $file_out_dir . umlaute(os_to_perl($input_filename_os)) . $html_suffix;

} # }}}

1;
