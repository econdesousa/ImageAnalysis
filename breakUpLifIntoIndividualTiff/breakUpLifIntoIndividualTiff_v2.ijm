/*
 * bioimaging - 27/06/2019
 * INEB -  Instituto Nacional de Engenharia Biomedica
 * i3S - Instituto de Investigacao e Inovacao em Saude
 * 
 * Eduardo Conde-Sousa
 * econdesousa@ineb.up.pt
 * econdesousa@gmail.com
 * 
 * 
 * =====================================================
 * Break up a lif into individual TIFF
 * =====================================================
 * 
 * 
 * Addapted with only minor modifications from: 
 * 		
 * 		https://depts.washington.edu/if/ij_lif.shtml
 * 		
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
		out_path = out_dir + "series_"+ s + "_" + getTitle() + ".tif";
		saveAs("tiff", out_path);
		close();
    }
}