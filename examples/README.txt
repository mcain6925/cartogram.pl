This directory contains a number of -options and -data files than can be used to
demonstrate several of the capabilities of cartogram.pl. The instructions given
here assume the commands are being run from one directory higher than this one.
Images should be in cartogram.png in all cases.

$ perl -options example/help.options

Should generate the help listing, which identifies all the command line options.

$ perl -options examples/flat.options

Should generate a flat map of the contiguous 48 United States. The 11 westernmost
states should be yellow and the remainder in light gray.

$ perl -options examples/contig.options

Should generate a contiguous cartogram based on federal land holdings per state.
This is the cartogram I wanted to draw when I started this whole mess.

$ perl -options examples/noncontig.options

Should generate a noncontiguous cartogram based on the same federal land holdings
data.

$ perl -options examples/prism.options

Should generate a prism map based on the same federal land holdings data. Note
the use of the -prune option to trim small polygons from the map. Those polygons
are particularly annoying in prism maps.

$ perl -options examples/great_plains_prism.options

Should generate a prism map of the ten Great Plains states with data reflecting
county-level population density. The Plains counties are in white.

$ perl -options examples/great_plains_contig.options

Should generate a contiguous cartogram of the ten Great Plains states with data
reflecting county-level population density.  Note the use of the -scale option
to produce a larger-than-default image, and the -cart2v option to run a version
of the Gastner and Newman algorithm that is faster and uses less memory.

$ perl -options examples/great_plains_mesh.options

Should generate a contiguous cartogram of the ten Great Plains states with data
reflecting county-level population density. Rather than county outlines, though,
a uniform rectangular grid is used.
