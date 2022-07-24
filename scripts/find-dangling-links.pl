#!/usr/bin/perl
# vim: ft=perl
use warnings;
use strict;

use utf8;
use File::Find;

# 2016-07-30 use File::Slurp;

use lib "$ENV{github_root}/notes/scripts/";
use notes;

chdir 'notes' or die "No subdirectory notes found";


find (
  {
    no_chdir => 1,
    wanted => sub {

      my $filename = $File::Find::name;


      my $dbg = 0;
#     $dbg = 1 if $filename =~ /Erde.index/;

      print "$filename\n" if $dbg;

      my $substr_4 = substr($filename, -4);

      return if -d $filename;
      return if $substr_4 eq '.swp' or
                $substr_4 eq '.swo' or
                $substr_4 eq '.svg' or
                $substr_4 eq '.png' or
                $substr_4 eq '.jpg';

      return if $filename =~ /\.index$/;




      my $content = read_file($filename);

      if ($dbg) {
        print "$content\n";
      }



      while ($content =~ m/→ *([^\ ,.()?:;*#`→«»\[\]\x0a\x0d]+(\.(png|svg|jpg))?)/g) { # {{{

        my $linked_to = $1;

        my $linked_to_os = notes::perl_to_os($linked_to);

        print "linked_to:    $linked_to\n" if $dbg;
        print "linked_to_os: $linked_to_os\n" if $dbg;

        next if $linked_to eq 'http';
        next if $linked_to eq 'https';
        next if $linked_to eq 'www';


# 2016-07-30        if (-f $linked_to) {
        if (-f $linked_to_os) {
          print " is a file\n" if $dbg;
          next;

        }

# 2016-07-30        if (-d $linked_to) {
       if (-d $linked_to_os) {

          print " is a directory\n" if $dbg;

#         print "$filename links to $linked_to, but no index file\n" unless -f "$linked_to/index";

          next;

        }

        print "$filename: $linked_to links nowhere\n";

        
#       print "$filename links to $linked_to<\n" unless -e $linked_to;

      } # }}}

    }
  },
  '.'
);

sub read_file {

  my $filename = shift;
# print "read_file: $filename\n";

  my $content = '';
  open (my $f, '<:encoding(UTF-8)', $filename) or die;

  while (my $l = <$f>) {
    $content .= $l;
  }

  close $f;

  return $content;

}
