#
# Copyright (C) 2012-2021 Michael Cain
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#

use strict;
use warnings;
use GD;
use GD::Polyline;
use Geo::ShapeFile;
use Cwd;
use Math::Trig;
use File::Copy;
use File::Glob qw(:bsd_glob);
use List::Util qw(max);
use Scalar::Util qw(looks_like_number);


##################################
# Lookup hashes for doing various things at the state level
#  - converting between identifier types
#  - geographic area values
#

#
# Numbers that can be used for the area of each of the states
# Numbers are in thousands of square miles
# Alaska and Hawaii are not included
#

my %state_area = (
	"AL" => 52.4,
	"AR" => 53.2,
	"AZ" => 114.0,
	"CA" => 163.7,
	"CO" => 104.1,
	"CT" => 5.5,
	"DC" => 0.068,
	"DE" => 2.5,
	"FL" => 65.7,
	"GA" => 59.4,
	"IA" => 56.3,
	"ID" => 83.6,
	"IL" => 57.9,
	"IN" => 36.4,
	"KS" => 82.3,
	"KY" => 40.4,
	"LA" => 51.8,
	"MA" => 10.6,
	"MD" => 12.4,
	"ME" => 35.4,
	"MI" => 96.7,
	"MN" => 86.9,
	"MO" => 69.7,
	"MS" => 48.4,
	"MT" => 147.0,
	"NC" => 53.8,
	"ND" => 70.7,
	"NE" => 77.4,
	"NH" => 9.3,
	"NJ" => 8.7,
	"NM" => 121.6,
	"NV" => 110.6,
	"NY" => 54.6,
	"OH" => 44.8,
	"OK" => 69.9,
	"OR" => 98.3,
	"PA" => 46.1,
	"RI" => 1.5,
	"SC" => 32.0,
	"SD" => 77.1,
	"TN" => 42.1,
	"TX" => 268.6,
	"UT" => 84.9,
	"VA" => 42.8,
	"VT" => 9.6,
	"WA" => 71.3,
	"WI" => 65.5,
	"WV" => 24.2,
	"WY" => 97.8,
);

#
# Translate spelled-out state names to two-character postal abbreviations
# Alaska and Hawaii not included
#

my %abbr_lookup = (
	"Alabama" =>				"AL",
	"Arizona" =>				"AZ",
	"Arkansas" =>				"AR",
	"California" =>				"CA",
	"Colorado" =>				"CO",
	"Connecticut" =>			"CT",
	"Delaware" =>				"DE",
	"District of Columbia" =>	"DC",
	"Florida" =>				"FL",
	"Georgia" =>				"GA",
	"Idaho" =>					"ID",
	"Illinois" =>				"IL",
	"Indiana" =>				"IN",
	"Iowa" =>					"IA",
	"Kansas" =>					"KS",
	"Kentucky" =>				"KY",
	"Louisiana" =>				"LA",
	"Maine" =>					"ME",
	"Maryland" =>				"MD",
	"Massachusetts" =>			"MA",
	"Michigan" =>				"MI",
	"Minnesota" =>				"MN",
	"Mississippi" =>			"MS",
	"Missouri" =>				"MO",
	"Montana" =>				"MT",
	"Nebraska" =>				"NE",
	"Nevada" =>					"NV",
	"New Hampshire" =>			"NH",
	"New Jersey" =>				"NJ",
	"New Mexico" =>				"NM",
	"New York" =>				"NY",
	"North Carolina" =>			"NC",
	"North Dakota" =>			"ND",
	"Ohio" =>					"OH",
	"Oklahoma" =>				"OK",
	"Oregon" =>					"OR",
	"Pennsylvania" =>			"PA",
	"Rhode Island" =>			"RI",
	"South Carolina" =>			"SC",
	"South Dakota" =>			"SD",
	"Tennessee" =>				"TN",
	"Texas" =>					"TX",
	"Utah" =>					"UT",
	"Vermont" =>				"VT",
	"Virginia" =>				"VA",
	"Washington" =>				"WA",
	"West Virginia" =>			"WV",
	"Wisconsin" =>				"WI",
	"Wyoming" =>				"WY",
);

#
# Translate two-character state abbreviations to FIPS code (as a string)
#

my %state_abbr_to_fips = (
	"AK" => "02",
	"AL" => "01",
	"AR" => "05",
	"AZ" => "04",
	"CA" => "06",
	"CO" => "08",
	"CT" => "09",
	"DC" => "11",
	"DE" => "10",
	"FL" => "12",
	"GA" => "13",
	"HI" => "15",
	"IA" => "19",
	"ID" => "16",
	"IL" => "17",
	"IN" => "18",
	"KS" => "20",
	"KY" => "21",
	"LA" => "22",
	"MA" => "25",
	"MD" => "24",
	"ME" => "23",
	"MI" => "26",
	"MN" => "27",
	"MO" => "29",
	"MS" => "28",
	"MT" => "30",
	"NC" => "37",
	"ND" => "38",
	"NE" => "31",
	"NH" => "33",
	"NJ" => "34",
	"NM" => "35",
	"NV" => "32",
	"NY" => "36",
	"OH" => "39",
	"OK" => "40",
	"OR" => "41",
	"PA" => "42",
	"RI" => "44",
	"SC" => "45",
	"SD" => "46",
	"TN" => "47",
	"TX" => "48",
	"UT" => "49",
	"VA" => "51",
	"VT" => "50",
	"WA" => "53",
	"WI" => "55",
	"WV" => "54",
	"WY" => "56",
);

#
# Translate two-character FIPS code to two-character abbreviation
#

my %state_fips_to_abbr = (
	"02" => "AK",
	"01" => "AL",
	"05" => "AR",
	"04" => "AZ",
	"06" => "CA",
	"08" => "CO",
	"09" => "CT",
	"11" => "DC",
	"10" => "DE",
	"12" => "FL",
	"13" => "GA",
	"15" => "HI",
	"19" => "IA",
	"16" => "ID",
	"17" => "IL",
	"18" => "IN",
	"20" => "KS",
	"21" => "KY",
	"22" => "LA",
	"25" => "MA",
	"24" => "MD",
	"23" => "ME",
	"26" => "MI",
	"27" => "MN",
	"29" => "MO",
	"28" => "MS",
	"30" => "MT",
	"37" => "NC",
	"38" => "ND",
	"31" => "NE",
	"33" => "NH",
	"34" => "NJ",
	"35" => "NM",
	"32" => "NV",
	"36" => "NY",
	"39" => "OH",
	"40" => "OK",
	"41" => "OR",
	"42" => "PA",
	"44" => "RI",
	"45" => "SC",
	"46" => "SD",
	"47" => "TN",
	"48" => "TX",
	"49" => "UT",
	"51" => "VA",
	"50" => "VT",
	"53" => "WA",
	"55" => "WI",
	"54" => "WV",
	"56" => "WY",
);

#
# Convert state_area hash to keys based on FIPS rather than abbreviation
#

foreach my $key (keys %state_area) {
	if (exists $state_abbr_to_fips{$key}) {
		$state_area{$state_abbr_to_fips{$key}} = $state_area{$key};
		delete $state_area{$key};
	}
}


#
# Make shape ids consistent
# Two-letter state names get converted to corresponding FIPS code
# Fix the South Dakota county FIPS change
#

sub patch_id {
	my $id = $_[0];
	$id = $state_abbr_to_fips{$id} if ($id =~ /^\s*[A-Z]{2}\s*$/);
	$id = "46102" if ($id eq "46113");
	return $id;
}


##################################
# Progress bar code
# Start the bar by calling &progress_start with an argument that represents 100% of things done
# Update the bar by calling &progress_update with an argument that represents how many things are done
# Update redraws the bar entirely, so it can run backwards if necessary
# Finish the bar by calling &progress_finish
# If &progress_start is called while the bar is "running", go to new line and restart
# The length of the progress bar is such that it's the same as that used in the cart programs
#

my $progress_maximum;
my $progress_current;
my $progress_state = 0;
my $progress_last;

sub progress_start {
	print STDERR "\n" if ($progress_state == 1);
	$progress_maximum = $_[0];
	return if ($progress_maximum <= 0);
	$progress_state = 1;
	$progress_last = -1;
	&progress_update(0);
}

sub progress_update {
	my $temp;
	my $string;

	return if ($progress_state == 0);
	$progress_current = $_[0];
	$progress_current = $progress_maximum if ($progress_current > $progress_maximum);
	$temp = 49 * $progress_current / $progress_maximum;
	return if (int($temp * (100 / 49)) == $progress_last);
	$progress_last = int($temp * (100 / 49));
	$temp = 1 + int($temp);
	$string = sprintf("%5d%%  |", $progress_last) . ('=' x $temp) . (' ' x (50 - $temp)) . "|\r";
	print STDERR $string;
	print STDERR "\n" if ($progress_current >= $progress_maximum);
}

sub progress_finish {
	&progress_update($progress_maximum);
	$progress_state = 0;
}	

##################################
# Initial values for various globals that can be adjusted on the command line, divided into groups
# Stuff specific to generating maps
# Projection types:
#   none - simple latitude and longitude
#   aea  - Albers Equal Area
#   laea - Lambert Azimuthal Equal Area
#   cea  - Cylindrical Equal Area
#   lcc  - Lambert Conformal Conic
#

my $generate_flag = 0;
my $from_shapefile = 0;
my $center_correction = 0;
my $lon_scale = 1;
my %project_hash = (
	"none" => '$proj_program +proj=latlong +to +proj=$project_type +lat_0=$center_lat +lon_0=$center_lon',
	"aea"  => '$proj_program +proj=latlong +to +proj=$project_type +lat_1=$min_lat +lat_2=$max_lat +lon_0=$center_lon',
	"laea" => '$proj_program +proj=latlong +to +proj=$project_type +lat_0=$center_lat +lon_0=$center_lon',
	"cea"  => '$proj_program +proj=latlong +to +proj=$project_type +lat_ts=$min_lat +lon_0=$center_lon',
	"lcc"  => '$proj_program +proj=latlong +to +proj=$project_type +lat_0=$center_lat +lat_1=$center_lat +lon_0=$center_lon',
);
my $project_type = "aea";

#
# Stuff mostly specific to contiguous cartograms
# Flat maps are just contiguous cartograms that skip the density adjustment steps
# Some of this stuff gets used in other cases, eg, $border_thickness in noncontiguous and prism
#
my %map_hash = ("flat" => 1, "contig" => 1, "noncontig" => 1, "prism" => 1);
my $map_type = "flat";
my $data_filename = "";
my $map_filename = "";
my $image_offset = 50;
my $user_scale = 1.0;
my $border_thickness = 2;
my $use_existing_density = 0;
my $unlink_flag = 1;
my $poly_max_edge = 3;
my $outline_flag = 1;
my $outline_color = "black";
my $background = "white";
my $cart_program = "cart";
my $one_color = 0;
my $adj_outside_density = 1.00;
my %img_hash = ("png" => 1, "jpg" => 1, "gif" => 1);
my $img_type = "png";
my $area_flag = 0;
my $transform = "";
my $adj_max_flag = 1;
my $video_string = "";
my @prune_values = ();

#
# Stuff specific to noncontiguous cartograms
#
my $scale_data_flag = 0;
my $adj_max_noncontig = 0;

#
# Stuff for overlays
#
my $overlay_map = "";
my $overlay_color = "0,0,255";
my $overlay_thickness = 3;

#
# Stuff for mesh overlay, used in contiguous cartograms and map generation
#
my $mesh_flag = 0;
my $mesh_filename = "";
my $mesh_thick = 1;
my $mesh_size = 100;
my $mesh_color = "black";

#
# Stuff specific to prism maps
#
my %camera_hash = ("perspective" => 1, "orthographic" => 1);
my $camera_type = "perspective";
my $camera_string = "1200,270,45";
my $camera_zoom = 45;
my $povray_width = 1200;
my $povray_height = 800;
my $overlay_radius = 1.5;
my $overlay_height = $overlay_radius;
my $transparency = 0.4;
my $y_point = 0;
my $gamma = 1.1;


##################################
# Global stuff that's not set from the command line
# All here in one place to avoid declaring names multiple times
# Really need to do better scoping one of these days
#

my $image;				# GD::Image for drawing the flat, contiguous, and non-contiguous cartograms
my $image_scale;
my $image_width;
my $image_height;
my %theme_value = ();	# Hash based on identifiers found in the the data file
my %state_fips = ();	# State FIPS identifiers found
my %county_fips = ();	# County FIPS identifiers found
my %district_fips = ();	# District FIPS identifiers found
my @value = ();			# Array used for building the initial density file
my $max_value;			# Largest value in @value
my %colors;				# Color indices used for building the density file
my $outside_density;	# Default initial density
my $x_min;				# x_min, x_max, y_min, and y_max define the bounding box for the map polyons
my $x_max;
my $y_min;
my $y_max;
my $x_offset;			# x_offset and y_offset implement empty space around map in flat and contig cases
my $y_offset;
my %shade;				# Color indices used for actually drawing polygons
my $clip_image;			# Separate GD::Image used for clipping an overlaid mesh
my $shape_count;		# Counter used to drive one of the progress bars
my $point_count;		# Counter used to drive another of the progress bars
my %county_area = ();	# Hash that will be filled with county land area if needed
my %district_area = ();	# Hash that will be filled with district land area if needed
my $proj_program;		# Cs2cs, specific for platform
my $interp_program;		# Interp, specific for platform
my $ray_program;		# POV-Ray, specific for platform
my $null_name;			# Name of the null file, either /dev/null or nul: depending on OS
my @poly_list1 = ();	# Lists of polygons and colors used for contiguous video sequence generation
my @poly_list2 = ();
my @poly_list3 = ();
my @poly_list4 = ();
my @poly_color_list = ();
my %total_points = ();	# Hash for recording total polygon points for an identifier

#
# Stuff specific to noncontiguous cartograms
# Hint identifiers (eg, "CA") get converted to FIPS codes first thing
# Left them as postal codes in the data declaration so they're more human friendly
#
my @x_list;
my @y_list;
my $x_centroid;
my $y_centroid;
my $noncontig_bg = "gray";
my $noncontig_fg = "blue";
my @noncontig_hints = (
	"CA", -30, -10,
	"ID", -10,  20,
	"OR", -15,  10,
	"UT", -10,   0,
	"FL",   5, -25,
	"LA", -10,   0,
	"MD",  -3, -10,
	"NJ",   3,   0,
	"MI", -10,   5,
	"WA",  10,   0,
);
for (my $i=0; $i<@noncontig_hints; $i+=3) {
	$noncontig_hints[$i] = &patch_id($noncontig_hints[$i]);
}

#
# Named color hash data all in one place here
# First three values in the referenced array are for GD, last three are for POV-Ray
# The hash values are replaced with a GD index if we're doing anything but prism map
# Exactly what gets put in there varies by the type of map
#

my %named_colors = (
	"white"     => [255, 255, 255, 1.0, 1.0, 1.0],
	"black"     => [0, 0, 0, 0.0, 0.0, 0.0],
	"red"       => [255, 0, 0, 1.0, 0.2, 0.2],
	"green"     => [0, 255, 0, 0.2, 1.0, 0.2],
	"blue"      => [0, 0, 255, 0.2, 0.2, 1.0],
	"purple"    => [255, 63, 255, 0.7, 0.2, 1.0],
	"yellow"    => [255, 255, 63, 1.0, 1.0, 0.0],
	"orange"    => [255, 165, 0, 1.0, 0.6, 0.0],
	"gray"      => [223, 223, 223, 0.6, 0.6, 0.6],
	"dark_gray" => [63, 63, 63, 0.3, 0.3, 0.3],
);


##################################
# The "main" program runs from here to the exit statement
# Getting started stuff that's common across all the map types
# Block of code for each of the four map types
# Both contiguous and noncontiguous will define $image as a GD image, which should be dumped to file
# Tidy up by unlinking various scratch files, unless instructed to keep them
#

print STDERR "Tag            Value\n";
print STDERR "--------------------------------\n";

&process_args();
&os_specific_stuff();
&read_areas() if ($area_flag);
&read_data_file();
&apply_transform() if ($transform);
&maps_start() if ($generate_flag);
die "Error          map file $map_filename doesn't exist\n" if ($map_filename and ! -e $map_filename);
die "Error          overlay file $overlay_map doesn't exist\n" if ($overlay_map and ! -e $overlay_map);
&first_map_pass();

if ($map_type eq "flat") {
	&setup_graphics();
	&second_pass_data();
	&second_pass_map();
	copy("cartogram.points", "cartogram.mapped.points") or die "Error          file copy failed\n";
	&third_pass_map();
	if ($mesh_flag) {
		&first_mesh_pass();
		copy("cartogram.points", "cartogram.mapped.points") or die "Error          file copy failed\n";
		&second_mesh_pass();
		&clip_mesh();
	}
	&overlay_pass() if ($overlay_map);
	&print_image();
}

if ($map_type eq "contig") {
	&setup_graphics();
	&second_pass_data();
	&second_pass_map();
	if (!$use_existing_density) {
		&build_density();
		print STDERR "Progress       running $cart_program\n";
		system("$cart_program $image_width $image_height cartogram.dat cartogram.mapped.dat");
	}
	print STDERR "Progress       running interp on polygon vertices\n";
	system("$interp_program $image_width $image_height cartogram.mapped.dat <cartogram.points >cartogram.mapped.points");
	&third_pass_map();
	if ($mesh_flag) {
		&first_mesh_pass();
		print STDERR "Progress       running interp on mesh vertices\n";
		system("$interp_program $image_width $image_height cartogram.mapped.dat <cartogram.points >cartogram.mapped.points");
		&second_mesh_pass();
		&clip_mesh();
	}
	&overlay_pass() if ($overlay_map);
	&print_image();
	&video_pass() if ($video_string);
}

if ($map_type eq "noncontig") {
	&setup_graphics();
	&noncontig_second_data();
	&noncontig_second_map();
	&noncontig_third_map();
	&noncontig_overlay() if ($overlay_map);
	&print_image();
}

if ($map_type eq "prism") {
	&make_prism_map();
}

if ($unlink_flag) {
	my @files = bsd_glob("video/frame*.png");
	unlink @files if (@files > 0);
	unlink "cartogram.dat";
	unlink "cartogram.points";
	unlink "cartogram.mapped.dat";
	unlink "cartogram.mapped.points";
	unlink "cartogram.pov";
}

exit;

#
# Read county and/or district areas from the bulk data file
# Called only if the -area command-line flag was set
#

sub read_areas {
	my @temp;
	open INPUT, "<bulk_data/gaz.data" or die "Error          could not open bulk data file bulk_data/gaz.data\n";
	printf STDERR "Progress       reading county areas\n";
	while (<INPUT>) {
		s/#.*$//;
		@temp = split " ";
		$county_area{$temp[0]} = $temp[1];
	}
	open INPUT, "<bulk_data/districts.area" or die "Error          could not open bulk data file bulk_data/districts.area\n";
	printf STDERR "Progress       reading district areas\n";
	while (<INPUT>) {
		@temp = split " ";
		$district_area{$temp[0]} = $temp[1];
	}
}

#
# OS specific preparations
# Basically, setting things up for the external programs that get run
# VERY specific to how things were installed on my machines
#

sub os_specific_stuff {
	printf STDERR "Progress       operating system is $^O\n";
	if ($^O eq "linux") {
		$null_name = "/dev/null";
		$proj_program = "/usr/bin/cs2cs";
		$cart_program = getcwd() . "/cart/" . $cart_program;
		$interp_program = getcwd() . "/cart/interp";
		$ray_program = "/usr/bin/povray +L./bin +Icartogram.pov +V +W$povray_width +H$povray_height +A +Q11 -D";
	}
	if ($^O eq "MSWin32") {
		$null_name = "nul:";
		$cart_program = getcwd() . "/cart/" . $cart_program . ".exe";
		$interp_program = getcwd() . "/cart/interp.exe";
	}
	if ($^O eq "darwin") {
		$null_name = "/dev/null";
	}
}


##################################
# Process arguments
# First there's just walking through all of the given options
# Note silent truncation of some values to a specific range
# Then there's checking related to combinations, like the string provided for -video
# There's not nearly enough error checking going on here
#

sub process_args {
	my $count = 0;
	my $temp;
	my @temp;
	my @new;

	while (@ARGV) {
		$temp = shift @ARGV;
		if ($temp eq "-help") {
			&print_help();
			exit;
		}
		elsif ($temp eq "-options") {
			$temp = shift @ARGV;
			if (-r $temp) {
				@new = ();
				open INPUT, "<$temp";
				while (<INPUT>) {
					chomp;
					s/#.*$//;
					@temp = split " ";
					push @new, shift @temp if (@temp > 0);
					push @new, join " ", @temp if (@temp > 0);
				}
				unshift @ARGV, @new;
			}
			else {
				print STDERR "Error          option file $temp not readable\n";
				$count += 1;
			}
		}
		elsif ($temp eq "-type") {
			$map_type = shift @ARGV;
			if (!exists $map_hash{$map_type}) {
				print STDERR "Error          unrecognized map_type $temp\n";
				$count += 1;
			}
		}
		elsif ($temp eq "-video") {
			$video_string = shift @ARGV;
		}
		elsif ($temp eq "-img_type") {
			$img_type = shift @ARGV;
			if (!exists $img_hash{$img_type}) {
				print STDERR "Error          unrecognized output file type $temp\n";
				$count += 1;
			}
		}
		elsif ($temp eq "-background") {
			$background = shift @ARGV;
			if (!&looks_like_color($background)) {
				print STDERR "Error          -background bad color value $temp\n";
				$count += 1;
			}
		}
		elsif ($temp eq "-data") {
			$data_filename = shift @ARGV;
		}
		elsif ($temp eq "-area") {
			$area_flag = 1;
		}
		elsif ($temp eq "-map") {
			$map_filename = shift @ARGV;
		}
		elsif ($temp eq "-scale") {
			$temp = shift @ARGV;
			if (looks_like_number($temp)) {
				$temp = 0.1 if ($temp < 0.1);
				$temp = 10  if ($temp > 10 );
				$user_scale = $temp;
			}
			else {
				print STDERR "Error          -scale value doesn't look like a number\n";
				$count += 1;
			}
		}
		elsif ($temp eq "-offset") {
			$temp = shift @ARGV;
			$temp = 0 if ($temp < 0);
			$temp = 300 if ($temp > 300);
			$image_offset = $temp;
		}
		elsif ($temp eq "-thick") {
			$border_thickness = shift @ARGV;
		}
		elsif ($temp eq "-edge") {
			$temp = shift @ARGV;
			$temp = 1 if ($temp < 1);
			$temp = 20 if ($temp > 20);
			$poly_max_edge = $temp;
		}
		elsif ($temp eq "-scale_data") {
			$scale_data_flag = 1;
		}
		elsif ($temp eq "-use_existing") {
			$use_existing_density = 1;
		}
		elsif ($temp eq "-no_unlink") {
			$unlink_flag = 0;
		}
		elsif ($temp eq "-no_outline") {
			$outline_flag = 0;
		}
		elsif ($temp eq "-outline_color") {
			$outline_color = shift @ARGV;
			if (!&looks_like_color($outline_color)) {
				print STDERR "Error          -outline_color bad color value $temp\n";
				$count += 1;
			}
		}
		elsif ($temp eq "-adj_outside_density") {
			$temp = shift @ARGV;
			$temp = 0.1 if ($temp < 0.1);
			$temp = 5.0 if ($temp > 5.0);
			$adj_outside_density = $temp;
		}
		elsif ($temp eq "-mesh") {
			$mesh_filename = shift @ARGV;
			$mesh_flag = 1;
		}
		elsif ($temp eq "-mesh_size") {
			$temp = shift @ARGV;
			$temp = 25 if ($temp < 25);
			$temp = 400 if ($temp > 400);
			$mesh_size = $temp;
		}
		elsif ($temp eq "-mesh_thick") {
			$temp = shift @ARGV;
			$temp = 1 if ($temp < 1);
			$temp = 10 if ($temp > 10);
			$mesh_thick = $temp;
		}
		elsif ($temp eq "-mesh_color") {
			$mesh_color = shift @ARGV;
			if (!&looks_like_color($mesh_color)) {
				print STDERR "Error          -mesh_color bad color value $temp\n";
				$count += 1;
			}
		}
		elsif ($temp eq "-one_color") {
			$one_color = shift @ARGV;
			if (!&looks_like_clor($one_color)) {
				print STDERR "Error          -one_color bad color value $temp\n";
				$count += 1;
			}
		}
		elsif ($temp eq "-overlay") {
			$overlay_map = shift @ARGV;
		}
		elsif ($temp eq "-overlay_thick") {
			$temp = shift @ARGV;
			$temp = 0.1 if ($temp < 0.1);
			$temp = 14  if ($temp > 14 );
			$overlay_thickness = $temp;
			$overlay_radius = $overlay_thickness;
			$overlay_height = $overlay_radius / 2;
		}
		elsif ($temp eq "-overlay_color") {
			$overlay_color = shift @ARGV;
			if (!&looks_like_color($overlay_color)) {
				print STDERR "Error          -overlay_color bad color value $temp\n";
				$count += 1;
			}
		}
		elsif ($temp eq "-cart2") {
			$cart_program = "cart2";
		}
		elsif ($temp eq "-cartv") {
			$cart_program = "cartv";
		}
		elsif ($temp eq "-cart2v") {
			$cart_program = "cart2v";
		}
		elsif ($temp eq "-generate") {
			$generate_flag = 1;
		}
		elsif ($temp eq "-from_shapefile") {
			$from_shapefile = 1;
		}
		elsif ($temp eq "-bg") {
			$noncontig_bg = shift @ARGV;
		}
		elsif ($temp eq "-fg") {
			$noncontig_fg = shift @ARGV;
		}
		elsif ($temp eq "-camera") {
			$camera_string = shift @ARGV;
		}
		elsif ($temp eq "-camera_type") {
			$camera_type = shift @ARGV;
			if (!exists $camera_hash{$camera_type}) {
				print STDERR "Error          unrecognized camera type $temp\n";
				$count += 1;
			}
		}
		elsif ($temp eq "-zoom") {
			$camera_zoom = shift @ARGV;
		}
		elsif ($temp eq "-gamma") {
			$gamma = shift @ARGV;
		}
		elsif ($temp eq "-width") {
			$povray_width = shift @ARGV;
		}
		elsif ($temp eq "-height") {
			$povray_height = shift @ARGV;
		}
		elsif ($temp eq "-transform") {
			$transform = shift @ARGV;
			print STDERR "Testing        transform string is $transform\n";
		}
		elsif ($temp eq "-no_adj_max") {
			$adj_max_flag = 0;
		}
		elsif ($temp eq "-adj_max_noncontig") {
			$adj_max_noncontig = shift @ARGV;
		}
		elsif ($temp eq "-ypoint") {
			$y_point = shift @ARGV;
		}
		elsif ($temp eq "-transparency") {
			$temp = shift @ARGV;
			$temp = 0 if ($temp < 0);
			$temp = 1 if ($temp > 1);
			$transparency = $temp;
		}
		elsif ($temp eq "-project") {
			$project_type = shift @ARGV;
			if (!exists $project_hash{$project_type}) {
				print STDERR "Error          unrecognized projection type $temp\n";
				$count += 1;
			}
		}
		elsif ($temp eq "-correction") {
			$center_correction = shift @ARGV;
		}
		elsif ($temp eq "-lon_scale") {
			$temp = shift @ARGV;
			$temp = 0.25 if ($temp < 0.25);
			$temp = 4.00 if ($temp > 4.00);
			$lon_scale = $temp;
		}
		elsif ($temp eq "-prune") {
			$temp = shift @ARGV;
			@temp = split ",", $temp;
			if (@temp == 2) {
				if ($temp[0] <= 0 or $temp[0] >= 1 or $temp[1] <= 0 or $temp[1] > 100) {
					print STDERR "Warning        prune string should look something like '0.3,30'\n";
				}
				@prune_values = @temp;
			}
			else {
				print STDERR "Error          bad -prune string $temp\n";
				$count += 1;
			}
		}
		else {
			print STDERR "Error          unrecognized option >$temp<\n";
			$count += 1;
		}
	}

	if ($map_type eq "contig" and $video_string) {
		if ($video_string !~ /^full$|^half$|^quarter$|^0?\.\d+$|^1\.0*$|\d+x\d+/) {
			print STDERR "Error          bad value $video_string for -video option for contiguous cartogram\n";
			$count += 1;
		}
	}
	if ($map_type eq "prism" and $video_string) {
		if ($video_string !~ /^grow$|^rotate$/) {
			print STDERR "Error          bad value $video_string for -video option for prism map\n";
			$count += 1;
		}
	}

	exit if ($count > 0);
}


sub print_help {
	print <<"EOT";
Options:
  -help
  -options                 option-file
  -type                    type of map, "flat", "contig", "noncontig", or "prism"
  -img_type                output image file type, "png", "jpg", or "gif"
  -video                   string
  -background              color
  -scale                   number
  -offset                  number
  -thick                   number
  -no_outline
  -adj_outside_density     number
  -edge                    number
  -use_existing
  -no_unlink
  -one_color               color
  -cart2
  -cartv
  -cart2v
  -bg                      color
  -fg                      color
  -data                    data-file
  -area
  -scale_data
  -generate
  -project                 projection type, "aea", "laea", or "none"
  -lon_scale               number
  -correction              number
  -prune                   number,number
  -map                     map-file
  -mesh                    mesh-file
  -mesh_thick              number
  -mesh_size               number
  -mesh_color              color
  -overlay                 map-file
  -overlay_thick           number
  -overlay_color           color
  -camera                  number,number,number
  -zoom                    number
  -gamma                   number
  -camera_type             string
  -width                   number
  -height                  number
  -transform               string
  -adj_max
  -adj_max_noncontig       number
  -ypoint                  number
  -transparency            number
EOT

}

#
# Check that a string is either a named color, or three comma-separated numeric values
#

sub looks_like_color {
	my $color = $_[0];
	return 1 if (exists $named_colors{$color});
	if ($color =~ /^(\d+),(\d+),(\d+)$/) {
		return 0 if ($1 < 0 or $1 > 255);
		return 0 if ($2 < 0 or $2 > 255);
		return 0 if ($3 < 0 or $3 > 255);
		return 1;
	}
	return 0;
}


##################################
# Generic first pass over the data and map files
# Collects identifiers for the map polygons, stores density information
# Four forms are accepted:
#   - four items  => identifier, area, theme value, color
#   - three items => identifier, area, theme value
#                    identifier, pre-commputed density, color
#                    identifier, theme value, color                    when -area flag is set
#   - two items   => identifier, pre-computed density
#                    identifier, theme value                           when -area flag is set
# In the no-color cases, "gray" is used
#

sub read_data_file {
	my @temp;
	my $id;
	my $value;
	my $key;
	my $color;
	my $line_count;

	open INPUT, "<$data_filename" or die "Error          could not open data file $data_filename\n";
	printf STDERR "Progress       first pass over data file\n";
	$max_value = -100e+100;
	$line_count = 0;
	while (<INPUT>) {
		@temp = split " ";
		$id = &patch_id($temp[0]);
		$line_count += 1;
		if ($id =~ /^(\d{2})(\d{3})$/) {
			next if (not exists $state_area{$1});
			$state_fips{$1} = 1;
			$county_fips{$id} = 1;
		}
		elsif ($id =~ /^(\d{2})(\d{2})$/) {
			next if (not exists $state_area{$1});
			$state_fips{$1} = 1;
			$district_fips{$id} = 1;
		}
		elsif ($id =~ /^(\d{2})$/) {
			next if (not exists $state_area{$1});
			$state_fips{$id} = 1;
		}
		elsif ($id =~ /^[A-Z_]+$/) {
		}
		else {
			print STDERR "Warning        bad identifier $temp[0]\n";
			next;
		}

		if (@temp == 2) {
			$value = $temp[1];
			$value /= $state_area{$id} if ($area_flag && $state_area{$id});
			$value /= $county_area{$id} if ($area_flag && $county_area{$id});
			$value /= $district_area{$id} if ($area_flag && $district_area{$id});
			$color = "gray";
		}
		elsif (@temp == 3) {
			if ($temp[2] =~ /^[0-9\.]+$/) {
				 $value = $temp[2] / $temp[1];
				 $color = "gray";
			}
			else {
				$value = $temp[1];
				$value /= $state_area{$id} if ($area_flag && $state_area{$id});
				$value /= $county_area{$id} if ($area_flag && $county_area{$id});
				$value /= $district_area{$id} if ($area_flag && $district_area{$id});
				$color = $temp[2];
			}
		}
		elsif (@temp == 4) {
			$value = $temp[2] / $temp[1];
			$color = $temp[3];
		}
		else {
			printf STDERR "Error          too many tokens, data file line %d\n", $line_count;
			exit;
		}
		$theme_value{$id} = $value;
		$max_value = $value if ($value > $max_value);
		$shade{$id} = $color;
		$total_points{$id} = 0;
	}

	printf STDERR "Progress       kept %d identifiers, %d states, %d counties, %d districts\n", scalar keys %theme_value, scalar keys %state_fips, scalar keys %county_fips, scalar keys %district_fips;
	printf STDERR "Progress       maximum thematic value %f\n", $max_value;
}

#
# Apply a transform, if specified, to the data values
# Assumption is that the eval string contains Perl and (most likely) uses $value local and $max_value global
#   to calculate a transformed theme value
# Eval is usually regarded as dangerous
# 

sub apply_transform {
	my $value;
	my $key;
	my $new_max = -100e+100;

	foreach $key (keys %theme_value) {
		$value = $theme_value{$key};
		$value = eval $transform;
		if ($@) {
			die "Error          error \"$@\" during transform \"$transform\"\n";
		}
		$theme_value{$key} = $value;
		$new_max = $value if ($value > $new_max);
	}
	$max_value = $new_max if ($adj_max_flag);
}

#
# Generic first pass over the map file
# Gets the bounding box for the polygons associated with labels from the data file (x_min, y_min, x_max, y_max)
# Counts the number of identifiers for future use in a progress bar in the contiguous case
#

sub first_map_pass {
	my $temp;
	my $id;
	my $x;
	my $y;
	my $count = 0;
	my $pt_count = 0;

	print STDERR "Progress       first pass over map file\n";
	open INPUT, "<$map_filename" or die "Error          couldn't open map file $map_filename\n";
	$x_min = $y_min =  10e100;
	$x_max = $y_max = -10e100;
	while (<INPUT>) {
		$temp = $_;
		if ($temp =~ /^([0-9A-Za-z_\-\']+)$/) {
			$id = &patch_id($1);
			if (exists $theme_value{$id}) {
				$count++;
			}
			else {
				print STDERR "Warning        unrecognized identifier $id\n";
			}
			next;
		}
		if ($temp =~ /\{/) {
			$pt_count = 0;
			next;
		}
		if ($temp =~ /\}/) {
			$total_points{$id} += $pt_count if (exists $total_points{$id});
			next;
		}
		if (exists $theme_value{$id}) {
			($x, $y) = split " ", $temp;
			$x_min = $x if ($x < $x_min);
			$x_max = $x if ($x > $x_max);
			$y_min = $y if ($y < $y_min);
			$y_max = $y if ($y > $y_max);
			$pt_count += 1;
		}
	}
	$shape_count = $count;
	print STDERR "Progress       recognized $count identifiers\n";
	print STDERR "Progress       bounding box " . (join " ", ($x_min, $y_min, $x_max, $y_max)) . "\n";
}


##################################
# Contiguous cartogram routines
# Set up all of the GD stuff that gets used for drawing for flat, contiguous, and noncontiguous cartograms
# While there's a bunch of common stuff for flat, contig, and noncontig, there's also some specific stuff
# In the contig/flat case, note the stuff for mesh clipping
#

sub setup_graphics {
	my $value;
	my $key;
	my $temp;

	print STDERR "Progress       setting up graphics environment\n";

	$image_width = $x_max - $x_min;
	$image_height = $y_max - $y_min;
	$image_scale = 1000 / max($image_width, $image_height);
	$image_scale = $image_scale * $user_scale;
	if ($map_type eq "noncontig") {
		$image_width = (50 * $user_scale) + int($image_scale * $image_width);
		$image_height = (50 * $user_scale) + int($image_scale * $image_height);
		print STDERR "Progress       image size $image_width, $image_height\n";
	}
	else {
		print STDERR "Progress       image scale $image_scale\n";
		$x_min *= $image_scale;
		$x_max *= $image_scale;
		$y_min *= $image_scale;
		$y_max *= $image_scale;
		print STDERR "Progress       bounding box " . (join " ", ($x_min, $y_min, $x_max, $y_max)) . "\n";
		$image_width = int($image_width * $image_scale + 1 + 2 * $image_offset);
		$image_height = int($image_height * $image_scale + 1 + 2 * $image_offset);
		$x_offset = int($image_offset - $x_min);
		$y_offset = int($image_offset - $y_min);
		print STDERR "Progress       image parameters " . (join " ", ($image_width, $image_height, $x_offset, $y_offset)) . "\n";
	}

	$image = new GD::Image($image_width, $image_height, 1);
	foreach $key (keys %named_colors) {
		$named_colors{$key} = $image->colorResolve($named_colors{$key}->[0], $named_colors{$key}->[1], $named_colors{$key}->[2]);
	}
	$background = &resolve_color($background, $named_colors{"white"});
	$overlay_color = &resolve_color($overlay_color, $named_colors{"blue"});
	$outline_color = &resolve_color($outline_color, $named_colors{"black"});
	$mesh_color = &resolve_color($mesh_color, $named_colors{"black"});

	if ($map_type eq "contig" or $map_type eq "flat") {
		$value = 10;
		foreach $key (keys %theme_value) {
			$colors{$key} = $image->colorResolve(10, ($value>>8)&0xff, $value&0xff);
			$value += 1;
		}
		if ($one_color) {
			$one_color = &resolve_color($one_color, 0);
		}
		if ($mesh_flag) {
			$clip_image = new GD::Image($image_width, $image_height, 1);
			$clip_image->setThickness(3);
		}
	}

	if ($map_type eq "noncontig") {
		$image->filledRectangle(0, 0, $image_width-1, $image_height-1, $background);
		$image->setThickness($border_thickness);
		$noncontig_bg = &resolve_color($noncontig_bg);
		$noncontig_fg = &resolve_color($noncontig_fg);
		print STDERR "Progress       finished graphics setup\n";
	}
}

sub resolve_color {
	my $color = $_[0];
	my $default = $_[1];
	if ($color) {
		if ($color =~ /^\s*(\d+),(\d+),(\d+)\s*$/) {
			$color = $image->colorResolve($1, $2, $3);
		}
		elsif (exists $named_colors{$color}) {
			$color = $named_colors{$color};
		}
		else {
			if (not defined $default) {
				die "Error          unrecognized named color $color\n";
			}
			print STDERR "Warning        replacing color $color with default\n";
			$color = $default;
		}
	}
	return $color;
}

sub print_image {
	my $out_name = "cartogram.$img_type";
	print STDERR "Progress       printing image to $out_name\n";
	open OUTPUT, ">$out_name" or die "Error          couldn't open output file $out_name\n";
	binmode OUTPUT;
	print OUTPUT $image->png  if ($img_type eq "png");
	print OUTPUT $image->jpeg if ($img_type eq "jpg");
	print OUTPUT $image->gif  if ($img_type eq "gif");
}

#
# Second pass over the data information takes care of things that couldn't be done
#   until the graphics environment was initialized
#

sub second_pass_data {
	my $id;

	print STDERR "Progress       second pass over thematic data\n";
	foreach $id (keys %theme_value) {
		$value[$colors{$id}] = $theme_value{$id};
		$shade{$id} = &resolve_color($shade{$id});
	}
}

#
# Second pass over the map file
# Draws the polygons on the GD image for generating density
# Each point (with interpolated points if necessary for smoothness) is printed to
#   an external file to be run through interp
#

sub second_pass_map {
	my $temp;
	my $id;
	my $x_last;
	my $y_last;
	my $x;
	my $y;
	my $x_step;
	my $y_step;
	my $x_temp;
	my $y_temp;
	my $n;
	my $progress_count = 0;
	my $poly;

	print STDERR "Progress       second pass over map file\n";
	open INPUT, "<$map_filename";
	open OUTPUT, ">cartogram.points";
	$image->filledRectangle(0, 0, $image_width-1, $image_height-1, $named_colors{white});
	$image->setThickness(1);
	&progress_start($shape_count);
	$point_count = 0;
	while (<INPUT>) {
		$temp = $_;
		if ($temp =~ /^([0-9A-Za-z_\-\']+)$/) {
			$id = &patch_id($1);
		}
		elsif ($temp =~ /\{/) {
			if (exists $theme_value{$id}) {
				$poly = GD::Polygon->new;
				$x_last = -1;
				$y_last = -1;
			}
		}
		elsif ($temp =~ /\}/) {
			if (exists $theme_value{$id}) {
				$image->filledPolygon($poly, $colors{$id});
				$image->polygon($poly, $colors{$id});
				$progress_count++;
				&progress_update($progress_count);
				push @poly_list1, $poly if ($video_string);
			}
		}
		elsif (exists $theme_value{$id}) {
			($x, $y) = split " ", $temp;
			$x = $image_scale * $x + $x_offset;
			$y = $image_scale * $y + $y_offset;
			if ($x_last >= 0) {
				$temp = &distance($x_last, $y_last, $x, $y);
				if ($poly_max_edge && $temp > $poly_max_edge) {
					$n = $temp / $poly_max_edge;
					$x_step = ($x - $x_last) / ($n+1);
					$y_step = ($y - $y_last) / ($n+1);
					$x_temp = $x_last;
					$y_temp = $y_last;
					while ($n > 0) {
						$x_temp += $x_step;
						$y_temp += $y_step;
						$poly->addPt($x_temp, $y_temp);
						printf OUTPUT "%f %f\n", $x_temp, $y_temp;
						$n = $n - 1;
						$point_count += 1;
					}
				}
			}
			$poly->addPt($x, $y);
			printf OUTPUT "%f %f\n", $x, $y;
			$point_count += 1;
			$x_last = $x;
			$y_last = $y;
		}
	}
	close OUTPUT;
	&progress_finish();
}

#
# Subroutine calculates Euclidean distance between two points
#

sub distance {
	my ($x1, $y1, $x2, $y2) = @_;
	$x1 = $x2 - $x1;
	$y1 = $y2 - $y1;
	return sqrt($x1*$x1+$y1*$y1);
}

#
# Generate the density file that cart will use
# The GD image was drawn with polygons, each using a color index that goes into an array of values
# First pass over the image calculates the average density of non-background, to be used for external density
# Second pass builds the density file for cart
#

sub build_density {
	my $y;
	my $x;
	my $temp;
	my $value = 0;
	my $count = 0;
	my $zero_count = 0;

	for ($y=0; $y<$image_height; $y++) {
		for ($x=0; $x<$image_width; $x++) {
			$temp = $image->getPixel($x, $y);
			if ($temp != $named_colors{white}) {
				$value += $value[$temp];
				$count++;
			}
		}
	}
	$outside_density = $adj_outside_density * $value / $count;
	print STDERR "Progress       average density $outside_density\n";
	print STDERR "Progress       building density file\n";

	$zero_count = 0;
	open OUTPUT, ">cartogram.dat";
	&progress_start($image_height);
	for ($y=0; $y<$image_height; $y++) {
		for ($x=0; $x<$image_width; $x++) {
			$temp = $image->getPixel($x, $y);
			$value = ($temp == $named_colors{white}) ? $outside_density : $value[$temp];
			$zero_count++ if ($value <= 0);
			printf OUTPUT " %f", $value;
		}
		printf OUTPUT "\n";
		&progress_update($y);
	}
	&progress_finish();
	if ($zero_count) {
		print STDERR "Warning        $zero_count points have value less than or equal to zero\n";
	}
}

#
# Third pass over the map file uses the transformed points to draw the actual map in the GD image
#

sub third_pass_map {
	my $temp;
	my $id;
	my $x_last;
	my $y_last;
	my $x;
	my $y;
	my $n;
	my $x_temp;
	my $y_temp;
	my $progress_count = 0;
	my $poly;

	print STDERR "Progress       third pass over map file\n";
	open INPUT, "<$map_filename";
	open MAPPED, "<cartogram.mapped.points";
	$image->filledRectangle(0, 0, $image_width-1, $image_height-1, $background);
	$image->setThickness($border_thickness);
	if ($mesh_flag) {
		$clip_image->filledRectangle(0, 0, $image_width-1, $image_height-1, $named_colors{white});
	}
	&progress_start($shape_count);
	while (<INPUT>) {
		$temp = $_;
		if ($temp =~ /^([0-9A-Za-z_\-\']+)$/) {
			$id = &patch_id($1);
			next;
		}
		if ($temp =~ /\{/) {
			if (exists $theme_value{$id}) {
				$poly = GD::Polygon->new;
				$x_last = -1;
				$y_last = -1;
			}
			next;
		}
		if ($temp =~ /\}/) {
			if (exists $theme_value{$id}) {
				my $color = $shade{$id};
				$color = $one_color if ($one_color);
				$image->filledPolygon($poly, $color);
				$image->polygon($poly, ($outline_flag) ? $outline_color : $color);
				if ($mesh_flag) {
					$clip_image->filledPolygon($poly, $named_colors{black});
				}
				$progress_count++;
				&progress_update($progress_count);
				push @poly_list2, $poly if ($video_string);
				push @poly_color_list, $color if ($video_string);
			}
			next;
		}
		if (exists $theme_value{$id}) {
			($x, $y) = split " ", $temp;
			$x = $image_scale * $x + $x_offset;
			$y = $image_scale * $y + $y_offset;
			if ($x_last >= 0) {
				$temp = &distance($x_last, $y_last, $x, $y);
				if ($poly_max_edge && $temp > $poly_max_edge) {
					$n =  $temp / $poly_max_edge;
					while ($n > 0) {
						$temp = <MAPPED>;
						($x_temp, $y_temp) = split " ", $temp;
						$poly->addPt($x_temp, $y_temp);
						$n = $n - 1;
					}
				}
			}
			$temp = <MAPPED>;
			($x_temp, $y_temp) = split " ", $temp;
			$poly->addPt($x_temp, $y_temp);
			$x_last = $x;
			$y_last = $y;
		}
	}
	close MAPPED;
	close INPUT;
	&progress_finish();
}


#
# Mesh passes
# First pass generates the vertices and puts them in a file to which interp can be applied
# Second pass uses post-interp points (unchanged if -flat was used) to draw the mesh
# &clip_mesh overwrites the background of the image again to "erase" mesh that appears outside of the map
#

sub first_mesh_pass {
	my $temp;
	my $x;
	my $y;
	my @temp;
	my $count = 0;

	print STDERR "Progress       first mesh pass\n";
	open INPUT, "<$mesh_filename" or die "Error          couldn't open mesh file $map_filename\n";
	open OUTPUT, ">cartogram.points" or die "Error          couldn't open working file cartogram.points\n";
	while (<INPUT>) {
		$temp = $_;
		$count += 1;
		next if ($temp =~ /\{|\}/);
		@temp = split " ", $temp;
		if (@temp != 2) {
			die "Error          bad format at mesh file line $count\n";
		}
		($x, $y) = @temp;
		$x = $image_scale * $x + $x_offset;
		$y = $image_scale * $y + $y_offset;
		printf OUTPUT "%12f %12f\n", $x, $y;
	}
	close INPUT;
	close OUTPUT;
}


sub second_mesh_pass {
	my $temp;
	my $poly;
	my $spline;
	my @temp;
	my $count = 0;

	print STDERR "Progress       second mesh pass\n";
	open MAPPED, "<cartogram.mapped.points" or die "Error          couldn't open working file cartogram.mapped.points\n";
	open INPUT, "<$mesh_filename";
	$image->setThickness($mesh_thick);
	&progress_start($point_count);
	while (<INPUT>) {
		if (/\{/) {
			$poly = new GD::Polyline;
		}
		elsif (/\}/) {
			$poly = $poly->addControlPoints();
			$spline = $poly->toSpline();
			$image->polyline($spline, $mesh_color);
			&progress_update($count);
		}
		else {
			$count += 1;
			@temp = split " ", <MAPPED>;
			if (@temp != 2) {
				die "Error          bad format at mesh file line $count\n";
			}
			$poly->addPt(@temp);
		}
	}
	close MAPPED;
	close INPUT;
	&progress_finish();
}


sub clip_mesh {
	my $x;
	my $y;

	print STDERR "Progress       clipping mesh\n";
	for ($y=0; $y<$image_height; $y++) {
		for ($x=0; $x<$image_width; $x++) {
			$image->setPixel($x, $y, $background) if ($clip_image->getPixel($x, $y) == $named_colors{white});
		}
	}
}


#
# Overlay pass
# Well, two passes actually, but both while loops are in this one routine
#

sub overlay_pass {
	my $temp;
	my $id;
	my $x_last;
	my $y_last;
	my $x;
	my $y;
	my $n;
	my $x_step;
	my $y_step;
	my $x_temp;
	my $y_temp;
	my $poly;

	print STDERR "Progress       first overlay pass\n";
	open INPUT, "<$overlay_map" or die "Error          couldn't open overlay map file";
	open OUTPUT, ">cartogram.points";
	while (<INPUT>) {
		$temp = $_;
		if ($temp =~ /^([0-9A-Za-z_\-\']+)$/) {
			$id = &patch_id($1);
			next;
		}
		if ($temp =~ /\{/) {
			$x_last = -1;
			$y_last = -1;
			$poly = GD::Polygon->new if ($video_string);
			next;
		}
		if ($temp =~ /\}/) {
			push @poly_list3, $poly if ($video_string);
			next;
		}
		($x, $y) = split " ", $temp;
		$x = $image_scale * $x + $x_offset;
		$y = $image_scale * $y + $y_offset;
		if ($x_last >= 0) {
			$temp = &distance($x_last, $y_last, $x, $y);
			if ($poly_max_edge && $temp > $poly_max_edge) {
				$n = $temp / $poly_max_edge;
				$x_step = ($x - $x_last) / ($n+1);
				$y_step = ($y - $y_last) / ($n+1);
				$x_temp = $x_last;
				$y_temp = $y_last;
				while ($n > 0) {
					$x_temp += $x_step;
					$y_temp += $y_step;
					$poly->addPt($x_temp, $y_temp) if ($video_string);
					printf OUTPUT "%12f %12f\n", $x_temp, $y_temp;
					$n = $n - 1;
				}
			}
		}
		$poly->addPt($x, $y) if ($video_string);
		printf OUTPUT "%12f %12f\n", $x, $y;
		$x_last = $x;
		$y_last = $y;
	}

	close OUTPUT;
	if ($map_type eq "flat") {
		copy("cartogram.points", "cartogram.mapped.points") or die "Error          file copy failed\n";
	}
	else {
		print STDERR "Progress       running interp on overlay polygon vertices\n";
		system("$interp_program $image_width $image_height cartogram.mapped.dat <cartogram.points >cartogram.mapped.points");
	}

	print STDERR "Progress       second overlay pass\n";
	open INPUT, "<$overlay_map" or die "Error          couldn't open overlay map file";
	open MAPPED, "<cartogram.mapped.points" or die "Error          couldn't open mapped points file";
	$image->setThickness($overlay_thickness);
	while (<INPUT>) {
		$temp = $_;
		if ($temp =~ /^([0-9A-Za-z_\-\']+)$/) {
			$id = &patch_id($1);
			next;
		}
		if ($temp =~ /\{/) {
			$poly = GD::Polygon->new;
			$x_last = -1;
			$y_last = -1;
			next;
		}
		if ($temp =~ /\}/) {
			$image->polygon($poly, $overlay_color);
			push @poly_list4, $poly if ($video_string);
			next;
		}
		($x, $y) = split " ", $temp;
		$x = $image_scale * $x + $x_offset;
		$y = $image_scale * $y + $y_offset;
		if ($x_last >= 0) {
			$temp = &distance($x_last, $y_last, $x, $y);
			if ($poly_max_edge && $temp > $poly_max_edge) {
				$n =  $temp / $poly_max_edge;
				while ($n > 0) {
					$temp = <MAPPED>;
					($x_temp, $y_temp) = split " ", $temp;
					$poly->addPt($x_temp, $y_temp);
					$n = $n - 1;
				}
			}
		}
		$temp = <MAPPED>;
		($x_temp, $y_temp) = split " ", $temp;
		$poly->addPt($x_temp, $y_temp);
		$x_last = $x;
		$y_last = $y;
	}
	close MAPPED;
	close INPUT;
}


#
# Video pass for contiguous cartograms
# Lists of polygons, before and after the gas-diffusion treatment have been stored previously
# Here new polygons are created based on a weighted average of the before and after version
# Images for individual frames are created in the "video" subdirectory
# Ffmpeg is used to combine those frames into a cartogram.mp4 video clip
#

sub video_pass {
	my $weight = 0;
	my $step = 0.01;
	my $limit = 101;
	my ($i, $j, $k);
	my ($poly, $poly1, $poly2);
	my ($x1, $x2, $y1, $y2);
	my $out_name;
	my $ff_cmd;
	my $temp;

	print STDERR "Progress       contiguous video pass\n";
	print STDERR "Progress       generating individual frames\n";
	&progress_start($limit);
	$poly = GD::Polygon->new;

	for ($i=0; $i<$limit; $i++) {
		$image->setThickness($border_thickness);
		$image->filledRectangle(0, 0, $image_width-1, $image_height-1, $named_colors{white});
		for ($j=0; $j<@poly_list1; $j++) {
			$poly  = GD::Polygon->new;
			$poly1 = $poly_list1[$j];
			$poly2 = $poly_list2[$j];
			for ($k=0; $k<$poly1->length; $k++) {
				($x1, $y1) = $poly1->getPt($k);
				($x2, $y2) = $poly2->getPt($k);
				$poly->addPt(($weight*$x2 + (1-$weight)*$x1), ($weight*$y2 + (1-$weight)*$y1));
			}
			$image->filledPolygon($poly, $poly_color_list[$j]);
			$image->polygon($poly, ($outline_flag) ? $named_colors{black} : $poly_color_list[$j]);
		}

		$image->setThickness($overlay_thickness);
		for ($j=0; $j<@poly_list3; $j++) {
			$poly  = GD::Polygon->new;
			$poly1 = $poly_list3[$j];
			$poly2 = $poly_list4[$j];
			for ($k=0; $k<$poly1->length; $k++) {
				($x1, $y1) = $poly1->getPt($k);
				($x2, $y2) = $poly2->getPt($k);
				$poly->addPt(($weight*$x2 + (1-$weight)*$x1), ($weight*$y2 + (1-$weight)*$y1));
			}
			$image->polygon($poly, $overlay_color);
		}

		$out_name = sprintf "video/frame%03d.png", $i;
		open OUTPUT, ">$out_name" or die "Error          couldn't open frame file $out_name\n";
		binmode OUTPUT;
		print OUTPUT $image->png;
		$weight += $step;
		&progress_update($i);
	}

	&progress_finish();
	$temp = "";
	$temp = sprintf("%dx%d", $image_width, $image_height) if ($video_string eq "full");
	$temp = sprintf("%dx%d", $image_width/2, $image_height/2) if ($video_string eq "half");
	$temp = sprintf("%dx%d", $image_width/4, $image_height/4) if ($video_string eq "quarter");
	$temp = sprintf("%dx%d", $image_width*$video_string, $image_height*$video_string) if ($video_string =~ /^0?\.\d+$|^1\.0*$/);
	$temp = $video_string if ($video_string =~ /^\d+x\d+$/);
	if ($temp eq "") {
		die "Error          bad video format $video_string\n";
	}
	$temp =~ /(\d+)x(\d+)/;
	$temp = sprintf("%dx%d", 2*int($1/2.0), 2*int($2/2.0));
	unlink("cartogram.mp4");
	print STDERR "Progress       running ffmpeg\n";
	$ff_cmd = sprintf "ffmpeg -i video/frame%%03d.png -vf scale=%s,setsar=1:1 -pix_fmt yuv420p cartogram.mp4 >%s 2>%s", $temp, $null_name, $null_name;
	system($ff_cmd);
}


##################################
# Code here for the noncontiguous case
#

sub noncontig_second_data {
	my $id;
	print STDERR "Progress       second pass over data\n";

	foreach $id (keys %theme_value) {
		if ($scale_data_flag) {
			$theme_value{$id} /= $max_value;
			$theme_value{$id} *= 100;
		}
		$shade{$id} = &resolve_color($shade{$id}, $noncontig_bg);
	}
}

sub noncontig_second_map {
	my $temp;
	my $id;
	my $x;
	my $y;
	my $count = 0;
	my $poly;

	print STDERR "Progress       second pass over map file\n";
	open INPUT, "<$map_filename";
	while (<INPUT>) {
		$temp = $_;
		chomp $temp;
		if ($temp =~ /^([0-9A-Za-z_]+)/) {
			$id = &patch_id($1);
		}
		elsif ($temp =~ /\{/) {
			$poly = GD::Polygon->new;
		}
		elsif ($temp =~ /\}/) {
			if (exists $theme_value{$id}) {
				$image->filledPolygon($poly, $shade{$id});
				$image->polygon($poly, $named_colors{black});
				$count++;
			}
		}
		elsif ($temp =~ / +([0-9\.\-]+) +([0-9\.\-]+)/) {
			$x = $1;
			$y = $2;
			$x = 25 + $image_scale * ($x - $x_min);
			$y = 25 + $image_scale * ($y - $y_min);
			$poly->addPt($x, $y);
		}
	}
	print STDERR "Progress       drew $count map polygons\n";
}

sub noncontig_third_map {
	my $temp;
	my $id;
	my $x;
	my $y;
	my $count = 0;

	print STDERR "Progress       third pass over map file\n";
	open INPUT, "<$map_filename";
	while (<INPUT>) {
		$temp = $_;
		chomp $temp;
		if ($temp =~ /^([0-9A-Za-z_]+)/) {
			$id = &patch_id($1);
		}
		elsif ($temp =~ /\{/) {
			@x_list = ();
			@y_list = ();
		}
		elsif ($temp =~ /\}/) {
			if (exists $theme_value{$id}) {
				&shrink($id);
				$count++;
			}
		}
		elsif ($temp =~ / +([0-9\.\-]+) +([0-9\.\-]+)/) {
			$x = $1;
			$y = $2;
			$x = 25 + $image_scale * ($x - $x_min);
			$y = 25 + $image_scale * ($y - $y_min);
			push @x_list, $x;
			push @y_list, $y;
		}
	}
	print STDERR "Progress       drew $count shrunken map polygons\n";
}

sub centroid {
	my $area;
	my $i;

	$area = 0;
	for ($i=0; $i<@x_list-1; $i++) {
		$area += ($x_list[$i]*$y_list[$i+1] - $x_list[$i+1]*$y_list[$i]);
	}
	$area *= 0.5;

	$x_centroid = 0;
	$y_centroid = 0;
	for ($i=0; $i<@x_list-1; $i++) {
		$x_centroid += ($x_list[$i] + $x_list[$i+1]) * ($x_list[$i]*$y_list[$i+1] - $x_list[$i+1]*$y_list[$i]);
		$y_centroid += ($y_list[$i] + $y_list[$i+1]) * ($x_list[$i]*$y_list[$i+1] - $x_list[$i+1]*$y_list[$i]);
	}
	$x_centroid /= 6 * $area;
	$y_centroid /= 6 * $area;
}

sub shrink {
	my $id = $_[0];
	my $shrink_scale;
	my $poly;
	my $i;
	my $x_shrunk;
	my $y_shrunk;

	&centroid();
	$shrink_scale = ($theme_value{$id}/100) ** 0.5;
	$shrink_scale = ($adj_max_noncontig * $theme_value{$id}/$max_value) ** 0.5 if ($adj_max_noncontig > 0);
	&apply_hints($id) if ($id =~ /^\d{2}$/);
	$poly = GD::Polygon->new;
	for ($i=0; $i<@x_list; $i++) {
		$x_shrunk = $x_centroid + $shrink_scale * ($x_list[$i] - $x_centroid);
		$y_shrunk = $y_centroid + $shrink_scale * ($y_list[$i] - $y_centroid);
		$poly->addPt($x_shrunk, $y_shrunk);
	}
	$image->filledPolygon($poly, $noncontig_fg);
}

sub apply_hints {
	my $id = $_[0];
	my $i;

	for ($i=0; $i<@noncontig_hints; $i+=3) {
		if ($id eq $noncontig_hints[$i]) {
			$x_centroid += $noncontig_hints[$i+1] * $user_scale;
			$y_centroid += $noncontig_hints[$i+2] * $user_scale;
			last;
		}
	}
}

sub noncontig_overlay {
	my @temp;
	my $temp;
	my $id;
	my $poly;
	my $x;
	my $y;
	my %state_fips = ();

	print STDERR "Progress       first noncontig overlay pass\n";
	open INPUT, "<$data_filename";
	while (<INPUT>) {
		@temp = split " ";
		$id = &patch_id($temp[0]);
		if ($id =~ /^(\d{2})\d{3}$/) {
			$state_fips{$1} = 1;
		}
		else {
			$state_fips{$id} = 1;
		}
	}
	close INPUT;

	print STDERR "Progress       second noncontig overlay pass\n";
	$image->setThickness($overlay_thickness);
	open INPUT, "<$overlay_map" or die "Error          couldn't open overlay map file";
	while (<INPUT>) {
		$temp = $_;
		if ($temp =~ /^([0-9A-Za-z_\-\']+)/) {
			$id = &patch_id($1);
		}
		elsif ($temp =~ /\{/) {
			$poly = GD::Polygon->new;
		}
		elsif ($temp =~ /\}/) {
			if ($state_fips{$id}) {
				$image->polygon($poly, $overlay_color);
			}
		}
		else {
			($x, $y) = split " ", $temp;
			$x = 25 + $image_scale * ($x - $x_min);
			$y = 25 + $image_scale * ($y - $y_min);
			$poly->addPt($x, $y);
		}
	}
	close INPUT;
}


##################################
# Map generation stuff here
# Shapefiles that start with cb_ obtained from the US Census Bureau
# Base_ files exist because it's simpler to use them than the shapefiles
# External cs2cs program from PROJ.4 is assumed
#

sub maps_start {
	my $flag;

	printf STDERR "Progress       generating maps\n";
	chdir("generate");
	if (scalar keys %county_fips) {
		if ($from_shapefile) {
			maps_generate("cb_2016_us_county_20m", "counties", $mesh_flag);
		}
		else {
			maps_generate("base_counties", "counties", $mesh_flag);
		}
	}
	if (scalar keys %district_fips) {
		if ($from_shapefile) {
			maps_generate("cb_2017_us_cd115_20m", "districts", $mesh_flag);
		}
		else {
			maps_generate("base_districts", "districts", $mesh_flag);
		}
	}
	if (0 < scalar keys %state_fips) {
		$flag = 1;
		$flag = 0 if (scalar keys %county_fips);
		$flag = 0 if (scalar keys %district_fips);
		$flag = 0 if (!$mesh_flag);
		if ($from_shapefile) {
	 		maps_generate("cb_2016_us_state_20m", "states", $flag);
		}
		else {
			maps_generate("base_states", "states", $flag);
		}
	}
	chdir("..");
}

#
# Extract polygons from shapefile(s)
# This makes a stupid number of passes over map files
# 

sub maps_generate {
	my ($root_name, $output_name, $mesh_flag) = @_;
	my $i;
	my $j;
	my $k;
	my %places = ();
	my @polys;
	my @points;
	my $x;
	my $y;
	my @temp;
	my $numbers;
	my @numbers;
	my $min_lon;
	my $max_lon;
	my $min_lat;
	my $max_lat;
	my $ymax;
	my $ymin;
	my $step_lon;
	my $step_lat;
	my $lat;
	my $lon;
	my $count;
	my $center_lon;
	my $center_lat;

#
# Extract polygons
#
	if ($from_shapefile) {
		print STDERR "Progress       extracting from shapefile root $root_name\n";
		%places = &from_shapefile($root_name, $output_name);
	}
	else {
		print STDERR "Progress       extracting from basemap root $root_name\n";
		%places = &from_basemap($root_name, $output_name);
	}

#
# Prune away small polygons if requested
# The %places hash contains references to arrays of polygons, one per named place from the data file
# Each polygon is a reference to an array of points
# Places where the description is only a single polygon are never pruned
#
	if (@prune_values) {
		my $prune_count = 0;
		my $total_points;
		my $count;
		print STDERR "Progress       pruning small polygons\n";
		foreach $i (keys %places) {
			@polys = @{ $places{$i} };
			next if (@polys == 1);
			$total_points = 0;
			foreach $j (@polys) {
				$total_points += scalar @{ $j };
			}
			@temp = ();
			foreach $j (@polys) {
				$count = scalar @{ $j };
				if ($count > $prune_values[0] * $total_points or $count > $prune_values[1]) {
					push @temp, $j;
				}
				else {
					$prune_count += 1;
				}
			}
			$places{$i} = [@temp];
		}
		print STDERR "Progress       pruned $prune_count polygons\n";
	}

#
# Projection transformation if needed
#
	$min_lon = $min_lat =  10e100;
	$max_lon = $max_lat = -10e100;
	foreach $i (keys %places) {
		@polys = @{ $places{$i} };
		foreach $j (@polys) {
			@points = @{ $j };
			foreach $k (@points) {
				$min_lon = $k->[0]  if ($k->[0] < $min_lon);
				$max_lon = $k->[0]  if ($k->[0] > $max_lon);
				$min_lat = $k->[1]  if ($k->[1] < $min_lat);
				$max_lat = $k->[1]  if ($k->[1] > $max_lat);
			}
		}
	}
	$center_lon = (($max_lon + $min_lon) / 2) + $center_correction;
	$center_lat = (($max_lat + $min_lat) / 2);
	print STDERR "Progress       center longitude $center_lon\n";
	print STDERR "Progress       center latitude $center_lat\n";

	if ($project_type eq "none") {
		open OUTPUT, ">temp1.numbers";
	}
	else {
		my $cmd = $project_hash{$project_type};
		$cmd =~ s/(\$\w+)/$1/gee;
		open OUTPUT, "| $cmd >temp1.numbers";
	}
	foreach $i (keys %places) {
		@polys = @{ $places{$i} };
		foreach $j (@polys) {
			@points = @{ $j };
			foreach $k (@points) {
				printf OUTPUT "    %f    %f\n", $k->[0], $k->[1];
			}
		}
	}
	close OUTPUT;

#
# Build the final map
#
	$ymin =  10e100;
	$ymax = -10e100;
	open INPUT, "<temp1.numbers" or die "Error          generation - unable to open file temp1.numbers for input\n";
	while (<INPUT>) {
		$numbers = $_;
		$numbers =~ s/\t/  /g;
		@numbers = split " ", $numbers;
		$ymax = $numbers[1] if ($numbers[1] > $ymax);
		$ymin = $numbers[1] if ($numbers[1] < $ymin);
	}
	close INPUT;

	open INPUT, "<temp1.numbers" or die "Error          generation - unable to open file temp1.numbers for input\n";
	open OUTPUT, ">$output_name.map" or die "Error          generation - unable to open file $output_name.map for output\n";
	foreach $i (keys %places) {
		print OUTPUT "$i\n";
		@polys = @{ $places{$i} };
		foreach $j (@polys) {
			print OUTPUT "{\n";
			@points = @{ $j };
			foreach $k (@points) {
				$numbers = <INPUT>;
				$numbers =~ s/\t/  /g;
				@numbers = split " ", $numbers;
				$x = $numbers[0];
				$y = $ymin + ($ymax - $numbers[1]);
				printf OUTPUT "    %12f    %12f\n", $x, $y;
			}
			print OUTPUT "}\n";
		}
	}

	close INPUT;
	close OUTPUT;
	print STDERR "Progress       generated map file $output_name.map\n";

#
# Generate mesh files if necessary
#
	if ($mesh_flag) {
		$step_lon = ($max_lon - $min_lon) / ($mesh_size - 1);
		$step_lat = ($max_lat - $min_lat) / ($mesh_size - 1);
		if ($project_type eq "none") {
			open OUTPUT, ">temp1.numbers";
		}
		else {
			my $cmd = $project_hash{$project_type};
			$cmd =~ s/(\$\w+)/$1/gee;
			open OUTPUT, "| $cmd >temp1.numbers";
		}
		print STDERR "Progress       latitude range " . (join " ", ($min_lat, $max_lat)) . "\n";
		print STDERR "Progress       longitude range " . (join " ", ($min_lon, $max_lon)) . "\n";
		print STDERR "Progress       step sizes " . (join " ", ($step_lat, $step_lon)) . "\n";
		$lat = $min_lat;
		for ($i=0; $i<$mesh_size; $i++) {
			$lon = $min_lon;
			for ($j=0; $j<$mesh_size; $j++) {
				printf OUTPUT "  %f  %f\n", $lon, $lat;
				$lon += $step_lon;
			}
			$lat += $step_lat;
		}
		$lon = $min_lon;
		for ($i=0; $i<$mesh_size; $i++) {
			$lat = $min_lat;
			for ($j=0; $j<$mesh_size; $j++) {
				printf OUTPUT "  %f  %f\n", $lon, $lat;
				$lat += $step_lat;
			}
			$lon += $step_lon;
		}
		close OUTPUT;

		open INPUT, "<temp1.numbers" or die "Error          generation mesh - unable to open file temp1.numbers for input\n";
		open OUTPUT, ">$output_name.mesh" or die "Error          generation mesh - unable to open file $output_name.mesh for output\n";
		$count = 0;
		while (<INPUT>) {
			print OUTPUT "{\n" if ($count == 0);
			$numbers = $_;
			$numbers =~ s/\t/ /g;
			@numbers = split " ", $numbers;
			$numbers[1] = $ymin + ($ymax - $numbers[1]);
			printf OUTPUT "  %f  %f\n", $numbers[0], $numbers[1];
			$count += 1;
			if ($count >= $mesh_size) {
				print OUTPUT "}\n";
				$count = 0;
			}
		}
		close INPUT;
		close OUTPUT;
		print STDERR "Progress       generated mesh file $output_name.mesh\n";
	}

	unlink "temp1.numbers";
}

#
# Extract polygon information and return it
# Two separate routines, one for shapefiles and one for basemap .map files
#

sub from_shapefile {
	my ($root_name, $output_name) = @_;
	my $shapefile;
	my $id_db_string;
	my %places;
	my $i;
	my %dbf_record;
	my $shape;
	my $fips;
	my $state;
	my @polys;
	my $j;
	my @temp;
	my @points;
	my $k;
	my $x;
	my $y;

	$shapefile = new Geo::ShapeFile($root_name);
	$id_db_string = "GEOID";
	%places = ();
	for ($i=1; $i<=$shapefile->shapes; $i++) {
		%dbf_record = $shapefile->get_dbf_record($i);
		$shape = $shapefile->get_shp_record($i);
		$fips = $dbf_record{$id_db_string};
		$fips = &patch_id($fips);
		$state = substr($fips, 0, 2);
		next if (not exists $state_area{$state});
		next if ($output_name eq "states" && !$state_fips{$state});
		next if ($output_name eq "counties" && !$county_fips{$fips});
		next if ($output_name eq "districts" && !$district_fips{$fips});
		@polys = ();
		for ($j=1; $j<=$shape->num_parts; $j++) {
			@temp = $shape->get_part($j);
			@points = ();
			if (@temp > 0) {
				for ($k=0; $k<@temp; $k++) {
					$x = $lon_scale * $temp[$k]->X;
					$y = $temp[$k]->Y;
					push @points, [$x, $y];
				}
				push @polys, [@points];
			}
		}
		$places{$fips} = [@polys];
	}

	return %places;
}

sub from_basemap {
	my ($root_name, $output_name) = @_;
	my $fips = "";
	my $line;
	my $flag;
	my $state;
	my %places = ();
	my @polys;
	my @points;
	my @temp;

	open INPUT, "<$root_name.map" or die "Error          unable to open $root_name.map\n";
	$line = <INPUT>;
	while (1) {
		last if (!$line);
		chomp $line;
		$fips = &patch_id($line);
		$state = substr($fips, 0, 2);
		@polys = ();
		$line = <INPUT>;
		while ($line and $line =~ /\{/) {
			@points = ();
			$line = <INPUT>;
			while ($line !~ /\}/) {
				@temp = split " ", $line;
				$temp[0] *= $lon_scale;
				push @points, [$temp[0], $temp[1]];
				$line = <INPUT>;
			}
			push @polys, [@points];
			$line = <INPUT>;
		}
		$flag = 1;
		$flag = 0 if ($output_name eq "states" && !$state_fips{$state});
		$flag = 0 if ($output_name eq "counties" && !$county_fips{$fips});
		$flag = 0 if ($output_name eq "districts" && !$district_fips{$fips});
		$places{$fips} = [@polys] if ($flag);
	}
	return %places;
}



##################################
# This is the code for generating a prism map
# Unlike the contig and noncontig stuff, everything but helper functions are in one function
#

sub make_prism_map {
	
	my $key;
	my $x_shift;
	my $y_shift;
	my $areal_scale;
	my @temp;
	my $temp;
	my $cam_azimuth;
	my $cam_height;
	my $actual_distance;
	my @camera_point_at = ();
	my $map_width;
	my $map_height;
	my $name;
	my @points;
	my @prisms = ();
	my @overlay_polygons = ();
	my $grow_string = "";
	my $rotate_string = "";
	my $ratio;
	my $idx;
	
	foreach $key (keys %theme_value) {
		$theme_value{$key} = 400 * ($theme_value{$key} / $max_value);
		$shade{$key} = &prism_color($shade{$key});
	}
	
#
# Calculate shifting and scaling values, where the camera points, adjust the camera and light locations
# Calculate map width and height
#
	
	$x_shift = -$x_min;
	$y_shift = -$y_min;
	$areal_scale = 800 / max($x_max-$x_min, $y_max-$y_min);
	print STDERR "Progress       xshift, yshift, areal_scale $x_shift, $y_shift, $areal_scale\n";

	@temp = split ",", $camera_string;
	if (@temp != 3) {
		die "Error          bad camera string value $camera_string\n";
	}
	$cam_azimuth      = $temp[1];
	$cam_height       = $temp[0] * sin(deg2rad($temp[2]));
	$actual_distance  = $temp[0] * cos(deg2rad($temp[2]));
	$camera_point_at[0] = (($x_max - $x_min) * $areal_scale) / 2;
	$camera_point_at[1] = (($y_max - $y_min) * $areal_scale) / 2;
	print STDERR "Progress       point at $camera_point_at[0], $camera_point_at[1]\n";
	
	$map_width  = ($x_max - $x_min) * $areal_scale;
	$map_height = ($y_max - $y_min) * $areal_scale;
	print STDERR "Progress       map width, height $map_width, $map_height\n";
	
#
# Read the map file, remembering POV-Ray prism data
# Again, polygons that aren't named something from the data file are ignored
#
	
	open INPUT, "<$map_filename" or die "Error          unable to open $map_filename\n";
	while (<INPUT>) {
		if (/^([A-Z0-9_]+)$/) {
			$name = &patch_id($1);
		}
		elsif (/\{/) {
			@points = ();
		}
		elsif (/\}/) {
			if (exists $theme_value{$name}) {
				push @prisms, $theme_value{$name};
				push @prisms, $shade{$name};
				push @prisms, scalar(@points)/2;
				push @prisms, @points;
			}
		}
		else {
			@temp = split;
			push @points, (($temp[0]+$x_shift)*$areal_scale, $map_height-($temp[1]+$y_shift)*$areal_scale);
		}
	}
	close INPUT;
	
#
# If an overlay file was specified, read the polygons
# Unlike the map, simply assume that the file matches what's in the data file
#
	
	if ($overlay_map) {
		open INPUT, "<$overlay_map" or die "Error          unable to open $overlay_map\n";
		while (<INPUT>) {
			if (/^([A-Z0-9_]+)$/) {
				$name = &patch_id($1);
			}
			elsif (/\{/) {
				@points = ();
			}
			elsif (/\}/) {
				push @overlay_polygons, scalar(@points)/2;
				push @overlay_polygons, @points;
			}
			else {
				@temp = split;
				push @points, (($temp[0]+$x_shift)*$areal_scale, $map_height-($temp[1]+$y_shift)*$areal_scale);
			}
		}
		close INPUT;
	}
	
#
# Then, generate the .pov file for POV-Ray
# First the global settings, the background, the camera, and the three light sources
# The location of the camera and lights is painful to look at, but moving the calculations into the .pov file
#   enabled having POV-Ray handle the "rotate" video clip directly
# Remember that POV-Ray's axes system uses x-z as the "horizontal" plane, with y being up and down
#
	
	$grow_string = "*clock" if ($video_string eq "grow");
	$rotate_string = "+clock*2*pi" if ($video_string eq "rotate");
	$ratio = $povray_width / $povray_height;
	open OUTPUT, ">cartogram.pov" or die "Error          unable to open cartogram.pov\n";
	print OUTPUT <<"EOT";
#version 3.6;
#include "colors.inc"
#include "textures.inc"

global_settings {
	assumed_gamma $gamma
}
background {
	color White
}
camera {
	$camera_type
	up <0, 1, 0>
	right <$ratio, 0, 0>
	location <
		$actual_distance*cos(radians($cam_azimuth)$rotate_string)+$camera_point_at[0],
		$cam_height,
		$actual_distance*sin(radians($cam_azimuth)$rotate_string)+$camera_point_at[1]
	>
	look_at <$camera_point_at[0], $y_point, $camera_point_at[1]>
	angle $camera_zoom
}
light_source {
	<0, 1200, 0>
	color 1.8*White
	parallel
	point_at <0, 0, 0>
	shadowless
}
light_source {
	<
		$actual_distance*cos(radians($cam_azimuth+45)$rotate_string)+$camera_point_at[0],
		0,
		$actual_distance*sin(radians($cam_azimuth+45)$rotate_string)+$camera_point_at[1]
	>
	color 0.9*White
	parallel
	point_at <$camera_point_at[0], $y_point, $camera_point_at[1]>
	shadowless
}
light_source {
	<
		$actual_distance*cos(radians($cam_azimuth-45)$rotate_string)+$camera_point_at[0],
		0,
		$actual_distance*sin(radians($cam_azimuth-45)$rotate_string)+$camera_point_at[1]
	>
	color 0.45*White
	parallel
	point_at <$camera_point_at[0], $y_point, $camera_point_at[1]>
	shadowless
}
EOT

#
# Now three loops to write the actual object descriptions
# First the prisms themselves
# Then the polygons the sit on top of the prisms
# Then the polygons for the overlay, if present
#
	
	$idx = 0;
	while ($idx < @prisms) {
		my $height = $prisms[$idx++];
		my $color  = $prisms[$idx++];
		my $count  = $prisms[$idx++];
		my $i;
		my $x;
		my $z;

		print OUTPUT "prism { linear_spline ";
		print OUTPUT "0, $height$grow_string, $count, ";
		for ($i=0; $i<$count; $i++) {
			$x = $prisms[$idx++];
			$z = $prisms[$idx++];
			print OUTPUT "<$x,$z>";
			print OUTPUT ($i < $count-1) ? ", " : " ";
		}
		print OUTPUT "texture { pigment { color $color } } ";
		print OUTPUT "finish { roughness 0.5 } ";
		print OUTPUT "}\n";
	}
	
	$idx = 0;
	while ($idx < @prisms) {
		my $height = $prisms[$idx++];
		my $color  = $prisms[$idx++];
		my $count  = $prisms[$idx++];
		my $i;
		my $x;
		my $z;

		print OUTPUT "sphere_sweep { linear_spline ";
		printf OUTPUT "%d, ", $count;
		for ($i=0; $i<$count; $i++) {
			$x = $prisms[$idx++];
			$z = $prisms[$idx++];
			print OUTPUT "<$x, $height$grow_string, $z>, $border_thickness "
		}
		print OUTPUT "texture { pigment { color Black } } }\n";
	}

	$idx = 0;
	$overlay_color = &prism_color($overlay_color);
	while ($idx < @overlay_polygons) {
		my $count = $overlay_polygons[$idx++];
		my $i;
		my $x;
		my $z;
	
		print OUTPUT "sphere_sweep { linear_spline ";
		printf OUTPUT "%d, ", $count;
		for ($i=0; $i<$count; $i++) {
			$x = $overlay_polygons[$idx++];
			$z = $overlay_polygons[$idx++];
			print OUTPUT "<$x, $overlay_height, $z>, $overlay_thickness ";
		}
		print OUTPUT "texture { pigment { color $overlay_color } } }\n";
	}

	close OUTPUT;
	
#
# Finally, invoke POV-ray, and ffmpeg if necessary
#
	
	$ray_program .= ($video_string eq "grow") ? " +ovideo/frame +KFI0 +KFF100" : "";
	$ray_program .= ($video_string eq "rotate") ? " +ovideo/frame +KFI0 +KFF180" : "";
	print STDERR "Progress       running POV-Ray\n\n";
	system $ray_program;
	if ($video_string eq "grow" or $video_string eq "rotate") {
		unlink("cartogram.mp4");
		$temp = sprintf "ffmpeg -i video/frame%%03d.png -pix_fmt yuv420p cartogram.mp4 >%s 2>%s", $null_name, $null_name;
		print STDERR "Progress       running ffmpeg\n";
		system($temp);
	}
}


#
# Utility routine for making a prism map
# Converts from "internal" color value to POV-ray's values
#

sub prism_color {
	my $value = $_[0];

	if (exists $named_colors{$value}) {
		$value = sprintf "rgb <%f,%f,%f>", $named_colors{$value}->[3], $named_colors{$value}->[4], $named_colors{$value}->[5];
	}
	elsif ($value =~ /(\d+),(\d+),(\d+)/) {
		$value = sprintf "rgb <%f,%f,%f>", $1/255, $2/255, $3/255;
	}
	else {
		print STDERR "Warning        bad color $value, using gray instead\n";
		$value = sprintf "rgb <%f,%f,%f>", $named_colors{"gray"}->[3], $named_colors{"gray"}->[4], $named_colors{"gray"}->[5];
	}
	$value =~ s/rgb/rgbf/;
	$value =~ s/>/,$transparency>/;
	return $value;
}
