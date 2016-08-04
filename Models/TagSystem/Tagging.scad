
// Currently used supervariables are: $managed, $shown, $not-shown, $colortable

$managed = false;


function contains(sArray, cString) = (len(sArray) > 0) ? max( [for(i = [0:len(sArray) -1]) sArray[i] == cString ? 1 : 0 ]) == 1 : false;

module color_appropriately(tagname) {
	if($colortable != $colortable) {
		children();
	}
	else {
		coloring = $colortable[search([tagname], $colortable, 1, 0)[0] + 1];
		if(coloring == coloring)
			color(coloring) children();
	}
}

module tag(tagname, showDefault = false) {
	if(!$managed && showDefault == true) {
		color_appropriately(tagname) children();
	}
	else if((len($shown) > 0) && contains($shown, tagname)) {
		color_appropriately(tagname) children();
	}
	else if((len($not_shown) > 0) && !contains($not_shown, tagname)) {
		color_appropriately(tagname) children();
	}
}

module showTag(tagname) {
	$managed = true;
	if(!(contains($not_shown, tagname) || contains($shown, tagname))) {
		$shown = concat($shown, tagname);
		children();
	}
	else 
		children();
}

module hideTag(tagname) {
	$managed = true;
	if(!(contains($not_shown, tagname) || contains($shown, tagname))) {
		$not_shown = concat($not_shown, tagname);
		children();
	}
	else 
		children();
}

module colorTag(tagname, coloring) {
	$colortable = concat($colortable, [tagname, coloring]);
	children();
}

hideTag("mop")
colorTag("test", "red")
colorTag("mop", "blue") {
	tag("test") sphere(r = 10);
	tag("mop") cube([15, 5, 5]);
}
