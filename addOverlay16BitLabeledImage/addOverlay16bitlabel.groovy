/*
 * b.IMAGE - 03/07/2020
 * INEB -  Instituto Nacional de Engenharia Biomedica
 * i3S - Instituto de Investigacao e Inovacao em Saude
 * 
 * author:
 * Eduardo Conde-Sousa
 * econdesousa@ineb.up.pt
 * econdesousa@gmail.com
 * 
 * 
 *
 * ########################################################################## 
 * add overlay to from 16-bit labeled image.
 * ########################################################################## 
 * 
 * 
 * adapted from Christian Tischer's code: https://forum.image.sc/t/16bit-lut-for-label-masks/10425/20
 * 
 * input 
 * 			'main image'
 * 					can be any image that can be open with IJ.openImage();
 * 			
 * 			'labeled image' 
 * 					an ilastik output of object classification workflow
 * 					or
 * 					an tif/jpeg/... label image
 *  
 * 
 * 
 * 
 * If you use this macro please add in the acknowledgements 
 * of your papers and/or thesis (MSc and PhD) the reference 
 * to Bioimaging and the project PPBI-POCI-01-0145-FEDER-022122. 
 * 
 * As a suggestion you may use the following sentence:
 * 
 * The authors acknowledge the support of the i3S Scientific Platform 
 * Bioimaging, member of the national infrastructure 
 * PPBI - Portuguese Platform of Bioimaging (PPBI-POCI-01-0145-FEDER-022122).
 * 
 * 
 * code version: 0.1	
 */


import ij.IJ
import ij.ImagePlus
import ij.gui.ImageRoi
import ij.gui.Overlay
import ij.process.ShortProcessor

import java.awt.image.BufferedImage
import java.awt.image.IndexColorModel

#@ DatasetIOService ds
#@ UIService ui
#@ File(label='main image') file
#@ File(label='labeled image') fileLab



impRaw = IJ.openImage(file.getAbsolutePath());
impRaw.show()	


if ( fileLab.toString().endsWith("h5") ){
	IJ.run("Import HDF5", "select=["+fileLab+"] datasetname=[/exported_data: (49, 512, 512, 1) uint32] axisorder=tyxc");
}else{
	impLab = IJ.openImage(fileLab.getAbsolutePath());
	impLab.show()
}
impLabel = IJ.getImage();



// Create a random 16-bit LUT
int n = Math.pow(2, 16)-1 as int
def r = new byte[n]
def g = new byte[n]
def b = new byte[n]
def a = new byte[n]
def rand = new Random(100L)
rand.nextBytes(r)
rand.nextBytes(g)
rand.nextBytes(b)
Arrays.fill(a, (byte)255)
a[0] = 0
def model = new IndexColorModel(16, n, r, g, b, a)

// Create a colored overlay
int width = impLabel.getWidth()
int height = impLabel.getHeight()
def overlay = new Overlay()
for (int s = 1; s <= impLabel.getStack().getSize(); s++) {
    def pixels = impLabel.getStack().getPixels(s) as short[]
    def raster = model.createCompatibleWritableRaster(width, height)
    def buffer = raster.getDataBuffer()
    System.arraycopy(pixels, 0, buffer.getData(), 0, buffer.getData().length);
    def img = new BufferedImage(model, raster, false, null)
    def roi = new ImageRoi(0, 0, img)
    roi.setOpacity(0.75)
    roi.setPosition(s)
    overlay.add(roi)
}

impRaw.setOverlay( overlay )
impLabel.close()
