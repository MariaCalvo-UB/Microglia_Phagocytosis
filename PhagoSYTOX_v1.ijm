/*
		Advanced Optical Microscopy Facility
		Scientific and Technological Centers- Clinic Campus
		Universitat de Barcelona
		C/ Casanova 143
		Barcelona 08036 
		Tel: 34 934037159
		Fax: 34 934024484
		mail: confomed@ccit.ub.edu
		------------------------------------------------
		Anna Bosch, Maria Calvo
		------------------------------------------------
		Name of Macro: 105_PhagoSYTOX_v1.ijm
		
		Date: 20/04/2018
		
		Objective: 	From a time lapse stack, the user selects the frame to analyze. The macro segments glia cells (red) and dead neurons (green).
					The macro measures the area of glia cells and, cell by cell, analyzes whether there are green particles (dead neurons) inside each cell, add them to the ROI manager, and measures each particle.
					When the frame analysis is finished, the macro asks user for analyzing another frame or stop.
		
		Input: Hyperstack (3Ch, nZ, nT)
		
		Output: The macro saves automaticaly: 	Projection of selected time-frame with flatten regions.
												Results of selected time-frame
												Summary of selected time-frame
												ROIs of selected time-frame
		
		Changes from last version:  	- Addition of a "wait for user" to check ROIs after segmentation of cells
										- Removal of Summary table
										- The region "outside" is actually All except the cells. In the last version was "All"
		
		Install macro: The first time: Create a "PersonalMacros" folder in your ImageJ's plugins folder. Copy this macro file, and place it in the "PersonalMacros" folder.
		
		*/

		
		dir = getDirectory("Choose directory to save results");
		run("Set Measurements...", "area perimeter shape display redirect=None decimal=3");
		title=getTitle();
		Stack.setChannel(1);
		run("Green");
		Stack.setChannel(2);
		run("Red");
		run("Z Project...", "projection=[Max Intensity] all");
		Stack.setDisplayMode("composite");
		Stack.setActiveChannels("110");
		originalStack=getImageID();
		do{
			cond=true;
			run("Select None");
			
			//Frame selection -------------------------------------------------------------------
			
			waitForUser("Select frame","Select frame.\n \nClick OK to continue");
			Stack.getPosition(channel, slice, timeFrame);
			run("Duplicate...", "duplicate channels=1-2 frames="+timeFrame);
			original=getImageID();
			run("Duplicate...", "duplicate");
			run("Split Channels");
			
			//get IDs of splitted Images
			
			for (i=1; i<=nImages; i++) {
					selectImage(i);
					t=getTitle();
					if (matches(t,"C1.*")==1){  // .*  to accept any value
					green=getImageID();
				}
					if (matches(t,"C2.*")==1){  // .*  to accept any value
					red=getImageID();
				}
			}
			
			//RED SEGMENTATION----------------------------------------------------------------------
			
			selectImage(red);
			rename(title+"_m_Frame-"+timeFrame);
			run("Mean...", "radius=1");
			setAutoThreshold("Huang dark");
			run("Threshold...");
			waitForUser("Threshold","Check Threshold.\n \n Click OK to continue");
			run("Convert to Mask");
			waitForUser("Check Mask", "Draw borders if necessary.\n \nClick OK to continue");
			run("Analyze Particles...", "size=100-Infinity  add in_situ");
			waitForUser("Check ROIs","Add or Delete ROIs\n \nClick OK to continue");
			
			//Rename ROIs Cell_1...
			
			roi=roiManager("count");
			for(j=0;j<roi;j++){
				roiManager("Select", j);
				roiManager("Rename", "Cell "+j+1);
			}
			
			//Measure cells
			
			roiManager("Deselect");
			roiManager("Measure");
			
			//Add outside cells region
			
			count=roiManager("count");
			ArrayRois=newArray(count); 
			for(j=0;j<count;j++){
				ArrayRois[j]=j;//Fill Array with numbers of ROIs (originals)
			}
			roiManager("Select", ArrayRois);
			roiManager("Combine");
			roiManager("Add");
			run("Select All");
			roiManager("Add");
			roiManager("Select", newArray(count,count+1));
			roiManager("XOR");
			roiManager("Add");
			roiManager("Select", count+2);
			roiManager("Rename", "Outside");
			roiManager("Select", newArray(count,count+1));
			roiManager("Delete");
			
			//GREEN SEGMENTATION------------------------------------------------------------------
			
			selectImage(green);
			rename(title+"_s_Frame-"+timeFrame);
			t=getTitle();
			run("Mean...", "radius=1");
			setAutoThreshold("IsoData dark");
			run("Threshold...");
			waitForUser("Threshold","Check Threshold.\n \n Click OK to continue");
			run("Convert to Mask");
			//Analyze Particles Cell By Cell
			for(k=0;k<=roi;k++){
				roiManager("Select", k);
				run("Analyze Particles...", "size=1-Infinity display  add in_situ");
			}
			
			//SAVE-------------------------------------------------------------------------------
			
			//Save merged image + ROIs
			
			selectImage(original);
			run("Flatten");
			roiManager("Show All with labels");
			run("Flatten");
			saveAs("tiff", dir+title+"_Frame-"+timeFrame+".tif"); 	
			
			//Save ROIs
			
			selectWindow("ROI Manager");
			roiManager("Deselect");
			roiManager("Save", dir+title+"_Frame-"+timeFrame+"_RoiSet.zip");
			
			//Save Results
			
			selectWindow("Results");			
			saveAs("measurements",dir+title+"_Frame-"+timeFrame+".txt");
			
			//END OF FRAME ANALYSIS---------------------------------------------------------------------
			
			selectImage(originalStack);
			roiManager("Show All with labels");
			waitForUser("Check Results", "Check Results.\n \n Click OK to close all windows");
			selectImage(originalStack);
			close("\\Others");
			selectWindow("Results");
			run("Close");
			selectWindow("ROI Manager");
			roiManager("Show None");
			run("Close");
			if(isOpen("Threshold")){
			selectWindow("Threshold");
			run("Close");
			
			//ASK USER TO ANALYZE MORE FRAMES OR TO END MACRO-------------------------------------------
			
			Dialog.create("End of Frame analysis");
			Dialog.addMessage("Do you whant to analyze another Frame?");
			Dialog.addCheckbox("Yes", false);
			Dialog.addCheckbox("No", false);
			Dialog.show(); 
			yes=Dialog.getCheckbox(); 
			no=Dialog.getCheckbox(); 
			if(no==true){
				run("Close All");
				cond=false;
			}else{
				cond=true;
				}
			}
		}
		while(cond==true);
