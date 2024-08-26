
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
print(f,"\\Headings:Image\tcell_#\tCell slices\tCytoplasm volume (voxels)\tNucleus volume (voxels)\t\tBackground_A\tCytoplasmic_A\tNuclear_A\t\tBackground_B\tCytoplasmic_B\tNuclear_B"); 

//channel setup while processing
for (i = 0; i < lst.length; i++) {open(input+lst[i]);
ttl=File.nameWithoutExtension;
rename("x");
cllr=1;
if(i==0) {getDimensions(width, height, channels, slices, frames);
ns=channels;		}
run("Split Channels");
run("Cascade");
cmb=0;

if(i==0) {cmb=0;
for (j = 1; j < ns+1; j++) {selectWindow("C"+j+"-x");
run("Z Project...", "projection=[Max Intensity]");
run("Enhance Contrast", "saturated=0.35");	
if(i==0) {Dialog.create(" ");
items=newArray("Nuclei", "Target_A", "Target_B");
Dialog.addRadioButtonGroup("Channel C"+j+1+"shows:", items, 1, 3, " ");
Dialog.addCheckbox("Use for cell segmentation", false);
Dialog.addMessage("(all checked channels will be combined\nfor segmentation purposes)");
Dialog.show();
if(j==1) {T1=Dialog.getRadioButton();
		CB1=Dialog.getCheckbox();		}
if(j==2) {T2=Dialog.getRadioButton();
		CB2=Dialog.getCheckbox();		}
if(j==3) {T3=Dialog.getRadioButton();		
		CB3=Dialog.getCheckbox();		}
close("MAX_C"+j+"-x");		}		}		}

selectWindow("C1-x");
rename(T1);
if(T1!="Nuclei") {if(CB1==1) {run("Duplicate...", "title=Cells duplicate");
run("Yellow");
cmb=1;		}		}
else {run("Z Project...", "projection=[Max Intensity]");
resetMinAndMax;
run("Enhance Contrast", "saturated=0.35");		}  

selectWindow("C2-x");
rename(T2);
if(T2!="Nuclei") {if(CB2==1) {if(cmb==1) {run("Duplicate...", "title=N duplicate");
imageCalculator("Add create stack", "Cells","N");
close("Cells");
close("N");
selectImage("Result of Cells");
rename("Cells");		}
else {run("Duplicate...", "title=Cells duplicate");		}
run("Yellow");
cmb=1;		}		}
else {run("Z Project...", "projection=[Max Intensity]");
resetMinAndMax;
run("Enhance Contrast", "saturated=0.35");		} 


selectWindow("C3-x");
rename(T3);
if(T3!="Nuclei") {if(CB3==1) {if(cmb==1) {run("Duplicate...", "title=N duplicate");
imageCalculator("Add create stack", "Cells","N");
close("Cells");
close("N");
selectImage("Result of Cells");
rename("Cells");		}
else {run("Duplicate...", "title=Cells duplicate");		}
run("Yellow");
cmb=1;		}		}
else {run("Z Project...", "projection=[Max Intensity]");
resetMinAndMax;
run("Enhance Contrast", "saturated=0.35");		} 	

selectWindow("Cells");
run("Z Project...", "projection=[Max Intensity]");
run("Gaussian Blur...", "sigma=2 stack");
resetMinAndMax;
run("Enhance Contrast", "saturated=0.35"); 
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
run("Fill Holes");
run("Watershed");
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
for (m = 0; m < clls; m++) {selectWindow("Cells");
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
run("Z Project...", "projection=[Sum Slices]");
dpt=getValue("Max");
close("SUM_MASK_S");
close("S");

selectImage("Nuclei");
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
run("Z Project...", "projection=[Sum Slices]");
nvol=getValue("RawIntDen");
close("SUM_MASK_N");
close("N");

imageCalculator("Subtract create stack", "MASK_S","MASK_N");
rename("MASK_C");
run("Z Project...", "projection=[Sum Slices]");
cvol=getValue("RawIntDen");
close("SUM_MASK_C");

selectImage("MASK_S");
run("Measure Stack...");
Table.sort("RawIntDen");
ctr=getResult("Slice");
close("Results");

selectImage("Target_A");
roiManager("select", m);
run("Duplicate...", "title=TA duplicate");
run("Select None");
setSlice(ctr);
run("Restore Selection");
run("Make Inverse");
bkgdA=getValue("Median");
run("Select None");

imageCalculator("Multiply create stack", "MASK_C","TA");
run("Z Project...", "projection=[Sum Slices]");
ctotA=getValue("RawIntDen");
csigA=ctotA-cvol*bkgdA;
close("SUM_Result of MASK_C");
close("Result of MASK_C");

imageCalculator("Multiply create stack", "MASK_N","TA");
run("Z Project...", "projection=[Sum Slices]");
ntotA=getValue("RawIntDen");
nsigA=ntotA-nvol*bkgdA;
close("SUM_Result of MASK_N");
close("Result of MASK_N");

selectImage("Target_B");
roiManager("select", m);
run("Duplicate...", "title=TB duplicate");
run("Select None");
setSlice(ctr);
run("Restore Selection");
run("Make Inverse");
bkgdB=getValue("Median");
run("Select None");

imageCalculator("Multiply create stack", "MASK_C","TB");
run("Z Project...", "projection=[Sum Slices]");
ctotB=getValue("RawIntDen");
csigB=ctotB-cvol*bkgdB;
close("SUM_Result of MASK_C");
close("Result of MASK_C");

imageCalculator("Multiply create stack", "MASK_N","TB");
run("Z Project...", "projection=[Sum Slices]");
ntotB=getValue("RawIntDen");
nsigB=ntotB-nvol*bkgdB;
close("SUM_Result of MASK_N");
close("Result of MASK_N");


close("MASK_C");
close("MASK_N");
close("MASK_S");
close("TA");
close("TB");

if(m==0) {print(f,ttl);		}
if(dpt>4) {print(f," "+"\t"+m+1+"\t"+dpt+"\t"+cvol+"\t"+nvol+"\t"+""+"\t"+bkgdA+"\t"+csigA+"\t"+nsigA+"\t"+""+"\t"+bkgdB+"\t"+csigB+"\t"+nsigB);			}
else {cllr=cllr-1;		}		}

if(cllr==0) {print(f," "+"\t"+"out of focus");			}
else {selectImage("MAX_Cells");
run("Outline");
run("Minimum...", "radius=1");
run("Invert");
run("Yellow");
run("RGB Color");
close("Cells");
close("Nuclei");
selectImage("MAX_Nuclei");
resetMinAndMax;
run("Enhance Contrast", "saturated=1.00");
run("RGB Color");
selectImage("Target_A");
run("Z Project...", "projection=[Max Intensity]");
resetMinAndMax;
run("Enhance Contrast", "saturated=0.35");
run("RGB Color");
close("Target_A");
selectImage("Target_B");
run("Z Project...", "projection=[Max Intensity]");
resetMinAndMax;
run("Enhance Contrast", "saturated=0.35");
run("RGB Color");
close("Target_B");
run("Images to Stack", "use");
run("Z Project...", "projection=[Max Intensity]");
roiManager("Show All with labels");
run("Flatten");
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




