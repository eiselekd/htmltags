if (typeof(document.htmltagid) == "undefined")
    document.htmltagid = "htmltag";
if (!top[document.htmltagid])
    top[document.htmltagid] = { };
if (!top[document.htmltagid].span)
    top[document.htmltagid].span = { };

top[document.htmltagid].span.replaceSpan = function (elem,str) {
    var span = top[document.htmltagid].find_ancestor(elem,"span");
    if (span == null) {
	return;
    }
    span.innerHTML = unescape(str);
};

top[document.htmltagid].span.showstruct = function ( thisid, id) {
    top[document.htmltagid].win.CreateDropdownWindow( document.getElementById('A'+thisid) ,"struct", id, true /*false*/);
};

top[document.htmltagid].span.showtool = function ( thisid, args) {
	var onextID = top[document.htmltagid].win.nextID;
	var argno = top[document.htmltagid].span.showtool.arguments.length-1;
	var tools = top[document.htmltagid].win.CreateDropdownWindow( document.getElementById('A'+thisid) ,"struct", argno , true /*false*/);
	for (i = 1; i < top[document.htmltagid].span.showtool.arguments.length; i++) {
		if (top[document.htmltagid].span.showtool.arguments[i]) {
			var elemid = top[document.htmltagid].span.showtool.arguments[i];
			var elem = document.getElementById(elemid);
			if (elem) {
				var html = elem.innerHTML;                                
				html = html.replace(/--xmlid--/g,onextID+".");
				top[document.htmltagid].replace(tools[i-1],html);
			} else if (elemid.substr(0,1) == 'L') {
				var n = elemid.substr(1);
				html = "<a href=\"_reload_"+n+".html\">"+n+"</a>";
                                //html = "<a href=\"test2.c.pinfo.main.html\">a</a>";
				html = html.replace(/--xmlid--/g,onextID+".");
				top[document.htmltagid].replace(tools[i-1],html);
			}
		}
	}
}
	
