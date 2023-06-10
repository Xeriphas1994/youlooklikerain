# [LV, gr_x, gr_y, bl_x, bl_y] = rain_init(num)
# Given a map number, return the starting map state, and starting coordinates
# for both characters.
# Helper function for rain_v15().
# 
# License: GPL v3+ -- see license.txt for copying/reuse conditions.
# There is ABSOLUTELY NO WARRANTY, not even for MERCHANTIBILITY or
# FITNESS FOR A PARTICULAR PURPOSE.

# Because the maps in Rain'Net are presumably still under copyright, I
# have not included them here.  They must be transcribed before the
# solver script can be used.
# 
# Tile types:
# 
# 0 wall
# 1 empty
# 2 strawberry
# 3 pit trap
# 4 teleporter
# 5 swapper
# 6 pusher (E)
# 7 pusher (N)
# 8 pusher (W)
# 9 pusher (S)
# 
# x and y are the conventional Octave row/column indexes of the matrix.  gr means
# green for Valentine, bl means blue for Cornelius.
# 
# I defined the lower right corner of the matrix as the one nearest the camera,
# but that's arbitrary.  If you change it, be sure to adjust all other constants
# to match, e.g the directions of pusher tiles.
# 
# The outer wall of the playfield isn't used to find the solution, just to reduce
# complexity and debugging time by ensuring indexes are always in band, so I don't
# need to throw in short-circuit conditions every single time.
# 
# There is a hidden level between 1 and 2, not directly accessible with a password,
# which I called 51 because I dimly remembered there were 50 levels total.  (May
# not be true, and yes I was probably making an Apogee Software reference.)  I
# planned to continue assigning the higher numbers to other hidden levels, but
# didn't find any more.
# 
# When Cornelius is absent from a map, I put him in a closet surrounded by solid
# blocks on all four sides, e.g. (2,2) on map 1.  Again this was to simplify code
# by not having to continually check whether "blue" coordinates were missing or
# equal to a reserved value.

function [LV gr_x gr_y bl_x bl_y] = rain_init(num)

	if not(isscalar(num) && isreal(num) && floor(num) == num && num >= 1 && num <= 100)
		error("Malformed input to rain_init function");
	endif

	switch (num)
	case 1
		LV = [
			0 0 0 0 0 0 0 0 0 0 0 0;
			0 1 1 1 1 1 1 1 1 1 1 0;
			0 1 1 1 1 1 1 1 1 1 1 0;
			0 1 1 1 1 1 1 1 1 1 1 0;
			0 1 1 1 1 1 1 1 1 1 1 0;
			0 1 1 1 1 1 1 1 1 1 1 0;
			0 1 1 1 1 1 1 1 1 1 1 0;
			0 1 1 1 1 1 1 1 1 1 1 0;
			0 1 1 1 1 1 1 1 1 1 1 0;
			0 1 1 1 1 1 1 1 1 1 1 0;
			0 1 1 1 1 1 1 1 1 1 1 0;
			0 0 0 0 0 0 0 0 0 0 0 0
		];
		gr_x = 0;
		gr_y = 0;
		bl_x = 0;
		bl_y = 0;
	otherwise
		warning("\n\nOut-of-band input to rain_init function.  Results may be unpredictable!\n");
		LV = [
			0 0 0 0 0 0 0 0 0 0 0 0;
			0 1 1 1 1 1 1 1 1 1 1 0;
			0 1 1 1 1 1 1 1 1 1 1 0;
			0 1 1 1 1 1 1 1 1 1 1 0;
			0 1 1 1 1 1 1 1 1 1 1 0;
			0 1 1 1 1 1 1 1 1 1 1 0;
			0 1 1 1 1 1 1 1 1 1 1 0;
			0 1 1 1 1 1 1 1 1 1 1 0;
			0 1 1 1 1 1 1 1 1 1 1 0;
			0 1 1 1 1 1 1 1 1 1 1 0;
			0 1 1 1 1 1 1 1 1 1 1 0;
			0 0 0 0 0 0 0 0 0 0 0 0
		];
		gr_x = 0;
		gr_y = 0;
		bl_x = 0;
		bl_y = 0;
	endswitch

endfunction


