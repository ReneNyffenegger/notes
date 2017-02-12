#!/usr/bin/perl
# vim: ft=perl foldmarker={{{,}}} foldmethod=marker

use warnings;
use strict;

my $remove_me_counter = 0;

use lib "$ENV{github_root}/notes/scripts/";
use lib "$ENV{github_root}/RN/";

use File::Touch;
use LWP::Simple;
use File::Copy;
use File::Find;
use File::Basename;
use File::Path qw(make_path);
use Cwd;
use Getopt::Long;
use utf8;
use notes;
use RN;


my $verbose = 0;
Getopt::Long::GetOptions(
    "web"        => \my $web,
    'verbose'    => \   $verbose
);

my $test;

if (cwd() =~ /notes.test$/) {
  $test = 1;
}
elsif (cwd() =~ /github.notes$/) {
  $test = 0;
}
else {
  $test = 0;
}

if (! $web and ! $test) {
}
else {
}

notes::init(
  $web,
  $test, 
# cwd(),  # 2017-01-02
  $verbose
);

my $target_env;
if ($web) {
  $target_env = 'web';
}
elsif ($test) {
  $target_env = 'test';
}
else {
  $target_env = 'local';
}

print "target_env = $target_env\n" if $verbose >= 1;
RN::init(
  $target_env,
  $verbose # 2017-01-02
);

my $last_run_file_url_path_abs   = '/notes/.last-run';
my $index_file_url_path_abs      = '/notes/.index';

my $last_run_file_os_path_abs = RN::url_path_abs_2_os_path_abs($last_run_file_url_path_abs);
my $index_file_os_path_abs    = RN::url_path_abs_2_os_path_abs($index_file_url_path_abs   );

print "last_run_file_url_path_abs = $last_run_file_url_path_abs\n" if $verbose >= 1;
print "index_file_os_path_abs     = $index_file_os_path_abs\n"     if $verbose >= 1;

RN::ensure_dir_for_url_path_abs($last_run_file_url_path_abs);
RN::ensure_dir_for_url_path_abs($index_file_url_path_abs   );

die "could not change into ./notes" unless -d './notes';
chdir './notes' or die;

$web = 0 unless $web;


# Also change in C:/localgit/biblisches/kommentare/alle_kapitel_local.pl


print "is_test:       $test\n";
print "web:           $web\n";
print "last_run_file: $last_run_file_os_path_abs (" . (-e $last_run_file_os_path_abs ? -M $last_run_file_os_path_abs : '?') . ")\n";
print "index file:    $index_file_os_path_abs\n";



my $debug = 0;
unless (-e $last_run_file_os_path_abs) {
  my $touch_1970 = new File::Touch (mtime => 0);
     $touch_1970 -> touch($last_run_file_os_path_abs);
}


notes::load_index($index_file_os_path_abs);

my $pass;
$pass = 1; find({ no_chdir=>1, wanted=> \&process_page, preprocess=>\&preprocess_dir} , '.');
$pass = 2; find({ no_chdir=>1, wanted=> \&process_page, preprocess=>\&preprocess_dir} , '.');

notes::store_index($index_file_os_path_abs);
print "$index_file_os_path_abs stored\n" if $verbose >= 1;

print "going to process index\n" if $verbose >= 1;
process_index();
print "index processed\n" if $verbose >= 1;


touch $last_run_file_os_path_abs;
print "touched $last_run_file_os_path_abs\n" if $verbose >= 1;

my $notes_css = '../res/notes.css';
die "$notes_css does not exist, cwd=" . cwd() unless -f $notes_css;
# RN::copy_os_path_2_url_path_abs('../res/notes.css', '/notes/notes.css');
# put_ftp('notes.css');
my $notes_css_dest = RN::url_path_abs_2_os_path_abs('/notes/notes.css');
print "copying $notes_css to $notes_css_dest\n";
copy($notes_css, $notes_css_dest) or print "\n\n  Failed to copying $notes_css to $notes_css_dest\n\n";

if ($web) {
# 
# # copy('notes.css', $notes::file_out_dir) or die "could not copy notes.css to $notes::file_out_dir";
#   # 2017-01-21 RN::copy_os_path_2_url_path_abs($notes_css, '/notes/notes.css');
   RN::copy_os_path_2_url_path_abs(RN::url_path_abs_2_os_path_abs($notes_css), "/notes/notes.css");
}


sub process_page { # {{{

  # {{{
  return if $File::Find::name eq '.';

  my $input_filename_os = substr($File::Find::name, 2);
  my $file_name_only_os      = basename($input_filename_os);

  if ($file_name_only_os =~ m'TODO DEBUG') {
     $debug = 1;
  }
  else {
     $debug = 0;
  }

  return if substr($file_name_only_os, 0, 1) eq '.' or
            substr($file_name_only_os, 0, 2) eq '_.'; # Windows vim swap files

  if (-M $last_run_file_os_path_abs < -M $input_filename_os) {
    return;
  }

# 2017-01-27 directories might be named exactly »svg«...
 if ($file_name_only_os ne 'svg') { # {{{
 (my $suffix = $file_name_only_os) =~ s/.*\.(\w*)$/$1/;

  if ( $suffix eq 'png' or $suffix eq 'jpg' or $suffix eq 'svg') { # {{{
    
    if ($pass == 2) {
      RN::copy_os_path_2_url_path_abs ($input_filename_os, "/notes/$input_filename_os");
    }

    return;
  } # }}}
  } # }}}


  my $file_name_with_path_uml = notes::umlaute(notes::os_to_perl($input_filename_os));
  if (-d $input_filename_os) { # {{{
    return;
  } # }}}


  return if $file_name_only_os =~ /\.pl$/;


  print "open [$pass] $input_filename_os\n" if $verbose >= 2;
  open (my $f, '<', $input_filename_os) or die "could not open $input_filename_os for reading";
  binmode($f); binmode($f, ':encoding(UTF-8)');

  my $next_t_with_gap = 0;
  my $last_thing_was_blocky_paragraph = 0;
  my $empty_line_sets_next_t_with_gap = 0;
  my $title = '';
  my $styles = '';
  my $line;
  my $abbr = '';
  my $aka  = '';
  my $wp   = '';
  my $ul   = 0;

  DIRECTIVES: while ($line = <$f>) { # 1st Iterate over directives {{{

    print "directive ?: $line" if $debug;

    if ($line =~ /^\$ *(.*) *$/) { $title = $1; next; }
    if ($line =~ /^abbr: *(.*) *$/) { $abbr = $1; next; }
    if ($line =~ /^aka: *(.*) *$/)   { $aka  = $1; next; }
    if ($line =~ /^wp *(.*) *$/   ) { $wp   = $1; next; }

    if ($line =~ /^style \{/) { # {{{

      while ($line =<$f>) {

        next DIRECTIVES if $line =~ /^style }/;
        $styles .= $line;

      }

    } # }}}

    last;
  } # }}}
  if ($line) { # {{{
    print "seeking, becauselength($line)\n" if $debug;
    my $length_line;
    { use bytes;
      $length_line = length($line);
    }
#   seek($f, -length($line), 1) or die "\n$!\nline = $line, length = " . length($line); # http://code.izzid.com/2008/01/21/How-to-move-back-a-line-with-reading-a-perl-filehandle.html
    seek($f, -$length_line, 1) or die "\n$!\nline = $line, length = " . $length_line; # http://code.izzid.com/2008/01/21/How-to-move-back-a-line-with-reading-a-perl-filehandle.html // http://perlmeme.org/howtos/using_perl/length.html

  } # }}}


  unless ($title) { # {{{
    if ($file_name_only_os eq 'index') {
      $title = notes::os_to_perl(basename(dirname($input_filename_os)));
    }
    else {
      $title = notes::os_to_perl($file_name_only_os);
    }
    $title =~ s/-/ /g;
    if ($debug) {
      print "No title found, assigned $file_name_only_os and substituted to $title\n";
    }
  } # }}}

  $title .= " - $abbr" if $abbr;

# TODO: It should be sufficient to call set_title_of_file only when $pass==1
  notes::set_title_of_file($input_filename_os, $title);

  my $url_path_abs = notes::os_path_to_perl_path("/notes/$input_filename_os");
  my $out;
  if ($pass == 2) {
# $out = open_html( $input_filename_os, $title, $styles);
    print "opening html $url_path_abs\n";
    $out = open_html( $url_path_abs     , $title, $styles);
  }

  if ($pass == 2 && $aka) { # {{{
    print $out "Also known as: <i>$aka</i><p>";
  } # }}}

  # }}}
# Then iterate over content {{{

  my $in_text  = 0; # {{{ Variables
  my $in_html  = 0;
  my $in_rem   = 0;
  my $in_code  = 0;
  my $in_quote = 0;
  my $in_sa_links_etc   = '';
  my $h_level = 1; # }}}

  while ($line = <$f>) { # {{{

    print "ntw: $next_t_with_gap, ltwc: $last_thing_was_blocky_paragraph, it: $in_text, q: $in_quote, line: $line" if $debug;

    chomp $line;

    if ($line =~ /^\s*rem\s*}\s*$/) {  # {{{ End remark

      dbg('end remark');

      $in_rem = 0;
      next;

    } # }}}

    if ($line =~ /^\s*rem\s*{\s*$/) {  # {{{ Begin remark

      dbg('start remark');

      $in_rem = 1;
      next;

    } # }}}

    next if $in_rem;


    if ($line =~ /^\s*html\s*}\s*$/) { # {{{ End raw html section

      dbg('ending raw html section');

      $last_thing_was_blocky_paragraph = 1;

      $in_html = 0;
      next;

    } # }}}

    if ($line =~ /^\s*html\s*{\s*$/) { # {{{ Begin raw html section

      dbg('starting raw html section');

      die if $in_html;
      $in_html = 1;

      blocky_paragraph_start($out, $pass, \$in_text, $ul, \$next_t_with_gap, \$empty_line_sets_next_t_with_gap);

      next;

    } # }}}

    if ($in_text and $line =~ /^ *- *$/) { # {{{ Paragraph without gap

      end_div_t($out, \$in_text, \$ul, $pass, \$next_t_with_gap);
      print $out "\n" if $pass == 2;
      $next_t_with_gap = 0;
      next;

    } # }}}

    if ($line =~ /^\s*code\s*}\s*$/) {  # {{{ End code

      dbg ('Ending code');

      die unless $in_code;

      $in_code = 0;
      print $out "</pre>" if $pass == 2;
      $empty_line_sets_next_t_with_gap = 1;
      $last_thing_was_blocky_paragraph = 1;
      next;

    } # }}}

    if ($line =~ /^\s*code\s*{\s*$/) {  # {{{ Begin code

      dbg ('Starting code');

      die if $in_code;
      $in_code = 1;

      blocky_paragraph_start($out, $pass, \$in_text, $ul, \$next_t_with_gap, \$empty_line_sets_next_t_with_gap);

      print $out "<pre class='code'>" if $pass == 2;
      next;

    } # }}}

    if (not $in_code and $line =~ /^\s*"\s*$/) { # {{{ start / end quote ( exactly one " in line)


      if ($in_quote) {
        dbg('found \", ending quote');
        end_quote($out, '', \$in_quote, \$in_text, \$ul, \$next_t_with_gap, \$empty_line_sets_next_t_with_gap, '', $input_filename_os);
      }
      else {
        dbg('found \", starting quote');
        start_quote($out, '', \$in_quote, \$in_text, \$ul, \$next_t_with_gap, \$empty_line_sets_next_t_with_gap, \$last_thing_was_blocky_paragraph, $input_filename_os);
      }
      next;

    } # }}}

    if (not $in_code and $line =~ /^ *"([^[]*)$/) { # {{{ Start Quote

      dbg("calling start_quote, ul=$ul");
      start_quote($out, $1, \$in_quote, \$in_text, \$ul, \$next_t_with_gap, \$empty_line_sets_next_t_with_gap, \$last_thing_was_blocky_paragraph);
      dbg("called start_quote, last_thing_was_blocky_paragraph = $last_thing_was_blocky_paragraph");
      next;

    } # }}}

    if (not $in_code and $line =~ /(.*)" *(\[ *(.+) *\])? *$/) { # {{{ End Quote

      my $q_text = $1;
      my $source = $3;

      dbg("end quote: source = " . (defined $source ? $source : '') );

      end_quote($out, $q_text, \$in_quote, \$in_text, \$ul, \$next_t_with_gap, \$empty_line_sets_next_t_with_gap, $source);
      next;

    } # }}}

    if ($in_rem) { # {{{
      dbg('in rem');
      print "in rem" if $debug;
      next;
    } # }}}

    if ($line =~ /^(sa|links|rel): */) { # {{{ See also

      my $sa_link_etc = $1;
      my $section_title;
      if ($sa_link_etc eq 'sa') {
         $section_title = 'See also';
      }
      elsif ($sa_link_etc eq 'rel') {
         $section_title = 'Related';
      }
      else {
         $section_title = 'Links';
      }

      if ($in_sa_links_etc) {
        end_section($out, \$in_text, \$h_level, \$last_thing_was_blocky_paragraph);
      }


      die "in_sa_links_etc: $in_sa_links_etc, sa_link_etc: $sa_link_etc" if $in_sa_links_etc eq $sa_link_etc;
      $in_sa_links_etc = $sa_link_etc;

      die "h_level = $h_level ($File::Find::name)" unless $h_level == 1;

      start_section($out, $section_title, \$h_level, '', \$in_text, \$next_t_with_gap, \$empty_line_sets_next_t_with_gap);
      next;

    } # }}}

    unless ($in_html) { # {{{ Replace html entities
      $line =~ s/&/&amp;/g;
      $line =~ s/</&lt;/g;
      $line =~ s/>/&gt;/g;
    } # }}}

    if ($in_code) { # {{{ in code
      dbg('in code');
       if ($pass == 2) {
         $line = notes::replace_notes_link($line, $input_filename_os);
         print $out "$line\n";
       }
       next;
    } # }}}

    if ($in_html) { # {{{ in html
      dbg('in html');
      print $out "$line" if $pass == 2;
      next;
    } # }}}

    if ($in_quote) { # {{{

      if ($pass == 2) {

        if ($line =~ /^\s*$/) {
           print $out "\n<div class='gap'></div>";
        }
        elsif ($line =~ /^\s*-\s*$/) {
           print $out "<br>";
        }
        else {

          $line = replace_external_link($line);
          $line = notes::replace_notes_link($line, $input_filename_os);
          $line = bold_italic($line);
          $line = bible_verse($line);

          print $out $line;
        }
      }
      next;

    } # }}}

    if ($line =~ /^\s*$/) { # {{{ Empty line, end div

      dbg('empty line, ending div');

      $last_thing_was_blocky_paragraph = 0;

      end_div_t($out, \$in_text, \$ul, $pass, \$next_t_with_gap);
#     $in_text = 0;

      if ($empty_line_sets_next_t_with_gap) {
        $next_t_with_gap = 1;
        $empty_line_sets_next_t_with_gap = 0;
      }

      next;
    } # }}}

    if ($line =~ /^\s*{ *(.*)/) { # {{{  start subtitle

        dbg('Starting subtitle');

        $last_thing_was_blocky_paragraph = 0;

        my $h_text = $1;

        dbg('start subtitle $h_text');

        my $anchor_txt='';
        if ($h_text =~ /(.*?) *?# *(.*?) *$/) {

          $h_text = $1;
          my $anchor_id = $2;
          $anchor_txt = " id='$anchor_id'";

          notes::set_title_of_anchor($input_filename_os, $anchor_id, $h_text);

        }

        start_section($out, $h_text, \$h_level, $anchor_txt, \$in_text, \$next_t_with_gap, \$empty_line_sets_next_t_with_gap);

        next;

    } # }}}

    if ($line =~ /^\s*}\s*$/) { # {{{ End of section

      end_section($out, \$in_text, \$h_level, \$last_thing_was_blocky_paragraph);

        next;

    } # }}}

    if (!$in_text or $last_thing_was_blocky_paragraph) { # {{{ Start new text div

      start_div_t(\$in_text);

      $in_text = 1;

      my $uc = '';

      if ($line =~ s/^(\s*)\?/$1/) {
         $uc = ' uc';
       }


      if ($pass == 2) {
        print $out "\n<div class='g'></div>" if $next_t_with_gap and not $last_thing_was_blocky_paragraph;
        print $out "\n<div class='t$uc'>\n";
      }

      $last_thing_was_blocky_paragraph = 0;
    } # }}}

    if ($pass == 2) { # {{{ Only manipulate $line if $pass == 2

#   $linkifyer->find(\$line);

    $line =~ s/(\d) (v|n)\. *Chr\./$1&nbsp;$2.&nbsp;Chr./g;
    $line =~ s/(\d) a\. *H\./$1&nbsp;a.&nbsp;H./g;

    $line =~ s/(\d)° *([0-9.]+)' *([0-9.]+)" *([NEWSO])/$1°&nbsp;$2′&nbsp;$3″&nbsp;$4/g;
    $line =~ s/(\d)° *([0-9.]+)' *([0-9.]+)"/$1°&nbsp;$2′&nbsp;$3″/g;
    $line =~ s/(\d)° *([0-9.]+)' *([NEWSO])/$1°&nbsp;$2′&nbsp;&nbsp;$3/g;
    $line =~ s/(\d)° *([0-9.]+)'/$1°&nbsp;$2′/g;

    $line =~ s/\bj(-?\d+)\b/$1/g;

    if ($line =~ s/(\s)•(.*)/$2/) { # {{{ UL element

      my $ul_ = length($1);

      unless ($ul) {

        print $out "<ul>";
        $ul = $ul_;

      }

      print $out "\n<li>";

    } # }}}
    else { # {{{ No UL Element

      if ($ul) {

        print $out "</ul>\n";
        $ul = 0;

      }

    } # }}}

    # {{{ Links
    # {{{  Media files jpg, png, svg ...

     $line =~ s{

      →\ *( ( [^$notes::non_file_chars]+ \.(png|svg|jpg) ) )

     }{

       my $media_file = $1;
       my $suffix     = $3;
       my $ret;

       if ($suffix eq 'png' or $suffix eq 'jpg') {

         $ret = "<img src='" . RN::url_path_abs_2_url_full('/notes/') . "$media_file' />";

       }
       elsif ($suffix eq 'svg') {

         $ret = "<object data='" . RN::url_path_abs_2_url_full('/notes/') .  "$media_file' type='image/svg+xml'></object>"

       }

       $ret;

     }gex;

    # }}}
    # {{{ replace → to external site
  
    $line = replace_external_link($line);

    # }}}
    # {{{ replace → to local file
  
    $line = notes::replace_notes_link($line, $input_filename_os);

    # }}}
    # }}}

    # {{{ replace yt|||
    
    $line =~ s{

      \byt\|
      ([^|]+)\|
      ([^|]+)\|

    }{

      "<a href='http://www.youtube.com/watch?v=$1' target='_blank'>$2</a>"

    }gex;

    # }}}
    # {{{ replace mapch|||
    
    $line =~ s{

      \bmapch\|
      ([^|]+)\|
      ([^|]+)\|
      ([^|]+)\|
      ([^|]*)\|

    }{

      my $x = $1;
      my $y = $2;
      my $zoom = $3;

      "<a href='https://map.geo.admin.ch/?lang=de&bgLayer=ch.swisstopo.pixelkarte-farbe&X=$x&Y=$y&zoom=$zoom'>Swisstopo: $x / $y</a>"

    }gex;

    # }}}
    # {{{ bold, italic, verses
    
    $line = bold_italic($line);
    $line = bible_verse($line);
    $line = sub_sup    ($line);
    


    # }}}
    # {{{ `

    $line =~ s{`([^`]+)`}{ <code>$1</code>}g;

    # }}}
    # {{{ Github source code (Must be at end, otherwise replacement of bold, italic etc kicks in!)

    $line =~ s{

      \bgh\|
      ([^|]+)\|
      ([^|]+)\|
      ([^|]*)\|

    }{

      my $repo = $1;
      my $path = $2;
      my $opts = $3;

      if ($pass == 2) {

  #     2017-01-27 $path should be prefixed by a slash anyway:
        if (substr($path, 0, 1) ne '/') {
          print "gh: $path does not start with /\n";
        }
  #     my $url = "https://raw.githubusercontent.com/ReneNyffenegger/$repo/master/$path";
        my $url = "https://raw.githubusercontent.com/ReneNyffenegger/$repo/master$path";

        my $code = get($url);

        $code =~ s/&/&amp;/g;
        $code =~ s/</&lt;/g;
        $code =~ s/>/&gt;/g;

        ($in_text ? "</div>" : "") .
        "<div class='ghf'>Github respository <a href='https://github.com/ReneNyffenegger/$repo'>$repo</a>, path: <a href='https://github.com/ReneNyffenegger/$repo/blob/master$path'>$path</a></div>" .
        "<pre class='code'>$code</pre>" .
        ($in_text ? "\n<div class='t'>" : "");


     }
     else {
       "gh pass 1";
     }

    }gex;

    # }}}
    print $out "$line ";

    } # }}}


  } # }}}

  if ($in_text) { # {{{ close in text

    end_div_t($out, \$in_text, \$ul, $pass, \$next_t_with_gap);
  } # }}}

  if ($in_sa_links_etc) {
    end_section($out, \$in_text, \$h_level, \$last_thing_was_blocky_paragraph);
  }

  die "h_level = $h_level in $File::Find::name" unless $h_level == 1;

  close_html($out, $wp) if $pass == 2;

  die "In quote" if $in_quote; 
  die "In code"  if $in_code;
  # }}}


  if ($pass == 2 and $target_env eq 'web') {
    print "to web: $url_path_abs\n";
    RN::copy_os_path_2_url_path_abs(RN::url_path_abs_2_os_path_abs($url_path_abs), $url_path_abs);
  }


} # }}}

sub replace_external_link { # {{{
  my $line = shift;

  $line =~ s{
    →\ *            # start with an arrow, followed by 0 or more blanks
    (               #   capture linked page.
       [^\ \[]+     #   linked page must not have spaces nor opening bracket
       (\.|localhost) #   linked page must have at least one dot or onsist of the word localhost
       [^\ \[]+     #   linked page must not have spaces nor opening bracket
    )
    (\[             # followed by an optional square bracket
       (
         [^\]]+
       )
    \])?
  }{


    my $link = $1;
    my $text = $4;

    my $text_after = '';
    unless (defined $text) {
      
      if ($link =~ s/(\.|,|!|:|\?|\))$//) {
        $text_after = $1;
      }

      $text = $link;
    }

    "<a class='ext' href='$link'>$text</a>$text_after"; 
      
  }gex;

  return $line;

} # }}}

sub process_index { # {{{

  for my $k (keys %notes::index) {
    print "no title for $k\n" unless exists $notes::index{$k}{title};
  }

  my $html;
  $html = open_html('/notes/index.html', 'Notes', '');


  for my $page (sort {lc($notes::index{$a}{title}) cmp 
                      lc($notes::index{$b}{title})
                     } keys %notes::index) {

    print $html "<a href='$page$notes::html_suffix'>$notes::index{$page}{title}</a><br>\n";

  }

  close_html($html, '');

  if ($target_env eq 'web') {
#   2016-08-01
#   RN::copy_os_path_2_url_path_abs(RN::url_path_abs_2_os_path_abs("/notes/index.html"), "/notes/index$notes::html_suffix");
    RN::copy_os_path_2_url_path_abs(RN::url_path_abs_2_os_path_abs("/notes/index.html"), "/notes/index.html");
  }
} # }}}

sub end_div_t { # {{{

  my $out                 = shift;
  my $in_text_ref         = shift;
  my $ul_ref              = shift;
  my $pass                = shift;
  my $next_t_with_gap_ref = shift;

  return unless $pass == 2;

  print "  ending div t\n" if $debug;

  if ($$ul_ref) {
     print $out "</ul>";
     $$ul_ref = 0;
  }
  if ($$in_text_ref) {
    print $out "</div>" if $pass == 2;
    print $out "<!-- end_div_t -->\n" if $debug and $pass == 2;
    $$next_t_with_gap_ref = 1;
  }
  $$in_text_ref = 0;
} # }}}

sub start_div_t { # {{{

} # }}}

sub open_html { # {{{

  my $input_filename_os = shift;
  my $title             = shift;
  my $styles            = shift;

  my $styles_='';

  if ($styles) {

    $styles_ = qq{
   <style type='text/css'> 
     $styles
   </style>
  };
  }



  my $out;
  if ($input_filename_os eq '/notes/index.html') {
     $out = RN::open_url_path_abs($input_filename_os);
  }
  else {
     $out = RN::open_url_path_abs("${input_filename_os}$notes::html_suffix");
  }

  my $notes_root = RN::url_path_abs_2_url_full('/notes/');
# print "notes_root: $notes_root (for js, css etc)\n";

  print $out qq{<!DOCTYPE html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>$title</title>
<link rel="stylesheet" type="text/css" href="${notes_root}notes.css">$styles_
<script src='${notes_root}q.js'></script>
</head>
<body>
<div class='screen-only'>Search notes: <input size='50' id='q' onchange='q();'></div>
<h1>$title</h1>
};

  return $out;

} # }}}

sub close_html { # {{{

  my $out = shift;
  my $wp  = shift;

  print $out "\n<div class='screen-only'>\n";
  print $out "<hr>";

  if ($wp) {
    print $out "<p><a href='https://en.wikipedia.org/wiki/$wp'>Wikipedia Link</a>";
  }

  print $out "<p><a href='/notes/index.html'>Index</a>"; # index.html is always with .html suffix

  print $out "<div class='bottom'></div>";

  print $out "</div>\n"; # screen-only
  print $out "</body>
</html>";

  close ($out);


} # }}}

sub preprocess_dir { # {{{

# print "preprocess_dir $File::Find::dir $_ - " . (join ",", @_) ."\n";

# Make sure that every folder (except .) contains an index file:
# die "no index file in $File::Find::dir" if $File::Find::dir ne '.' and not -e "$File::Find::dir/index";

  return grep { $_ !~ /^\./}  @_;

} # }}}

sub start_section { # {{{

  my $out                                 = shift;
  my $h_text                              = shift;
  my $h_level_ref                         = shift;
  my $anchor_txt                          = shift;
  my $in_text_ref                         = shift;
  my $next_t_with_gap_ref                 = shift;
  my $empty_line_sets_next_t_with_gap_ref = shift;

  if ($$in_text_ref) {
    print $out "\n</div>" if $pass == 2;
    print $out "<!-- closing t -->\n" if $debug and $pass == 2;
  }

  $$in_text_ref = 0;

  $$h_level_ref ++;
  print $out "\n<div class='h'>" if $pass == 2;
  print $out "\n<h${$h_level_ref}$anchor_txt>$h_text</h${$h_level_ref}>" if $pass == 2;

  $$next_t_with_gap_ref = 0;
  $$empty_line_sets_next_t_with_gap_ref = 0;

} # }}}

sub end_section { # {{{

  my $out                     = shift;
  my $in_text_ref             = shift;
  my $h_level_ref             = shift;
  my $last_thing_was_code_or_html_ref = shift;

   dbg('ending section');
   $$last_thing_was_code_or_html_ref = 0;
   if ($$in_text_ref) {
     print $out "\n</div>" if $pass == 2;
     print $out "<!-- closing t (because $$in_text_ref) -->\n" if $debug and $pass == 2;
   }

   $$in_text_ref = 0;
   $$h_level_ref --;
   print $out "\n</div>" if $pass == 2;
   print $out "<!-- closing h -->\n" if $debug and $pass == 2;

} # }}}

sub blocky_paragraph_start { # {{{

  my $out  = shift;
  my $pass = shift;
  my $in_text_ref = shift;
  my $ul          = shift;
  my $next_t_with_gap_ref = shift;
  my $empty_line_sets_next_t_with_gap_ref = shift;

  dbg("blocky_paragraph_start, ul=$ul"); 

  if ($$in_text_ref) {
    end_div_t($out, $in_text_ref, \$ul, $pass, $next_t_with_gap_ref);
#   $$in_text_ref = 0;
  }
  else {
    if ($$next_t_with_gap_ref) {
      print $out "\n<div class='g'></div>\n" if $pass == 2;
    }
  }

  $$empty_line_sets_next_t_with_gap_ref = 1;

} # }}}

sub dbg { # {{{

  return unless $debug;
  my $t = shift;
  print "DBG: $t\n";

} # }}}

sub bible_verse { # {{{

  my $line = shift;

  return $line unless $pass == 2;

  $line =~ s{§(\w+)-(\d+)-(\d+)(-((\d+|ff)))?} {

    my $bk = $1;
    my $ch = $2;
    my $v  = $3;
    my $w  = $5;

    my $ret;

    my $url_path_abs = "/Biblisches/Kommentare/${bk}_$ch.html#I$bk-$ch-$v";
    my $link_text;


    if ($bk =~ /(\d)(\w+)/) {
      my $bk_ = $2;
      my $no  = $1;
      $bk_ = 'Kö' if $bk_ eq 'koe';
      $link_text = $no . ".&nbsp;" . ucfirst($bk_);
    }
    else {
      $bk = 'Röm' if $bk eq 'roem';
      $link_text .= ucfirst($bk);
    }

    $link_text .= "&nbsp;$ch:$v";

    if ($w) {
      if ($w eq 'ff') {
        $link_text .= "&nbsp;ff";
      }
      else {
        $link_text .= "-$w";
      }
    }

    "<a href='" . RN::url_path_abs_2_url_full($url_path_abs) . "'>$link_text</a>";

  }gex;

  return $line;


} # }}}

sub bold_italic { # {{{

  my $line = shift;
  return $line unless $pass == 2;

  my $boundary = '[ ,.!?():]';

  $line =~ s{(^|$boundary)\*([a-zA-ZäöüÄÖÜ0-9<][^*]*)\*($|$boundary)}{$1<i>$2</i>$3}g;
  $line =~ s{(^|$boundary)~([a-zA-ZäöüÄÖÜ0-9<][^~]*)~($|$boundary)}{$1<b>$2</b>$3}g;

  return $line;
} # }}}

sub sub_sup { # {{{

  my $line = shift;
  return $line unless $pass == 2;

  $line =~ s{([₁₂₃₄₅₆₇₈₉₀₊₋]+)}{<sub>$1</sub>}g && $line  =~ tr/₁₂₃₄₅₆₇₈₉₀₊₋/1234567890+-/;
  $line =~ s{([¹²³⁴⁵⁶⁷⁸⁹⁰⁺⁻]+)}{<sup>$1</sup>}g && $line  =~ tr/¹²³⁴⁵⁶⁷⁸⁹⁰⁺⁻/1234567890+-/;

  return $line;

} # }}}

sub end_quote { # {{{

  my $out                                 = shift;
  my $q_text                              = shift;
  my $in_quote_ref                        = shift;

  my $in_text_ref                         = shift;
  my $ul_ref                              = shift;
  my $next_t_with_gap_ref                 = shift;
  my $empty_line_sets_next_t_with_gap_ref = shift;

  my $source                              = shift;
  my $file_name_with_path                 = shift;

  die "in quote ref error [$file_name_with_path]" unless $$in_quote_ref;
  $$in_quote_ref = 0;

  if ($pass == 2) {
    $q_text = bold_italic($q_text);
    $q_text = bible_verse($q_text);
    print $out "$q_text";

    if ($source) {
      $source = replace_external_link($source);
      $source = notes::replace_notes_link($source, $file_name_with_path);
      $source = bold_italic($source);
      $source = bible_verse($source);
      print $out "<footer><cite>$source</cite></footer>";
    }
    
    print $out "</blockquote>";

  }

} # }}}

sub start_quote { # {{{
  my $out = shift;
  my $q_text = shift;
  my $in_quote_ref = shift;

  my $in_text_ref = shift;
  my $ul_ref      = shift;
  my $next_t_with_gap_ref = shift;
  my $empty_line_sets_next_t_with_gap_ref = shift;
  my $last_thing_was_blocky_paragraph_ref = shift;
  
  die "in_quote: $$in_quote_ref" if $$in_quote_ref;
  $$in_quote_ref = 42;
  
  dbg("calling blocky_paragraph_start, ul_ref=$$ul_ref");
  blocky_paragraph_start($out, $pass, $in_text_ref,$$ul_ref, $next_t_with_gap_ref, $empty_line_sets_next_t_with_gap_ref);
  
  if ($pass == 2) {
    $q_text = bold_italic($q_text);
    print $out "<blockquote>$q_text";
  }
  $$empty_line_sets_next_t_with_gap_ref = 1;
  $$last_thing_was_blocky_paragraph_ref = 1;
} # }}}
