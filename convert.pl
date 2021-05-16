#!/usr/bin/env perl

use utf8;
use strict;
use open IO => ":utf8", ":std";

use File::Basename;

sub main {
    my $file_dir = dirname(__FILE__);
    my @files = map { $_ =~ s{[\r\n]*$}{}r; } `git -C $file_dir diff-tree --no-commit-id --name-only -r HEAD`;
    
    for my $in_file(@files) {
        my $out_dir = "$file_dir/".($in_file =~ s{\.txt$}{}r);
        print "$out_dir\n";
        mkdir $out_dir or die if not -d $out_dir;
        my @commits = map { s{[\r\n]*$}{}r; } `git -C $file_dir log --pretty=format:"%H"`;
        print "$_\n" for @commits;

        for my $commit(@commits) {
            my @lines = map { s{[\r\n]*$}{}r; } `git -C $file_dir show $commit:$in_file`;
            my $title = $lines[2];
            open OUT, ">", "$out_dir/$commit.html";
            print OUT <<HEAD;
<html>
<!DOCTYPE html>
<html lang="ja">
  <head>
    <title>$title</title>
    <style>
    body {
      background-color: white;
      font-size: small;
    }
    a {
      color: #dddddd;
    }
    </style>
  </head>
    
  <body>
HEAD
    
            while (my ($num, $line) = each @lines) {
                print OUT (($line =~ m{^\[(\d+)\]} ? qq{    <p id="f${1}n">} : "    <p>").$line =~ s{(?<!^)(\[(\d+)\])}{<a href="#f${2}n">$1</a>}gr."</p>\n") if $num % 5 == 2;
            }
            print OUT "  </body>\n</html>\n";
            close OUT;
            system("git -C $file_dir add $out_dir/$commit.html");
        }
        system("ln -nfs $out_dir/$commits[0].html $out_dir/index.html");
        system("git -C $file_dir add $out_dir/index.html");
        system(qq{git -C $file_dir commit -m "Generated HTML files."});
    }
}

if ($0 eq __FILE__) {
    main();
}
