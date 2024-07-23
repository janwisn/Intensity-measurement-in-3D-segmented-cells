
//  specify folders
res=getDirectory("Choose/create Results Folder");
input=getDirectory("Select Source Folder");
lst=getFileList(input); 

run("Brightness/Contrast...");
run("Colors...", "foreground=white background=black selection=yellow");
run("Set Measurements...", "area mean min bounding integrated median display redirect=None decimal=2");

//create custom table
title1 = "Analysis Table"; 
title2 = "["+title1+"]"; 
f=title2; 
run("New... ", "name="+title2+" type=Table"); 
print(f,"\\Headings:Image\tcell_#\tbackground (ADUs/voxel)\tCell slices\tCytoplasm volume (voxels)\tNucleus volume (voxels)\tCytoplasmic signal\tNuclear Signal"); 

//channel setup while processing
for (i = 0; i < lst.length; i++) {open(input+lst[i]);
ttl=File.nameWithoutExtension;
rename("x");
cllr=1;
if(i==0) {getDimensions(width, height, channels, slices, frames);
ns=channels;		}
run("Split Channels");
run("Cascade");
for (j = 0; j < ns; j++) {selectWindow("C"+j+1+"-x");
run("Z Project...", "projection=[Max Intensity]");
run("Enhance Contrast", "saturated=0.35");	
if(i==0) {Dialog.create(" ");
items=newArray("cells", "nuclei");
Dialog.addRadioButtonGroup("Channel"+"C"+j+1+"shows:", items, 2, 1, "cells");
Dialog.show();
if(j==0) {T1=Dialog.getRadioButton();		}
if(j==1) {T2=Dialog.getRadioButton();		}
close("MAX_C"+j+1+"-x");	}		}	

selectWindow("C1-x");
rename(T1);
run("Z Project...", "projection=[Max Intensity]");
run("Enhance Contrast", "saturated=0.35");	
selectWindow("C2-x");
rename(T2);
run("Z Project...", "projection=[Max Intensity]");
run("Enhance Contrast", "saturated=0.35");	

selectWindow("MAX_cells");
run("Gaussian Blur...", "sigma=2 stack");
if(i==0) {setAutoThreshold("Default dark");
run("Threshold...");
setThreshold(0, 65535, "raw");
waitForUser("Adjust thereshold to select cells");
getThreshold(lower, upper);
THR=lower; 
close("Threshold");		}
setThreshold(THR, 65535, "raw");
run("Convert to Mask");
run("Options...", "iterations=8 count=3 pad do=Open");
run("Grays");
if(i==0) {setTool("wand");
waitForUser("Click on a small cell");
mns=getValue("RawIntDen")/255;
waitForUser("Click on a large cell");
mxs=getValue("RawIntDen")/255;
run("Select None");
Dialog.create(" ");
Dialog.addNumber("Minimun cell area (pixels):", mns);
Dialog.addNumber("Maximum cell area (pixels):", mxs);
Dialog.addMessage("(measured values shown - modify if needed)");
Dialog.show();
smin=Dialog.getNumber();
smax=Dialog.getNumber();		}

run("Find Maxima...", "prominence=100 strict exclude output=List");
if(Table.size>0) {Table.sort("X");  
for (k = 0; k < Table.size; k++) {cx=getResult("X", k);
	cy=getResult("Y", k);
	doWand(cx, cy);
	car=getValue("RawIntDen")/255;
if(car<smin) {run("Clear", "slice");		}
else {if(car>smax) {run("Clear", "slice");		}
	else {roiManager("add");		}		}		}
for (l = 0; l < 20; l++) {bval=getPixel(10+100*l, 100);
	if(bval==0) {doWand(10+100*l, 100);
		run("Clear Outside");
		run("Select None");
		l=20;		}		}
if(i==0) {roiManager("Show All with labels");
waitForUser("Adjust label size by going to ROI Manager>More>Labels...");
roiManager("Show None");		}
close("Results");

clls=roiManager("count"); 
if(clls>0) {setBatchMode(true);
cllr=clls;
for (m = 0; m < clls; m++) {selectWindow("cells");
roiManager("select", m);
run("Duplicate...", "title=S duplicate");
run("Select None");
setThreshold(THR, 65535, "raw");
run("Convert to Mask", "background=Dark create");
run("Fill Holes", "stack");
run("Options...", "iterations=8 count=3 pad do=Open stack");
run("Grays");
run("Divide...", "value=255 stack");
setMinAndMax(0, 1);
run("16-bit");
selectImage("S");
run("Grays");

selectImage("nuclei");
roiManager("select", m);
run("Duplicate...", "title=N duplicate");
run("Select None");
run("Measure Stack...");
Table.sort("RawIntDen");
ntr=getResult("Slice");
close("Results");
setSlice(ntr);
run("Gaussian Blur...", "sigma=2 stack");
setAutoThreshold("Default dark");
run("Convert to Mask", "background=Dark create");
run("Fill Holes", "stack");
run("Options...", "iterations=8 count=3 pad do=Open stack");
run("Grays");
run("Divide...", "value=255 stack");
setMinAndMax(0, 1);
run("16-bit");  

close("N");
imageCalculator("Subtract create stack", "MASK_S","MASK_N");
rename("MASK_C");

selectImage("MASK_S");
run("Measure Stack...");
Table.sort("RawIntDen");
ctr=getResult("Slice");
close("Results");
close("MASK_S");
selectImage("S");
setSlice(ctr);
run("Restore Selection");
run("Make Inverse");
bkgd=getValue("Median");
run("Select None");

imageCalculator("Multiply create stack", "MASK_C","S");
run("Z Project...", "projection=[Sum Slices]");
ctot=getValue("RawIntDen");
selectWindow("MASK_C");
run("Z Project...", "projection=[Sum Slices]");
cvol=getValue("RawIntDen");
close("SUM_Result of MASK_C");
close("Result of MASK_C");
close("MASK_C");
close("SUM_MASK_C");
close("MASK_S");
csig=ctot-cvol*bkgd;

imageCalculator("Multiply create stack", "MASK_N","S");
run("Z Project...", "projection=[Sum Slices]");
ntot=getValue("RawIntDen");
selectWindow("MASK_N");
run("Z Project...", "projection=[Sum Slices]");
nvol=getValue("RawIntDen");
dpt=getValue("Max");
close("SUM_Result of MASK_N");
close("Result of MASK_N");
close("MASK_N");
close("SUM_MASK_N");
close("S");
nsig=ntot-nvol*bkgd;

if(m==0) {print(f,ttl);		}
if(dpt>4) {print(f," "+"\t"+m+1+"\t"+bkgd+"\t"+dpt+"\t"+cvol+"\t"+nvol+"\t"+csig+"\t"+nsig);			}
else {cllr=cllr-1;		}		}

close("MAX_cells");	
selectImage("cells");
roiManager("Show None");

if(cllr==0) {print(f," "+"\t"+"out of focus");			}
else {run("Z Project...", "projection=[Max Intensity]");
resetMinAndMax;
run("Enhance Contrast", "saturated=0.35");
run("RGB Color");
roiManager("Show All with labels");
run("Flatten");
roiManager("Show None");
selectImage("MAX_nuclei");
run("RGB Color");
imageCalculator("Max create", "MAX_nuclei","MAX_cells-1");
saveAs("Jpeg", res + ttl + "_map");		
setBatchMode(false);			}
roiManager("Delete");			}
	
else {print(f,ttl);
		print(f," "+"\t"+"outside size range");			}		}
else {print(f,ttl);
		print(f," "+"\t"+"no cells detected");		}

nim=nImages;
for (p = 0; p < nim; p++) {close();		} 		}
close("ROI Manager");

selectWindow("Analysis Table");
saveAs("Text", res + "Analysis Table.csv");
close("Analysis Table");
exit("FINISHED");




