/*
# BIOIMAGING 
Eduardo Conde-Sousa (econdesousa@gmail.com)

## Code Header Generator
Generates header for macro scripts
code base on https://twitter.com/DrNickCondon/status/1250310396642078720

### code version
0.1

### last modification
15/03/2021 at 15:51:29 (GMT)

### Attribution:
If you use this macro please add in the acknowledgements of your papers and/or thesis (MSc and PhD) the reference to Bioimaging and the project PPBI-POCI-01-0145-FEDER-022122.
As a suggestion you may use the following sentence:
 * The authors acknowledge the support of the i3S Scientific Platform Bioimaging, member of the national infrastructure PPBI - Portuguese Platform of Bioimaging (PPBI-POCI-01-0145-FEDER-022122).

*/



print("\\Clear");
var msg1="";
var msg2="";

Dialog.create("Details");
Dialog.addString("Script Title", "Title",100);
Dialog.addString("Author", "Eduardo Conde-Sousa",100);
Dialog.addString("email", "econdesousa@gmail.com",100);
Dialog.addString("Version", "0.1",100);
Dialog.addString("Description", "Description",100);
Dialog.addMessage("Note: you can use <br> for a line break");
Dialog.show();

codeTitle		= Dialog.getString();
codeAuthor		= Dialog.getString();
codeEmail		= Dialog.getString();
codeVersion		= Dialog.getString();
codeDescription = Dialog.getString();
titlebreak 		= "======================================";
titlebreak = titlebreak+titlebreak;



generateCode(codeTitle,codeAuthor,codeVersion,codeDescription,titlebreak);
showMessage(msg1,msg2);

function generateCode(codeTitle,codeAuthor,codeVersion,codeDescription,titlebreak){
	
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	
	if (dayOfMonth <10){dayOfMonth = "0" + dayOfMonth;}
	month = month +1;
	if (month <10){month = "0" + month;}
	printDate = toString(dayOfMonth) + "/" + month + "/" + year + " at "+ hour +":"+ minute +":"+ second +" (GMT)";
	//print("last modification: "+ printDate);

	msg1="INEB/i3S";
	msg2="<html>"
	+"<h1><font color=blue>BIOIMAGING</h1>"
	+"<p1><b>"+codeAuthor+"</b><br>"
	+"<a href=\"mailto:"+codeEmail+"\">"+codeEmail+"</a><br>"
	+titlebreak+"<br><b>"+codeTitle+"</b><br>"+titlebreak+"<br>"
	+codeDescription+"<br>"
	+"<br>code version: <b>"+codeVersion+"</b><br>"
	+"last modification: "+ printDate +"</p1>"
	+"<h3>Attribution:</h3>"
	+"<p1>"
	+"If you use this macro please add in the acknowledgements of your papers and/or thesis (MSc and PhD) the reference to Bioimaging and the project PPBI-POCI-01-0145-FEDER-022122.<br><br>"
	+"As a suggestion you may use the following sentence:"
	+"<ul><li>The authors acknowledge the support of the i3S Scientific Platform Bioimaging, member of the national infrastructure PPBI - Portuguese Platform of Bioimaging (PPBI-POCI-01-0145-FEDER-022122).</li></ul>"
	+"</p1>"	
	+"</html>";

	print("/*");
	print("# BIOIMAGING ");
	print(codeAuthor,"("+codeEmail+")");
	print("## "+codeTitle);
	print(codeDescription);
	print("### code version");
	print(codeVersion);
	print("### last modification");
	print(printDate);
	print("### Attribution:");
	print("If you use this macro please add in the acknowledgements of your papers and/or thesis (MSc and PhD) the reference to Bioimaging and the project PPBI-POCI-01-0145-FEDER-022122.");
	print("As a suggestion you may use the following sentence:");
	print(" * The authors acknowledge the support of the i3S Scientific Platform Bioimaging, member of the national infrastructure PPBI - Portuguese Platform of Bioimaging (PPBI-POCI-01-0145-FEDER-022122).");
	print("*/");
	print("");
	print("showMessage(\"INEB/i3S\" ,\""+msg2+"\")");
}