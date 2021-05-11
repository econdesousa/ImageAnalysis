


#  BIOIMAGING - INEB/i3S
Eduardo Conde-Sousa (econdesousa@gmail.com)

****************************************************
## Process folder of LIF files
****************************************************

### code version
1

### last modification
11/05/2021

### Attribution:
If you use this macro please add in the acknowledgements of your papers and/or thesis (MSc and PhD) the reference to Bioimaging and the project PPBI-POCI-01-0145-FEDER-022122.
As a suggestion you may use the following sentence:
 * The authors acknowledge the support of the i3S Scientific Platform Bioimaging, member of the national infrastructure PPBI - Portuguese Platform of Bioimaging (PPBI-POCI-01-0145-FEDER-022122).


# Setup

```java
path=getDirectory("input directory");
outdir=getDirectory("output directory");
fileList = getFileList(path);
close("*");
print("\\Clear");
resetNonImageWindows();

```

# loop over all files in path

```java
for (i = 0; i < lengthOf(fileList); i++) {
	if (endsWith(fileList[i], "lif")) {
		run("Bio-Formats Macro Extensions");
		Ext.setId(path+fileList[i]);
		Ext.getCurrentFile(file);
		Ext.getSeriesCount(seriesCount);
		for (s=1; s<=seriesCount; s++) {
			proc1Image(path,fileList[i],s,outdir);
			close("*");
		}
	}
}

```
<pre>
> 12 2 well.lif - Series002
> 12 2 well.lif - Series005
> 12 2 well.lif - Series008
> 12 2 well.lif - Series011
> 12 2 well.lif - Series014
> 12 2 well.lif - Series017
> 12 crispr.lif - Series002
> 12 crispr.lif - Series005
> 12 crispr.lif - Series007
> 12 crispr.lif - Series009
> 12 crispr.lif - Series012
> 12 crispr.lif - Series015
> 12 crispr.lif - Series020
> 12 crispr.lif - Series024
> 12 crispr.lif - Series029
> 12 crispr.lif - Series032
> 12 crispr.lif - Series035
> Hela 2 well.lif - Series003
> Hela 2 well.lif - Series007
> Hela 2 well.lif - Series010
> Hela 2 well.lif - Series013
> Hela 2 well.lif - Series017
> Hela 2 well.lif - Series021
> HeLa.lif - Series002
> HeLa.lif - Series005
> HeLa.lif - Series008
> HeLa.lif - Series011
> HeLa.lif - Series014
> HeLa.lif - Series018
> HeLa.lif - Series021
> HeLa.lif - Series024
> HeLa.lif - Series027
> HeLa.lif - Series030
</pre>

# main function

```java

function proc1Image(path,filename,s,outdir) {
	run("Bio-Formats Importer", "open=["+path+filename+"]  autoscale color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_"+s);
	print(getTitle());
	// paste main code here
}
```

# auxiliary functions

```java

function resetNonImageWindows(){
	list = getList("window.titles");
	for (i = 0; i < lengthOf(list); i++) {
		selectWindow(list[i]);run("Close");
	}
}
```


