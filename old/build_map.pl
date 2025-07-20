#!/bin/perl
# build_map.pl 
# This script is run by walks_deploy.pl to gather information about all posts and build a map.html file in /public 
# 

use strict;
use warnings;

my $debug = 1;

my $root_dir = 'c:\code\dartmoorwalking';  # Where to start running from
my $map_template = 'scripts\map_template.html';  # where, below above, the template is. 
#my $map_output = 'public/map.html';  # Where to output final
my $map_output = 'static\map.html';  # Where to output final
my $posts_dir = 'content\post/';   # Where the posts content is. This script will try each dir for a ./index.md
my $url_prefix = 'https://dartmoorwalking.org/p/';  # What to prepend to the normalised title to get a url

######################################

my @postsdirs;  # List of subdirs in $posts_dir
my $postpath = $root_dir . $posts_dir;

my $popup_string;  # This replaces FORM_POPUPS

my $good_hits = 0;
my $bad_hits = 0;

debug("postpath = $postpath");

opendir( my $DIR, $postpath );
while ( my $entry = readdir $DIR ) {
    next unless -d $postpath . $entry;
    next if $entry eq '.' or $entry eq '..' or $entry eq '.wrangler';
    push(@postsdirs, $entry);
    }
closedir $DIR;

debug("POST DIRS FOUND (" . scalar(@postsdirs) . "): @postsdirs");

foreach(@postsdirs) {
    my $indexpath = $root_dir . $posts_dir . $_ . "/index.md";
    if (-e $indexpath) {
        debug("Found post at $indexpath");

        # Read in and parse this file
        open my $fh, '<', $indexpath or die "Can't open file $!";
        my $file_content = do { local $/; <$fh> };
        close $fh;

        my $coords;
        my $title;
        my $url;
        my $distance;
        my $grade;

        no warnings; # Skip empty string carp

        # Just the first of each pattern
        # title: Yes Tor, via Row Tor
        if ( $file_content =~ /coords: (.*)/ )          { $coords = $1; }
        if ( $file_content =~ /title: (.*)/  )          { $title = $1; }
        if ( $file_content =~ /distance: (.*)/ )        { $distance = $1; }
        if ( $file_content =~ /grade: (.*)/ )           { $grade = lc($1); }

#        $file_content =~ /title: (.*)/;
#        $title = $1;

        # Remove any bad chars from title
        $title =~ s/'//g;

        my $normalised_title = convert_to_lowercase_dash($title);
        debug("Parsed title: \"$title\" normalised to: ($normalised_title)");
        $url = $url_prefix . $normalised_title . '/';
        debug("URL: $url");

        # Check we're good
        if ( ( ! $title) || ( ! $distance ) || ( ! $grade ) || ( ! $coords ) || (! $url) ) {
            print "WARNING: Incomplete data for $title, skipping this popup\n(Title=$title, Distance=$distance, Grade=$grade, Coords=$coords, URL=$url\n\n";
            $bad_hits++;
            next;
            }


        # Build popup
        #     const marker = L.marker([50.579587, -3.797581]).addTo(map)  .bindPopup('<a href="#">Walk Title</a><br />A 3 mile gentle walk.');
        $good_hits++;
        $popup_string .= "const marker" . $good_hits . " = L.marker([$coords]).addTo(map) .bindPopup('<a href=\"$url\" target=\"_parent\">$title</a><br />A $grade $distance mile walk.');\n";
        print "POPUP added: $title\n\n";
        } else {
        debug("No post in post dir, $_ at $indexpath");
        }

    }

# Now we have a full $popup_string, we can read in the template, change the FORM_POPUPS string and write out to $map_output

debug("Building map...\n");

open my $fhi, '<', $root_dir . $map_template or die "Can't open file $!";
my $map_code = do { local $/; <$fhi> };
close $fhi;

$map_code =~ s/FORM_POPUPS/$popup_string/;
$map_code =~ s/FORM_NUMMAPS/$good_hits/;

open my $fho, '>', $root_dir . $map_output or die "Can't open file $!";
print $fho $map_code;
close $fho; 


print "Map built. $good_hits popups created. $bad_hits posts failed parsing.\n\n";



sub debug {
    if ($debug == 1) {
        print shift . "\n";
        }
    }

sub convert_to_lowercase_dash {
    my $str = shift;

    # Convert to lowercase
    $str = lc $str;

    # Replace non-alphabetic characters with dashes
    $str =~ s/[^a-z]/-/g;

    # Remove consecutive dashes
    $str =~ s/-+/-/g;

    # Remove leading and trailing dashes
    $str =~ s/^-|-$//g;

    return $str;
}
