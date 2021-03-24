/*

#  BIOIMAGING - INEB/i3S
Eduardo Conde-Sousa 
econdesousa@gmail.com
econdesousa@i3s.up.pt

****************************************************
## Break up a lif into individual TIFF
****************************************************

Addapted from:
* https://depts.washington.edu/if/ij_lif.shtml

### code version
1.3

### last modification
24/03/2021 at 09:59:18 (GMT)

### Attribution:
If you use this macro please add in the acknowledgements of your papers and/or thesis (MSc and PhD) the reference to Bioimaging and the project PPBI-POCI-01-0145-FEDER-022122.
As a suggestion you may use the following sentence:
 * The authors acknowledge the support of the i3S Scientific Platform Bioimaging, member of the national infrastructure PPBI - Portuguese Platform of Bioimaging (PPBI-POCI-01-0145-FEDER-022122).

*/


macro "Break up a lif into individual TIFF" {
	// only the metadata specific to a series will be written
	setBatchMode(true);
	path = File.openDialog("Select a File");
	out_dir=getDirectory("Choose an Output Directory");
	run("Bio-Formats Macro Extensions");
	Ext.setId(path);
	Ext.getCurrentFile(file);
	Ext.getSeriesCount(seriesCount);
	
	for (s=1; s<=seriesCount; s++) {
		// Bio-Formats Importer uses an argument that can be built by concatenate a set of strings
		run("Bio-Formats Importer", "open=&path autoscale color_mode=Default view=Hyperstack stack_order=XYCZT series_"+s);
		proc1image(out_dir,s);
    }
}

function proc1image(out_dir,s){
	out_path = out_dir + "series_"+ s + "_" + getTitle() + ".tif";
	saveAs("tiff", out_path);
	close();
}
