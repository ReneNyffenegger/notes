#!/usr/bin/perl
# vim: ft=perl

use warnings;
use strict;
use utf8;
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

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

my $debug = 0;
# $| = 1;

my $temp_dir;
if ($^O eq 'MSWin32') {
  $temp_dir = 'c:/temp/';
}
else {
  $temp_dir = '/tmp/';
}

my $verbose = 0;
print "$0 -> Getopt::Long::GetOptions\n" if $debug;
Getopt::Long::GetOptions(
    "web"        => \my $web,
    'verbose'    => \   $verbose
);

my $test;

print "cwd() = " . cwd() . "\n" if $debug;
if (cwd() =~ /notes.test$/) {
  print "Setting test to 1\n" if $debug;
  $test = 1;
}
elsif (cwd() =~ /github.notes$/) {
  print "Setting test to 0\n" if $debug;
  $test = 0;
}
else {
  print "Setting test to 0\n" if $debug;
  $test = 0;
}
print "test = $test\n" if $debug;


print "$0 -> notes::init\n" if $debug;
notes::init(
  $web,
  $test, 
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
  $verbose
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



unless (-e $last_run_file_os_path_abs) {
  my $touch_1970 = new File::Touch (mtime => 0);
     $touch_1970 -> touch($last_run_file_os_path_abs);
}


dbg("-> notes::load_index($index_file_os_path_abs)");
notes::load_index($index_file_os_path_abs);
dbg("<- notes::load_index()");

my $pass;
$pass = 1; dbg("pass: $pass"); find({ no_chdir=>1, wanted=> \&process_page, preprocess=>\&preprocess_dir} , '.');
$pass = 2; dbg("pass: $pass"); find({ no_chdir=>1, wanted=> \&process_page, preprocess=>\&preprocess_dir} , '.');

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


sub process_page { #_{

  #_{

  dbg("process_page: File::Find::name=$File::Find::name");
  return if $File::Find::name eq '.';

  my $input_filename_os = substr($File::Find::name, 2);
  my $file_name_only_os      = basename($input_filename_os);
  my $dirname_os             = dirname ($input_filename_os);

  dbg("file_name_only_os: $file_name_only_os");

  if ($file_name_only_os =~ m'TODO DEBUG') {
     $debug = 1;
  }
  else {
#    $debug = 0;
  }

  if (substr($file_name_only_os, 0, 1) eq '.' or #_{
      substr($file_name_only_os, 0, 2) eq '_.') { # Windows vim swap files

      dbg('process_page: filename starts with . or _, returning');
      return;
  } #_}

  if (-M $last_run_file_os_path_abs < -M $input_filename_os) { #_{
    dbg("process_page: returning because older");
    return;
  } #_}

# 2017-01-27 directories might be named exactly »svg«...
 if ($file_name_only_os ne 'svg' and $file_name_only_os ne 'png' and $file_name_only_os ne 'jpg') { #_{
 (my $suffix = $file_name_only_os) =~ s/.*\.(\w*)$/$1/;

  if ( $suffix eq 'png' or $suffix eq 'jpg' or $suffix eq 'svg') { #_{

    
    if ($pass == 2) {
      RN::copy_os_path_2_url_path_abs ($input_filename_os, "/notes/$input_filename_os");
    }

    return;
  } #_}
  } #_}


  my $file_name_with_path_uml = notes::umlaute(notes::os_to_perl($input_filename_os));
  if (-d $input_filename_os) { #_{
    return;
  } #_}


  return if $file_name_only_os =~ /\.pl$/;


  print "open [$pass] $input_filename_os\n" if $verbose >= 2;
  open (my $f, '<', $input_filename_os) or die "could not open $input_filename_os for reading";
  binmode($f); binmode($f, ':encoding(UTF-8)');

  my $next_t_with_gap = 0;
  my $last_thing_was_blocky_paragraph = 0;
  my $empty_line_sets_next_t_with_gap = 0;
  my $title = '';
  my $title_intern = '';
  my $styles = '';
  my $line;
  my $abbr = '';
  my $aka  = '';
  my $wp   = '';
  my $ul   = 0;
  my $meta_robots_no_index = 0;

  DIRECTIVES: while ($line = <$f>) { #_{ 1st Iterate over directives

    print "directive ?: $line" if $debug;

    if ($line =~ /^\$ *(.*) *$/) { $title = $1; next; }
    if ($line =~ /^\@ *(.*) *$/) { $title_intern = $1; next; }
    if ($line =~ /^- *$/) { $meta_robots_no_index=1; next; }
    if ($line =~ /^abbr: *(.*) *$/) { $abbr = $1; next; }
    if ($line =~ /^aka: *(.*) *$/)   { $aka  = $1; next; }
    if ($line =~ /^wp *(.*) *$/   ) { $wp   = $1; next; }

    if ($line =~ /^style \{/) { #_{

      while ($line =<$f>) {

        next DIRECTIVES if $line =~ /^style }/;
        $styles .= $line;

      }

    } #_}

    last;
  } #_}
  if ($line) { #_{
    print "seeking, becauselength($line)\n" if $debug;
    my $length_line;
    { use bytes;
      $length_line = length($line);
    }
    seek($f, -$length_line, 1) or die "\n$!\nline = $line, length = " . $length_line; # http://code.izzid.com/2008/01/21/How-to-move-back-a-line-with-reading-a-perl-filehandle.html // http://perlmeme.org/howtos/using_perl/length.html

  } #_}


  unless ($title) { #_{
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
  } #_}

  $title .= " - $abbr" if $abbr;

# TODO: It should be sufficient to call set_title_of_file only when $pass==1
  notes::set_title_of_file($input_filename_os, $title, $title_intern);

  my $url_path_abs = notes::os_path_to_perl_path("/notes/$input_filename_os");
  my $out;
  if ($pass == 2) {
    print "opening html $url_path_abs\n";

    $out = open_html($url_path_abs, $title, $styles, $meta_robots_no_index);
  }

  if ($pass == 2 && $aka) { #_{
    print $out "Also known as: <i>$aka</i><p>";
  } #_}

  #_}
#_{ Then iterate over content

  my $in_text  = 0; #_{ Variables
  my $in_html  = 0;
  my $in_rem   = 0;
  my $in_code  = 0;
  my $in_quote = 0;
  my $in_sa_links_etc   = '';
  my $in_table = 0;
  my $table_nof_columns=0;
  my @table_column_alignment;
  my $h_level = 1; #_}

  while ($line = <$f>) { #_{

    print "ntw: $next_t_with_gap, ltwc: $last_thing_was_blocky_paragraph, it: $in_text, q: $in_quote, line: $line" if $debug;

    chomp $line;

    if ($line =~ /^\s*rem\s*}\s*$/) {  #_{ End remark

      die unless $in_rem;
      dbg('end remark');

      $in_rem = 0;
      next;

    } #_}

    if ($line =~ /^\s*rem\s*{\s*$/) {  #_{ Begin remark

      die "Already in remark ($File::Find::name)" if $in_rem;
      dbg('start remark');

      $in_rem = 1;
      next;

    } #_}

    next if $in_rem;

    if ($line =~ /^\s*table\s*{\s*(\w*)\s*$/) {  #_{ Begin table

      dbg('start table');

      my $alignments = $1;
      die if $in_table;
      die "Alignments: >$alignments<" unless $alignments =~ /^[rlc]+$/;


      if ($table_nof_columns) {
        die "Cannot specify table alignment twice";
      }
      $table_nof_columns=length($alignments);
      @table_column_alignment = split '', $alignments;



      $in_table = 1;
      blocky_paragraph_start($out, $pass, \$in_text, $ul, \$next_t_with_gap, \$empty_line_sets_next_t_with_gap);

      if ($pass == 2) {
         print $out "\n<table>\n";
      }
      next;

    } #_}

    if ($line =~ /^\s*table\s*}\s*$/) {  #_{ End table

      die unless $in_table;
      dbg('end table');
      $last_thing_was_blocky_paragraph = 1;

      $in_table = 0;
      $table_nof_columns = 0;
      if ($pass == 2) {
         print $out "\n</table>\n";
      }
      next;

    } #_}

    if ($line =~ /^\s*html\s*}\s*$/) { #_{ End raw html section

      dbg('ending raw html section');

      $last_thing_was_blocky_paragraph = 1;

      $in_html = 0;
      next;

    } #_}

    if ($line =~ /^\s*html\s*{\s*$/) { #_{ Begin raw html section

      dbg('starting raw html section');

      die if $in_html;
      $in_html = 1;

      blocky_paragraph_start($out, $pass, \$in_text, $ul, \$next_t_with_gap, \$empty_line_sets_next_t_with_gap);

      next;

    } #_}

    if ($in_text and $line =~ /^ *- *$/) { #_{ Paragraph without gap

      end_div_t($out, \$in_text, \$ul, $pass, \$next_t_with_gap);
      print $out "\n" if $pass == 2;
      $next_t_with_gap = 0;
      next;

    } #_}

    if ($line =~ /^\s*code\s*}\s*$/) {  #_{ End code

      dbg ('Ending code');

      die "Should be in code, but am not." unless $in_code;

      $in_code = 0;
      print $out "</pre>" if $pass == 2;
      $empty_line_sets_next_t_with_gap = 1;
      $last_thing_was_blocky_paragraph = 1;
      next;

    } #_}

    if ($line =~ /^\s*code\s*{\s*$/) {  #_{ Begin code

      dbg ('Starting code');

      die "In code, line = $." if $in_code;
      $in_code = 1;

      blocky_paragraph_start($out, $pass, \$in_text, $ul, \$next_t_with_gap, \$empty_line_sets_next_t_with_gap);

      print $out "<pre class='code'>" if $pass == 2;
      next;

    } #_}

    if (not $in_code and $line =~ /^\s*"\s*$/) { #_{ start / end quote ( exactly one " in line)


      if ($in_quote) {
        dbg('found \", ending quote');
        end_quote($out, '', \$in_quote, \$in_text, \$ul, \$next_t_with_gap, \$empty_line_sets_next_t_with_gap, '', $input_filename_os);
      }
      else {
        dbg('found \", starting quote');
        start_quote($out, '', \$in_quote, \$in_text, \$ul, \$next_t_with_gap, \$empty_line_sets_next_t_with_gap, \$last_thing_was_blocky_paragraph, $input_filename_os);
      }
      next;

    } #_}

    if (not $in_code and $line =~ /^ *"([^[]*)$/) { #_{ Start Quote

      dbg("calling start_quote, ul=$ul");
      start_quote($out, $1, \$in_quote, \$in_text, \$ul, \$next_t_with_gap, \$empty_line_sets_next_t_with_gap, \$last_thing_was_blocky_paragraph);
      dbg("called start_quote, last_thing_was_blocky_paragraph = $last_thing_was_blocky_paragraph");
      next;

    } #_}

    if (not $in_code and $line =~ /(.*)" *(\[ *(.+) *\])? *$/) { #_{ End Quote

      my $q_text = $1;
      my $source = $3;

      dbg("end quote: source = " . (defined $source ? $source : '') );

      end_quote($out, $q_text, \$in_quote, \$in_text, \$ul, \$next_t_with_gap, \$empty_line_sets_next_t_with_gap, $source, $input_filename_os);
      next;

    } #_}

    if ($in_rem) { #_{
      dbg('in rem');
      print "in rem" if $debug;
      next;
    } #_}

    if ($line =~ /^(sa|links|rel): */) { #_{ See also

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

    } #_}

    unless ($in_html) { #_{ Replace html entities
      $line =~ s/&/&amp;/g;
      $line =~ s/</&lt;/g;
      $line =~ s/>/&gt;/g;
    } #_}

    if ($in_table) { #_{
      next if $line =~ /^\s*$/;

      my @tds = split '☰', $line, -1;
      die sprintf ('%s -> @tds: %i, table_nof_columns: %i', $line, scalar @tds, $table_nof_columns) unless @tds == $table_nof_columns;

      if ($pass == 2) {
        print $out "  <tr>";

        for my $col_align (@table_column_alignment) {
          my $td = shift @tds;

          print $out "<td class='";
          print $out $col_align;

          $td = replace_external_link($td);
          $td = notes::replace_notes_link($td, $input_filename_os);
          $td = bold_italic($td);
          $td = bible_verse($td);
          $td = code       ($td);

          print $out "'>$td</td>"

        }
        print $out "</tr>\n";

      }
      next;

    } #_}

    if ($in_code) { #_{ in code
      dbg('in code');
       if ($pass == 2) {
         $line = notes::replace_notes_link($line, $input_filename_os);
         print $out "$line\n";
       }
       next;
    } #_}

    if ($in_html) { #_{ in html
      dbg('in html');
      print $out "$line" if $pass == 2;
      next;
    } #_}

    if ($in_quote) { #_{

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

    } #_}

    if ($line =~ /^\s*$/) { #_{ Empty line, end div

      dbg('empty line, ending div');

      $last_thing_was_blocky_paragraph = 0;

      end_div_t($out, \$in_text, \$ul, $pass, \$next_t_with_gap);
#     $in_text = 0;

      if ($empty_line_sets_next_t_with_gap) {
        $next_t_with_gap = 1;
        $empty_line_sets_next_t_with_gap = 0;
      }

      next;
    } #_}

    if ($line =~ /^\s*{ *(.*)/) { #_{  start subtitle

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

    } #_}

    if ($line =~ /^\s*}\s*$/) { #_{ End of section

      end_section($out, \$in_text, \$h_level, \$last_thing_was_blocky_paragraph);
      next;

    } #_}

    if (!$in_text or $last_thing_was_blocky_paragraph) { #_{ Start new text div


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
    } #_}

    if ($pass == 2) { #_{ Only manipulate $line if $pass == 2

#   $linkifyer->find(\$line);

    $line =~ s/(\d) (v|n)\. *Chr\./$1&nbsp;$2.&nbsp;Chr./g;
    $line =~ s/(\d) a\. *H\./$1&nbsp;a.&nbsp;H./g;
    $line =~ s/(\d) AM\b/$1&nbsp;AM/g;

    $line =~ s/(\d)° *([0-9.]+)' *([0-9.]+)" *([NEWSO])/$1°&nbsp;$2′&nbsp;$3″&nbsp;$4/g;
    $line =~ s/(\d)° *([0-9.]+)' *([0-9.]+)"/$1°&nbsp;$2′&nbsp;$3″/g;
    $line =~ s/(\d)° *([0-9.]+)' *([NEWSO])/$1°&nbsp;$2′&nbsp;&nbsp;$3/g;
    $line =~ s/(\d)° *([0-9.]+)'/$1°&nbsp;$2′/g;

    $line =~ s/(?<! -)j(-?\d+)\b/$1/g; # 2018-08-18 because of `make -j2` etc.

    if ($line =~ s/(\s)•(.*)/$2/) { #_{ UL element

      my $ul_ = length($1);

      unless ($ul) {

        print $out "<ul>";
        $ul = $ul_;

      }

      print $out "\n<li>";

    } #_}
    else { #_{ No UL Element

      if ($ul) {

        print $out "</ul>\n";
        $ul = 0;

      }

    } #_}

    #_{ Links
    #_{  Media files jpg, png, svg ...

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

    #_}
    #_{ replace → to external site
  
    $line = replace_external_link($line);

    #_}
    #_{ replace → to local file
  
    $line = notes::replace_notes_link($line, $input_filename_os);

    #_}
    #_}

    #_{ replace yt|||
    
    $line =~ s{

      \byt\|
      ([^|]+)\|
      ([^|]+)\|

    }{

      "<a href='http://www.youtube.com/watch?v=$1' target='_blank'>$2</a>"

    }gex;

    #_}
    #_{ replace mapch|||
    
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

    #_}
    #_{ bold, italic, verses, code
    
    $line = bold_italic($line);
    $line = bible_verse($line);
    $line = sub_sup    ($line);
    $line = code       ($line);
    

    #_}
    #_{ Github source code (Must be at end, otherwise replacement of bold, italic etc kicks in!)

    $line =~ s{

      \bgh\|
      ([^|]+)\|
      ([^|]+)\|
      ([^|]*)\|

    }{

      my $repo = $1;
      my $path = $2;
      my $opts = $3;

      my $gh_ret;

      if ($pass == 2) {

        my $url = "https://raw.githubusercontent.com/ReneNyffenegger/$repo/master$path";

          print ("dirname_os = $dirname_os\n");

          print ("dirname_os = $dirname_os\n");

        print "gh: $url\n";
        if ($path =~ m!/([^//]+\.(png|jpg|jpeg|gif))$!) {

          my $image_name = $1;

          print "Found $image_name in dir $dirname_os (url = $url)\n";
          my $http_response_code = getstore($url, $temp_dir . $image_name);
          print "http_response_code = $http_response_code\n";
        #

        # 2019-05-29
          $dirname_os =~ s/\xc3\xbc/ue/g;
          $dirname_os =~ s/\xc3\xa4/ae/g;
          $dirname_os =~ s/\xc3\xb6/oe/g;
          print "copying img to /notes/$dirname_os/$image_name\n";
          RN::copy_os_path_2_url_path_abs ($temp_dir . $image_name, "/notes/$dirname_os/$image_name");

          $gh_ret = "<img src='" . RN::url_path_abs_2_url_full('/notes/') . "$dirname_os/$image_name' />";

        }
        else {

  #        2017-01-27 $path should be prefixed by a slash anyway:
           if (substr($path, 0, 1) ne '/') {
             print "gh: $path does not start with /\n";
           }

           my $code = get($url);

           print "\n\n  $url did not return anything\n\n" unless $code;

           $code =~ s/&/&amp;/g;
           $code =~ s/</&lt;/g;
           $code =~ s/>/&gt;/g;

           $gh_ret = ($in_text ? "</div>" : "") .
           "<pre class='code'>$code</pre>" .
           "<div class='ghf2'>Github respository <a href='https://github.com/ReneNyffenegger/$repo'>$repo</a>, path: <a href='https://github.com/ReneNyffenegger/$repo/blob/master$path'>$path</a></div>" .
           ($in_text ? "\n<div class='t'>" : "");
       }

       $gh_ret;

     }
     else {
       "gh pass 1";
     }

    }gex;

    #_}
    print $out "$line ";

    } #_}


  } #_}

  if ($in_text) { #_{ close in text

    end_div_t($out, \$in_text, \$ul, $pass, \$next_t_with_gap);
  } #_}

  if ($in_sa_links_etc) { #_{
    end_section($out, \$in_text, \$h_level, \$last_thing_was_blocky_paragraph);
  } #_}

  die "h_level = $h_level in $File::Find::name" unless $h_level == 1;

  close_html($out, $wp) if $pass == 2;

  die "In quote"  if $in_quote; 
  die "In code"   if $in_code;
  die "In table"  if $in_table;
  #_}


  if ($pass == 2 and $target_env eq 'web') { #_{
    print "to web: $url_path_abs\n";
    RN::copy_os_path_2_url_path_abs(RN::url_path_abs_2_os_path_abs($url_path_abs), $url_path_abs);
  } #_}


} #_}

sub replace_external_link { #_{
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

} #_}

sub process_index { #_{

  for my $k (keys %notes::index) {
    print "no title for $k\n" unless exists $notes::index{$k}{title};
  }

  my $html;
  $html = open_html('/notes/index.html', 'Notes', '', 0);
  


  for my $page (sort {lc($notes::index{$a}{title}) cmp 
                      lc($notes::index{$b}{title})
                     } keys %notes::index) {

    print $html "<a href='$page$notes::html_suffix'>$notes::index{$page}{title}</a><br>\n";

  }

  close_html($html, '');

  if ($target_env eq 'web') {
    RN::copy_os_path_2_url_path_abs(RN::url_path_abs_2_os_path_abs("/notes/index.html"), "/notes/index.html");
  }
} #_}

sub end_div_t { #_{

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
} #_}

sub open_html { #_{

  my $input_filename_os    = shift;
  my $title                = shift;
  my $styles               = shift;
  my $meta_robots_no_index = shift;

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

  my $meta_robots = '';

  if ($meta_robots_no_index) {
    $meta_robots = "\n<meta name=\"robots\" content=\"noindex\">";
  }

  print $out qq{<!DOCTYPE html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">$meta_robots
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$title</title>
<link rel="stylesheet" type="text/css" href="${notes_root}notes.css">$styles_
<script src='${notes_root}q.js'></script>
</head>
<body>
<div class='screen-only'>Search notes: <input size='50' id='q' onchange='q();'></div>
<h1>$title</h1>
};

  return $out;

} #_}

sub close_html { #_{

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


} #_}

sub preprocess_dir { #_{

# print "preprocess_dir $File::Find::dir $_ - " . (join ",", @_) ."\n";

# Make sure that every folder (except .) contains an index file:
# die "no index file in $File::Find::dir" if $File::Find::dir ne '.' and not -e "$File::Find::dir/index";

  return grep { $_ !~ /^\./}  @_;

} #_}

sub start_section { #_{

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

} #_}

sub end_section { #_{

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

} #_}

sub blocky_paragraph_start { #_{

  my $out  = shift;
  my $pass = shift;
  my $in_text_ref = shift;
  my $ul          = shift;
  my $next_t_with_gap_ref = shift;
  my $empty_line_sets_next_t_with_gap_ref = shift;

  dbg("blocky_paragraph_start, ul=$ul"); 

  if ($$in_text_ref) {
    end_div_t($out, $in_text_ref, \$ul, $pass, $next_t_with_gap_ref);
  }
  else {
    if ($$next_t_with_gap_ref) {
      print $out "\n<div class='g'></div>\n" if $pass == 2;
    }
  }

  $$empty_line_sets_next_t_with_gap_ref = 1;

} #_}

sub dbg { #_{

  return unless $debug;
  my $t = shift;
  print "DBG: $t\n";

} #_}

sub bible_verse { #_{

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


} #_}

sub bold_italic { #_{

  my $line = shift;
  return $line unless $pass == 2;

  my $boundary = '[ ,.!?():]';

  $line =~ s{(^|$boundary)\*([a-zA-ZäöüÄÖÜ0-9<][^*]*)\*($|$boundary)}{$1<i>$2</i>$3}g;
  $line =~ s{(^|$boundary)~([a-zA-ZäöüÄÖÜ0-9<][^~]*)~($|$boundary)}{$1<b>$2</b>$3}g;

  return $line;
} #_}

sub sub_sup { #_{

  my $line = shift;
  return $line unless $pass == 2;

# Apparently, the dash needs to be the last character in tr.
  $line =~ s{([₁₂₃₄₅₆₇₈₉₀₊₋]+)}{<sub>$1</sub>}g && $line  =~ tr/₁₂₃₄₅₆₇₈₉₀₊₋/1234567890+-/;
  $line =~ s{([¹²³⁴⁵⁶⁷⁸⁹⁰⁺ᵃᴬ⁻]+)}{<sup>$1</sup>}g && $line  =~ tr/¹²³⁴⁵⁶⁷⁸⁹⁰⁺ᵃᴬ⁻/1234567890+aA-/; # development/security/cryptography/Public-key-cryptography

  $line =~ s|↑([^↑]+)↑|<sup>$1</sup>|g;
  $line =~ s|↓([^↓]+)↓|<sub>$1</sub>|g;
  

  return $line;

} #_}

sub code { #_{
  my $line = shift;
  return $line unless $pass == 2;
  $line =~ s{`([^`]+)`}{ <code>$1</code>}g;
  return $line
} #_}

sub end_quote { #_{

  my $out                                 = shift;
  my $q_text                              = shift;
  my $in_quote_ref                        = shift;

  my $in_text_ref                         = shift;
  my $ul_ref                              = shift;
  my $next_t_with_gap_ref                 = shift;
  my $empty_line_sets_next_t_with_gap_ref = shift;

  my $source                              = shift;
  my $file_name_with_path                 = shift;

  dbg("end_quote, file_name_with_path: $file_name_with_path");

  die "in quote ref error [file_name_with_path: $file_name_with_path]" unless $$in_quote_ref;
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

} #_}

sub start_quote { #_{
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
} #_}
