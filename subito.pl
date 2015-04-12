#!/usr/bin/env perl
#
# Subito: a hastily developed SubDB client.
# Searches for English subtitles only.
#

use strict;
use Fcntl qw(SEEK_SET);
use Digest::MD5;

my $user_agent = "SubDB/1.0 (Subito/1.0; http://github.com/hogmoru/subito)";
my $api = "http://api.thesubdb.com/?action=";
my $read_size = 64*1024; # 64KiB as per SubDB protocol
my $file = $ARGV[0];
my $file_size = -s $file;
my ($head, $tail, $md5, $hash, $reply);

if (! $file_size) {
  print STDERR "File not found: $file\n";
  exit 1;
}

open(IN, "<${file}");
read(IN, $head, $read_size);
seek(IN, $file_size-$read_size, SEEK_SET);
read(IN, $tail, $read_size);
close(IN);

$md5 = Digest::MD5->new;
$md5->add($head);
$md5->add($tail);
$hash = $md5->hexdigest;

print "Hash: $hash\n";

$reply = `curl -s -A "$user_agent" "${api}search&hash=$hash"`;
if (!($reply =~ /en/)) {
  print "No english subtitle found\n";
  exit 2;
}

$reply = `curl -s -A "$user_agent" "${api}download&hash=$hash&language=en"`;

$file = $file . ".srt";
$file =~ s/\....\.srt$/.srt/;
open(my $fh, '>', $file) or die "Could not open file '$file' $!";
print $fh $reply;
close $fh;
print "Wrote $file\n";
