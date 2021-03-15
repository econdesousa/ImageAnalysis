/*

#  BIOIMAGING - INEB/i3S
Eduardo Conde-Sousa (econdesousa@gmail.com)

## Code Header Generator

Generates header for macro scripts
Code base on https://twitter.com/DrNickCondon/status/1250310396642078720

### code version
0.1
### last modification
15/03/2021 at 16:56:10 (GMT)

### Attribution:
If you use this macro please add in the acknowledgements of your papers and/or thesis (MSc and PhD) the reference to Bioimaging and the project PPBI-POCI-01-0145-FEDER-022122.
As a suggestion you may use the following sentence:
 * The authors acknowledge the support of the i3S Scientific Platform Bioimaging, member of the national infrastructure PPBI - Portuguese Platform of Bioimaging (PPBI-POCI-01-0145-FEDER-022122).

*/



//code base on https://twitter.com/DrNickCondon/status/1250310396642078720





print("\\Clear");
var msg1="";
var msg2="";

Dialog.create("Details");
Dialog.addString("Script Title", "Title",100);
Dialog.addString("Institution", "BIOIMAGING - INEB/i3S",100);
Dialog.addString("Author", "Eduardo Conde-Sousa",100);
Dialog.addString("email", "econdesousa@gmail.com",100);
Dialog.addString("Version", "0.1",100);
Dialog.addString("Description", "Description",100);
Dialog.addMessage("Note: you can use <br> for a line break");
Dialog.show();

codeTitle		= Dialog.getString();
codeInstitution = Dialog.getString();
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
	if (hour <10){hour = "0" + hour;}
	if (minute <10){minute = "0" + minute;}
	if (second <10){second = "0" + second;}
	month = month +1;
	if (month <10){month = "0" + month;}
	printDate = toString(dayOfMonth) + "/" + month + "/" + year + " at "+ hour +":"+ minute +":"+ second +" (GMT)";
	//print("last modification: "+ printDate);

	msg1="INEB/i3S";
	msg2="<html>"
	+"<h1><font color=blue>"+codeInstitution+"</h1>"
	+"<p1><b>"+codeAuthor+"</b><br></p1>"
	+"<a href=\"mailto:"+codeEmail+"\">"+codeEmail+"</a><br>"
	+"<p1>"+titlebreak+"<br><font color=red>"+codeTitle+"</font><br>"+titlebreak+"<br></p1>"
	+"<p1>"+codeDescription+"<br>"
	+"<br>code version: <b>"+codeVersion+"</b><br>"
	+"last modification: "+ printDate +"</p1>"
	+"<h3>Attribution:</h3>"
	+"<p1>If you use this macro please add in the acknowledgements of your papers and/or thesis (MSc and PhD) the reference to Bioimaging and the project PPBI-POCI-01-0145-FEDER-022122.<br><br>"
	+"As a suggestion you may use the following sentence:</p1>"
	+"<ul><li>The authors acknowledge the support of the i3S Scientific Platform Bioimaging, member of the national infrastructure PPBI - Portuguese Platform of Bioimaging (PPBI-POCI-01-0145-FEDER-022122).</li></ul>"
	+"</html>";

	print("/*");
	print("");
	print("# ",codeInstitution);
	print(codeAuthor,"("+codeEmail+")");
	print("");
	print("## "+codeTitle);
	print("");
	print(codeDescription);
	print("");
	print("### code version");
	print(codeVersion);
	print("### last modification");
	print(printDate);
	print("");
	print("### Attribution:");
	print("If you use this macro please add in the acknowledgements of your papers and/or thesis (MSc and PhD) the reference to Bioimaging and the project PPBI-POCI-01-0145-FEDER-022122.");
	print("As a suggestion you may use the following sentence:");
	print(" * The authors acknowledge the support of the i3S Scientific Platform Bioimaging, member of the national infrastructure PPBI - Portuguese Platform of Bioimaging (PPBI-POCI-01-0145-FEDER-022122).");
	print("");
	print("*/");
	print("");
	print("showMessage(\"INEB/i3S\" ,\""+msg2+"\")");
}