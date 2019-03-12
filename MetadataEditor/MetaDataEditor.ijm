// This macro allows to add/edit metadata associated with an image
// Save image as Tiff if you want to retain metadata

// File retrived from: https://imagej.nih.gov/ij/macros/examples/2010-macros-workshop/metadata_editor.txt with a single edition on line 33

macro "Edit metadata [F1]" {
	List.setList(getMetadata("Info"));
	keys = getListKeys();

	Dialog.create("Metadata Editor");
		for (i=0;i<keys.length;i++){
			Dialog.addString(keys[i],List.get(keys[i]));
		}
		Dialog.addCheckbox("add", false); 
   		Dialog.addString("new_key","key");
   		Dialog.addString("new_value","value");
	Dialog.show();

	for (i=0;i<keys.length;i++) {
    		List.set(keys[i],Dialog.getString());
  	}
	if (Dialog.getCheckbox()==true) {
		newKey=Dialog.getString();
		newValue=Dialog.getString();
    		List.set(newKey,newValue);
	} 
 	setMetadata("Info",List.getList());
}


function getListKeys() {
	lines = split(List.getList(),'\n');
	keys = Array.getSequence(List.size);
	for (i=0;i<lines.length;i++) {
		line = split(lines[i],"=");
		keys[i]=line[0];
	}
	keys = Array.sort(keys);
	return keys;
}