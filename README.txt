This is a set of scripts for automatically solving puzzles in the Macintosh game Rain'Net (Freemen Software, 1994), using the scientific programming language Octave.

++++++++++++++++++++
HOW TO USE THIS CODE
++++++++++++++++++++

1.
Install the Octave application if you don't have it:

    https://octave.org/download

These scripts have only been tested in v3.4.0, but should work in any later version and perhaps even in MATLAB.  (I didn't use any of the features the documentation warns about, e.g. combining error trapping with broadcasting.)

2.
Assuming you already know how to run System 7 apps in general, get a copy of Rain'Net.  Search engines stumble over apostrophes, and old games move around a lot.  :>  But as of May 2023 you might try:

    https://archive.org/details/tucows_205605_Rain_Net
    https://web.archive.org/web/19980513082423/http://fantasoft.com:80/HTML/Rain_Net/rainnet.html
    https://archive.info-mac.org/game/rain-net-11.hqx

(omg info-mac)

3.
Save these scripts to a location where you have write access.

4.
Transcribe the level(s) you want to solve from the Rain'Net display into rain_init.m .

5.
In rain_v15_launch.m , change the variable levelvec to include the desired map numbers.  Note that the map numbers in the game HUD differ when entering a password vs playing straight though from level 1; whichever scheme you choose, be consistent between this step and step 4.

6.
Within Octave, navigate to the directory in step 3 and execute rain_v15_launch.m .

++++++++++++
KNOWN ISSUES
++++++++++++

There might be any number of *unknown* issues, given my overall inexperience at programming and optimization logic, but here are some that come to mind.

* The tail recursion step is brittle because the segments aren't necessarily much smaller than the total size.  On a linear map, many candidate paths might have the same number of strawberries, so you might just run out of memory again trying to process the subset.

* Available disk space is not verified before writing swap files.  (I guess SSDs are now received wisdom, so we have to start conserving again.)

* Octave doesn't warn on integer overflow, but caps each result at the max or min allowed value.  I didn't account for this systematically at all, I just kept casting arrays to slightly larger types until the final answer popped out.  :P

* I didn't try to handle every plausible corner case in map design, e.g. a move that starts and ends in the same location via special tiles, yet still affects state by eating strawberries en route.

* I'm still uncertain if, in a single-segment run, the history of partial paths must be retained for the de-duplication step at the end to work.  If it's not needed, it's just occupying memory without affecting the final answer.

* Cornelius is absent from certain maps, and I didn't support that in a user-friendly manner, because it seemed to increase points of failure throughout the main function.  (See comments in rain_init.m for one possible workaround.)

++++++++++
THANKS TO:
++++++++++

Jérome Crêtaux, Bidouille, and Aquarium for Rain'Net.

Fantasoft LLC for hosting Rain'Net, so uneducated gamers like myself would notice it.  :>

The Octave development team:

    https://hg.savannah.gnu.org/hgweb/octave/file/tip/doc/interpreter/contributors.in

My day job co-workers, for teaching me about modular programming.  Hopefully it makes this code easier to read; it definitely made it easier to write.

Jesper Schmidt Hansen, whose book _GNU Octave Beginners Guide_ (Packt Publishing, 2011) introduced me to vectorization, without which this code would be impractical on all but the most cramped levels.

siddhartha77 for retro software development, which as a marginal side effect, exposed a bug in my pathfinding logic when Cornelius is swapped off of a pit.

++++++++++++
LEGAL NOTICE
++++++++++++

The source code of Rain'Net is, to my knowledge, unpublished.  All playsim behavior considered by this package was reverse engineered through the front end of the application.

This package is free software.  You can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This package is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See <http://www.gnu.org/licenses/> for more information.


