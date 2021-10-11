/*
This macro processes multiple images in a folder, outputting the number of bacteria pixels in the red channel and the green channel respectively to calculate the 
viability of a biofilm stained with red and green viability stains. 
It also saves overlay images showing the bacteria which have been detected.


MIT License
Copyright (c) [2021] [Marie Held {mheldb@liverpool.ac.uk}, Image Analyst Liverpool CCI (https://cci.liverpool.ac.uk/)]
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/


//get input and output directories from user
#@ String (visibility=MESSAGE, value="Process fluorescence images of biofilm stained with SYTO9 and propidium iodide to calculate the percentage of live and dead bacteria in each image.", required=false) msg
#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output
#@ String (label = "File suffix", value = ".tif", persist=false) suffix
#@ boolean overlay (label = "Save overlay?") 

processFolder(input);

beep();
print("Done! Please check the specified output folder for the generated results files."); 

// Loop over all the files in the input folder that have the specified file extension
function processFolder(input) {
	list = getFileList(input);
	//Array.print(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + list[i]))
			processFolder("" + input + list[i]);
		if(endsWith(list[i], suffix))
			processFile(input, output, list[i],i,list);
	}
}

// process each file
function processFile(input, output, file,i,list) {
	open(input + File.separator + file);
	file_name_without_extension = file_name_remove_extension(file);
	print("Processing file " + i + "/" + list.length + " -->"  + file);
	
	//check whether the image is a z stack. If so,  create Maximum intensity projection
	getDimensions(width, height, channels, slices, frames);
	if(slices > 1){
		title = getTitle();
		Dialog.create("Error");
		Dialog.addMessage("The image currently being processed is " + title + "\n" + "The image is a z stack. Please creare maximum intensity projection or \n save z slices as individual files to be processed individually.");
		Dialog.show();
		close("*");
	} 
	else {title = getTitle();
	
	channel_title = split_channels(title);
	preprocessing();
	segmentation();
	area_measurement();
	intensity_measurement(); 

	// Tidy up
	close("*");	 
	}
}

function file_name_remove_extension(file_name){
	dotIndex = lastIndexOf(file_name, "." ); 
	file_name_without_extension = substring(file_name, 0, dotIndex );
	//print( "Name without extension: " + file_name_without_extension );
	return file_name_without_extension;
}

function split_channels(title){
	/* Split channels */
	selectWindow(title);
	run("Duplicate...", "duplicate");
	dup_title = getTitle();
	selectWindow(dup_title); 
	run("Split Channels");
	selectWindow("C1-" + dup_title); 
	rename(file_name_without_extension + "-C1");
	
	selectWindow("C2-" + dup_title); 
	rename(file_name_without_extension + "-C2");
	channel_title = newArray(2);
	channel_title[0] = file_name_without_extension + "-C1";
	channel_title[1] = file_name_without_extension + "-C2";
	//Array.print(channel_title); 
	return channel_title;
}

function preprocessing(){
	/*Image pre-processing:
	Red and green channel smoothing */
	selectWindow(channel_title[0]);
	run("Median...", "radius=2.5");
	selectWindow(channel_title[1]);
	run("Median...", "radius=2.5");	

}

function segmentation(){
	/* Segmentation */
	run("Options...", "iterations=1 count=1 black");
	
	//green channel segmentation
	selectWindow(channel_title[0]);
	setAutoThreshold("Otsu dark");
	//run("Threshold...");
	run("Convert to Mask");
		setOption("BlackBackground", false);
	run("Erode");
	run("Erode");
	run("Dilate");
	run("Dilate");
	// uncomment next line to save mask for troubleshooting
	//save(output + File.separator + channel_title[0] + "-mask.tif");
	
	//red channel segmentation
	selectWindow(channel_title[1]);
	setAutoThreshold("Otsu dark");
	//run("Threshold...");
	run("Convert to Mask");		
	setOption("BlackBackground", false);
	run("Erode");
	run("Erode");
	run("Dilate");
	run("Dilate");
	// uncomment next line to save mask for troubleshooting
	//save(output + File.separator + channel_title[1] + "-mask.tif");

	}

function area_measurement(){
	run("Duplicate...", " ");	
	temp_title = getTitle();

	// Create a mask where all white pixels from both channels are combined
	setPasteMode("OR");
	selectWindow(channel_title[0]);
	run("Copy");
	selectWindow(temp_title);
	run("Paste");
	rename("sum"); 

	// Create a mask with only white pixels that appear in both masks
	selectWindow(channel_title[0]);
	run("Duplicate...", " ");	
	temp_title = getTitle();
	setPasteMode("Subtract");
	selectWindow(channel_title[1]);
	run("Copy");
	selectWindow(temp_title);
	run("Paste");
	rename("live"); 

	// Measure the areas of the green channel, the red channel, the combination of red and green channels and the area that is live to the red and green channels and write to disk
	run("Set Measurements...", "area_fraction display redirect=None decimal=3");
	run("Clear Results");
	selectWindow(channel_title[0]); 
	run("Measure"); 
	selectWindow(channel_title[1]); 
	run("Measure"); 
	selectWindow("sum"); 
	run("Measure"); 
	selectWindow("live");
	run("Measure"); 

	results_filename = file_name_without_extension + "_area-results.txt"; 
	saveAs("Results", output + File.separator + results_filename);
}

function intensity_measurement(){
	/*Measurements */
	//set parameters to be measured
	run("Set Measurements...", "area integrated median redirect=None decimal=3");

	// process channel one, generate ROIs and combine them and then measure the parameters of the combined area, write results to file
	selectWindow("live"); 
	run("Analyze Particles...", "clear add");
	//roiManager("save", output + File.separator + file_name_without_extension + "-live-cells.zip" );
	roiManager("Select All"); 
	roiManager("Combine"); 
	roiManager("Add"); 
	nROIs = roiManager("count");
	roiManager("Select", (nROIs-1));
	//roiManager("save", output + File.separator + file_name_without_extension + "-live-cells.roi" );
	selectWindow(title);
	setSlice(1);
	roiManager("multi-measure");
	results_filename = file_name_without_extension + "_live-results.txt"; 
	saveAs("Results", output + File.separator + results_filename);

	//generate overlay image if selected
	if (overlay == 1){
		roiManager("Show All"); 
		roiManager("Show None");
		roiManager("Deselect");
		run("Duplicate...", " ");
		run("Enhance Contrast", "saturated=0.00");
		//run("RGB Color");
		
		run("Flatten");
		setForegroundColor(255, 255, 255);
		roiManager("Deselect");
		roiManager("Draw");
		C1_overlay = getTitle();
	}

	//process channel one, generate ROIs and combine them and then measure the parameters of the combined area, write results to file
	roiManager("Delete");
	selectWindow(channel_title[1]); 
	run("Analyze Particles...", "clear add");
	roiManager("Select All"); 
	roiManager("Combine"); 
	roiManager("Add"); 
	nROIs = roiManager("count");
	roiManager("Select", (nROIs-1));

	
	selectWindow(title); 
	setSlice(2);
	roiManager("multi-measure");
	results_filename = file_name_without_extension + "_dead-results.txt"; 
	saveAs("Results", output + File.separator + results_filename);

	//generate overlay image if selected
	if (overlay == 1){
		roiManager("Show All"); 
		roiManager("Show None");
		roiManager("Deselect");
		run("Duplicate...", " ");
		run("Enhance Contrast", "saturated=0.00");
		//run("RGB Color");
		run("Flatten");
		setForegroundColor(255, 255, 255);
		roiManager("Deselect");
		roiManager("Draw");
		C2_overlay = getTitle();

		//save overlay image
		run("Merge Channels...", "c1=" + C2_overlay + " c2=" + C1_overlay + " create keep");
		run("Flatten");
		save(output + File.separator+ file_name_without_extension + "_overlay" + ".tif");
	}
}

