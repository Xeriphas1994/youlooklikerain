# License: GPL v3+ -- see license.txt for copying/reuse conditions.
# There is ABSOLUTELY NO WARRANTY, not even for MERCHANTIBILITY or
# FITNESS FOR A PARTICULAR PURPOSE.
clear -g;
clear -all;
clear -all;

addpath(pwd);
# never overwrite previous output
filename = strftime("rain_results_%Y%m%d_%H%M%S.txt",localtime(time()));
fid = fopen(filename, 'w');

# test case
# this was VERY fast when vectorized, two seconds at most,
# even on a potato
# levelvec = [1];

levelvec = [1 51 2:44];
for iiii = levelvec
	state_soln = rain_v15(iiii);
	fprintf(fid, "\nProposed final path for level %d:\n\n", iiii)
	for ii = 1:numel(state_soln)
		switch(state_soln(ii))
		case 0
			dirtemp = "Valentine E";
		case 1
			dirtemp = "Valentine N";
		case 2
			dirtemp = "Valentine W";
		case 3
			dirtemp = "Valentine S";
		case 4
			dirtemp = "Cornelius E";
		case 5
			dirtemp = "Cornelius N";
		case 6
			dirtemp = "Cornelius W";
		case 7
			dirtemp = "Cornelius S";
		endswitch
		fprintf(fid, "%s\n", dirtemp);
	endfor
	fprintf(fid, "\n");
	fprintf("\n");
endfor

fclose(fid);
rmpath(pwd);


