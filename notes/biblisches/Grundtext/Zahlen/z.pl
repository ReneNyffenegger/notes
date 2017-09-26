#!/usr/bin/perl
use warnings;
use strict;
use utf8;

for my $n (1 .. 73) {

  my $Δ = $n*($n+1) / 2;

  my $Δ_37 = ' '; # Dreickszahl ist ganzahliges vielfaches von 37?
  if (int $Δ/37 == $Δ/37) {
    $Δ_37 = '*'; 
  }

  printf "%2d | %4d | %s\n", $n, $Δ, $Δ_37;

}

