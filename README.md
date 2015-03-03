Tue Mar  3 15:57:57 2015  jpmorgen@snipe

This directory contains some useful routines for requesting JPL
ephemerides at specific times.  It was designed to work on a UNIX
system and make use of UNIX email to send and receive requests.  You
can make it work on other systems.  Just use eph_table_req to generate
an email, send it to JPL, take the response and run it through
eph_get_col with the column names you want extracted from the
ephemeris.
