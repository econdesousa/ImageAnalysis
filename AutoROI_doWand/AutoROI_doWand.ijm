/*
 * b.IMAGE - 13/11/2018
 * INEB -  Instituto Nacional de Engenharia Biomedica
 * i3S - Instituto de Investigacao e Inovacao em Saude
 * 
 * authors:
 * Eduardo Conde-Sousa (1)			Paulo Aguiar
 * econdesousa@ineb.up.pt			pauloaguiar@ineb.up.pt
 * 
 * (1) corresponding author
 * 
 */

start = getTime(); 

silent=true;
slowMotion=100;
// Parameters
threshold=0.7;
Porportion=0.12;
minSize=0.40;
Dialog.create("Parameters:");
Dialog.addNumber("Threshold:", threshold);
Dialog.addNumber("Porportion:", Porportion);
Dialog.addNumber("MinSize", minSize);
Dialog.addNumber("Slow Motion:", slowMotion);
Dialog.addCheckbox("Silent Mode ", silent);
//Dialog.addMessage("Time between updates. Only works if Silent is off)") ;
Dialog.show();
threshold = Dialog.getNumber();
Porportion = Dialog.getNumber();;
minSize = Dialog.getNumber();
silent = Dialog.getCheckbox();
if (!silent){
	slowMotion = Dialog.getNumber();
}else{
	slowMotion = 0;
}
slowMotion=abs(slowMotion);



//print uesed parameters
if (!silent){
	print("\\Update"+0+":Threshold  = "+threshold);
	print("\\Update"+1+":Porportion = "+Porportion);
	print("\\Update"+2+":MinSize    = "+minSize);
	print("\\Update"+3+":Silent    = "+silent);
}



setBatchMode(silent);
T=getTitle();
run("Select None");
run("Duplicate...", "title=mask");
run("8-bit");

run("Clear Results") ;
getRawStatistics(nPixels, mean, min, max);
run("Find Maxima...", "noise="+max+" output=[Point Selection]"); 
getSelectionBounds(x, y, w, h); 
//print("coordinates=("+x+","+y+"), value="+getPixel(x,y)); 
it=0;
histSize=5;
startingThresh=1;
stepSize=1;
stdVec=newArray(255);
AreaVec=newArray(255);
thVec=newArray(255);
th=startingThresh-stepSize;
flag=0;
MAX=max;
plateau=newArray(2);
flag=0;
dir=1;
plateau[1]=MAX;

while(th<255){
	th+=stepSize;
	thVec[it]=th;
	//wait(100);
	doWand(x, y, th, "smooth");
	wait(slowMotion);
	getStatistics(area);
	AreaVec[it]=area;
	if (it>=histSize){
		tmpvec=Array.slice(AreaVec,it-histSize+1,it+1);
	}else{
		tmpvec=AreaVec;
	}
	Array.getStatistics(tmpvec, tmpmin, tmpmax, tmpmean, stdDev);
	stdVec[it]=stdDev;
		
	
	if(dir==1 && stdVec[it]>threshold){
		dir=-1;
	}
	if(dir==-1 && stdVec[it]<threshold){
		dir=1;
		plateau[0]=it+1;
	}
	it=it+1;
}
if (!silent){
	print("plateau[0]="+plateau[0]);
	print("plateau[1]="+plateau[1]);
}

threshold=floor(Porportion*plateau[0]+(1-Porportion)*plateau[1]);



if(!silent){
	setBatchMode(false);
	//print("\\Clear");
	print("MAX= "+MAX);
	print("threshold = "+threshold);
	//print(MAX-threshold+1);
	for(it=0;it<AreaVec.length;it++){
		setResult("th", it, it+1);
		setResult("area", it, AreaVec[it]);
		setResult("stdDev", it, stdVec[it]);
	}
	
	Plot.create("p1", "th", "area");
	Plot.add("Circle", thVec, AreaVec);
	Plot.show();
	
	
	Plot.create("p2", "th", "stdDev");
	Plot.add("Circle", thVec, stdVec);
	Plot.show();
}


selectWindow("mask");
setThreshold(threshold, 255);
run("Convert to Mask");
run("Invert");
run("Fill Holes");
run("Analyze Particles...", "size="+minSize+"-Infinity show=Masks");
selectWindow("mask");
close();
selectWindow("Mask of mask");
rename("mask");
run("Create Selection");
roiManager("add");
selectWindow(T);
roiManager("select", roiManager("count")-1);
roiManager("delete");
setBatchMode(false);
run("Restore Selection");
roiManager("add");
if (!silent){
	print("elapsed time: "+(getTime()-start)/1000+" sec");   
}
