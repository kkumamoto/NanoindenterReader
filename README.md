# NanoindenterReader
----- F O R E W O R D -----

This code has designed to read the exported spreadsheet data produced by the the Agilent and Bruker nanoindenters, and it has multiple functions which should all be kept within the same folder.
The code to run is named NanoMainCode, the other codes are needed but should ideally not be run, but will be called upon when necessary.


----- A C K N O W L E D G E M E N T S -----

This code is written first hand (i.e. not used any code by others not involved with the development of this code), and unless stated by comments within the code assume that Robert J Scales wrote the code.
Clear acknowledgement of the use of this code, whether that be by using it for data analysis, or by the modification or merging of this code with another, would be very much appreciated as many hours have been put into writing this code.
Contacting the IonicRob GitHub account for any of the aforementioned uses would be appreciated to see how the code will be used in research and in development of other work!


----- H O W _ T O _ U S E -----

Current List of Actions in NanoMainCode:
Import
Should be used for converting the valid exported data from the nanoindenter into a more suitable format (a structure) which can then be used by the other actions.
The saved structure contains the data for the mean average and the respective errors of the data outputted from the nanoindenter, which is achieved by binning each indent within a given depth range, and then meaning that data with all of the other indents.

Plot
Most of the analysis and the plotting of figures for showing results is done within this code. It loads ".mat" files produced by Import, thus allowing for analysis and plotting across multiple files loaded.
The code then can plot the selected data you would like to plot against indent depth for the files loaded, and it can then find the mean values of the data within a chosen indent depth range, and it can save each of the figures in the desired saving format.

Export
This uses the structure ".mat" files produced by Import and converts them into a readable Excel spreadsheet. This can then be used for further analysis not available in this code yet, to share results with those who do not have Matlab, or can't be bothered to use this code to use the Plot action. Ideally, the two former points should be the primary reason for using this action and not the latter!
