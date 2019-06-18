/*
 * b.IMAGE - 28/06/2018
 * INEB -  Instituto Nacional de Engenharia Biomedica
 * i3S - Instituto de Investigacao e Inovacao em Saude
 * 
 * authors:
 * Eduardo Conde-Sousa 
 * econdesousa@ineb.up.pt
 * 
 * 
 * 
 * 
 * ##########################################################################
 * compute the Edit Distance between two strings
 * ##########################################################################
 * 
 * 
 * 
 * adapted from:
 * 				
 * 				https://www.geeksforgeeks.org/edit-distance-dp-5/
 * 	
 * 	
 * 	Very inefficient for large strings (sentences)
 * 	
 * 	don't work for all possible cases
 * 	ijm language don't distinguish lowercase from uppercase
 * 
 */
 
 

/* 
 * differences between strings 1 and 2:
 * 
 * replacements:
 * 
 * 		"L__g" replaced by "Long":			replacement "__" by "on":	2 diffs
 * 		"IsAL" replaced by "Is_L":			replacement "A" by "_":		1 diff
 * 
 * deletions:
 * 
 * 		"thisIs" converted to "this Is":	Insertion of " ":			1 diff	
 * 		
 * 	insertions:
 * 	
 * 		"this" converted to "ths": 			deletion of a "i":			1 diff
 */
 
string1="thisIsAL__gString";
string2="ths Is_LongString";

windows = getList("window.titles"); 
for (i=0; i<windows.length; i++){
	selectWindow(windows[i]);
	if(windows[i]=="Log"){
		run("Close");
	}
} 

print("edit distance between ");
print("        "+string1);
print("and");
print("        "+string2);
print("is:");

dist=editDist(string1,string2);
print("        "+ dist);


function editDist(str1,str2){
	return editDist_bounded(str1,str2,lengthOf(str1),lengthOf(str2));
}

function editDist_bounded( str1 , str2 , m , n){ 
    // If first string is empty, the only option is to 
    // insert all characters of second string into first 
    if (m == 0) {
    	return n; 
    }else{  
	    // If second string is empty, the only option is to 
	    // remove all characters of first string 
	    if (n == 0) {
	    	return m; 
	    }else{
  
		    // If last characters of two strings are same, nothing 
		    // much to do. Ignore last characters and get count for 
		    // remaining strings. 
		    if ( substring(str1, m-1,m) == substring(str2,n-1,n) ){
		    	return editDist_bounded(str1, str2, m-1, n-1); 
		    
		    }else{
  
			    // If last characters are not same, consider all three 
			    // operations on last character of first string, recursively 
			    // compute minimum cost for all three operations and take 
			    // minimum of three values. 
			    ins = editDist_bounded(str1,  str2, m, n-1);		// Insert
			    rem = editDist_bounded(str1,  str2, m-1, n); 	// Remove
			    rep = editDist_bounded(str1,  str2, m-1, n-1);	// Replace 
			    
			    // print(1+ins);
			    // print(1+rem);
			    // print(1+rep);
			    
			    return 1 + minOf(minOf(ins, rem), rep);
		    }
	    }
    }  																			
} 
