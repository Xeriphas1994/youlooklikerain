# state_soln = rain_v15(num, filename)
#
# Find a vector of moves that solves a Rain'Net level.  Rain'Net is a
# Macintosh game developed by Freemen Software and published by
# Fantasoft LLC in 1994.
# num: the level number.  An initial level state with this number
# must be defined in rain_init.m , and that file must be visible to
# this function.
# filename: optional, reads in partial move trees from a file in
# Octave binary format (see instantiation of the variable
# stateM_new).  Such files are not really intended to be created by
# humans, but as part of calling this function recursively.
# Move notation:
# 0-3 means Valentine E, N, W, S
# 4-7 means Cornelius E, N, W, S
# using compass directions implied by the matrix geometry in
# rain_init.m .
# 
# License: GPL v3+ -- see license.txt for copying/reuse conditions.
# There is ABSOLUTELY NO WARRANTY, not even for MERCHANTIBILITY or
# FITNESS FOR A PARTICULAR PURPOSE.

# The word "state" here means the characters'
# current coordinates plus the current playfield snapshot.  The
# move sequence is separate, otherwise the number of reachable
# states could grow indefinitely by tacking on more moves as the
# character paced back and forth without affecting anything.
# To save RAM we don't actually store the full playfield
# as part of each possible path, only some booleans indicating
# strawberry presence, and then overlay that on the initial
# conditions LV_0 when it's time to take a step.
# 
# Also to save RAM we often downcast float types to int types.
# *Unsigned* ints are however not a good idea, e.g. due to
# negative results of diff(), which are interpreted quite
# differently if "corrected" to zero.
# 
# Filters based on aggregating comparison operations, such as idx_M,
# are sometimes linear indexes and sometimes boolean vectors.
# This is probably very confusing if someone actually attempts to
# modify the code.
function state_soln = rain_v15(num, filename)

	if nargin < 1
		error("Too few inputs to rain function");
	endif
	if nargin > 2
		error("Too many inputs to rain function");
	endif
	if not(isscalar(num) && isreal(num) && floor(num) == num && num >= 1 && num <= 100)
		error("Malformed input to rain function");
	endif
	# Save memory by not examining every path in the main array simultaneously.
	# Safe to increase if your machine's memory management is reasonable.  Mine seems
	# kind of boneheaded: whereas I have 32GB of physical memory and supposedly
	# native VM support, I can only allocate perhaps 2GB within an Octave session,
	# and 750MB for any single variable.  Could very well have improved in later
	# Octave releases, especially if multithreading is fully supported now.
	chunksize = 10000;
	if nargin == 1
		overloadsize = 500000;
		# mop up any incomplete runs
		FF = glob("*.dat");
		for zz = 1:length(FF)
			unlink(FF{zz,1});
		endfor
	else
		# In principle this can be higher than the above, because the partial routes
		# within a shard tend to be more similar, so more likely to find the same
		# attractor in a given pass, thus inflation of total states per pass
		# is smaller.
		overloadsize = 500000;
	endif

	[ LV_0 gr_x_0 gr_y_0 bl_x_0 bl_y_0 ] = rain_init(num);
	if not(and(LV_0(gr_x_0, gr_y_0) == 1, LV_0(bl_x_0, bl_y_0) == 1))
		error("Obstructed starting coords in rain_init");
	endif
	Nrows = int32(size(LV_0, 1));
	Ncols = int32(size(LV_0, 2));
	# ID of next move direction: {Valentine, Cornelius} X {E, N, W, S}
	moveset = [0:7];
	Ndirs = int32(length(moveset));
	# Playfield state
	# Sleight of hand because bool type can't be cast directly
	straw_bool = ( LV_0(:) == 2 );
	[straw_idx, ~, vv] = find(straw_bool);
	if nargin == 1
		# if no filename was input then this is the root invocation
		stateM_new = vv;
		# Valentine coords
		grM_new = [ (Nrows*(gr_y_0-1))+gr_x_0 ];
		# Cornelius coords
		blM_new = [ (Nrows*(bl_y_0-1))+bl_x_0 ];
		moveseq = [];
		# Don't initialize this as empty because the deduplication step
		# should know whether we returned to the start point.
		state_accum = vertcat(int32(stateM_new), grM_new, blM_new);
		fprintf("\n================================================\n", num);
		fprintf("Attempting to solve level %d.  Seriously.\n", num);
	else
		# otherwise it's a shard being examined recursively
		load(filename)
		stateM_new = stateM_shard;
		grM_new = grM_shard;
		blM_new = blM_shard;
		moveseq = moveseq_shard;
		state_accum = vertcat(int32(stateM_new), grM_new, blM_new, moveseq);
	endif
	straw_cnt_0 = sum(straw_bool);
	if isempty(vv) || straw_cnt_0 < 1
		error("Invalid map: no strawberries to collect");
	endif
	state_soln = [];
	# Teleporter coords to be used later in vectorized comparisons.
	# Assumes each level has either none or two; I have no clue how
	# the game would behave otherwise.
	idx_T = find( LV_0(:) == 4 );
	if isempty(idx_T)
		teleport1 = 0;
		teleport2 = 0;
	else
		teleport1 = idx_T(1);
		teleport2 = idx_T(2);
	endif

	# MAIN LOOP
	fprintf("\n");
	iteration = 0;
	stateM_big = stateM_new;
	grM_big = grM_new;
	blM_big = blM_new;
	moveseq_big = moveseq;
	do
		fprintf("Pass %d of pathfinding", ++iteration);
		if nargin == 2
			fprintf(", using tree snapshot file %s", filename);
		endif
		fprintf(".\n");
		stateM_stage = [];
		grM_stage = [];
		blM_stage = [];
		moveseq_stage = [];
		# integer division throws sand in my eyes again
		chunkcnt = floor( (columns(stateM_big) - mod(columns(stateM_big), chunksize)) / chunksize ) + 1;
		for ii = 1:chunkcnt
			fprintf("\tSorting chunk %d of %d.\n", ii, chunkcnt);
			# CHUNK DEFINITION START
			treecnt = min([chunksize columns(stateM_big)]);
			stateM_new = stateM_big(:,1:treecnt);
			stateM_big(:,1:treecnt) = [];
			grM_new = grM_big(:,1:treecnt);
			if isscalar(grM_big)
				grM_big = [];
			else
				grM_big(:,1:treecnt) = [];
			endif
			blM_new = blM_big(:,1:treecnt);
			if isscalar(blM_big)
				blM_big = [];
			else
				blM_big(:,1:treecnt) = [];
			endif
			if not(isempty(moveseq_big))
				moveseq = moveseq_big(:,1:treecnt);
				if isscalar(moveseq_big)
					moveseq_big = [];
				else
					moveseq_big(:,1:treecnt) = [];
				endif
			endif
			# CHUNK DEFINITION END
			stateM_prev = stateM_new;
			grM_prev = grM_new;
			blM_prev = blM_new;
			# "Cartesian product" of existing snapshots with possible next moves
			moveM = repmat(moveset, columns(stateM_prev), 1)(:)';
			stateM_new = repmat(stateM_prev, 1, Ndirs);
			grM_new = repmat(grM_prev, 1, Ndirs);
			blM_new = repmat(blM_prev, 1, Ndirs);
			# first match move history with its state above, then tack on the next proposed move
			moveseq = repmat(moveseq, 1, Ndirs);
			# Update the movement history *now*, in case terrain changes someone's orientation
			moveseq = vertcat(moveseq, moveM);
			teleport1M = teleport1 * ones(1,columns(stateM_new));
			teleport2M = teleport2 * ones(1,columns(stateM_new));
			if nargin == 1
				# declutter terminal somewhat in recursive runs
				fprintf("\t\t%d hypothetical moves to examine.\n", columns(stateM_new));
			endif
			# Last known good positions for comparison/undo
			stateM_old = stateM_new;
			grM_old = grM_new;
			blM_old = blM_new;
			# This flag will be set if the entire move is impermissible due to
			# Valentine falling in a pit
			haltflag = zeros(1, columns(stateM_new));
			# This flag will be set whenever the character's next step is blocked,
			# so if they're standing on a special tile, we know not to
			# activate it again
			wallflag = zeros(1, columns(stateM_new));
			# Prevent infinite loops when teleporters are aligned to move grid
			teleportcnt = zeros(1, columns(stateM_new));
			# now create a copy of the next move to track any transient
			# changes (e.g. swapper tile)
			moveM_tmp = moveM;
			# Attempt the move
			do
				# Last known good positions for comparison/undo
				grM_step = grM_new;
				blM_step = blM_new;
				# extra validation since a teleporting character changes coords
				# without stepping, so comparing to coords before step doesn't
				# completely determine valid vs invalid
				teleport_step = teleportcnt;
				# Attempt a step
				grM_new = grM_new + Nrows * (moveM_tmp == 0) - (moveM_tmp == 1) - Nrows * (moveM_tmp == 2) + (moveM_tmp == 3);
				blM_new = blM_new + Nrows * (moveM_tmp == 4) - (moveM_tmp == 5) - Nrows * (moveM_tmp == 6) + (moveM_tmp == 7);
				# Undo step if previously deemed resolved
				grM_new(wallflag == 1) = grM_step(wallflag == 1);
				blM_new(wallflag == 1) = blM_step(wallflag == 1);
				grM_new(haltflag == 1) = grM_step(haltflag == 1);
				blM_new(haltflag == 1) = blM_step(haltflag == 1);
				# Undo step if an impassable object was hit.
				# In this and subsequent checks we have to make sure we're only
				# altering columns where the coord changed on the current step,
				# so e.g. characters don't keep swapping on every iteration while
				# they should be patiently leaning against a wall.
				idx_gr_wall = find(and(LV_0(grM_new) == 0, wallflag == 0, grM_new != grM_step));
				grM_new(idx_gr_wall) = grM_step(idx_gr_wall);
				wallflag(idx_gr_wall) = 1;
				idx_bl_wall = find(and(LV_0(blM_new) == 0, wallflag == 0, blM_new != blM_step));
				blM_new(idx_bl_wall) = blM_step(idx_bl_wall);
				wallflag(idx_bl_wall) = 1;
				# oh dear
				idx_bl_straw = find(and( any(repmat(blM_new, rows(stateM_new), 1) == stateM_new .* repmat(straw_idx, 1, columns(stateM_new))) , wallflag == 0 , blM_new != blM_step ));
				blM_new(idx_bl_straw) = blM_step(idx_bl_straw);
				wallflag(idx_bl_straw) = 1;
				idx_collision = find(and(wallflag == 0, or(grM_new != grM_step , blM_new != blM_step), grM_new == blM_new));
				grM_new(idx_collision) = grM_step(idx_collision);
				blM_new(idx_collision) = blM_step(idx_collision);
				wallflag(idx_collision) = 1;
				# Abort the entire move if a pit trap was hit
				idx_pit = find(and(LV_0(grM_new) == 3, wallflag == 0, grM_new != grM_step));
				grM_new(idx_pit) = grM_step(idx_pit);
				wallflag(idx_pit) = 1;
				haltflag(idx_pit) = 1;
				# If none of the above conditions are true, then we're staying, so apply
				# effects for non-empty tiles.
				# Pick up strawberry
				( repmat(straw_idx, 1, columns(stateM_new)) .* stateM_new ) == repmat(grM_new, rows(stateM_new), 1);
				stateM_new = and(stateM_new, not(ans));
				# Apply swapper
				idx_swap = find(or(
					and(LV_0(grM_new) == 5, wallflag == 0, grM_new != grM_step),
					and(LV_0(blM_new) == 5, wallflag == 0, blM_new != blM_step)
				));
				# v1.1.1 shim: just saw, if Valentine lands on a pit as a result,
				# she is still affected!
				idx_swap_3 = find(
					and(LV_0(grM_new) == 5, wallflag == 0, grM_new != grM_step, LV_0(blM_new) == 3)
				);
				tmp_new = grM_new(idx_swap);
				grM_new(idx_swap) = blM_new(idx_swap);
				blM_new(idx_swap) = tmp_new;
				moveM_tmp(idx_swap) = mod(moveM_tmp(idx_swap) + 4, 8);
				haltflag(idx_swap_3) = 1;
				# Apply pusher
				moveM_tmp(find(and(LV_0(grM_new) == 6, wallflag == 0, grM_new != grM_step))) = 0;
				moveM_tmp(find(and(LV_0(grM_new) == 7, wallflag == 0, grM_new != grM_step))) = 1;
				moveM_tmp(find(and(LV_0(grM_new) == 8, wallflag == 0, grM_new != grM_step))) = 2;
				moveM_tmp(find(and(LV_0(grM_new) == 9, wallflag == 0, grM_new != grM_step))) = 3;
				moveM_tmp(find(and(LV_0(blM_new) == 6, wallflag == 0, blM_new != blM_step))) = 4;
				moveM_tmp(find(and(LV_0(blM_new) == 7, wallflag == 0, blM_new != blM_step))) = 5;
				moveM_tmp(find(and(LV_0(blM_new) == 8, wallflag == 0, blM_new != blM_step))) = 6;
				moveM_tmp(find(and(LV_0(blM_new) == 9, wallflag == 0, blM_new != blM_step))) = 7;
				# Apply teleportation... only once per tile!
				idx_gr_T1 = find(and(LV_0(grM_new) == 4, grM_new == teleport1M, wallflag == 0, grM_new != grM_step, teleportcnt == teleport_step));
				grM_new(idx_gr_T1) = teleport2M(idx_gr_T1);
				teleportcnt(idx_gr_T1) = teleportcnt(idx_gr_T1) + 1;
				idx_gr_T2 = find(and(LV_0(grM_new) == 4, grM_new == teleport2M, wallflag == 0, grM_new != grM_step, teleportcnt == teleport_step));
				grM_new(idx_gr_T2) = teleport1M(idx_gr_T2);
				teleportcnt(idx_gr_T2) = teleportcnt(idx_gr_T2) + 1;
				idx_bl_T1 = find(and(LV_0(blM_new) == 4, blM_new == teleport1M, wallflag == 0, blM_new != blM_step, teleportcnt == teleport_step));
				blM_new(idx_bl_T1) = teleport2M(idx_bl_T1);
				teleportcnt(idx_bl_T1) = teleportcnt(idx_bl_T1) + 1;
				idx_bl_T2 = find(and(LV_0(blM_new) == 4, blM_new == teleport2M, wallflag == 0, blM_new != blM_step, teleportcnt == teleport_step));
				blM_new(idx_bl_T2) = teleport1M(idx_bl_T2);
				teleportcnt(idx_bl_T2) = teleportcnt(idx_bl_T2) + 1;
				idx_T3 = find( teleportcnt >= 3 );
				haltflag(idx_T3) = 1;
			until( all( or(and(grM_new == grM_step, blM_new == blM_step), haltflag == 1, wallflag == 1) ) )
			# Did the move actually change the state?
			stateM_new_total = vertcat(stateM_new, grM_new, blM_new);
			stateM_old_total = vertcat(stateM_old, grM_old, blM_old);
			idx_M = find(any(stateM_new_total != stateM_old_total));
			stateM_new_total = [];
			stateM_old_total = [];
			stateM_new = stateM_new(:,idx_M);
			grM_new = grM_new(:,idx_M);
			blM_new = blM_new(:,idx_M);
			moveseq = moveseq(:,idx_M);
			haltflag = haltflag(:,idx_M);
			# Would the move have made Valentine lose a life?
			idx_M = find(haltflag == 0);
			stateM_new = stateM_new(:,idx_M);
			grM_new = grM_new(:,idx_M);
			blM_new = blM_new(:,idx_M);
			moveseq = moveseq(:,idx_M);
			if nargin == 1
				fprintf("\t\t%d moves were not blocked.\n", columns(stateM_new));
			endif
			# Deduplicate the new states, padding shorter move sequences
			# for vectorization.
			# With sharding, state_accum becomes much more important because
			# the current shard may not contain a solution.  Hence the inner loop
			# MUST exit when every state duplicates a previous state with fewer
			# moves, and it isn't possible to know that if we throw away the shorter
			# sequences after each pass.
			# 
			# Shit.
			state_wad = int32(vertcat(stateM_new, grM_new, blM_new, moveseq));
			if isempty(state_accum)
				state_accum = state_wad;
			elseif isempty(stateM_stage)
				state_accum = horzcat( vertcat(state_accum, repmat(8, 1, columns(state_accum))) , state_wad );
			else
				state_accum = horzcat( state_accum , state_wad );
			endif
			# First sortkey is state only: maybe you've returned to a
			# previous situation.
			# Don't transpose at the very beginning and very end just to
			# make this step more concise; it helps visualization if differing
			# states are always, always dimension 2.
			state_accum = flipud(sortrows(state_accum', [1:rows(stateM_new)+2 rows(state_accum):-1:rows(stateM_new)+3]))';
			# duh, first row is always the first found occurrence of its own state
			idx_M = [1 1+find( any(diff(state_accum(1:rows(stateM_new)+2,:),[],2)) )];
			state_accum = state_accum(:,idx_M);
			# now you've retained all the new states, but those with less than
			# max length sequences have already been extended in all eight
			# directions, so carrying them forward to the next loop is redundant.
			idx_M = find((state_accum(rows(state_accum),:) != 8));
			# CHUNK ACCRETION START
			state_bump = state_accum(:,idx_M);
			if isempty(stateM_stage)
				stateM_stage = (state_bump(1:rows(stateM_new),:) == 1);
				grM_stage = state_bump(rows(stateM_new)+1,:);
				blM_stage = state_bump(rows(stateM_new)+2,:);
				moveseq_stage = int32(state_bump(rows(stateM_new)+3:rows(state_bump),:));
			else
				stateM_stage = (horzcat( stateM_stage , state_bump(1:rows(stateM_new),:) ) == 1);
				grM_stage = horzcat( grM_stage , state_bump(rows(stateM_new)+1,:) );
				blM_stage = horzcat( blM_stage , state_bump(rows(stateM_new)+2,:) );
				moveseq_stage = int32(horzcat ( moveseq_stage , state_bump(rows(stateM_new)+3:rows(state_bump),:) ));
			endif
			# CHUNK ACCRETION END
		endfor
		# If a shard has been fully searched without finding a solution, these
		# will all be blank
		stateM_big = stateM_stage;
		grM_big = grM_stage;
		blM_big = blM_stage;
		moveseq_big = moveseq_stage;
		fprintf("\t%d partial routes were unique.\n", columns(stateM_big));
		# Did we complete the level?
		if not(isempty(stateM_big))
			straw_cnt = min(sum(stateM_big, 1));
			if isempty(straw_cnt)
				straw_cnt = 0;
			endif
		endif
		fprintf("\tLocated %d of %d strawberries.\n", straw_cnt_0 - straw_cnt, straw_cnt_0);
		# return to parent function call
		if and(straw_cnt > 0, isempty(stateM_big))
			fprintf("Saved paths in this file are exhausted.\n");
		endif
		idx_M = find(sum(stateM_big, 1) == 0, 1, "first");
		# if solution and overflow happen on the same pass, return the
		# solution and exit, don't take both branches!
		if not(isempty(idx_M))
			state_soln = moveseq_big(:,idx_M);
		elseif columns(stateM_big) > overloadsize
			if nargin == 2
				filenamebase = filename;
			else
				filenamebase = 'rain-vec';
			endif
			fprintf("\nCrap!  Cumulative path tree may not fit in memory.\n");
			fprintf("Defining segments to save to disk.\n");
			# Large optimization: prioritize the paths where you've already made a lot of
			# progress, so the solution appears sooner.  (I think there were cases in
			# the wild where the smallest number of strawberries was a dead end, hence
			# the check above for empty state variables.)
			straw_cnt_array = unique(sum(stateM_big, 1));
			for jj = straw_cnt_array
				idx_S = ( sum(stateM_big, 1) == jj );
				stateM_shard = stateM_big(:,idx_S);
				grM_shard = grM_big(:,idx_S);
				blM_shard = blM_big(:,idx_S);
				moveseq_shard = moveseq_big(:,idx_S);
				filename = cstrcat(filenamebase, '-', dec2base(jj, 10, ceil(log10(straw_cnt_0))), '.dat');
				save("-binary", "-zip", filename, "*shard");
			endfor
			# oops, doesn't actually save memory if we keep the backlog
			stateM_big = [];
			grM_big = [];
			blM_big = [];
			moveseq_big = [];
			state_accum = [];
			blM_stage = [];
			grM_stage = [];
			moveM = [];
			moveM_tmp = [];
			moveseq = [];
			moveseq_stage = [];
			stateM_new = [];
			stateM_old = [];
			stateM_prev = [];
			stateM_shard = [];
			stateM_stage = [];
			teleport_step = [];
			teleportcnt = [];
			wallflag = [];
			for kk = straw_cnt_array
				filename = cstrcat(filenamebase, '-', dec2base(kk, 10, ceil(log10(straw_cnt_0))), '.dat');
				state_soln = rain_v15(num, filename);
				if not(isempty(state_soln))
					break;
				endif
			endfor
			for ww = straw_cnt_array
				filename = cstrcat(filenamebase, '-', dec2base(ww, 10, ceil(log10(straw_cnt_0))), '.dat');
				if exist(filename)
					unlink(filename);
				endif
			endfor
		endif
	until (or(
		not(isempty(state_soln)),
		isempty(stateM_big)
	))
	# Running out of proposed moves is only a deal-breaker at the top level,
	# when there are no more shards to search.
	if and(nargin == 1, isempty(state_soln))
		fprintf("\n\n");
		error("Puzzle completion was never reached for level %d!", num);
	endif

endfunction

